use crate::db::{Database, DownloadRow};
use crate::providers::Track;
use anyhow::{anyhow, Context, Result};
use parking_lot::Mutex;
use reqwest::header::{CONTENT_RANGE, ETAG, IF_RANGE, LAST_MODIFIED, RANGE};
use reqwest::StatusCode;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::fs::{File, OpenOptions};
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

/// One admitted download. `started` tells cancellation whether the worker is
/// already streaming (the file handle must be allowed to close) or still
/// waiting for a slot (the entry can be dropped immediately).
pub struct Job {
    cancel: AtomicBool,
    started: AtomicBool,
}

/// A deliberately small queue around the streaming downloader: every job gets
/// a cancellation flag, and a semaphore limits how many sockets are open.
pub struct DownloadQueue {
    semaphore: Arc<tokio::sync::Semaphore>,
    jobs: Mutex<HashMap<String, Arc<Job>>>,
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
            jobs: Mutex::new(HashMap::new()),
            submission: Mutex::new(()),
        }
    }

    /// Jobs that hold a concurrency slot right now.
    pub fn running(&self) -> usize {
        MAX_CONCURRENT.saturating_sub(self.semaphore.available_permits())
    }

    pub fn is_active(&self, track_id: &str) -> bool {
        self.jobs.lock().contains_key(track_id)
    }

    fn owns(&self, track_id: &str, job: &Arc<Job>) -> bool {
        self.jobs
            .lock()
            .get(track_id)
            .is_some_and(|current| Arc::ptr_eq(current, job))
    }

    fn release(&self, track_id: &str, job: &Arc<Job>) {
        let mut jobs = self.jobs.lock();
        if jobs
            .get(track_id)
            .is_some_and(|current| Arc::ptr_eq(current, job))
        {
            jobs.remove(track_id);
        }
    }

    /// Flags a queued or running job. A job still waiting for a slot is
    /// removed immediately so it can be retried or deleted without waiting
    /// for unrelated downloads. Returns `None` when it already finished.
    pub fn cancel(&self, track_id: &str) -> Option<Arc<Job>> {
        let mut jobs = self.jobs.lock();
        let job = jobs.get(track_id)?.clone();
        job.cancel.store(true, Ordering::Relaxed);
        if !job.started.load(Ordering::Relaxed) {
            jobs.remove(track_id);
        }
        Some(job)
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
    fn enqueue(
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
            let job = Arc::new(Job {
                cancel: AtomicBool::new(false),
                started: AtomicBool::new(false),
            });
            {
                // A rapid double-click must not start the same track twice.
                let mut jobs = self.jobs.lock();
                if let Some(existing) = jobs.get(&track.id) {
                    if !existing.cancel.load(Ordering::Relaxed) {
                        continue;
                    }
                }
                jobs.insert(track.id.clone(), job.clone());
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
                    queue.release(&track.id, &job);
                    return;
                }

                let claimed = {
                    let jobs = queue.jobs.lock();
                    let owner = jobs
                        .get(&track.id)
                        .is_some_and(|current| Arc::ptr_eq(current, &job));
                    if owner && !job.cancel.load(Ordering::Relaxed) {
                        job.started.store(true, Ordering::Relaxed);
                        true
                    } else {
                        false
                    }
                };
                if claimed {
                    let _ = run(
                        app.clone(),
                        http,
                        db.clone(),
                        queue.clone(),
                        track.clone(),
                        job.clone(),
                        artwork_dir,
                    )
                    .await;
                }
                queue.release(&track.id, &job);
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
        .filter(|row| match row.status.as_str() {
            "queued" | "downloading" => true,
            // A `done` row whose file vanished is repairable, not blocked.
            "done" => row
                .file_path
                .as_deref()
                .map(|path| Path::new(path).exists())
                .unwrap_or(false),
            _ => false,
        })
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
    let mut paths: Vec<PathBuf> = Vec::new();
    if let Some(path) = final_path {
        paths.push(PathBuf::from(path));
    }
    if let Some(part) = part_path {
        paths.push(part.to_path_buf());
        paths.push(meta_path(part));
    }
    for path in paths {
        match std::fs::metadata(&path) {
            Ok(meta) => {
                std::fs::remove_file(&path)
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

/// What the storage panel shows. Sizes come from the files themselves so the
/// panel never counts a file that was deleted outside the app; recorded bytes
/// are only a fallback for older rows without a path.
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
    pub queued: usize,
}

pub fn totals(rows: &[DownloadRow], local: &[Track], running: usize) -> StorageTotals {
    let mut totals = StorageTotals {
        downloaded_bytes: 0,
        downloaded_count: 0,
        partial_bytes: 0,
        partial_count: 0,
        local_bytes: 0,
        local_count: 0,
        total_bytes: 0,
        active: running,
        queued: 0,
    };

    for row in rows {
        if row.status == "done" {
            let size = match row.file_path.as_deref() {
                Some(path) => std::fs::metadata(path).ok().map(|meta| meta.len()),
                None if row.bytes_total > 0 => Some(row.bytes_total),
                None => None,
            };
            if let Some(size) = size {
                totals.downloaded_bytes += size;
                totals.downloaded_count += 1;
            }
        } else {
            let size = match row.part_path.as_deref() {
                Some(path) => std::fs::metadata(path).ok().map(|meta| meta.len()),
                None if row.bytes_done > 0 => Some(row.bytes_done),
                None => None,
            };
            if let Some(size) = size {
                totals.partial_bytes += size;
                totals.partial_count += 1;
            }
        }
        if row.status == "queued" {
            totals.queued += 1;
        }
    }

    for track in local {
        let size = track
            .local_path
            .as_deref()
            .and_then(|path| std::fs::metadata(path).ok())
            .map(|meta| meta.len());
        if let Some(size) = size {
            totals.local_bytes += size;
            totals.local_count += 1;
        }
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
    queue: Arc<DownloadQueue>,
    track: Track,
    job: Arc<Job>,
    artwork_dir: PathBuf,
) -> Result<Option<String>> {
    let url = track
        .stream_url
        .clone()
        .ok_or_else(|| anyhow!("track has no stream URL"))?;
    let (final_path, part_path) = paths_for(&app, &track)?;
    db.set_download_part(&track.id, &part_path.to_string_lossy())?;

    let cancelled = || job.cancel.load(Ordering::Relaxed);
    let owner = || queue.owns(&track.id, &job);

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
        &job.cancel,
        |received, total| {
            // A stale worker must never overwrite a retry's progress.
            if cancelled() || !owner() {
                return;
            }
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
    // A network failure that raced the cancel flag is a cancellation, not a
    // user-facing error.
    let result = match result {
        Err(_) if cancelled() => Ok(None),
        other => other,
    };

    match result {
        Ok(Some((received, total))) => {
            // Once the body is complete the file is final: a cancel that
            // raced the rename must not turn a finished download into a
            // cancelled row.
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
            if !owner() {
                return Ok(None);
            }
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
            let code = error_code(&error);
            eprintln!("download {} failed ({code}): {error:#}", track.id);
            if owner() {
                let _ = db.fail_download(&track.id, code);
                emit(
                    &app,
                    Progress {
                        track_id: track.id.clone(),
                        status: "error".into(),
                        received: file_size(&part_path),
                        total: 0,
                        path: None,
                        error: Some(code.into()),
                    },
                );
            }
            Err(error)
        }
    }
}

/// Stable codes persisted in the DB; the UI maps them to translated copy and
/// the raw English detail only goes to the log.
fn error_code(error: &anyhow::Error) -> &'static str {
    let message = format!("{error:#}").to_ascii_lowercase();
    if message.contains("unexpected range") {
        "resume-mismatch"
    } else if message.contains("cannot be resumed") {
        "range-invalid"
    } else if message.contains("empty file") {
        "empty-file"
    } else if message.contains("ended before") {
        "truncated"
    } else if message.contains("no stream url") {
        "no-url"
    } else if message.contains("requesting")
        || message.contains("server returned")
        || message.contains("reading audio stream")
        || message.contains("request")
    {
        "network"
    } else {
        "file"
    }
}

/// Validators recorded next to a `.part` file. `If-Range` ensures the server
/// only appends when the remote file is the same one the prefix came from.
#[derive(Serialize, Deserialize, Default)]
struct PartMeta {
    url: String,
    etag: Option<String>,
    last_modified: Option<String>,
}

fn meta_path(part_path: &Path) -> PathBuf {
    let mut value = part_path.as_os_str().to_owned();
    value.push(".meta");
    PathBuf::from(value)
}

fn read_meta(part_path: &Path) -> Option<PartMeta> {
    let payload = std::fs::read_to_string(meta_path(part_path)).ok()?;
    serde_json::from_str(&payload).ok()
}

fn write_meta(part_path: &Path, meta: &PartMeta) {
    if let Ok(payload) = serde_json::to_string(meta) {
        let _ = std::fs::write(meta_path(part_path), payload);
    }
}

fn remove_meta(part_path: &Path) {
    let _ = std::fs::remove_file(meta_path(part_path));
}

fn header_value(response: &reqwest::Response, header: reqwest::header::HeaderName) -> Option<String> {
    response
        .headers()
        .get(header)
        .and_then(|value| value.to_str().ok())
        .map(str::to_string)
}

/// `bytes 100-199/2000` or `bytes */2000`.
fn parse_content_range(value: &str) -> Option<(Option<u64>, Option<u64>)> {
    let rest = value.strip_prefix("bytes ")?;
    let (range, total) = rest.split_once('/')?;
    let total = total.parse::<u64>().ok();
    let start = if range == "*" {
        None
    } else {
        range.split('-').next().and_then(|value| value.parse::<u64>().ok())
    };
    Some((start, total))
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
    let resume_meta = if existing > 0 {
        read_meta(part_path).filter(|meta| meta.url == url)
    } else {
        None
    };
    let mut request = http.get(url);
    if existing > 0 {
        request = request.header(RANGE, format!("bytes={existing}-"));
        if let Some(validator) = resume_meta
            .as_ref()
            .and_then(|meta| meta.etag.clone().or_else(|| meta.last_modified.clone()))
        {
            request = request.header(IF_RANGE, validator);
        }
    }
    let response = request
        .send()
        .await
        .context("requesting audio stream")?;

    if existing > 0 && response.status() == StatusCode::RANGE_NOT_SATISFIABLE {
        // The server may be telling us the part is already the whole file
        // (e.g. the app stopped after the last byte, before the rename).
        let total = response
            .headers()
            .get(CONTENT_RANGE)
            .and_then(|value| value.to_str().ok())
            .and_then(parse_content_range)
            .and_then(|(_, total)| total);
        if total == Some(existing) {
            let _ = std::fs::remove_file(final_path);
            std::fs::rename(part_path, final_path).context("finalising download")?;
            remove_meta(part_path);
            progress(existing, existing);
            return Ok(Some((existing, existing)));
        }
        let _ = std::fs::remove_file(part_path);
        remove_meta(part_path);
        return Err(anyhow!("the partial download cannot be resumed; retry to start it again"));
    }

    let response = response
        .error_for_status()
        .context("audio server returned an error")?;
    let resuming = existing > 0 && response.status() == StatusCode::PARTIAL_CONTENT;
    if resuming {
        // A 206 for a different start offset would corrupt the file; only
        // append when the server honoured exactly the requested offset.
        let start = response
            .headers()
            .get(CONTENT_RANGE)
            .and_then(|value| value.to_str().ok())
            .and_then(parse_content_range)
            .and_then(|(start, _)| start);
        if start != Some(existing) {
            let _ = std::fs::remove_file(part_path);
            remove_meta(part_path);
            return Err(anyhow!(
                "the server sent an unexpected range; retry to start the download again"
            ));
        }
    }
    let response_total = response.content_length().unwrap_or(0);
    let total = if resuming {
        existing.saturating_add(response_total)
    } else {
        response_total
    };
    let start = if resuming { existing } else { 0 };
    let mut received = start;
    if !resuming {
        let _ = std::fs::remove_file(part_path);
        remove_meta(part_path);
    }

    // Record the validator for the next attempt. Only a fresh 200 replaces an
    // existing meta file; a 206 keeps the validator that made it valid.
    if !resuming {
        write_meta(
            part_path,
            &PartMeta {
                url: url.to_string(),
                etag: header_value(&response, ETAG),
                last_modified: header_value(&response, LAST_MODIFIED),
            },
        );
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
        remove_meta(part_path);
        return Err(anyhow!("the server sent an empty file"));
    }
    // A 206 with no body, or a stream that closed before Content-Length, must
    // never be renamed into a final file.
    if received == start || (total > 0 && received < total) {
        return Err(anyhow!(
            "the download ended before the full file arrived; retry to resume"
        ));
    }

    let _ = std::fs::remove_file(final_path);
    std::fs::rename(part_path, final_path).context("finalising download")?;
    remove_meta(part_path);
    progress(received, total.max(received));
    Ok(Some((received, total.max(received))))
}

fn file_size(path: &Path) -> u64 {
    std::fs::metadata(path).map(|meta| meta.len()).unwrap_or(0)
}

/// Stable across releases, unlike `DefaultHasher`, so an app update can still
/// resume the same `.part` file.
fn stable_hash(value: &str) -> u64 {
    let mut hash: u64 = 0xcbf2_9ce4_8422_2325;
    for byte in value.as_bytes() {
        hash ^= u64::from(*byte);
        hash = hash.wrapping_mul(0x0000_0100_0000_01b3);
    }
    hash
}

fn file_name(track: &Track, extension: &str) -> String {
    let hash = format!("{:08x}", stable_hash(&track.id) as u32);

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

    /// A one-shot HTTP server that always answers with a 206 whose range does
    /// not match the requested offset.
    async fn serve_wrong_range() -> String {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        tokio::spawn(async move {
            let (mut socket, _) = listener.accept().await.unwrap();
            let mut buffer = [0u8; 2048];
            let _ = socket.read(&mut buffer).await.unwrap();
            let response = "HTTP/1.1 206 Partial Content\r\nContent-Length: 5\r\nContent-Range: bytes 0-4/11\r\nConnection: close\r\n\r\nworld";
            socket.write_all(response.as_bytes()).await.unwrap();
        });
        format!("http://{address}/track.mp3")
    }

    /// A one-shot server that claims a 206 but sends no body.
    async fn serve_empty_range() -> String {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        tokio::spawn(async move {
            let (mut socket, _) = listener.accept().await.unwrap();
            let mut buffer = [0u8; 2048];
            let _ = socket.read(&mut buffer).await.unwrap();
            let response = "HTTP/1.1 206 Partial Content\r\nContent-Length: 0\r\nContent-Range: bytes 6-5/11\r\nConnection: close\r\n\r\n";
            socket.write_all(response.as_bytes()).await.unwrap();
        });
        format!("http://{address}/track.mp3")
    }

    /// A one-shot server that reports the partial file is already complete.
    async fn serve_range_not_satisfiable() -> String {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        tokio::spawn(async move {
            let (mut socket, _) = listener.accept().await.unwrap();
            let mut buffer = [0u8; 2048];
            let _ = socket.read(&mut buffer).await.unwrap();
            let response = "HTTP/1.1 416 Range Not Satisfiable\r\nContent-Length: 0\r\nContent-Range: bytes */6\r\nConnection: close\r\n\r\n";
            socket.write_all(response.as_bytes()).await.unwrap();
        });
        format!("http://{address}/track.mp3")
    }

    #[tokio::test]
    async fn rejects_a_mismatched_range_instead_of_corrupting() {
        let url = serve_wrong_range().await;
        let (final_path, part_path) = temp_paths("wrong-range");
        std::fs::write(&part_path, b"hello ").unwrap();
        let cancel = AtomicBool::new(false);
        let error = download_to_paths(
            &reqwest::Client::new(),
            &url,
            &final_path,
            &part_path,
            &cancel,
            |_, _| {},
        )
        .await
        .unwrap_err();
        assert!(format!("{error:#}").contains("unexpected range"));
        assert!(!part_path.exists(), "the untrustworthy partial is discarded");
        assert!(!final_path.exists());
        let _ = std::fs::remove_dir_all(final_path.parent().unwrap());
    }

    #[tokio::test]
    async fn empty_partial_response_is_not_treated_as_complete() {
        let url = serve_empty_range().await;
        let (final_path, part_path) = temp_paths("empty-range");
        std::fs::write(&part_path, b"hello ").unwrap();
        let cancel = AtomicBool::new(false);
        let error = download_to_paths(
            &reqwest::Client::new(),
            &url,
            &final_path,
            &part_path,
            &cancel,
            |_, _| {},
        )
        .await
        .unwrap_err();
        assert!(format!("{error:#}").contains("ended before"));
        assert!(part_path.exists(), "the resumable part is kept");
        assert_eq!(std::fs::read(&part_path).unwrap(), b"hello ");
        assert!(!final_path.exists());
        let _ = std::fs::remove_dir_all(final_path.parent().unwrap());
    }

    #[tokio::test]
    async fn a_complete_partial_is_finalised_when_the_server_returns_416() {
        let url = serve_range_not_satisfiable().await;
        let (final_path, part_path) = temp_paths("range-complete");
        std::fs::write(&part_path, b"hello ").unwrap();
        let cancel = AtomicBool::new(false);
        let (received, total) = download_to_paths(
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
        assert_eq!((received, total), (6, 6));
        assert_eq!(std::fs::read(&final_path).unwrap(), b"hello ");
        assert!(!part_path.exists());
        let _ = std::fs::remove_dir_all(final_path.parent().unwrap());
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
        let mut stale = Track::new("mp3quran", "6", "المائدة", TrackKind::Quran);
        stale.stream_url = Some("https://x/6.mp3".into());
        let missing = Track::new("mp3quran", "5", "بلا رابط", TrackKind::Quran);

        let (final_path, _) = temp_paths("queue-done");
        std::fs::write(&final_path, b"done").unwrap();
        let stored = final_path.to_string_lossy().to_string();

        let row = |track: &Track, status: &str, path: Option<String>| DownloadRow {
            track: track.clone(),
            status: status.into(),
            bytes_total: 0,
            bytes_done: 0,
            file_path: path,
            part_path: None,
            error: None,
            created_at: 0,
        };
        let existing = vec![
            row(&done, "done", Some(stored)),
            row(&queued, "downloading", None),
            row(&retry, "error", None),
            row(&cancelled, "cancelled", None),
            // A done row whose file vanished must be downloadable again.
            row(&stale, "done", Some("C:/sakeenah-missing/6.mp3".into())),
        ];

        let expected = vec![retry.id.clone(), cancelled.id.clone(), stale.id.clone()];
        let selected = select_for_queue(
            &existing,
            vec![done, queued, retry, cancelled, stale, missing],
            MAX_BATCH,
        );
        let ids: Vec<&str> = selected.iter().map(|track| track.id.as_str()).collect();
        assert_eq!(
            ids, expected,
            "only failed/missing jobs are retried, and duplicates collapse"
        );
        let _ = std::fs::remove_dir_all(final_path.parent().unwrap());
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
    fn cancelling_a_waiting_job_releases_it_but_a_running_job_does_not() {
        let queue = DownloadQueue::new();

        let waiting = Arc::new(Job {
            cancel: AtomicBool::new(false),
            started: AtomicBool::new(false),
        });
        queue
            .jobs
            .lock()
            .insert("waiting".into(), waiting.clone());
        assert!(queue.cancel("waiting").is_some());
        assert!(waiting.cancel.load(Ordering::Relaxed));
        assert!(!queue.is_active("waiting"), "a queued cancel frees the id");
        // The old worker must see that it no longer owns the id.
        assert!(!queue.owns("waiting", &waiting));

        let running = Arc::new(Job {
            cancel: AtomicBool::new(false),
            started: AtomicBool::new(true),
        });
        queue
            .jobs
            .lock()
            .insert("running".into(), running.clone());
        assert!(queue.cancel("running").is_some());
        assert!(queue.owns("running", &running));
        assert!(queue.is_active("running"));
        queue.release("running", &running);
        assert!(!queue.is_active("running"));
    }

    #[test]
    fn delete_removes_finished_partial_and_sidecar_files() {
        let (final_path, part_path) = temp_paths("delete");
        std::fs::write(&final_path, b"done").unwrap();
        std::fs::write(&part_path, b"partial").unwrap();
        std::fs::write(meta_path(&part_path), b"{}").unwrap();

        let freed = remove_files(Some(&final_path.to_string_lossy()), Some(&part_path)).unwrap();
        assert_eq!(freed, 13);
        assert!(!final_path.exists());
        assert!(!part_path.exists());
        assert!(!meta_path(&part_path).exists());
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
        let part_path = final_path.with_extension("mp3.part");
        std::fs::write(&part_path, b"abcdefghijklm").unwrap();
        let stored = final_path.to_string_lossy().to_string();
        let stored_part = part_path.to_string_lossy().to_string();

        let track = |id: &str| {
            let mut track = Track::new("mp3quran", id, "سورة", TrackKind::Quran);
            track.stream_url = Some(format!("https://x/{id}.mp3"));
            track
        };
        let row = |track: Track,
                   status: &str,
                   total: u64,
                   done: u64,
                   path: Option<String>,
                   part: Option<String>| {
            DownloadRow {
                track,
                status: status.into(),
                bytes_total: total,
                bytes_done: done,
                file_path: path,
                part_path: part,
                error: None,
                created_at: 0,
            }
        };

        let rows = vec![
            // A legacy row without a path falls back to its recorded size.
            row(track("1"), "done", 100, 100, None, None),
            row(track("2"), "done", 0, 0, Some(stored.clone()), None),
            // Partial rows use the bytes actually on disk, not the stale DB count.
            row(track("3"), "error", 500, 30, None, Some(stored_part)),
            // A file deleted outside the app must not be counted.
            row(
                track("9"),
                "done",
                50,
                50,
                Some("C:/sakeenah-missing/file.mp3".into()),
                None,
            ),
            row(track("4"), "queued", 0, 0, None, None),
        ];
        let mut local = Track::new("local", stored.clone(), "ملف", TrackKind::Local);
        local.local_path = Some(stored.clone());

        let totals = totals(&rows, &[local], 1);
        assert_eq!(totals.downloaded_bytes, 107);
        assert_eq!(totals.downloaded_count, 2);
        assert_eq!(totals.partial_bytes, 13);
        assert_eq!(totals.partial_count, 1);
        assert_eq!(totals.local_bytes, 7);
        assert_eq!(totals.local_count, 1);
        assert_eq!(totals.total_bytes, 127);
        assert_eq!(totals.active, 1);
        assert_eq!(totals.queued, 1);
        let _ = std::fs::remove_dir_all(final_path.parent().unwrap());
    }
}
