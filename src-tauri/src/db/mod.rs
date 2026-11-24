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
    // --- v2 : memorisation is per surah, not per reciter -------------------
    r#"
    CREATE TABLE IF NOT EXISTS memorization (
        surah      INTEGER PRIMARY KEY,
        memorized  TEXT NOT NULL DEFAULT '[]',
        updated_at INTEGER NOT NULL
    );
    "#,
];

/// Memorisation state for one surah. Ayah numbers are 1-based.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Memorization {
    pub surah: u16,
    #[serde(default)]
    pub memorized: Vec<u16>,
    #[serde(default)]
    pub updated_at: i64,
}

impl Memorization {
    #[allow(dead_code)]
    pub fn count(&self) -> usize {
        self.memorized.len()
    }
}

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

    // --- memorisation ------------------------------------------------------

    pub fn get_memorized(&self, surah: u16) -> Result<Vec<u16>> {
        let conn = self.conn.lock();
        let raw: Option<String> = conn
            .query_row(
                "SELECT memorized FROM memorization WHERE surah = ?1",
                [surah],
                |r| r.get(0),
            )
            .optional()?;
        Ok(raw
            .and_then(|json| serde_json::from_str(&json).ok())
            .unwrap_or_default())
    }

    pub fn save_memorized(&self, surah: u16, memorized: &[u16]) -> Result<()> {
        let mut marks = memorized.to_vec();
        marks.sort_unstable();
        marks.dedup();
        let json = serde_json::to_string(&marks)?;
        let conn = self.conn.lock();
        conn.execute(
            "INSERT INTO memorization(surah, memorized, updated_at) VALUES(?1, ?2, ?3)
             ON CONFLICT(surah) DO UPDATE SET
                memorized  = excluded.memorized,
                updated_at = excluded.updated_at",
            params![surah, json, now()],
        )?;
        Ok(())
    }

    /// All surahs with memorisation marks, most recently touched first.
    pub fn all_memorization(&self) -> Result<Vec<Memorization>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT surah, memorized, updated_at FROM memorization ORDER BY updated_at DESC",
        )?;
        let rows = stmt
            .query_map([], |r| {
                Ok(Memorization {
                    surah: r.get::<_, u16>(0)?,
                    memorized: serde_json::from_str(&r.get::<_, String>(1)?).unwrap_or_default(),
                    updated_at: r.get::<_, i64>(2)?,
                })
            })?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows)
    }

    // --- resume position ---------------------------------------------------

    /// Last ayah played for a surah under a given ayah-level reciter.
    pub fn get_position(&self, surah: u16, reciter_id: &str) -> Result<Option<u16>> {
        let conn = self.conn.lock();
        let value = conn
            .query_row(
                "SELECT last_ayah FROM surah_progress WHERE surah = ?1 AND reciter_id = ?2",
                params![surah, reciter_id],
                |r| r.get(0),
            )
            .optional()?;
        Ok(value)
    }

    pub fn save_position(&self, surah: u16, reciter_id: &str, last_ayah: u16) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute(
            "INSERT INTO surah_progress(surah, reciter_id, last_ayah, updated_at)
             VALUES(?1, ?2, ?3, ?4)
             ON CONFLICT(surah, reciter_id) DO UPDATE SET
                last_ayah  = excluded.last_ayah,
                updated_at = excluded.updated_at",
            params![surah, reciter_id, last_ayah, now()],
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

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_db() -> (std::path::PathBuf, Database) {
        let dir = std::env::temp_dir().join(format!(
            "dandanah-test-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        std::fs::create_dir_all(&dir).unwrap();
        let db = Database::open(&dir.join("test.db")).unwrap();
        (dir, db)
    }

    #[test]
    fn migrations_apply_and_memorisation_round_trips() {
        let (dir, db) = temp_db();
        // Deduplicates and sorts on write.
        db.save_memorized(2, &[5, 1, 5]).unwrap();
        assert_eq!(db.get_memorized(2).unwrap(), vec![1, 5]);
        assert_eq!(db.get_memorized(3).unwrap(), Vec::<u16>::new());

        db.save_position(2, "Husary_128kbps", 7).unwrap();
        assert_eq!(db.get_position(2, "Husary_128kbps").unwrap(), Some(7));
        assert_eq!(db.get_position(2, "Alafasy_128kbps").unwrap(), None);

        assert_eq!(db.all_memorization().unwrap().len(), 1);

        drop(db);
        let reopened = Database::open(&dir.join("test.db")).unwrap();
        assert_eq!(reopened.get_memorized(2).unwrap(), vec![1, 5]);
        assert_eq!(reopened.get_position(2, "Husary_128kbps").unwrap(), Some(7));
        drop(reopened);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn stale_cache_ignores_ttl() {
        let (dir, db) = temp_db();
        db.cache_put("k", "v").unwrap();
        assert!(db.cache_get("k", 60).unwrap().is_some());
        assert!(db.cache_get("k", -1).unwrap().is_none());
        assert_eq!(db.stale_cache("k").unwrap().map(|(p, _)| p), Some("v".into()));
        drop(db);
        let _ = std::fs::remove_dir_all(&dir);
    }
}
