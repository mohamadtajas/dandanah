use crate::db::Database;
use crate::providers::Track;
use anyhow::{anyhow, Context, Result};
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use std::io::Write;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tauri::{AppHandle, Emitter, Manager};

pub const EVENT: &str = "download:progress";

#[derive(Clone, serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Progress {
    pub track_id: String,
    pub status: String,
    pub received: u64,
    pub total: u64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub path: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

fn emit(app: &AppHandle, progress: Progress) {
    let _ = app.emit(EVENT, progress);
}

/// Streams one track into the app data directory, reporting progress to the UI.
pub async fn run(
    app: AppHandle,
    http: reqwest::Client,
    db: Arc<Database>,
    track: Track,
) -> Result<String> {
    let url = track
        .stream_url
        .clone()
        .ok_or_else(|| anyhow!("track has no stream URL"))?;

    db.queue_download(&track)?;
    emit(
        &app,
        Progress {
            track_id: track.id.clone(),
            status: "queued".into(),
            received: 0,
            total: 0,
            path: None,
            error: None,
        },
    );

    match fetch_to_file(&app, &http, &db, &track, &url).await {
        Ok(path) => {
            db.finish_download(&track.id, &path)?;
            emit(
                &app,
                Progress {
                    track_id: track.id.clone(),
                    status: "done".into(),
                    received: 0,
                    total: 0,
                    path: Some(path.clone()),
                    error: None,
                },
            );
            Ok(path)
        }
        Err(error) => {
            let message = error.to_string();
            db.fail_download(&track.id, &message)?;
            emit(
                &app,
                Progress {
                    track_id: track.id.clone(),
                    status: "error".into(),
                    received: 0,
                    total: 0,
                    path: None,
                    error: Some(message.clone()),
                },
            );
            Err(error)
        }
    }
}

async fn fetch_to_file(
    app: &AppHandle,
    http: &reqwest::Client,
    db: &Database,
    track: &Track,
    url: &str,
) -> Result<String> {
    let dir = app
        .path()
        .app_data_dir()
        .context("resolving app data directory")?
        .join("downloads");
    std::fs::create_dir_all(&dir).context("creating downloads directory")?;

    let extension = extension_for(url);
    let final_path = dir.join(file_name(track, &extension));
    let part_path = final_path.with_extension(format!("{extension}.part"));

    let response = http
        .get(url)
        .send()
        .await
        .context("requesting audio stream")?
        .error_for_status()
        .context("audio server returned an error")?;
    let total = response.content_length().unwrap_or(0);

    let mut file = std::fs::File::create(&part_path).context("creating download file")?;
    let mut response = response;
    let mut received: u64 = 0;
    let mut last_report = Instant::now();

    while let Some(chunk) = response.chunk().await.context("reading audio stream")? {
        file.write_all(&chunk).context("writing download file")?;
        received += chunk.len() as u64;

        if last_report.elapsed() >= Duration::from_millis(250) {
            last_report = Instant::now();
            db.set_download_progress(&track.id, received, total, "downloading")?;
            emit(
                app,
                Progress {
                    track_id: track.id.clone(),
                    status: "downloading".into(),
                    received,
                    total,
                    path: None,
                    error: None,
                },
            );
        }
    }

    file.flush().context("flushing download file")?;
    drop(file);

    if received == 0 {
        let _ = std::fs::remove_file(&part_path);
        return Err(anyhow!("the server sent an empty file"));
    }

    std::fs::rename(&part_path, &final_path).context("finalising download")?;
    db.set_download_progress(&track.id, received, total.max(received), "done")?;

    Ok(final_path.to_string_lossy().to_string())
}

fn file_name(track: &Track, extension: &str) -> String {
    let mut hasher = DefaultHasher::new();
    track.id.hash(&mut hasher);
    let hash = format!("{:08x}", hasher.finish() as u32);

    let mut slug: String = format!("{} - {}", track.artist, track.title)
        .chars()
        .take(70)
        .map(|c| {
            if c.is_alphanumeric() || c == '-' || c == '_' {
                c
            } else {
                ' '
            }
        })
        .collect();
    slug = slug.split_whitespace().collect::<Vec<_>>().join(" ");
    if slug.is_empty() {
        slug = "track".into();
    }
    format!("{hash} {slug}.{extension}")
}

fn extension_for(url: &str) -> String {
    let path = url.split('?').next().unwrap_or(url);
    let ext = path
        .rsplit('.')
        .next()
        .map(|e| e.to_ascii_lowercase())
        .unwrap_or_default();
    match ext.as_str() {
        "mp3" | "m4a" | "m4b" | "aac" | "ogg" | "oga" | "opus" | "flac" | "wav" | "wma" => ext,
        _ => "mp3".into(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::providers::TrackKind;

    #[test]
    fn picks_extension_from_path_ignoring_query() {
        assert_eq!(extension_for("https://x/a/b.mp3"), "mp3");
        assert_eq!(extension_for("https://x/stream?id=1"), "mp3");
        assert_eq!(extension_for("https://x/a/b.FLAC?token=2"), "flac");
        assert_eq!(extension_for("https://x/a/b.php"), "mp3");
    }

    #[test]
    fn file_names_are_unique_and_safe() {
        let mut a = Track::new("mp3quran", "1-1", "سورة الفاتحة", TrackKind::Quran);
        a.artist = "الحصري".into();
        let mut b = Track::new("mp3quran", "1-2", "سورة البقرة", TrackKind::Quran);
        b.artist = "الحصري".into();

        let fa = file_name(&a, "mp3");
        let fb = file_name(&b, "mp3");
        assert_ne!(fa, fb);
        assert!(fa.ends_with(".mp3"));
        assert!(!fa.contains('/') && !fa.contains(':'));
        assert!(fa.contains("سورة"));
    }
}
