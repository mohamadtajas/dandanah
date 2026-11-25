use crate::adhkar::{AdhkarDay, AdhkarProgress, EVENING, MORNING};
use crate::providers::Track;
use crate::worship::PrayerLog;
use anyhow::{Context, Result};
use parking_lot::Mutex;
use rusqlite::{params, Connection, OptionalExtension};
use serde::{Deserialize, Serialize};
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
    // --- v3 : track payloads for playlists and local files ------------------
    r#"
    ALTER TABLE tracks ADD COLUMN payload TEXT;
    CREATE INDEX IF NOT EXISTS idx_tracks_kind ON tracks(kind);
    CREATE INDEX IF NOT EXISTS idx_tracks_added ON tracks(added_at DESC);
    "#,
    // --- v4 : daily prayer log ---------------------------------------------
    r#"
    CREATE TABLE IF NOT EXISTS prayer_log (
        date       TEXT PRIMARY KEY,
        fajr       INTEGER NOT NULL DEFAULT 0,
        dhuhr      INTEGER NOT NULL DEFAULT 0,
        asr        INTEGER NOT NULL DEFAULT 0,
        maghrib    INTEGER NOT NULL DEFAULT 0,
        isha       INTEGER NOT NULL DEFAULT 0,
        excused    INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
    );
    "#,
    // --- v5 : adhkar progress and daily completion --------------------------
    r#"
    CREATE TABLE IF NOT EXISTS adhkar_progress (
        date        TEXT NOT NULL,
        category_id TEXT NOT NULL,
        item_id     TEXT NOT NULL,
        remaining   INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        PRIMARY KEY (date, category_id, item_id)
    );

    CREATE TABLE IF NOT EXISTS adhkar_log (
        date       TEXT PRIMARY KEY,
        morning    INTEGER NOT NULL DEFAULT 0,
        evening    INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
    );
    "#,
    // --- v6 : Quran reader bookmarks and last position ----------------------
    r#"
    CREATE TABLE IF NOT EXISTS quran_bookmarks (
        surah      INTEGER NOT NULL,
        ayah       INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (surah, ayah)
    );

    CREATE TABLE IF NOT EXISTS reader_state (
        id         INTEGER PRIMARY KEY CHECK (id = 1),
        surah      INTEGER NOT NULL,
        ayah       INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
    );
    "#,
    // --- v7 : remember whether the reader was in surah or juz mode ---------
    r#"
    ALTER TABLE reader_state ADD COLUMN mode TEXT NOT NULL DEFAULT 'surah';
    ALTER TABLE reader_state ADD COLUMN juz INTEGER NOT NULL DEFAULT 1;
    "#,
    // --- v8 : exact partial file path for resume, storage and deletion ------
    r#"
    ALTER TABLE downloads ADD COLUMN part_path TEXT;
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

/// A saved playlist with its item count, for the library list.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Playlist {
    pub id: String,
    pub name: String,
    pub created_at: i64,
    pub track_count: u32,
}

/// One row of the downloads table.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DownloadRow {
    pub track: Track,
    pub status: String,
    pub bytes_total: u64,
    pub bytes_done: u64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub file_path: Option<String>,
    /// Partial file while a download is running, so resume, totals and delete
    /// all point at the same bytes.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub part_path: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
    pub created_at: i64,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct QuranBookmark {
    pub surah: u16,
    pub ayah: u16,
    pub created_at: i64,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ReaderPosition {
    /// `surah` or `juz`.
    pub mode: String,
    pub juz: u16,
    pub surah: u16,
    pub ayah: u16,
    pub updated_at: i64,
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
        // A download cannot survive a restart; surface it as interrupted rather
        // than leaving a phantom "downloading" row forever.
        let _ = db.conn.lock().execute(
            "UPDATE downloads SET status = 'error', error = 'interrupted'
             WHERE status IN ('queued', 'downloading')",
            [],
        );
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
            // Each schema change and its version bump commit together, so a
            // crash cannot leave ALTER TABLE half-applied with a stale version.
            let tx = conn
                .unchecked_transaction()
                .context("starting migration transaction")?;
            tx.execute_batch(sql)
                .with_context(|| format!("applying migration v{}", i + 1))?;
            tx.pragma_update(None, "user_version", (i + 1) as i64)
                .with_context(|| format!("recording migration v{}", i + 1))?;
            tx.commit()
                .with_context(|| format!("committing migration v{}", i + 1))?;
        }
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

    // --- prayer log --------------------------------------------------------

    fn read_prayer_log(conn: &Connection, date: &str) -> Result<PrayerLog> {
        let row = conn
            .query_row(
                "SELECT date, fajr, dhuhr, asr, maghrib, isha, excused
                 FROM prayer_log WHERE date = ?1",
                [date],
                prayer_row,
            )
            .optional()?;
        Ok(row.unwrap_or_else(|| PrayerLog::empty(date)))
    }

    pub fn prayer_log(&self, date: &str) -> Result<PrayerLog> {
        let conn = self.conn.lock();
        Self::read_prayer_log(&conn, date)
    }

    /// Every logged day, oldest first. At most one row per day.
    pub fn prayer_logs(&self) -> Result<Vec<PrayerLog>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT date, fajr, dhuhr, asr, maghrib, isha, excused
             FROM prayer_log ORDER BY date ASC",
        )?;
        let rows = stmt.query_map([], prayer_row)?.collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows)
    }

    pub fn set_prayer_done(&self, date: &str, prayer: &str, done: bool) -> Result<PrayerLog> {
        validate_log_date(date)?;
        let column = match prayer {
            "fajr" => "fajr",
            "dhuhr" => "dhuhr",
            "asr" => "asr",
            "maghrib" => "maghrib",
            "isha" => "isha",
            other => anyhow::bail!("unknown prayer: {other}"),
        };
        {
            let conn = self.conn.lock();
            conn.execute(
                "INSERT INTO prayer_log(date, updated_at) VALUES(?1, ?2)
                 ON CONFLICT(date) DO NOTHING",
                params![date, now()],
            )?;
            conn.execute(
                &format!("UPDATE prayer_log SET {column} = ?1, updated_at = ?2 WHERE date = ?3"),
                params![done as i32, now(), date],
            )?;
        }
        self.prayer_log(date)
    }

    pub fn set_prayer_excused(&self, date: &str, excused: bool) -> Result<PrayerLog> {
        validate_log_date(date)?;
        {
            let conn = self.conn.lock();
            conn.execute(
                "INSERT INTO prayer_log(date, updated_at) VALUES(?1, ?2)
                 ON CONFLICT(date) DO NOTHING",
                params![date, now()],
            )?;
            conn.execute(
                "UPDATE prayer_log SET excused = ?1, updated_at = ?2 WHERE date = ?3",
                params![excused as i32, now(), date],
            )?;
        }
        self.prayer_log(date)
    }

    // --- adhkar ------------------------------------------------------------

    pub fn adhkar_progress(&self, date: &str) -> Result<Vec<AdhkarProgress>> {
        validate_log_date(date)?;
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT date, category_id, item_id, remaining
             FROM adhkar_progress WHERE date = ?1
             ORDER BY category_id, item_id",
        )?;
        let rows = stmt
            .query_map([date], |r| {
                Ok(AdhkarProgress {
                    date: r.get(0)?,
                    category_id: r.get(1)?,
                    item_id: r.get(2)?,
                    remaining: r.get::<_, i64>(3)?.max(0) as u32,
                })
            })?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows)
    }

    pub fn set_adhkar_remaining(
        &self,
        date: &str,
        category_id: &str,
        item_id: &str,
        remaining: u32,
    ) -> Result<AdhkarProgress> {
        validate_log_date(date)?;
        if category_id.trim().is_empty() || item_id.trim().is_empty() {
            anyhow::bail!("adhkar category and item ids are required");
        }
        let remaining = remaining.min(1000);
        {
            let conn = self.conn.lock();
            conn.execute(
                "INSERT INTO adhkar_progress(date, category_id, item_id, remaining, updated_at)
                 VALUES(?1, ?2, ?3, ?4, ?5)
                 ON CONFLICT(date, category_id, item_id) DO UPDATE SET
                    remaining  = excluded.remaining,
                    updated_at = excluded.updated_at",
                params![date, category_id, item_id, remaining as i64, now()],
            )?;
        }
        Ok(AdhkarProgress {
            date: date.to_string(),
            category_id: category_id.to_string(),
            item_id: item_id.to_string(),
            remaining,
        })
    }

    /// Clear one category's progress for a day and its streak flag if it has
    /// one. Used by the "start over" action.
    pub fn clear_adhkar_category(&self, date: &str, category_id: &str) -> Result<AdhkarDay> {
        validate_log_date(date)?;
        {
            let conn = self.conn.lock();
            conn.execute(
                "DELETE FROM adhkar_progress WHERE date = ?1 AND category_id = ?2",
                params![date, category_id],
            )?;
            if category_id == MORNING || category_id == EVENING {
                let column = if category_id == MORNING {
                    "morning"
                } else {
                    "evening"
                };
                conn.execute(
                    &format!("UPDATE adhkar_log SET {column} = 0, updated_at = ?1 WHERE date = ?2"),
                    params![now(), date],
                )?;
            }
        }
        self.adhkar_day(date)
    }

    pub fn adhkar_day(&self, date: &str) -> Result<AdhkarDay> {
        let conn = self.conn.lock();
        let row = conn
            .query_row(
                "SELECT date, morning, evening FROM adhkar_log WHERE date = ?1",
                [date],
                adhkar_row,
            )
            .optional()?;
        Ok(row.unwrap_or_else(|| AdhkarDay::empty(date)))
    }

    pub fn adhkar_logs(&self) -> Result<Vec<AdhkarDay>> {
        let conn = self.conn.lock();
        let mut stmt =
            conn.prepare("SELECT date, morning, evening FROM adhkar_log ORDER BY date ASC")?;
        let rows = stmt
            .query_map([], adhkar_row)?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows)
    }

    /// Mark morning/evening finished. Other categories never affect the streak.
    pub fn mark_adhkar_done(&self, date: &str, category_id: &str) -> Result<AdhkarDay> {
        validate_log_date(date)?;
        if category_id != MORNING && category_id != EVENING {
            return self.adhkar_day(date);
        }
        {
            let conn = self.conn.lock();
            let (morning, evening) = (
                (category_id == MORNING) as i32,
                (category_id == EVENING) as i32,
            );
            conn.execute(
                "INSERT INTO adhkar_log(date, morning, evening, updated_at)
                 VALUES(?1, ?2, ?3, ?4)
                 ON CONFLICT(date) DO UPDATE SET
                    morning    = MAX(morning, excluded.morning),
                    evening    = MAX(evening, excluded.evening),
                    updated_at = excluded.updated_at",
                params![date, morning, evening, now()],
            )?;
        }
        self.adhkar_day(date)
    }

    // --- Quran reader bookmarks and position ------------------------------

    pub fn quran_bookmarks(&self) -> Result<Vec<QuranBookmark>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT surah, ayah, created_at FROM quran_bookmarks
             ORDER BY created_at DESC, surah, ayah",
        )?;
        let rows = stmt
            .query_map([], |r| {
                Ok(QuranBookmark {
                    surah: r.get(0)?,
                    ayah: r.get(1)?,
                    created_at: r.get(2)?,
                })
            })?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows)
    }

    pub fn add_quran_bookmark(&self, surah: u16, ayah: u16) -> Result<QuranBookmark> {
        {
            let conn = self.conn.lock();
            conn.execute(
                "INSERT INTO quran_bookmarks(surah, ayah, created_at)
                 VALUES(?1, ?2, ?3)
                 ON CONFLICT(surah, ayah) DO NOTHING",
                params![surah, ayah, now()],
            )?;
        }
        let created_at = {
            let conn = self.conn.lock();
            conn.query_row(
                "SELECT created_at FROM quran_bookmarks WHERE surah = ?1 AND ayah = ?2",
                params![surah, ayah],
                |r| r.get(0),
            )?
        };
        Ok(QuranBookmark {
            surah,
            ayah,
            created_at,
        })
    }

    pub fn remove_quran_bookmark(&self, surah: u16, ayah: u16) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute(
            "DELETE FROM quran_bookmarks WHERE surah = ?1 AND ayah = ?2",
            params![surah, ayah],
        )?;
        Ok(())
    }

    pub fn reader_position(&self) -> Result<Option<ReaderPosition>> {
        let conn = self.conn.lock();
        let position = conn
            .query_row(
                "SELECT mode, juz, surah, ayah, updated_at FROM reader_state WHERE id = 1",
                [],
                |r| {
                    Ok(ReaderPosition {
                        mode: r.get(0)?,
                        juz: r.get(1)?,
                        surah: r.get(2)?,
                        ayah: r.get(3)?,
                        updated_at: r.get(4)?,
                    })
                },
            )
            .optional()?;
        Ok(position)
    }

    pub fn save_reader_position(
        &self,
        mode: &str,
        juz: u16,
        surah: u16,
        ayah: u16,
    ) -> Result<ReaderPosition> {
        let updated_at = now();
        {
            let conn = self.conn.lock();
            conn.execute(
                "INSERT INTO reader_state(id, mode, juz, surah, ayah, updated_at)
                 VALUES(1, ?1, ?2, ?3, ?4, ?5)
                 ON CONFLICT(id) DO UPDATE SET
                    mode       = excluded.mode,
                    juz        = excluded.juz,
                    surah      = excluded.surah,
                    ayah       = excluded.ayah,
                    updated_at = excluded.updated_at",
                params![mode, juz, surah, ayah, updated_at],
            )?;
        }
        Ok(ReaderPosition {
            mode: mode.to_string(),
            juz,
            surah,
            ayah,
            updated_at,
        })
    }

    // --- favourites --------------------------------------------------------

    pub fn upsert_track(&self, track: &Track) -> Result<()> {
        let conn = self.conn.lock();
        upsert_track_on(&conn, track)
    }

    pub fn add_favorite(&self, track: &Track) -> Result<()> {
        self.upsert_track(track)?;
        let conn = self.conn.lock();
        conn.execute(
            "INSERT INTO favorites(track_id, added_at, payload) VALUES(?1, ?2, ?3)
             ON CONFLICT(track_id) DO UPDATE SET added_at = excluded.added_at,
                                                payload  = excluded.payload",
            params![track.id, now(), serde_json::to_string(track)?],
        )?;
        Ok(())
    }

    pub fn remove_favorite(&self, track_id: &str) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute("DELETE FROM favorites WHERE track_id = ?1", [track_id])?;
        Ok(())
    }

    pub fn favorite_ids(&self) -> Result<Vec<String>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare("SELECT track_id FROM favorites")?;
        let rows = stmt
            .query_map([], |r| r.get::<_, String>(0))?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows)
    }

    pub fn favorites(&self, limit: u32) -> Result<Vec<Track>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT f.payload, d.file_path
             FROM favorites f
             LEFT JOIN downloads d ON d.track_id = f.track_id AND d.status = 'done'
             ORDER BY f.added_at DESC
             LIMIT ?1",
        )?;
        let rows = stmt
            .query_map([limit], |r| {
                Ok((r.get::<_, String>(0)?, r.get::<_, Option<String>>(1)?))
            })?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows
            .into_iter()
            .filter_map(|(payload, file)| {
                let mut track: Track = serde_json::from_str(&payload).ok()?;
                if file.is_some() {
                    track.local_path = file;
                }
                Some(track)
            })
            .collect())
    }

    // --- playlists ---------------------------------------------------------

    pub fn create_playlist(&self, name: &str) -> Result<Playlist> {
        let id = uuid::Uuid::new_v4().to_string();
        let created = now();
        let conn = self.conn.lock();
        conn.execute(
            "INSERT INTO playlists(id, name, created_at) VALUES(?1, ?2, ?3)",
            params![id, name, created],
        )?;
        Ok(Playlist {
            id,
            name: name.to_string(),
            created_at: created,
            track_count: 0,
        })
    }

    pub fn rename_playlist(&self, id: &str, name: &str) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute("UPDATE playlists SET name = ?2 WHERE id = ?1", params![id, name])?;
        Ok(())
    }

    pub fn delete_playlist(&self, id: &str) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute("DELETE FROM playlist_items WHERE playlist_id = ?1", [id])?;
        conn.execute("DELETE FROM playlists WHERE id = ?1", [id])?;
        Ok(())
    }

    pub fn playlists(&self) -> Result<Vec<Playlist>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT p.id, p.name, p.created_at,
                    (SELECT COUNT(*) FROM playlist_items i WHERE i.playlist_id = p.id)
             FROM playlists p
             ORDER BY p.sort ASC, p.created_at DESC",
        )?;
        let rows = stmt
            .query_map([], |r| {
                Ok(Playlist {
                    id: r.get(0)?,
                    name: r.get(1)?,
                    created_at: r.get(2)?,
                    track_count: r.get(3)?,
                })
            })?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows)
    }

    pub fn playlist_tracks(&self, playlist_id: &str) -> Result<Vec<Track>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT t.payload, d.file_path
             FROM playlist_items i
             JOIN tracks t ON t.id = i.track_id
             LEFT JOIN downloads d ON d.track_id = i.track_id AND d.status = 'done'
             WHERE i.playlist_id = ?1
             ORDER BY i.position ASC",
        )?;
        let rows = stmt
            .query_map([playlist_id], |r| {
                Ok((r.get::<_, String>(0)?, r.get::<_, Option<String>>(1)?))
            })?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows
            .into_iter()
            .filter_map(|(payload, file)| {
                let mut track: Track = serde_json::from_str(&payload).ok()?;
                if file.is_some() {
                    track.local_path = file;
                }
                Some(track)
            })
            .collect())
    }

    pub fn add_to_playlist(&self, playlist_id: &str, track: &Track) -> Result<()> {
        self.upsert_track(track)?;
        let conn = self.conn.lock();
        conn.execute(
            "INSERT INTO playlist_items(playlist_id, track_id, position)
             SELECT ?1, ?2, COALESCE(MAX(position), 0) + 1
             FROM playlist_items WHERE playlist_id = ?1
             ON CONFLICT(playlist_id, track_id) DO NOTHING",
            params![playlist_id, track.id],
        )?;
        Ok(())
    }

    pub fn remove_from_playlist(&self, playlist_id: &str, track_id: &str) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute(
            "DELETE FROM playlist_items WHERE playlist_id = ?1 AND track_id = ?2",
            params![playlist_id, track_id],
        )?;
        Ok(())
    }

    // --- downloads ---------------------------------------------------------

    pub fn queue_download(&self, track: &Track) -> Result<()> {
        self.queue_downloads(std::slice::from_ref(track))
    }

    /// Persists a whole batch in one transaction, then the downloader spawns
    /// the tasks. Keeping the rows and the queue in step avoids rows stuck in
    /// `queued` with no worker.
    pub fn queue_downloads(&self, tracks: &[Track]) -> Result<()> {
        let conn = self.conn.lock();
        let tx = conn.unchecked_transaction()?;
        let created = now();
        for track in tracks {
            upsert_track_on(&tx, track)?;
            tx.execute(
                "INSERT INTO downloads(track_id, payload, status, created_at)
                 VALUES(?1, ?2, 'queued', ?3)
                 ON CONFLICT(track_id) DO UPDATE SET
                    payload    = excluded.payload,
                    status     = 'queued',
                    bytes_done = 0,
                    bytes_total = 0,
                    file_path  = NULL,
                    error      = NULL,
                    created_at = excluded.created_at",
                params![track.id, serde_json::to_string(track)?, created],
            )?;
        }
        tx.commit()?;
        Ok(())
    }

    pub fn set_download_progress(
        &self,
        track_id: &str,
        done: u64,
        total: u64,
        status: &str,
    ) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute(
            "UPDATE downloads SET bytes_done = ?2, bytes_total = ?3, status = ?4
             WHERE track_id = ?1",
            params![track_id, done as i64, total as i64, status],
        )?;
        Ok(())
    }

    pub fn set_download_part(&self, track_id: &str, part_path: &str) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute(
            "UPDATE downloads SET part_path = ?2 WHERE track_id = ?1",
            params![track_id, part_path],
        )?;
        Ok(())
    }

    pub fn finish_download(&self, track_id: &str, path: &str) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute(
            "UPDATE downloads SET status = 'done', file_path = ?2, part_path = NULL,
                    error = NULL
             WHERE track_id = ?1",
            params![track_id, path],
        )?;
        Ok(())
    }

    pub fn fail_download(&self, track_id: &str, error: &str) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute(
            "UPDATE downloads SET status = 'error', error = ?2 WHERE track_id = ?1",
            params![track_id, error],
        )?;
        Ok(())
    }

    /// Marks a job cancelled only while it is still cancellable. A row that
    /// just finished must stay `done`, even if the cancel request raced it.
    pub fn mark_cancelled(&self, track_id: &str) -> Result<bool> {
        let conn = self.conn.lock();
        let changed = conn.execute(
            "UPDATE downloads SET status = 'cancelled', error = NULL
             WHERE track_id = ?1 AND status IN ('queued', 'downloading')",
            [track_id],
        )?;
        Ok(changed > 0)
    }

    /// Runs at startup: a process that stopped mid-download leaves no worker,
    /// so the row is marked interrupted. Retrying resumes from its `.part`.
    pub fn interrupt_downloads(&self) -> Result<usize> {
        let conn = self.conn.lock();
        Ok(conn.execute(
            "UPDATE downloads SET status = 'error', error = 'interrupted'
             WHERE status IN ('queued', 'downloading')",
            [],
        )?)
    }

    pub fn downloads(&self) -> Result<Vec<DownloadRow>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT payload, status, bytes_total, bytes_done, file_path, part_path,
                    error, created_at
             FROM downloads ORDER BY created_at DESC, rowid DESC",
        )?;
        let rows = stmt
            .query_map([], |r| {
                Ok((
                    r.get::<_, String>(0)?,
                    r.get::<_, String>(1)?,
                    r.get::<_, i64>(2)? as u64,
                    r.get::<_, i64>(3)? as u64,
                    r.get::<_, Option<String>>(4)?,
                    r.get::<_, Option<String>>(5)?,
                    r.get::<_, Option<String>>(6)?,
                    r.get::<_, i64>(7)?,
                ))
            })?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows
            .into_iter()
            .filter_map(
                |(payload, status, bytes_total, bytes_done, file_path, part_path, error, created_at)| {
                    Some(DownloadRow {
                        track: serde_json::from_str(&payload).ok()?,
                        status,
                        bytes_total,
                        bytes_done,
                        file_path,
                        part_path,
                        error,
                        created_at,
                    })
                },
            )
            .collect())
    }

    pub fn download_path(&self, track_id: &str) -> Result<Option<String>> {
        let conn = self.conn.lock();
        let path = conn
            .query_row(
                "SELECT file_path FROM downloads WHERE track_id = ?1 AND status = 'done'",
                [track_id],
                |r| r.get(0),
            )
            .optional()?;
        Ok(path)
    }

    pub fn delete_download(&self, track_id: &str) -> Result<Option<String>> {
        let path = self.download_path(track_id)?;
        let conn = self.conn.lock();
        conn.execute("DELETE FROM downloads WHERE track_id = ?1", [track_id])?;
        Ok(path)
    }

    /// Deletes several rows in one transaction after the caller has removed
    /// their files. Returns how many rows actually existed.
    pub fn delete_downloads(&self, track_ids: &[String]) -> Result<usize> {
        if track_ids.is_empty() {
            return Ok(0);
        }
        let conn = self.conn.lock();
        let tx = conn.unchecked_transaction()?;
        let mut deleted = 0;
        for track_id in track_ids {
            deleted += tx.execute("DELETE FROM downloads WHERE track_id = ?1", [track_id])?;
        }
        tx.commit()?;
        Ok(deleted)
    }

    /// Repairs rows whose files disappeared outside the app. Called at startup
    /// so storage totals, retry and playback agree with the disk.
    pub fn reconcile_downloads(&self) -> Result<usize> {
        let rows = self.downloads()?;
        let mut repaired = 0;
        let conn = self.conn.lock();
        for row in rows {
            match row.status.as_str() {
                "done" => {
                    let exists = row
                        .file_path
                        .as_deref()
                        .map(|path| std::path::Path::new(path).exists())
                        .unwrap_or(false);
                    if !exists {
                        conn.execute(
                            "UPDATE downloads SET status = 'error', error = 'missing',
                                    file_path = NULL, bytes_done = 0
                             WHERE track_id = ?1",
                            [&row.track.id],
                        )?;
                        repaired += 1;
                    }
                }
                "error" | "cancelled" => {
                    if let Some(part) = row.part_path.as_deref() {
                        if !std::path::Path::new(part).exists() {
                            conn.execute(
                                "UPDATE downloads SET part_path = NULL, bytes_done = 0
                                 WHERE track_id = ?1",
                                [&row.track.id],
                            )?;
                            repaired += 1;
                        }
                    }
                }
                _ => {}
            }
        }
        Ok(repaired)
    }

    /// Stores an extracted cover path on every stored copy of a track: the
    /// tracks table, the downloads queue and favourites.
    pub fn set_track_artwork(&self, track_id: &str, artwork_url: &str) -> Result<()> {
        let conn = self.conn.lock();

        let track_payload: Option<Option<String>> = conn
            .query_row("SELECT payload FROM tracks WHERE id = ?1", [track_id], |r| r.get(0))
            .optional()?;
        if let Some(Some(payload)) = track_payload {
            if let Ok(mut value) = serde_json::from_str::<serde_json::Value>(&payload) {
                value["artworkUrl"] = serde_json::Value::String(artwork_url.to_string());
                let json = serde_json::to_string(&value)?;
                conn.execute(
                    "UPDATE tracks SET artwork_url = ?2, payload = ?3 WHERE id = ?1",
                    params![track_id, artwork_url, json],
                )?;
            }
        }

        for table in ["downloads", "favorites"] {
            let payload: Option<String> = conn
                .query_row(
                    &format!("SELECT payload FROM {table} WHERE track_id = ?1"),
                    [track_id],
                    |r| r.get(0),
                )
                .optional()?;
            if let Some(payload) = payload {
                if let Ok(mut value) = serde_json::from_str::<serde_json::Value>(&payload) {
                    value["artworkUrl"] = serde_json::Value::String(artwork_url.to_string());
                    let json = serde_json::to_string(&value)?;
                    conn.execute(
                        &format!("UPDATE {table} SET payload = ?2 WHERE track_id = ?1"),
                        params![track_id, json],
                    )?;
                }
            }
        }

        Ok(())
    }

    // --- local library -----------------------------------------------------

    pub fn local_tracks(&self) -> Result<Vec<Track>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT payload FROM tracks WHERE is_local = 1 ORDER BY added_at DESC",
        )?;
        let rows = stmt
            .query_map([], |r| r.get::<_, String>(0))?
            .collect::<rusqlite::Result<Vec<_>>>()?;
        Ok(rows
            .into_iter()
            .filter_map(|payload| serde_json::from_str(&payload).ok())
            .collect())
    }

    pub fn forget_local_track(&self, track_id: &str) -> Result<()> {
        let conn = self.conn.lock();
        conn.execute(
            "DELETE FROM tracks WHERE id = ?1 AND is_local = 1",
            [track_id],
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

fn upsert_track_on(conn: &rusqlite::Connection, track: &Track) -> Result<()> {
    let payload = serde_json::to_string(track)?;
    conn.execute(
        "INSERT INTO tracks(id, provider, provider_id, title, artist, album,
                            duration_s, artwork_url, local_path, is_local,
                            license, license_url, attribution, source_page,
                            kind, added_at, payload)
         VALUES(?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17)
         ON CONFLICT(id) DO UPDATE SET
            title       = excluded.title,
            artist      = excluded.artist,
            album       = excluded.album,
            duration_s  = excluded.duration_s,
            artwork_url = excluded.artwork_url,
            local_path  = excluded.local_path,
            is_local    = excluded.is_local,
            payload     = excluded.payload",
        params![
            track.id,
            track.provider,
            track.provider_id,
            track.title,
            track.artist,
            track.album,
            track.duration_s,
            track.artwork_url,
            track.local_path,
            track.local_path.is_some() as i32,
            track.license,
            track.license_url,
            track.attribution,
            track.source_page,
            track.kind.as_str(),
            now(),
            payload
        ],
    )?;
    Ok(())
}

fn validate_log_date(date: &str) -> Result<()> {
    chrono::NaiveDate::parse_from_str(date, "%Y-%m-%d")
        .map(|_| ())
        .map_err(|error| anyhow::anyhow!("invalid prayer-log date {date}: {error}"))
}

fn adhkar_row(r: &rusqlite::Row<'_>) -> rusqlite::Result<AdhkarDay> {
    Ok(AdhkarDay {
        date: r.get(0)?,
        morning: r.get::<_, i64>(1)? != 0,
        evening: r.get::<_, i64>(2)? != 0,
    })
}

fn prayer_row(r: &rusqlite::Row<'_>) -> rusqlite::Result<PrayerLog> {
    Ok(PrayerLog {
        date: r.get(0)?,
        fajr: r.get::<_, i64>(1)? != 0,
        dhuhr: r.get::<_, i64>(2)? != 0,
        asr: r.get::<_, i64>(3)? != 0,
        maghrib: r.get::<_, i64>(4)? != 0,
        isha: r.get::<_, i64>(5)? != 0,
        excused: r.get::<_, i64>(6)? != 0,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicU64, Ordering};

    static COUNTER: AtomicU64 = AtomicU64::new(0);

    fn temp_db() -> (std::path::PathBuf, Database) {
        let dir = std::env::temp_dir().join(format!(
            "sakeenah-test-{}-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos(),
            COUNTER.fetch_add(1, Ordering::Relaxed)
        ));
        std::fs::create_dir_all(&dir).unwrap();
        let db = Database::open(&dir.join("test.db")).unwrap();
        (dir, db)
    }

    #[test]
    fn migrations_apply_and_reopen_cleanly() {
        let (dir, db) = temp_db();
        let version: i64 = db
            .conn
            .lock()
            .query_row("PRAGMA user_version", [], |row| row.get(0))
            .unwrap();
        assert_eq!(version, MIGRATIONS.len() as i64);
        drop(db);
        let reopened = Database::open(&dir.join("test.db")).unwrap();
        let again: i64 = reopened
            .conn
            .lock()
            .query_row("PRAGMA user_version", [], |row| row.get(0))
            .unwrap();
        assert_eq!(again, MIGRATIONS.len() as i64);
        drop(reopened);
        let _ = std::fs::remove_dir_all(&dir);
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

    fn sample_track() -> Track {
        use crate::providers::TrackKind;
        let mut track = Track::new("mp3quran", "1-1", "سورة الفاتحة", TrackKind::Quran);
        track.artist = "محمود خليل الحصري".into();
        track.stream_url = Some("https://cdn.example/001.mp3".into());
        track
    }

    #[test]
    fn favourites_playlists_and_downloads_round_trip() {
        let (dir, db) = temp_db();
        let track = sample_track();

        db.add_favorite(&track).unwrap();
        assert_eq!(db.favorite_ids().unwrap(), vec![track.id.clone()]);
        let favorites = db.favorites(10).unwrap();
        assert_eq!(favorites.len(), 1);
        assert_eq!(
            favorites[0].stream_url.as_deref(),
            Some("https://cdn.example/001.mp3")
        );

        let playlist = db.create_playlist("حفظ").unwrap();
        db.add_to_playlist(&playlist.id, &track).unwrap();
        // Adding the same track twice must not duplicate the row.
        db.add_to_playlist(&playlist.id, &track).unwrap();
        let all = db.playlists().unwrap();
        assert_eq!(all.len(), 1);
        assert_eq!(all[0].track_count, 1);
        assert_eq!(db.playlist_tracks(&playlist.id).unwrap().len(), 1);

        // A finished download is surfaced as a local path on library tracks.
        db.queue_download(&track).unwrap();
        db.set_download_progress(&track.id, 10, 20, "downloading").unwrap();
        db.finish_download(&track.id, "C:/audio/001.mp3").unwrap();
        assert_eq!(
            db.favorites(10).unwrap()[0].local_path.as_deref(),
            Some("C:/audio/001.mp3")
        );
        assert_eq!(
            db.playlist_tracks(&playlist.id).unwrap()[0]
                .local_path
                .as_deref(),
            Some("C:/audio/001.mp3")
        );
        assert_eq!(db.downloads().unwrap()[0].status, "done");

        assert_eq!(
            db.delete_download(&track.id).unwrap().as_deref(),
            Some("C:/audio/001.mp3")
        );
        assert!(db.downloads().unwrap().is_empty());
        assert!(db.favorites(10).unwrap()[0].local_path.is_none());

        db.remove_from_playlist(&playlist.id, &track.id).unwrap();
        assert!(db.playlist_tracks(&playlist.id).unwrap().is_empty());
        db.delete_playlist(&playlist.id).unwrap();
        assert!(db.playlists().unwrap().is_empty());

        db.remove_favorite(&track.id).unwrap();
        assert!(db.favorite_ids().unwrap().is_empty());
        drop(db);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn batch_queue_is_atomic_and_interrupted_rows_are_retryable() {
        use crate::providers::TrackKind;
        let (dir, db) = temp_db();
        let mut a = Track::new("mp3quran", "1", "الفاتحة", TrackKind::Quran);
        a.stream_url = Some("https://x/1.mp3".into());
        let mut b = Track::new("mp3quran", "2", "البقرة", TrackKind::Quran);
        b.stream_url = Some("https://x/2.mp3".into());
        let mut c = Track::new("mp3quran", "3", "آل عمران", TrackKind::Quran);
        c.stream_url = Some("https://x/3.mp3".into());

        db.queue_downloads(&[a.clone(), b.clone(), c.clone()]).unwrap();
        let queued = db.downloads().unwrap();
        assert_eq!(queued.len(), 3);
        assert!(queued.iter().all(|row| row.status == "queued"));

        // One job starts, one is cancelled while queued.
        db.set_download_progress(&a.id, 4, 8, "downloading").unwrap();
        db.mark_cancelled(&b.id).unwrap();
        let interrupted = db.interrupt_downloads().unwrap();
        assert_eq!(interrupted, 2, "running and queued jobs lost their worker");
        let rows = db.downloads().unwrap();
        let status = |id: &str| {
            rows.iter()
                .find(|row| row.track.id == id)
                .map(|row| row.status.as_str())
                .unwrap()
        };
        assert_eq!(status(&a.id), "error");
        assert_eq!(status(&b.id), "cancelled");
        assert_eq!(status(&c.id), "error");
        assert_eq!(
            rows.iter()
                .find(|row| row.track.id == c.id)
                .and_then(|row| row.error.as_deref()),
            Some("interrupted")
        );

        drop(db);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn cancel_is_conditional_and_missing_files_are_reconciled() {
        use crate::providers::TrackKind;
        let (dir, db) = temp_db();
        let mut track = Track::new("mp3quran", "1", "الفاتحة", TrackKind::Quran);
        track.stream_url = Some("https://x/1.mp3".into());

        db.queue_download(&track).unwrap();
        db.finish_download(&track.id, "C:/sakeenah-missing/1.mp3")
            .unwrap();
        // A cancel that races the finalize must leave `done` intact.
        assert!(!db.mark_cancelled(&track.id).unwrap());
        assert_eq!(db.downloads().unwrap()[0].status, "done");

        // Startup reconciliation notices the file disappeared.
        assert_eq!(db.reconcile_downloads().unwrap(), 1);
        let row = &db.downloads().unwrap()[0];
        assert_eq!(row.status, "error");
        assert_eq!(row.error.as_deref(), Some("missing"));
        assert!(row.file_path.is_none());

        // A running row is cancellable.
        db.queue_download(&track).unwrap();
        db.set_download_progress(&track.id, 5, 10, "downloading")
            .unwrap();
        assert!(db.mark_cancelled(&track.id).unwrap());
        assert_eq!(db.downloads().unwrap()[0].status, "cancelled");

        drop(db);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn batch_delete_counts_only_rows_that_existed() {
        use crate::providers::TrackKind;
        let (dir, db) = temp_db();
        let mut a = Track::new("mp3quran", "1", "الفاتحة", TrackKind::Quran);
        a.stream_url = Some("https://x/1.mp3".into());
        let mut b = Track::new("mp3quran", "2", "البقرة", TrackKind::Quran);
        b.stream_url = Some("https://x/2.mp3".into());
        db.queue_downloads(&[a.clone(), b.clone()]).unwrap();

        let ids = vec![a.id.clone(), b.id.clone(), "mp3quran:missing".into()];
        assert_eq!(db.delete_downloads(&ids).unwrap(), 2);
        assert!(db.downloads().unwrap().is_empty());

        drop(db);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn local_tracks_are_kept_separate() {
        use crate::providers::TrackKind;
        let (dir, db) = temp_db();
        let mut local = Track::new("local", "C:/m/001.mp3", "سورة الكهف", TrackKind::Local);
        local.artist = "مكتبتي".into();
        local.local_path = Some("C:/m/001.mp3".into());
        db.upsert_track(&local).unwrap();

        let imported = db.local_tracks().unwrap();
        assert_eq!(imported.len(), 1);
        assert_eq!(imported[0].local_path.as_deref(), Some("C:/m/001.mp3"));
        assert_eq!(imported[0].kind, TrackKind::Local);

        db.forget_local_track(&local.id).unwrap();
        assert!(db.local_tracks().unwrap().is_empty());
        drop(db);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn artwork_is_written_to_every_payload_copy() {
        use crate::providers::TrackKind;
        let (dir, db) = temp_db();

        let quran = sample_track();
        db.add_favorite(&quran).unwrap();
        db.queue_download(&quran).unwrap();
        db.upsert_track(&quran).unwrap();
        db.set_track_artwork(&quran.id, "C:/art/1.png").unwrap();

        assert_eq!(
            db.favorites(10).unwrap()[0].artwork_url.as_deref(),
            Some("C:/art/1.png")
        );
        assert_eq!(
            db.downloads().unwrap()[0].track.artwork_url.as_deref(),
            Some("C:/art/1.png")
        );

        let mut local = Track::new("local", "C:/m/001.mp3", "غلاف", TrackKind::Local);
        local.local_path = Some("C:/m/001.mp3".into());
        db.upsert_track(&local).unwrap();
        db.set_track_artwork(&local.id, "C:/art/2.png").unwrap();
        assert_eq!(
            db.local_tracks().unwrap()[0].artwork_url.as_deref(),
            Some("C:/art/2.png")
        );

        drop(db);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn prayer_log_round_trips_and_streak_survives_reopen() {
        use crate::worship::{compute_streak, PRAYER_KEYS};
        use chrono::NaiveDate;

        let (dir, db) = temp_db();
        assert_eq!(db.prayer_log("2026-11-25").unwrap().count(), 0);

        for date in ["2026-11-23", "2026-11-24", "2026-11-25"] {
            for prayer in PRAYER_KEYS {
                db.set_prayer_done(date, prayer, true).unwrap();
            }
        }
        let today = db.prayer_log("2026-11-25").unwrap();
        assert!(today.complete());
        assert_eq!(today.count(), 5);
        assert_eq!(db.prayer_logs().unwrap().len(), 3);

        let day = NaiveDate::from_ymd_opt(2026, 11, 25).unwrap();
        assert_eq!(compute_streak(&db.prayer_logs().unwrap(), day).current, 3);

        drop(db);
        let reopened = Database::open(&dir.join("test.db")).unwrap();
        assert!(reopened.prayer_log("2026-11-24").unwrap().complete());
        let logs = reopened.prayer_logs().unwrap();
        assert_eq!(compute_streak(&logs, day).current, 3);
        assert_eq!(logs[0].date, "2026-11-23");

        drop(reopened);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn prayer_log_toggles_excused_and_rejects_unknown_prayers() {
        let (dir, db) = temp_db();
        let excused = db.set_prayer_excused("2026-11-20", true).unwrap();
        assert!(excused.excused);
        assert_eq!(excused.count(), 0);

        db.set_prayer_done("2026-11-20", "fajr", true).unwrap();
        let log = db.set_prayer_done("2026-11-20", "fajr", false).unwrap();
        assert!(!log.fajr);
        assert_eq!(log.count(), 0);

        assert!(db.set_prayer_done("2026-11-20", "tahajjud", true).is_err());
        assert!(db.set_prayer_done("2026-13-40", "fajr", true).is_err());
        assert!(db.set_prayer_excused("not-a-date", true).is_err());

        drop(db);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn adhkar_progress_round_trips_and_resets_by_date() {
        let (dir, db) = temp_db();
        assert!(db.adhkar_progress("2026-11-26").unwrap().is_empty());

        db.set_adhkar_remaining("2026-11-26", "morning", "morning-01", 3)
            .unwrap();
        db.set_adhkar_remaining("2026-11-26", "evening", "evening-01", 1)
            .unwrap();
        db.set_adhkar_remaining("2026-11-25", "morning", "morning-01", 9)
            .unwrap();

        let today = db.adhkar_progress("2026-11-26").unwrap();
        assert_eq!(today.len(), 2);
        assert_eq!(
            (today[0].category_id.as_str(), today[0].remaining),
            ("evening", 1)
        );
        assert_eq!(
            (today[1].category_id.as_str(), today[1].remaining),
            ("morning", 3)
        );

        db.mark_adhkar_done("2026-11-26", "morning").unwrap();
        assert!(db.adhkar_day("2026-11-26").unwrap().morning);
        db.clear_adhkar_category("2026-11-26", "morning").unwrap();
        let day = db.adhkar_day("2026-11-26").unwrap();
        assert!(!day.morning);
        assert_eq!(db.adhkar_progress("2026-11-26").unwrap().len(), 1);
        assert_eq!(db.adhkar_progress("2026-11-25").unwrap()[0].remaining, 9);

        drop(db);
        let reopened = Database::open(&dir.join("test.db")).unwrap();
        assert_eq!(reopened.adhkar_progress("2026-11-25").unwrap()[0].remaining, 9);
        drop(reopened);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn adhkar_completion_and_streak_survive_reopen() {
        use crate::adhkar::compute_adhkar_streak;
        use chrono::NaiveDate;

        let (dir, db) = temp_db();
        for date in ["2026-11-24", "2026-11-25", "2026-11-26"] {
            db.mark_adhkar_done(date, "morning").unwrap();
        }
        db.mark_adhkar_done("2026-11-25", "evening").unwrap();

        let day = db.adhkar_day("2026-11-25").unwrap();
        assert!(day.morning && day.evening);
        let logs = db.adhkar_logs().unwrap();
        assert_eq!(logs.len(), 3);

        let today = NaiveDate::from_ymd_opt(2026, 11, 26).unwrap();
        let streak = compute_adhkar_streak(&logs, today);
        assert_eq!(streak.current, 3);
        assert!(streak.today_morning);
        assert!(!streak.today_evening);

        drop(db);
        let reopened = Database::open(&dir.join("test.db")).unwrap();
        let streak = compute_adhkar_streak(&reopened.adhkar_logs().unwrap(), today);
        assert_eq!(streak.current, 3);
        drop(reopened);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn quran_bookmarks_and_reader_position_round_trip() {
        let (dir, db) = temp_db();
        assert!(db.quran_bookmarks().unwrap().is_empty());
        assert!(db.reader_position().unwrap().is_none());

        let bookmark = db.add_quran_bookmark(2, 255).unwrap();
        assert_eq!((bookmark.surah, bookmark.ayah), (2, 255));
        db.add_quran_bookmark(2, 255).unwrap();
        assert_eq!(db.quran_bookmarks().unwrap().len(), 1, "no duplicates");
        db.add_quran_bookmark(18, 10).unwrap();
        assert_eq!(db.quran_bookmarks().unwrap().len(), 2);

        db.remove_quran_bookmark(2, 255).unwrap();
        assert_eq!(db.quran_bookmarks().unwrap().len(), 1);

        let position = db.save_reader_position("surah", 1, 18, 10).unwrap();
        assert_eq!((position.surah, position.ayah), (18, 10));
        db.save_reader_position("juz", 23, 36, 28).unwrap();
        let saved = db.reader_position().unwrap().unwrap();
        assert_eq!((saved.mode.as_str(), saved.juz, saved.surah), ("juz", 23, 36));

        drop(db);
        let reopened = Database::open(&dir.join("test.db")).unwrap();
        assert_eq!(reopened.quran_bookmarks().unwrap()[0].surah, 18);
        let saved = reopened.reader_position().unwrap().unwrap();
        assert_eq!((saved.mode.as_str(), saved.juz, saved.ayah), ("juz", 23, 28));
        drop(reopened);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn adhkar_rejects_bad_input_and_other_categories_do_not_count() {
        let (dir, db) = temp_db();
        assert!(db.set_adhkar_remaining("bad", "morning", "x", 1).is_err());
        assert!(db.set_adhkar_remaining("2026-11-26", "", "x", 1).is_err());

        let day = db.mark_adhkar_done("2026-11-26", "sleep").unwrap();
        assert!(!day.morning && !day.evening);
        assert!(db.adhkar_logs().unwrap().is_empty());

        drop(db);
        let _ = std::fs::remove_dir_all(&dir);
    }
}
