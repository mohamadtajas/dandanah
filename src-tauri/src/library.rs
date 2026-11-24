use crate::providers::{Track, TrackKind};
use std::path::{Path, PathBuf};

/// Extensions WebView2 can decode without transcoding.
const AUDIO_EXTENSIONS: &[&str] = &[
    "mp3", "m4a", "m4b", "aac", "flac", "ogg", "oga", "opus", "wav", "wma",
];

const MAX_DEPTH: usize = 8;

pub struct ScanResult {
    pub tracks: Vec<Track>,
    pub truncated: bool,
}

/// Walks `root` and returns one track per audio file, reading tags with lofty
/// when they exist and falling back to the filename and parent folder.
pub fn scan_folder(root: &Path, limit: usize) -> ScanResult {
    let mut files: Vec<PathBuf> = Vec::new();
    walk(root, 0, &mut files, limit);
    let truncated = files.len() >= limit;

    let mut tracks: Vec<Track> = files.iter().filter_map(|p| track_from_file(p)).collect();
    tracks.sort_by(|a, b| a.title.cmp(&b.title));
    tracks.truncate(limit);
    ScanResult { tracks, truncated }
}

fn walk(dir: &Path, depth: usize, out: &mut Vec<PathBuf>, limit: usize) {
    if depth > MAX_DEPTH || out.len() >= limit {
        return;
    }
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        if out.len() >= limit {
            return;
        }
        let path = entry.path();
        if path.is_dir() {
            let name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
            if name.starts_with('.') || name.starts_with('$') {
                continue;
            }
            walk(&path, depth + 1, out, limit);
        } else if is_audio(&path) {
            out.push(path);
        }
    }
}

fn is_audio(path: &Path) -> bool {
    path.extension()
        .and_then(|e| e.to_str())
        .map(|e| AUDIO_EXTENSIONS.contains(&e.to_ascii_lowercase().as_str()))
        .unwrap_or(false)
}

fn track_from_file(path: &Path) -> Option<Track> {
    // `canonicalize` adds the `\\?\` verbatim prefix on Windows; strip it so
    // stored paths stay readable and portable.
    let absolute = path.canonicalize().unwrap_or_else(|_| path.to_path_buf());
    let absolute = match absolute.to_string_lossy().strip_prefix(r"\\?\") {
        Some(stripped) => PathBuf::from(stripped),
        None => absolute,
    };
    let path_str = absolute.to_string_lossy().to_string();

    let stem = path.file_stem().and_then(|s| s.to_str()).unwrap_or("Untitled");
    let folder = absolute
        .parent()
        .and_then(|p| p.file_name())
        .and_then(|n| n.to_str())
        .unwrap_or("")
        .to_string();

    let mut track = Track::new(
        "local",
        path_str.clone(),
        clean_stem(stem),
        TrackKind::Local,
    );
    track.artist = folder.clone();
    track.source_page = Some(format!("file://{}", path_str.replace('\\', "/")));
    track.local_path = Some(path_str);

    if let Ok(tagged) = lofty::read_from_path(&absolute) {
        use lofty::prelude::{Accessor, AudioFile, TaggedFileExt};

        let secs = tagged.properties().duration().as_secs();
        if secs > 0 {
            track.duration_s = Some(secs.min(u32::MAX as u64) as u32);
        }

        if let Some(tag) = tagged.primary_tag().or_else(|| tagged.first_tag()) {
            if let Some(title) = tag
                .title()
                .map(|t| t.trim().to_string())
                .filter(|t| !t.is_empty())
            {
                track.title = title;
            }
            // An album artist is a better fallback for compilations.
            let artist = tag
                .artist()
                .map(|a| a.trim().to_string())
                .or_else(|| {
                    tag.get_string(&lofty::tag::ItemKey::AlbumArtist)
                        .map(|a| a.trim().to_string())
                })
                .filter(|a| !a.is_empty());
            if let Some(artist) = artist {
                track.artist = artist;
            }
            if let Some(album) = tag
                .album()
                .map(|a| a.trim().to_string())
                .filter(|a| !a.is_empty())
            {
                track.album = Some(album);
            }
        }
    }

    if track.artist.is_empty() {
        track.artist = "مكتبتي".to_string();
    }

    Some(track)
}

/// Removes a leading track number ("03 - ", "03. ", "03 ") from a filename.
fn clean_stem(stem: &str) -> String {
    let trimmed = stem.trim();
    let digits_end = trimmed
        .char_indices()
        .take_while(|(_, c)| c.is_ascii_digit())
        .last()
        .map(|(i, c)| i + c.len_utf8())
        .unwrap_or(0);
    let rest = trimmed[digits_end..]
        .trim_start_matches(['-', '.', '_', ')', ']', ' '])
        .trim();
    if digits_end > 0 && !rest.is_empty() && digits_end <= 4 {
        rest.to_string()
    } else if trimmed.is_empty() {
        "Untitled".to_string()
    } else {
        trimmed.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn strips_numeric_prefixes() {
        assert_eq!(clean_stem("03 - سورة الكهف"), "سورة الكهف");
        assert_eq!(clean_stem("01. Intro"), "Intro");
        assert_eq!(clean_stem("Track 4"), "Track 4");
        assert_eq!(clean_stem("12345 long"), "12345 long");
    }

    #[test]
    fn recognises_audio_extensions() {
        assert!(is_audio(Path::new("a.mp3")));
        assert!(is_audio(Path::new("a.FLAC")));
        assert!(!is_audio(Path::new("cover.jpg")));
        assert!(!is_audio(Path::new("noext")));
    }

    #[test]
    fn scan_skips_hidden_and_non_audio() {
        let dir = std::env::temp_dir().join(format!("dandanah-scan-{}", std::process::id()));
        std::fs::create_dir_all(dir.join("hidden")).ok();
        std::fs::write(dir.join("one.mp3"), b"not audio").ok();
        std::fs::write(dir.join("cover.jpg"), b"x").ok();
        let result = scan_folder(&dir, 10);
        assert_eq!(result.tracks.len(), 1);
        assert_eq!(result.tracks[0].kind, TrackKind::Local);
        assert_eq!(result.tracks[0].local_path.is_some(), true);
        let _ = std::fs::remove_dir_all(&dir);
    }
}
