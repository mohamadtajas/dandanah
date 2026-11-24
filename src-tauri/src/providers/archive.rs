use super::{license_label, repair_mojibake, Track, TrackKind};
use anyhow::{Context, Result};
use serde_json::Value;
use std::time::Duration;

pub const PROVIDER: &str = "archive";
const SEARCH: &str = "https://archive.org/advancedsearch.php";
const METADATA: &str = "https://archive.org/metadata";

/// One archive.org audio item, as returned by the search endpoint.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ArchiveItem {
    pub identifier: String,
    pub title: String,
    pub creator: String,
    #[serde(default)]
    pub license_url: Option<String>,
}

/// Finds audio items for a Lucene fragment such as `subject:(anasheed)`.
pub async fn search_items(
    client: &reqwest::Client,
    query: &str,
    limit: usize,
) -> Result<Vec<ArchiveItem>> {
    let fragment = if query.trim().is_empty() {
        "subject:(anasheed)".to_string()
    } else {
        query.trim().to_string()
    };
    let full = format!("mediatype:(audio) AND ({fragment})");
    let rows = limit.clamp(1, 10).to_string();

    let response = client
        .get(SEARCH)
        .query(&[
            ("q", full.as_str()),
            ("fl[]", "identifier"),
            ("fl[]", "title"),
            ("fl[]", "creator"),
            ("fl[]", "licenseurl"),
            ("sort[]", "downloads desc"),
            ("rows", rows.as_str()),
            ("page", "1"),
            ("output", "json"),
        ])
        .send()
        .await
        .context("requesting archive.org search")?
        .error_for_status()
        .context("archive.org search returned an error")?;

    let body: Value = response.json().await.context("decoding archive.org search")?;
    Ok(parse_docs(&body))
}

fn parse_docs(body: &Value) -> Vec<ArchiveItem> {
    body.pointer("/response/docs")
        .and_then(Value::as_array)
        .map(|docs| {
            docs.iter()
                .filter_map(|doc| {
                    let identifier = doc.get("identifier")?.as_str()?.to_string();
                    Some(ArchiveItem {
                        title: repair_mojibake(
                            &text_of(doc.get("title")).unwrap_or_else(|| identifier.clone()),
                        ),
                        creator: repair_mojibake(
                            &text_of(doc.get("creator"))
                                .unwrap_or_else(|| "archive.org".into()),
                        ),
                        license_url: text_of(doc.get("licenseurl")),
                        identifier,
                    })
                })
                .collect()
        })
        .unwrap_or_default()
}

/// Expands one item into its individual audio files (capped at eight).
pub async fn item_tracks(
    client: &reqwest::Client,
    item: &ArchiveItem,
    kind: TrackKind,
) -> Result<Vec<Track>> {
    let url = format!("{METADATA}/{}", item.identifier);
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
                        .map(|t| repair_mojibake(t.trim()))
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

    let license = item.license_url.as_deref().map(license_label);
    let details = format!("https://archive.org/details/{}", item.identifier);

    Ok(files
        .into_iter()
        .map(|(name, file_title, duration)| {
            let derived = file_title.unwrap_or_else(|| {
                name.rsplit('/')
                    .next()
                    .unwrap_or(&name)
                    .rsplit_once('.')
                    .map(|(stem, _)| stem.to_string())
                    .unwrap_or_else(|| name.clone())
            });
            let title = repair_mojibake(&derived);
            let mut track = Track::new(
                PROVIDER,
                format!("{}/{}", item.identifier, name),
                title,
                kind,
            );
            track.artist = item.creator.clone();
            track.album = Some(item.title.clone());
            track.duration_s = duration;
            track.stream_url = Some(download_url(&item.identifier, &name));
            track.license = license.clone();
            track.license_url = item.license_url.clone();
            track.source_page = Some(details.clone());
            track.attribution = Some(format!(
                "{} — archive.org{}",
                item.creator,
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

    #[test]
    fn parses_search_docs() {
        let body = serde_json::json!({
            "response": {
                "docs": [
                    { "identifier": "a", "title": "أناشيد", "creator": ["فنان"], "licenseurl": "https://creativecommons.org/licenses/by/4.0/" },
                    { "identifier": "b" }
                ]
            }
        });
        let items = parse_docs(&body);
        assert_eq!(items.len(), 2);
        assert_eq!(items[0].title, "أناشيد");
        assert_eq!(items[0].creator, "فنان");
        assert_eq!(items[1].creator, "archive.org");
        assert!(items[1].license_url.is_none());
    }
}
