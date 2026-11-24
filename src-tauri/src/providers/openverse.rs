use super::{license_label, Track, TrackKind};
use anyhow::{Context, Result};
use serde::Deserialize;

pub const PROVIDER: &str = "openverse";
const API: &str = "https://api.openverse.org/v1/audio/";

#[derive(Deserialize)]
struct Envelope {
    #[serde(default)]
    results: Vec<Item>,
}

#[derive(Deserialize)]
struct Item {
    id: String,
    #[serde(default)]
    title: String,
    #[serde(default)]
    creator: String,
    url: String,
    /// Milliseconds in the Openverse schema.
    #[serde(default)]
    duration: Option<u64>,
    #[serde(default)]
    license: String,
    #[serde(default)]
    license_url: Option<String>,
    #[serde(default)]
    foreign_landing_url: Option<String>,
    #[serde(default)]
    thumbnail: Option<String>,
}

/// Searches the Openverse audio index. It aggregates Jamendo, Freesound and
/// other CC sources, so no provider key is needed.
pub async fn search(
    client: &reqwest::Client,
    query: &str,
    limit: u32,
) -> Result<Vec<Track>> {
    let response = client
        .get(API)
        .query(&[
            ("q", query),
            // Anonymous Openverse requests are capped at 20; asking for more
            // returns 401 rather than a smaller page.
            ("page_size", &limit.clamp(1, 20).to_string()),
        ])
        .send()
        .await
        .context("requesting Openverse")?
        .error_for_status()
        .context("Openverse returned an error")?;

    let body: Envelope = response.json().await.context("decoding Openverse")?;

    Ok(body
        .results
        .into_iter()
        .filter(|item| !item.url.trim().is_empty())
        .map(|item| {
            let mut track = Track::new(
                PROVIDER,
                item.id,
                if item.title.trim().is_empty() {
                    "Untitled".to_string()
                } else {
                    item.title.trim().to_string()
                },
                TrackKind::Music,
            );
            track.artist = if item.creator.trim().is_empty() {
                "Openverse".into()
            } else {
                item.creator.trim().to_string()
            };
            track.duration_s = item.duration.map(|ms| (ms / 1000).min(u32::MAX as u64) as u32);
            track.stream_url = Some(item.url);
            track.artwork_url = item.thumbnail;
            track.license = Some(license_label(&item.license));
            track.license_url = item.license_url;
            track.source_page = item.foreign_landing_url;
            track.attribution = Some(format!(
                "{} — {} · Openverse",
                track.artist,
                track.license.clone().unwrap_or_else(|| "CC".into())
            ));
            track
        })
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_payload_to_tracks() {
        let payload = serde_json::json!({
            "result_count": 1,
            "results": [{
                "id": "abc",
                "title": "Layla",
                "creator": "Nasser",
                "url": "https://example.org/a.mp3",
                "duration": 245000,
                "license": "by-sa",
                "license_url": "https://creativecommons.org/licenses/by-sa/4.0/",
                "foreign_landing_url": "https://example.org/page"
            }]
        });
        let body: Envelope = serde_json::from_value(payload).unwrap();
        let item = &body.results[0];
        assert_eq!(item.duration, Some(245000));
        assert_eq!(license_label(&item.license), "CC BY-SA");
    }
}
