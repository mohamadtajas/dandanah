use super::{license_label, Track, TrackKind};
use anyhow::{Context, Result};
use serde_json::Value;
use std::time::Duration;

pub const PROVIDER: &str = "archive";
const SEARCH: &str = "https://archive.org/advancedsearch.php";
const METADATA: &str = "https://archive.org/metadata";

/// Searches archive.org audio items and expands each into its audio files.
/// Items can contain dozens of tracks, so the per-item list is capped.
pub async fn search(
    client: &reqwest::Client,
    query: &str,
    items: usize,
    kind: TrackKind,
) -> Result<Vec<Track>> {
    let rows = items.clamp(1, 10);
    let base = if query.trim().is_empty() {
        "subject:(anasheed)".to_string()
    } else {
        format!("({})", query.trim())
    };
    let full = format!("mediatype:(audio) AND {base}");

    let response = client
        .get(SEARCH)
        .query(&[
            ("q", full.as_str()),
            ("fl[]", "identifier"),
            ("fl[]", "title"),
            ("fl[]", "creator"),
            ("fl[]", "licenseurl"),
            ("sort[]", "downloads desc"),
            ("rows", &rows.to_string()),
            ("page", "1"),
            ("output", "json"),
        ])
        .send()
        .await
        .context("requesting archive.org search")?
        .error_for_status()
        .context("archive.org search returned an error")?;

    let body: Value = response.json().await.context("decoding archive.org search")?;
    let identifiers: Vec<String> = body
        .pointer("/response/docs")
        .and_then(Value::as_array)
        .map(|docs| {
            docs.iter()
                .filter_map(|doc| doc.get("identifier")?.as_str().map(str::to_string))
                .collect()
        })
        .unwrap_or_default();

    let mut set = tokio::task::JoinSet::new();
    for id in identifiers {
        let client = client.clone();
        set.spawn(async move { fetch_item(&client, &id, kind).await });
    }

    let mut tracks = Vec::new();
    while let Some(joined) = set.join_next().await {
        if let Ok(Ok(mut list)) = joined {
            tracks.append(&mut list);
        }
    }
    Ok(tracks)
}

async fn fetch_item(
    client: &reqwest::Client,
    identifier: &str,
    kind: TrackKind,
) -> Result<Vec<Track>> {
    let url = format!("{METADATA}/{identifier}");
    let meta: Value = client
        .get(&url)
        .timeout(Duration::from_secs(15))
        .send()
        .await
        .context("requesting archive.org metadata")?
        .error_for_status()
        .context("archive.org metadata returned an error")?
        .json()
        .await
        .context("decoding archive.org metadata")?;

    let item = meta.get("metadata").cloned().unwrap_or(Value::Null);
    let item_title = text_of(item.get("title")).unwrap_or_else(|| identifier.to_string());
    let creator = text_of(item.get("creator")).unwrap_or_else(|| "archive.org".into());
    let license_url = text_of(item.get("licenseurl"));
    let license = license_url.as_deref().map(license_label);
    let details = format!("https://archive.org/details/{identifier}");

    let mut files: Vec<(String, Option<String>, Option<u32>)> = meta
        .get("files")
        .and_then(Value::as_array)
        .map(|files| {
            files
                .iter()
                .filter_map(|file| {
                    let name = file.get("name")?.as_str()?.to_string();
                    if !is_audio(&name) {
                        return None;
                    }
                    let format = file
                        .get("format")
                        .and_then(Value::as_str)
                        .unwrap_or("")
                        .to_ascii_lowercase();
                    if format.contains("spectrogram") || format.contains("metadata") {
                        return None;
                    }
                    let title = file
                        .get("title")
                        .and_then(Value::as_str)
                        .map(|t| t.trim().to_string())
                        .filter(|t| !t.is_empty());
                    let duration = file
                        .get("length")
                        .and_then(|v| match v {
                            Value::String(s) => s.parse::<f64>().ok(),
                            Value::Number(n) => n.as_f64(),
                            _ => None,
                        })
                        .map(|s| s.round() as u32)
                        .filter(|s| *s > 0);
                    Some((name, title, duration))
                })
                .collect()
        })
        .unwrap_or_default();

    // Prefer MP3, then Ogg/FLAC, so the first tracks are the playable ones.
    files.sort_by_key(|(name, _, _)| {
        let lower = name.to_ascii_lowercase();
        if lower.ends_with(".mp3") {
            0
        } else if lower.ends_with(".ogg") || lower.ends_with(".oga") {
            1
        } else {
            2
        }
    });
    files.truncate(8);

    Ok(files
        .into_iter()
        .map(|(name, file_title, duration)| {
            let title = file_title.unwrap_or_else(|| {
                name.rsplit('/')
                    .next()
                    .unwrap_or(&name)
                    .rsplit_once('.')
                    .map(|(stem, _)| stem.to_string())
                    .unwrap_or_else(|| name.clone())
            });
            let mut track = Track::new(
                PROVIDER,
                format!("{identifier}/{name}"),
                title,
                kind,
            );
            track.artist = creator.clone();
            track.album = Some(item_title.clone());
            track.duration_s = duration;
            track.stream_url = Some(download_url(identifier, &name));
            track.license = license.clone();
            track.license_url = license_url.clone();
            track.source_page = Some(details.clone());
            track.attribution = Some(format!(
                "{} — archive.org{}",
                creator,
                license
                    .as_deref()
                    .map(|l| format!(" · {l}"))
                    .unwrap_or_default()
            ));
            track
        })
        .collect())
}

fn download_url(identifier: &str, name: &str) -> String {
    let path = name
        .split('/')
        .map(|segment| urlencoding::encode(segment).into_owned())
        .collect::<Vec<_>>()
        .join("/");
    format!(
        "https://archive.org/download/{}/{path}",
        urlencoding::encode(identifier)
    )
}

fn is_audio(name: &str) -> bool {
    let lower = name.to_ascii_lowercase();
    [".mp3", ".ogg", ".oga", ".flac", ".m4a", ".wav", ".opus"]
        .iter()
        .any(|ext| lower.ends_with(ext))
}

fn text_of(value: Option<&Value>) -> Option<String> {
    match value? {
        Value::String(s) => {
            let trimmed = s.trim();
            (!trimmed.is_empty()).then(|| trimmed.to_string())
        }
        Value::Array(items) => {
            let joined = items
                .iter()
                .filter_map(|v| v.as_str())
                .collect::<Vec<_>>()
                .join("، ");
            (!joined.is_empty()).then_some(joined)
        }
        Value::Number(n) => Some(n.to_string()),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builds_encoded_download_urls() {
        assert_eq!(
            download_url("anasheed-1", "track one.mp3"),
            "https://archive.org/download/anasheed-1/track%20one.mp3"
        );
        assert_eq!(
            download_url("id", "disc 1/01.mp3"),
            "https://archive.org/download/id/disc%201/01.mp3"
        );
    }

    #[test]
    fn filters_non_audio_files() {
        assert!(is_audio("a/b.mp3"));
        assert!(is_audio("X.FLAC"));
        assert!(!is_audio("cover.jpg"));
        assert!(!is_audio("notes.txt"));
    }

    #[test]
    fn reads_creator_arrays() {
        let value = serde_json::json!(["أحمد", "محمد"]);
        assert_eq!(text_of(Some(&value)).as_deref(), Some("أحمد، محمد"));
        let single = serde_json::json!("فنان");
        assert_eq!(text_of(Some(&single)).as_deref(), Some("فنان"));
    }
}
