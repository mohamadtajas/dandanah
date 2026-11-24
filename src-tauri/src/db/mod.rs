use crate::providers::Track;
use anyhow::{Context, Result};
use parking_lot::Mutex;
use rusqlite::{params, Connection, OptionalExtension};
use std::path::Path;

/// Schema migrations, applied in order and tracked with `PRAGMA user_version`.
const MIGRATIONS: &[&str] = &[
    // --- v1 : core library -------------------------------------------------
    r#"
    CREATE TABLE IF NOT EXISTS settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS cache (
        key        TEXT PRIMARY KEY,
        payload    TEXT NOT NULL,
        fetched_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS tracks (
        id           TEXT PRIMARY KEY,
        provider     TEXT NOT NULL,
        provider_id  TEXT NOT NULL,
        title        TEXT NOT NULL,
        artist       TEXT NOT NULL DEFAULT '',
        album        TEXT,
        duration_s   INTEGER,
        artwork_url  TEXT,
        local_path   TEXT,
        is_local     INTEGER NOT NULL DEFAULT 0,
        license      TEXT,
        license_url  TEXT,
        attribution  TEXT,
        source_page  TEXT,
        kind         TEXT NOT NULL DEFAULT 'music',
        added_at     INTEGER NOT NULL
    );
    CREATE UNIQUE INDEX IF NOT EXISTS idx_tracks_provider
        ON tracks(provider, provider_id);

    CREATE TABLE IF NOT EXISTS playlists (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        cover_path TEXT,
        created_at INTEGER NOT NULL,
        sort       INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS playlist_items (
        playlist_id TEXT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
        track_id    TEXT NOT NULL,
        position    INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, track_id)
    );

    CREATE TABLE IF NOT EXISTS favorites (
        track_id TEXT PRIMARY KEY,
        added_at INTEGER NOT NULL,
        payload  TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS history (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        track_id   TEXT NOT NULL,
        payload    TEXT NOT NULL,
        played_at  INTEGER NOT NULL,
        position_s INTEGER NOT NULL DEFAULT 0,
        completed  INTEGER NOT NULL DEFAULT 0
    );
    CREATE INDEX IF NOT EXISTS idx_history_played ON history(played_at DESC);

    CREATE TABLE IF NOT EXISTS downloads (
        track_id    TEXT PRIMARY KEY,
        payload     TEXT NOT NULL,
        status      TEXT NOT NULL DEFAULT 'queued',
        bytes_total INTEGER NOT NULL DEFAULT 0,
        bytes_done  INTEGER NOT NULL DEFAULT 0,
        file_path   TEXT,
        error       TEXT,
        created_at  INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS surah_progress (
        surah       INTEGER NOT NULL,
        reciter_id  TEXT NOT NULL,
        last_ayah   INTEGER NOT NULL DEFAULT 1,
        memorized   TEXT NOT NULL DEFAULT '[]',
        updated_at  INTEGER NOT NULL,
        PRIMARY KEY (surah, reciter_id)
    );
    "#,
];

pub struct Database {
    conn: Mutex<Connection>,
}

impl Database {
    pub fn open(path: &Path) -> Result<Self> {
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent).ok();
        }
        let conn = Connection::open(path)
            .with_context(|| format!("opening database at {}", path.display()))?;
        conn.pragma_update(None, "journal_mode", "WAL").ok();
        conn.pragma_update(None, "synchronous", "NORMAL").ok();
        conn.pragma_update(None, "foreign_keys", "ON").ok();
        let db = Self {
            conn: Mutex::new(conn),
        };
        db.migrate()?;
        Ok(db)
    }

    fn migrate(&self) -> Result<()> {
        let conn = self.conn.lock();
        let current: i64 = conn
            .query_row("PRAGMA user_version", [], |r| r.get(0))
            .unwrap_or(0);
        let target = MIGRATIONS.len() as i64;
        if current >= target {
            return Ok(());
        }
        for (i, sql) in MIGRATIONS.iter().enumerate().skip(current as usize) {
            conn.execute_batch(sql)
                .with_context(|| format!("applying migration v{}", i + 1))?;
        }
        conn.pragma_update(None, "user_version", target)
            .context("recording schema version")?;
        Ok(())
    }

    // --- settings ---------------------------------------------------------

    #[allow(dead_code)]
    pub fn get_setting(&self, key: &str) -> Result<Option<String>> {
        let conn = self.conn.lock();
        let value = conn
            .query_row("SELECT value FROM settings WHERE key = ?1", [key], |r| r.get(0))
            .optional()?;
        Ok(value)
    }

    pub fn set_setting(&self, key: &str, value: &str) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute(
            "INSERT INTO settings(key, value) VALUES(?1, ?2)
             ON CONFLICT(key) DO UPDATE SET value = excluded.value",
            params![key, value],
        )?;
        Ok(())
    }

    pub fn all_settings(&self) -> Result<Vec<(String, String)>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare("SELECT key, value FROM settings")?;
        let rows = stmt
            .query_map([], |r| Ok((r.get(0)?, r.get(1)?)))?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows)
    }

    // --- response cache ---------------------------------------------------

    pub fn cache_get(&self, key: &str, max_age_secs: i64) -> Result<Option<String>> {
        let conn = self.conn.lock();
        let row = conn
            .query_row(
                "SELECT payload, fetched_at FROM cache WHERE key = ?1",
                [key],
                |r| Ok((r.get::<_, String>(0)?, r.get::<_, i64>(1)?)),
            )
            .optional()?;
        match row {
            Some((payload, at)) if now() - at <= max_age_secs => Ok(Some(payload)),
            _ => Ok(None),
        }
    }

    /// Returns a cached payload regardless of age — used as an offline fallback.
    pub fn stale_cache(&self, key: &str) -> Result<Option<(String, i64)>> {
        let conn = self.conn.lock();
        let row = conn
            .query_row(
                "SELECT payload, fetched_at FROM cache WHERE key = ?1",
                [key],
                |r| Ok((r.get::<_, String>(0)?, r.get::<_, i64>(1)?)),
            )
            .optional()?;
        Ok(row)
    }

    pub fn cache_put(&self, key: &str, payload: &str) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute(
            "INSERT INTO cache(key, payload, fetched_at) VALUES(?1, ?2, ?3)
             ON CONFLICT(key) DO UPDATE SET payload = excluded.payload, fetched_at = excluded.fetched_at",
            params![key, payload, now()],
        )?;
        Ok(())
    }

    // --- history ----------------------------------------------------------

    pub fn record_play(&self, track: &Track) -> Result<()> {
        let payload = serde_json::to_string(track)?;
        let conn = self.conn.lock();
        conn.execute(
            "INSERT INTO history(track_id, payload, played_at) VALUES(?1, ?2, ?3)",
            params![track.id, payload, now()],
        )?;
        // keep the table bounded
        conn.execute(
            "DELETE FROM history WHERE id NOT IN (SELECT id FROM history ORDER BY played_at DESC LIMIT 2000)",
            [],
        )?;
        Ok(())
    }

    pub fn recent(&self, limit: u32) -> Result<Vec<Track>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT payload FROM history
             GROUP BY track_id
             ORDER BY MAX(played_at) DESC
             LIMIT ?1",
        )?;
        let rows = stmt
            .query_map([limit], |r| r.get::<_, String>(0))?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        drop(stmt);
        Ok(rows
            .into_iter()
            .filter_map(|p| serde_json::from_str(&p).ok())
            .collect())
    }
}

pub fn now() -> i64 {
    chrono::Utc::now().timestamp()
}
