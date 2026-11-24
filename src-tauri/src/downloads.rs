use crate::db::{Database, DownloadRow};
use crate::providers::Track;
use anyhow::{anyhow, Context, Result};
use parking_lot::Mutex;
use reqwest::header::RANGE;
use reqwest::StatusCode;
use serde::Serialize;
use std::collections::hash_map::DefaultHasher;
use std::collections::{HashMap, HashSet};
use std::fs::{File, OpenOptions};
use std::hash::{Hash, Hasher};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};
use tauri::{AppHandle, Emitter, Manager};

pub const EVENT: &str = "download:progress";

/// Downloads that may run at the same time. Providers throttle aggressively,
/// and three streams keeps the UI responsive without stalling the queue.
pub const MAX_CONCURRENT: usize = 3;
/// Safety cap for one bulk request (a full mushaf is ~114 files, a reciter
/// with several moshafs can be a few hundred).
pub const MAX_BATCH: usize = 700;

/// A deliberately small queue around the streaming downloader: every job gets
/// a cancellation flag, and a semaphore limits how many sockets are open.
pub struct DownloadQueue {
    semaphore: Arc<tokio::sync::Semaphore>,
    cancels: Mutex<HashMap<String, Arc<AtomicBool>>>,
    /// Serialises batch admission so two clicks cannot create two workers (or
    /// a `queued` row with no worker) for the same track.
    submission: Mutex<()>,
}

impl Default for DownloadQueue {
    fn default() -> Self {
        Self::new()
    }
}

impl DownloadQueue {
    pub fn new() -> Self {
        Self {
            semaphore: Arc::new(tokio::sync::Semaphore::new(MAX_CONCURRENT)),
            cancels: Mutex::new(HashMap::new()),
            submission: Mutex::new(()),
        }
    }

    /// Number of jobs enqueued or running right now.
    pub fn active(&self) -> usize {
        self.cancels.lock().len()
    }

    pub fn is_active(&self, track_id: &str) -> bool {
        self.cancels.lock().contains_key(track_id)
    }

    /// Flags a queued or running job. Returns `None` when it already finished.
    pub fn cancel(&self, track_id: &str) -> Option<Arc<AtomicBool>> {
        let flag = self.cancels.lock().get(track_id).cloned()?;
        flag.store(true, Ordering::Relaxed);
        Some(flag)
    }

    /// Applies the queue policy, persists the batch in one transaction and
    /// only then spawns the workers. Admission is serialised end to end.
    pub fn submit(
        self: &Arc<Self>,
        app: AppHandle,
        http: reqwest::Client,
        db: Arc<Database>,
        incoming: Vec<Track>,
    ) -> Result<usize> {
        let _guard = self.submission.lock();
        let existing = db.downloads()?;
        let selected: Vec<Track> =
            select_for_queue(&existing, incoming, MAX_BATCH)
                .into_iter()
                .filter(|track| !self.is_active(&track.id))
                .collect();
        if selected.is_empty() {
            return Ok(0);
        }
        // The rows must exist before the workers can report progress.
        db.queue_downloads(&selected)?;
        Ok(self.enqueue(app, http, db, selected))
    }

    /// Queues tracks that the caller already persisted as `queued` and spawns
    /// one task per track; the semaphore decides when each one actually runs.
    pub fn enqueue(
        self: &Arc<Self>,
        app: AppHandle,
        http: reqwest::Client,
        db: Arc<Database>,
        tracks: Vec<Track>,
    ) -> usize {
        let artwork_dir = app
            .path()
            .app_data_dir()
            .map(|dir| dir.join("artwork"))
            .unwrap_or_else(|_| std::env::temp_dir().join("sakeenah-artwork"));
        std::fs::create_dir_all(&artwork_dir).ok();

        let mut queued = 0;
        for track in tracks {
            let cancel = Arc::new(AtomicBool::new(false));
            {
                // A rapid double-click must not start the same track twice.
                let mut flags = self.cancels.lock();
                if flags.contains_key(&track.id) {
                    continue;
                }
                flags.insert(track.id.clone(), cancel.clone());
            }
            queued += 1;

            let queue = self.clone();
            let app = app.clone();
            let http = http.clone();
            let db = db.clone();
            let artwork_dir = artwork_dir.clone();
            let permit = self.semaphore.clone();
            tauri::async_runtime::spawn(async move {
                // Holding the permit until the stream finishes is what keeps
                // the number of concurrent downloads bounded.
                let acquired = permit.acquire_owned().await;
                if acquired.is_err() {
                    queue.cancels.lock().remove(&track.id);
                    return;
                }

                if cancel.load(Ordering::Relaxed) {
                    let _ = db.set_download_progress(&track.id, 0, 0, "cancelled");
                    emit(
                        &app,
                        Progress {
                            track_id: track.id.clone(),
                            status: "cancelled".into(),
                            received: 0,
                            total: 0,
                            path: None,
                            error: None,
                        },
                    );
                } else {
                    let _ = run(
                        app.clone(),
                        http,
                        db.clone(),
                        track.clone(),
                        cancel,
                        artwork_dir,
                    )
                    .await;
                }

                queue.cancels.lock().remove(&track.id);
                drop(acquired);
            });
        }
        queued
    }
}

/// Applies the queue policy: known stream URL, no duplicate within the batch,
/// and no job that is already queued, running or finished.
pub fn select_for_queue(
    existing: &[DownloadRow],
    incoming: Vec<Track>,
    cap: usize,
) -> Vec<Track> {
    let blocked: HashSet<&str> = existing
        .iter()
        .filter(|row| matches!(row.status.as_str(), "queued" | "downloading" | "done"))
        .map(|row| row.track.id.as_str())
        .collect();
    let mut seen = HashSet::new();
    incoming
        .into_iter()
        .filter(|track| {
            track.stream_url.is_some() && !blocked.contains(track.id.as_str())
        })
        .filter(|track| seen.insert(track.id.clone()))
        .take(cap)
        .collect()
}

/// Both the finished file and a resumable `.part` file, derived from the path
/// stored on a completed row.
pub fn sibling_part(path: &Path) -> PathBuf {
    let extension = path
        .extension()
        .and_then(|value| value.to_str())
        .map(|value| format!("{value}.part"))
        .unwrap_or_else(|| "part".into());
    path.with_extension(extension)
}

/// Removes the files belonging to one download. The download row must only be
/// deleted after this succeeds, so a failure leaves the library consistent.
pub fn remove_files(final_path: Option<&str>, part_path: Option<&Path>) -> Result<u64> {
    let mut freed = 0;
    for path in [final_path.map(Path::new), part_path].into_iter().flatten() {
        match std::fs::metadata(path) {
            Ok(meta) => {
                std::fs::remove_file(path)
                    .with_context(|| format!("removing {}", path.display()))?;
                freed += meta.len();
            }
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
            Err(error) => {
                return Err(error).with_context(|| format!("inspecting {}", path.display()))
            }
        }
    }
    Ok(freed)
}

/// What the storage panel shows. Completed files use the size recorded at
/// download time (falling back to the file), partial rows use the bytes that
/// actually reached disk, and imported files are measured directly.
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct StorageTotals {
    pub downloaded_bytes: u64,
    pub downloaded_count: usize,
    pub partial_bytes: u64,
    pub partial_count: usize,
    pub local_bytes: u64,
    pub local_count: usize,
    pub total_bytes: u64,
    pub active: usize,
}

pub fn totals(rows: &[DownloadRow], local: &[Track], active: usize) -> StorageTotals {
    let mut totals = StorageTotals {
        downloaded_bytes: 0,
        downloaded_count: 0,
        partial_bytes: 0,
        partial_count: 0,
        local_bytes: 0,
        local_count: 0,
        total_bytes: 0,
        active,
    };

    for row in rows {
        if row.status == "done" {
            let size = if row.bytes_total > 0 {
                row.bytes_total
            } else {
                row.file_path
                    .as_deref()
                    .and_then(|path| std::fs::metadata(path).ok())
                    .map(|meta| meta.len())
                    .unwrap_or(0)
            };
            totals.downloaded_bytes += size;
            totals.downloaded_count += 1;
        } else if row.bytes_done > 0 {
            totals.partial_bytes += row.bytes_done;
            totals.partial_count += 1;
        }
    }

    for track in local {
        let size = track
            .local_path
            .as_deref()
            .and_then(|path| std::fs::metadata(path).ok())
            .map(|meta| meta.len())
            .unwrap_or(0);
        totals.local_bytes += size;
        totals.local_count += 1;
    }

    totals.total_bytes = totals.downloaded_bytes + totals.partial_bytes + totals.local_bytes;
    totals
}

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

/// Final and `.part` paths for a track. Deterministic, so a retry can resume
/// the same partial file after a restart.
pub fn paths_for(app: &AppHandle, track: &Track) -> Result<(PathBuf, PathBuf)> {
    let url = track
        .stream_url
        .as_deref()
        .ok_or_else(|| anyhow!("track has no stream URL"))?;
    let dir = app
        .path()
        .app_data_dir()
        .context("resolving app data directory")?
        .join("downloads");
    std::fs::create_dir_all(&dir).context("creating downloads directory")?;
    let extension = extension_for(url);
    let final_path = dir.join(file_name(track, &extension));
    let part_path = final_path.with_extension(format!("{extension}.part"));
    Ok((final_path, part_path))
}

/// Streams one queued track into the app data directory. The row must already
/// be queued by the caller. Returns `Ok(None)` when cancelled; the `.part`
/// file is kept so a retry can resume.
pub async fn run(
    app: AppHandle,
    http: reqwest::Client,
    db: Arc<Database>,
    track: Track,
    cancel: Arc<AtomicBool>,
    artwork_dir: PathBuf,
) -> Result<Option<String>> {
    let url = track
        .stream_url
        .clone()
        .ok_or_else(|| anyhow!("track has no stream URL"))?;
    let (final_path, part_path) = paths_for(&app, &track)?;

    let _ = db.set_download_progress(&track.id, 0, 0, "downloading");
    emit(
        &app,
        Progress {
            track_id: track.id.clone(),
            status: "downloading".into(),
            received: 0,
            total: 0,
            path: None,
            error: None,
        },
    );

    let result = download_to_paths(
        &http,
        &url,
        &final_path,
        &part_path,
        &cancel,
        |received, total| {
            let _ = db.set_download_progress(&track.id, received, total, "downloading");
            emit(
                &app,
                Progress {
                    track_id: track.id.clone(),
                    status: "downloading".into(),
                    received,
                    total,
                    path: None,
                    error: None,
                },
            );
        },
    )
    .await;

    match result {
        Ok(Some((received, total))) => {
            db.finish_download(&track.id, &final_path.to_string_lossy())?;
            if let Some(artwork) = crate::library::extract_artwork(&final_path, &artwork_dir) {
                let _ = db.set_track_artwork(&track.id, &artwork);
            }
            emit(
                &app,
                Progress {
                    track_id: track.id.clone(),
                    status: "done".into(),
                    received,
                    total: total.max(received),
                    path: Some(final_path.to_string_lossy().to_string()),
                    error: None,
                },
            );
            Ok(Some(final_path.to_string_lossy().to_string()))
        }
        Ok(None) => {
            let received = file_size(&part_path);
            let _ = db.set_download_progress(&track.id, received, 0, "cancelled");
            emit(
                &app,
                Progress {
                    track_id: track.id.clone(),
                    status: "cancelled".into(),
                    received,
                    total: 0,
                    path: None,
                    error: None,
                },
            );
            Ok(None)
        }
        Err(error) => {
            let message = error.to_string();
            let _ = db.fail_download(&track.id, &message);
            emit(
                &app,
                Progress {
                    track_id: track.id.clone(),
                    status: "error".into(),
                    received: file_size(&part_path),
                    total: 0,
                    path: None,
                    error: Some(message.clone()),
                },
            );
            Err(error)
        }
    }
}

/// Downloads `url` into `part_path`, resuming a non-empty partial file with a
/// Range request, and atomically renames it to `final_path` on success.
/// Returns `Ok(None)` if cancelled (the part is kept), otherwise the byte count.
pub async fn download_to_paths<F>(
    http: &reqwest::Client,
    url: &str,
    final_path: &Path,
    part_path: &Path,
    cancel: &AtomicBool,
    progress: F,
) -> Result<Option<(u64, u64)>>
where
    F: Fn(u64, u64),
{
    let existing = file_size(part_path);
    let mut request = http.get(url);
    if existing > 0 {
        request = request.header(RANGE, format!("bytes={existing}-"));
    }
    let response = request
        .send()
        .await
        .context("requesting audio stream")?;

    if existing > 0 && response.status() == StatusCode::RANGE_NOT_SATISFIABLE {
        let _ = std::fs::remove_file(part_path);
        return Err(anyhow!("the partial download cannot be resumed; retry to start it again"));
    }

    let response = response
        .error_for_status()
        .context("audio server returned an error")?;
    let resuming = existing > 0 && response.status() == StatusCode::PARTIAL_CONTENT;
    let response_total = response.content_length().unwrap_or(0);
    let total = if resuming {
        existing.saturating_add(response_total)
    } else {
        response_total
    };
    let mut received = if resuming { existing } else { 0 };
    if !resuming {
        let _ = std::fs::remove_file(part_path);
    }

    if cancel.load(Ordering::Relaxed) {
        return Ok(None);
    }

    let mut file: File = if resuming {
        OpenOptions::new()
            .append(true)
            .open(part_path)
            .context("opening partial download")?
    } else {
        File::create(part_path).context("creating download file")?
    };

    progress(received, total);
    let mut response = response;
    let mut last_report = Instant::now();

    while let Some(chunk) = response.chunk().await.context("reading audio stream")? {
        if cancel.load(Ordering::Relaxed) {
            file.flush().ok();
            drop(file);
            progress(received, total);
            return Ok(None);
        }
        file.write_all(&chunk).context("writing download file")?;
        received += chunk.len() as u64;

        if last_report.elapsed() >= Duration::from_millis(250) {
            last_report = Instant::now();
            progress(received, total);
        }
    }

    file.flush().context("flushing download file")?;
    drop(file);

    if received == 0 {
        let _ = std::fs::remove_file(part_path);
        return Err(anyhow!("the server sent an empty file"));
    }

    let _ = std::fs::remove_file(final_path);
    std::fs::rename(part_path, final_path).context("finalising download")?;
    progress(received, total.max(received));
    Ok(Some((received, total.max(received))))
}

fn file_size(path: &Path) -> u64 {
    std::fs::metadata(path).map(|meta| meta.len()).unwrap_or(0)
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
    use tokio::io::{AsyncReadExt, AsyncWriteExt};
    use tokio::net::TcpListener;

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
        a.artist = "حفص".into();
        let mut b = Track::new("mp3quran", "1-2", "سورة البقرة", TrackKind::Quran);
        b.artist = "حفص".into();

        let fa = file_name(&a, "mp3");
        let fb = file_name(&b, "mp3");
        assert_ne!(fa, fb);
        assert!(fa.ends_with(".mp3"));
        assert!(!fa.contains('/') && !fa.contains(':'));
        assert!(fa.contains("حفص"));
    }

    fn temp_paths(name: &str) -> (PathBuf, PathBuf) {
        let dir = std::env::temp_dir().join(format!(
            "sakeenah-download-test-{}-{}",
            std::process::id(),
            name
        ));
        std::fs::create_dir_all(&dir).unwrap();
        (dir.join("final.mp3"), dir.join("final.mp3.part"))
    }

    /// A one-shot HTTP server that serves `body`, honouring a `Range` header
    /// when `range_body` is supplied.
    async fn serve_once(
        body: &'static [u8],
        range_body: Option<(u64, &'static [u8])>,
    ) -> String {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        tokio::spawn(async move {
            let (mut socket, _) = listener.accept().await.unwrap();
            let mut buffer = [0u8; 2048];
            let read = socket.read(&mut buffer).await.unwrap();
            let request = String::from_utf8_lossy(&buffer[..read]).to_string();
            let wants_range = request.to_ascii_lowercase().contains("range:");
            let (status, payload, extra) = match (wants_range, range_body) {
                (true, Some((start, partial))) => (
                    "206 Partial Content",
                    partial,
                    format!(
                        "Content-Range: bytes {}-{}/{}\r\n",
                        start,
                        start + partial.len() as u64 - 1,
                        body.len()
                    ),
                ),
                _ => ("200 OK", body, String::new()),
            };
            let response = format!(
                "HTTP/1.1 {status}\r\nContent-Length: {}\r\n{extra}Connection: close\r\n\r\n",
                payload.len()
            );
            socket.write_all(response.as_bytes()).await.unwrap();
            socket.write_all(payload).await.unwrap();
        });
        format!("http://{address}/track.mp3")
    }

    #[tokio::test]
    async fn downloads_and_finalises_a_file() {
        let url = serve_once(b"hello world", None).await;
        let (final_path, part_path) = temp_paths("basic");
        let cancel = AtomicBool::new(false);
        let result = download_to_paths(
            &reqwest::Client::new(),
            &url,
            &final_path,
            &part_path,
            &cancel,
            |_, _| {},
        )
        .await
        .unwrap()
        .unwrap();
        assert_eq!(result.0, 11);
        assert_eq!(std::fs::read_to_string(&final_path).unwrap(), "hello world");
        assert!(!part_path.exists());
        let _ = std::fs::remove_dir_all(final_path.parent().unwrap());
    }

    #[tokio::test]
    async fn resumes_from_a_partial_file() {
        let url = serve_once(b"hello world", Some((6, b"world"))).await;
        let (final_path, part_path) = temp_paths("resume");
        std::fs::write(&part_path, b"hello ").unwrap();
        let cancel = AtomicBool::new(false);
        let result = download_to_paths(
            &reqwest::Client::new(),
            &url,
            &final_path,
            &part_path,
            &cancel,
            |_, _| {},
        )
        .await
        .unwrap()
        .unwrap();
        assert_eq!(result.0, 11);
        assert_eq!(std::fs::read_to_string(&final_path).unwrap(), "hello world");
        let _ = std::fs::remove_dir_all(final_path.parent().unwrap());
    }

    /// The queue must not re-download finished work, but retrying an errored or
    /// cancelled job is exactly how resume is offered to the user.
    #[test]
    fn queue_skips_active_and_done_but_retries_failures() {
        let mut done = Track::new("mp3quran", "1", "الفاتحة", TrackKind::Quran);
        done.stream_url = Some("https://x/1.mp3".into());
        let mut queued = Track::new("mp3quran", "2", "البقرة", TrackKind::Quran);
        queued.stream_url = Some("https://x/2.mp3".into());
        let mut retry = Track::new("mp3quran", "3", "آل عمران", TrackKind::Quran);
        retry.stream_url = Some("https://x/3.mp3".into());
        let mut cancelled = Track::new("mp3quran", "4", "النساء", TrackKind::Quran);
        cancelled.stream_url = Some("https://x/4.mp3".into());
        let missing = Track::new("mp3quran", "5", "بلا رابط", TrackKind::Quran);

        let row = |track: &Track, status: &str| DownloadRow {
            track: track.clone(),
            status: status.into(),
            bytes_total: 0,
            bytes_done: 0,
            file_path: None,
            error: None,
            created_at: 0,
        };
        let existing = vec![
            row(&done, "done"),
            row(&queued, "downloading"),
            row(&retry, "error"),
            row(&cancelled, "cancelled"),
        ];

        let expected = vec![retry.id.clone(), cancelled.id.clone()];
        let selected = select_for_queue(
            &existing,
            vec![done, queued, retry, cancelled, missing],
            MAX_BATCH,
        );
        let ids: Vec<&str> = selected.iter().map(|track| track.id.as_str()).collect();
        assert_eq!(ids, expected, "only failed jobs are retried, and duplicates collapse");
    }

    #[test]
    fn queue_respects_the_batch_cap() {
        let tracks: Vec<Track> = (0..5)
            .map(|i| {
                let mut track = Track::new("mp3quran", i.to_string(), "سورة", TrackKind::Quran);
                track.stream_url = Some(format!("https://x/{i}.mp3"));
                track
            })
            .collect();
        assert_eq!(select_for_queue(&[], tracks, 3).len(), 3);
    }

    #[test]
    fn delete_removes_finished_and_partial_files() {
        let (final_path, part_path) = temp_paths("delete");
        std::fs::write(&final_path, b"done").unwrap();
        std::fs::write(&part_path, b"partial").unwrap();

        let freed = remove_files(Some(&final_path.to_string_lossy()), Some(&part_path)).unwrap();
        assert_eq!(freed, 11);
        assert!(!final_path.exists());
        assert!(!part_path.exists());
        // A second delete is a no-op rather than an error, so retrying is safe.
        assert_eq!(
            remove_files(Some(&final_path.to_string_lossy()), Some(&part_path)).unwrap(),
            0
        );
        let _ = std::fs::remove_dir_all(final_path.parent().unwrap());
    }

    #[test]
    fn part_path_is_derived_from_the_final_name() {
        assert_eq!(
            sibling_part(Path::new("C:/x/track.mp3")),
            PathBuf::from("C:/x/track.mp3.part")
        );
    }

    #[test]
    fn storage_totals_match_completed_partial_and_local_files() {
        let (final_path, _) = temp_paths("totals");
        std::fs::write(&final_path, b"1234567").unwrap();
        let stored = final_path.to_string_lossy().to_string();

        let track = |id: &str| {
            let mut track = Track::new("mp3quran", id, "سورة", TrackKind::Quran);
            track.stream_url = Some(format!("https://x/{id}.mp3"));
            track
        };
        let row = |track: Track, status: &str, total: u64, done: u64, path: Option<String>| {
            DownloadRow {
                track,
                status: status.into(),
                bytes_total: total,
                bytes_done: done,
                file_path: path,
                error: None,
                created_at: 0,
            }
        };

        let rows = vec![
            row(track("1"), "done", 100, 100, None),
            // Older rows may have no recorded size; the file is the fallback.
            row(track("2"), "done", 0, 0, Some(stored.clone())),
            row(track("3"), "error", 500, 30, None),
            row(track("4"), "queued", 0, 0, None),
        ];
        let mut local = Track::new("local", stored.clone(), "ملف", TrackKind::Local);
        local.local_path = Some(stored.clone());

        let totals = totals(&rows, &[local], 1);
        assert_eq!(totals.downloaded_bytes, 107);
        assert_eq!(totals.downloaded_count, 2);
        assert_eq!(totals.partial_bytes, 30);
        assert_eq!(totals.partial_count, 1);
        assert_eq!(totals.local_bytes, 7);
        assert_eq!(totals.local_count, 1);
        assert_eq!(totals.total_bytes, 144);
        assert_eq!(totals.active, 1);
        let _ = std::fs::remove_dir_all(final_path.parent().unwrap());
    }
}
