use super::{Track, TrackKind};
use anyhow::{Context, Result};
use serde::Deserialize;

pub const PROVIDER: &str = "audius";
const API: &str = "https://api.audius.co";

#[derive(Debug, Deserialize)]
struct Envelope {
    #[serde(default)]
    data: Vec<Item>,
}

#[derive(Debug, Deserialize)]
struct Item {
    id: String,
    #[serde(default)]
    title: Option<String>,
    #[serde(default)]
    duration: Option<u32>,
    #[serde(default)]
    is_streamable: Option<bool>,
    #[serde(default)]
    permalink: Option<String>,
    #[serde(default)]
    user: Option<User>,
    #[serde(default)]
    artwork: Option<Artwork>,
}

#[derive(Debug, Deserialize)]
struct User {
    #[serde(default)]
    name: Option<String>,
}

#[derive(Debug, Deserialize)]
struct Artwork {
    #[serde(rename = "480x480", default)]
    large: Option<String>,
    #[serde(rename = "150x150", default)]
    small: Option<String>,
}

/// Searches Audius, a free streaming network with a public API and no key.
/// Tracks are streamed from Audius; no licence is claimed, so downloads stay
/// behind the unknown-licence gate.
pub async fn search(client: &reqwest::Client, query: &str, limit: u32) -> Result<Vec<Track>> {
    let text = if query.trim().is_empty() {
        "arabic"
    } else {
        query.trim()
    };
    let limit = limit.clamp(1, 30).to_string();

    let envelope: Envelope = client
        .get(format!("{API}/v1/tracks/search"))
        .query(&[
            ("query", text),
            ("app_name", "Sakeenah"),
            ("limit", limit.as_str()),
        ])
        .send()
        .await
        .context("requesting Audius")?
        .error_for_status()
        .context("Audius returned an error")?
        .json()
        .await
        .context("decoding Audius")?;

    Ok(envelope
        .data
        .into_iter()
        .filter(|item| {
            item.is_streamable != Some(false)
                && item
                    .title
                    .as_deref()
                    .map(|title| !title.trim().is_empty())
                    .unwrap_or(false)
        })
        .map(to_track)
        .collect())
}

fn to_track(item: Item) -> Track {
    let Item {
        id,
        title,
        duration,
        permalink,
        user,
        artwork,
        ..
    } = item;

    let artist = user
        .and_then(|user| user.name)
        .map(|name| name.trim().to_string())
        .filter(|name| !name.is_empty())
        .unwrap_or_else(|| "Audius".into());

    let mut track = Track::new(
        PROVIDER,
        id.clone(),
        title.unwrap_or_default().trim().to_string(),
        TrackKind::Music,
    );
    track.artist = artist.clone();
    track.duration_s = duration.filter(|value| *value > 0);
    track.stream_url = Some(format!("{API}/v1/tracks/{id}/stream?app_name=Sakeenah"));
    track.artwork_url = artwork.and_then(|art| art.large.or(art.small));
    track.source_page = permalink.map(|path| format!("https://audius.co{path}"));
    track.attribution = Some(format!("{artist} — Audius"));
    track.subtitle = Some("Audius".into());
    track
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_audius_payload() {
        let payload = serde_json::json!({
            "data": [{
                "id": "qR29RBz",
                "title": "Arabic Rap Type Beat",
                "duration": 139,
                "is_streamable": true,
                "permalink": "/stark/calm",
                "user": { "name": "STARK" },
                "artwork": { "150x150": "https://x/150.jpg", "480x480": "https://x/480.jpg" }
            }]
        });
        let envelope: Envelope = serde_json::from_value(payload).unwrap();
        let track = to_track(envelope.data.into_iter().next().unwrap());
        assert_eq!(track.provider, PROVIDER);
        assert_eq!(track.title, "Arabic Rap Type Beat");
        assert_eq!(track.artist, "STARK");
        assert_eq!(track.duration_s, Some(139));
        assert_eq!(track.artwork_url.as_deref(), Some("https://x/480.jpg"));
        assert!(track.stream_url.unwrap().contains("/v1/tracks/qR29RBz/stream"));
        assert!(track.license.is_none());
    }

    #[test]
    fn tolerates_null_optional_fields() {
        let payload = serde_json::json!({
            "data": [{
                "id": "abc",
                "title": "Track",
                "duration": null,
                "user": null,
                "artwork": null,
                "permalink": null
            }]
        });
        let envelope: Envelope = serde_json::from_value(payload).unwrap();
        let track = to_track(envelope.data.into_iter().next().unwrap());
        assert_eq!(track.duration_s, None);
        assert_eq!(track.artist, "Audius");
        assert_eq!(track.artwork_url, None);
    }
}
