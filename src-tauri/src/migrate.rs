use anyhow::{Context, Result};
use rusqlite::{params, Connection};
use std::path::{Path, PathBuf};

pub const OLD_IDENTIFIER: &str = "app.dandanah.desktop";
const OLD_DB: &str = "dandanah.db";
pub const NEW_DB: &str = "sakeenah.db";

/// Copies a pre-rename app-data folder into the new identifier folder and
/// rewrites absolute paths. Returns the old directory when a migration ran.
/// A missing new database is the marker that migration has not happened yet.
pub fn migrate_legacy(new_dir: &Path) -> Result<Option<PathBuf>> {
    let new_db = new_dir.join(NEW_DB);
    if new_db.exists() {
        return Ok(None);
    }

    let parent = new_dir
        .parent()
        .context("new app-data directory has no parent")?;
    let old_dir = parent.join(OLD_IDENTIFIER);
    let old_db = old_dir.join(OLD_DB);
    if !old_db.is_file() {
        return Ok(None);
    }

    std::fs::create_dir_all(new_dir)?;
    copy_tree(&old_dir.join("downloads"), &new_dir.join("downloads"))?;
    copy_tree(&old_dir.join("artwork"), &new_dir.join("artwork"))?;

    for suffix in ["", "-wal", "-shm"] {
        let from = old_dir.join(format!("{OLD_DB}{suffix}"));
        if from.is_file() {
            std::fs::copy(&from, new_dir.join(format!("{NEW_DB}{suffix}")))
                .with_context(|| format!("copying {}", from.display()))?;
        }
    }

    if let Err(error) = rewrite_paths(&new_db, &old_dir, new_dir) {
        // Leave no half-migrated database behind so the next launch retries.
        for suffix in ["", "-wal", "-shm"] {
            let _ = std::fs::remove_file(new_dir.join(format!("{NEW_DB}{suffix}")));
        }
        return Err(error);
    }

    Ok(Some(old_dir))
}

fn copy_tree(from: &Path, to: &Path) -> Result<()> {
    if !from.is_dir() {
        return Ok(());
    }
    std::fs::create_dir_all(to)?;
    for entry in std::fs::read_dir(from).with_context(|| format!("reading {}", from.display()))? {
        let entry = entry?;
        let target = to.join(entry.file_name());
        if entry.file_type()?.is_dir() {
            copy_tree(&entry.path(), &target)?;
        } else {
            std::fs::copy(entry.path(), &target)
                .with_context(|| format!("copying {}", entry.path().display()))?;
        }
    }
    Ok(())
}

fn rewrite_paths(db: &Path, old_dir: &Path, new_dir: &Path) -> Result<()> {
    let old = old_dir.to_string_lossy().to_string();
    let new = new_dir.to_string_lossy().to_string();
    let old_url = old.replace('\\', "/");
    let new_url = new.replace('\\', "/");

    let conn = Connection::open(db).context("opening migrated database")?;
    let tx = conn.unchecked_transaction()?;

    rewrite_column(&tx, "tracks", "id", "local_path", &old, &new, &old_url, &new_url)?;
    rewrite_column(&tx, "tracks", "id", "artwork_url", &old, &new, &old_url, &new_url)?;
    rewrite_column(
        &tx,
        "downloads",
        "track_id",
        "file_path",
        &old,
        &new,
        &old_url,
        &new_url,
    )?;
    rewrite_column(
        &tx,
        "playlists",
        "id",
        "cover_path",
        &old,
        &new,
        &old_url,
        &new_url,
    )?;

    for (table, column) in [
        ("tracks", "payload"),
        ("downloads", "payload"),
        ("favorites", "payload"),
        ("history", "payload"),
        ("cache", "payload"),
    ] {
        rewrite_payload(&tx, table, column, &old, &new, &old_url, &new_url)?;
    }

    tx.commit()?;
    // Fold the WAL back into the main file so a single copied file is enough
    // for the app to open next time.
    let _ = conn.execute_batch("PRAGMA wal_checkpoint(TRUNCATE);");
    Ok(())
}

fn rewrite_column(
    conn: &Connection,
    table: &str,
    key: &str,
    column: &str,
    old: &str,
    new: &str,
    old_url: &str,
    new_url: &str,
) -> Result<()> {
    let sql = format!("SELECT {key}, {column} FROM {table} WHERE {column} IS NOT NULL");
    let mut statement = conn.prepare(&sql)?;
    let rows = statement
        .query_map([], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?))
        })?
        .collect::<rusqlite::Result<Vec<_>>>()?;
    drop(statement);

    for (id, value) in rows {
        if !value.contains(old) && !value.contains(old_url) {
            continue;
        }
        let updated = value.replace(old, new).replace(old_url, new_url);
        conn.execute(
            &format!("UPDATE {table} SET {column} = ?2 WHERE {key} = ?1"),
            params![id, updated],
        )?;
    }
    Ok(())
}

fn rewrite_payload(
    conn: &Connection,
    table: &str,
    column: &str,
    old: &str,
    new: &str,
    old_url: &str,
    new_url: &str,
) -> Result<()> {
    let old_json = old.replace('\\', "\\\\");
    let new_json = new.replace('\\', "\\\\");
    let sql = format!("SELECT rowid, {column} FROM {table} WHERE {column} IS NOT NULL");
    let mut statement = conn.prepare(&sql)?;
    let rows = statement
        .query_map([], |row| {
            Ok((row.get::<_, i64>(0)?, row.get::<_, String>(1)?))
        })?
        .collect::<rusqlite::Result<Vec<_>>>()?;
    drop(statement);

    for (rowid, raw) in rows {
        if !raw.contains(old) && !raw.contains(old_url) && !raw.contains(&old_json) {
            continue;
        }
        // JSON stores Windows paths with doubled backslashes, so replace the
        // escaped form first, then the URL form, then the plain form.
        let updated = raw
            .replace(&old_json, &new_json)
            .replace(old_url, new_url)
            .replace(old, new);
        conn.execute(
            &format!("UPDATE {table} SET {column} = ?2 WHERE rowid = ?1"),
            params![rowid, updated],
        )?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicU64, Ordering};

    static COUNTER: AtomicU64 = AtomicU64::new(0);

    fn temp_root() -> PathBuf {
        let root = std::env::temp_dir().join(format!(
            "sakeenah-migrate-{}-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos(),
            COUNTER.fetch_add(1, Ordering::Relaxed)
        ));
        std::fs::create_dir_all(&root).unwrap();
        root
    }

    #[test]
    fn migrates_database_and_rewrites_paths() {
        let root = temp_root();
        let old_dir = root.join(OLD_IDENTIFIER);
        let new_dir = root.join("app.sakeenah.desktop");
        std::fs::create_dir_all(old_dir.join("downloads")).unwrap();
        std::fs::create_dir_all(old_dir.join("artwork")).unwrap();
        std::fs::write(old_dir.join("downloads/a.mp3"), b"audio").unwrap();
        std::fs::write(old_dir.join("artwork/c.png"), b"png").unwrap();

        let old_prefix = old_dir.to_string_lossy().to_string();
        let audio_path = format!("{old_prefix}\\downloads\\a.mp3");
        let art_path = format!("{old_prefix}\\artwork\\c.png");

        {
            let conn = Connection::open(old_dir.join(OLD_DB)).unwrap();
            conn.execute_batch(
                "CREATE TABLE tracks(id TEXT PRIMARY KEY, local_path TEXT, artwork_url TEXT, payload TEXT);
                 CREATE TABLE downloads(track_id TEXT PRIMARY KEY, file_path TEXT, payload TEXT);
                 CREATE TABLE favorites(track_id TEXT PRIMARY KEY, payload TEXT);
                 CREATE TABLE history(id INTEGER PRIMARY KEY, payload TEXT);
                 CREATE TABLE cache(key TEXT PRIMARY KEY, payload TEXT);
                 CREATE TABLE playlists(id TEXT PRIMARY KEY, cover_path TEXT);",
            )
            .unwrap();
            conn.execute(
                "INSERT INTO tracks VALUES(?1, ?2, ?3, ?4)",
                params![
                    "local:x",
                    audio_path,
                    art_path,
                    serde_json::json!({ "localPath": audio_path, "artworkUrl": art_path }).to_string()
                ],
            )
            .unwrap();
            conn.execute(
                "INSERT INTO downloads VALUES(?1, ?2, ?3)",
                params![
                    "local:x",
                    audio_path,
                    serde_json::json!({ "artworkUrl": art_path }).to_string()
                ],
            )
            .unwrap();
            conn.execute(
                "INSERT INTO favorites VALUES(?1, ?2)",
                params!["local:x", serde_json::json!({ "localPath": audio_path }).to_string()],
            )
            .unwrap();
            conn.execute(
                "INSERT INTO history VALUES(1, ?1)",
                params![serde_json::json!({ "localPath": audio_path }).to_string()],
            )
            .unwrap();
            conn.execute(
                "INSERT INTO cache VALUES('k', ?1)",
                params![serde_json::json!([{ "artworkUrl": art_path }]).to_string()],
            )
            .unwrap();
            conn.execute(
                "INSERT INTO playlists VALUES('p', ?1)",
                params![art_path],
            )
            .unwrap();
        }

        let migrated = migrate_legacy(&new_dir).unwrap();
        assert!(migrated.is_some());
        assert!(new_dir.join(NEW_DB).exists());
        assert!(new_dir.join("downloads/a.mp3").exists());
        assert!(new_dir.join("artwork/c.png").exists());

        let new_prefix = new_dir.to_string_lossy().to_string();
        let conn = Connection::open(new_dir.join(NEW_DB)).unwrap();
        let local: String = conn
            .query_row("SELECT local_path FROM tracks", [], |r| r.get(0))
            .unwrap();
        assert!(local.starts_with(&new_prefix));
        assert!(!local.contains(&old_prefix));
        let payload: String = conn
            .query_row("SELECT payload FROM tracks", [], |r| r.get(0))
            .unwrap();
        assert!(payload.contains(&new_prefix.replace('\\', "\\\\")));
        let history: String = conn
            .query_row("SELECT payload FROM history", [], |r| r.get(0))
            .unwrap();
        assert!(history.contains(&new_prefix.replace('\\', "\\\\")));
        drop(conn);

        // Second run is a no-op once the new database exists.
        assert!(migrate_legacy(&new_dir).unwrap().is_none());

        let _ = std::fs::remove_dir_all(&root);
    }

    #[test]
    fn leaves_no_database_when_there_is_no_legacy_folder() {
        let root = temp_root();
        let new_dir = root.join("app.sakeenah.desktop");
        assert!(migrate_legacy(&new_dir).unwrap().is_none());
        assert!(!new_dir.join(NEW_DB).exists());
        let _ = std::fs::remove_dir_all(&root);
    }
}
