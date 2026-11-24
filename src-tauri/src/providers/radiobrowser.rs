use super::{Track, TrackKind};
use anyhow::{anyhow, Result};
use serde::Deserialize;

/// Public mirrors, tried in order. radio-browser asks clients to use a mirror
/// with DNS round-robin and a descriptive User-Agent instead of the .org host.
const MIRRORS: &[&str] = &[
    "https://de1.api.radio-browser.info",
    "https://de2.api.radio-browser.info",
    "https://at1.api.radio-browser.info",
];

pub const PROVIDER: &str = "radiobrowser";

/// Country codes with the richest Arabic station coverage.
pub const ARAB_COUNTRIES: &[&str] = &[
    "SA", "EG", "AE", "QA", "KW", "JO", "MA", "DZ", "TN", "LB", "IQ", "OM", "BH", "PS", "SD",
    "YE", "SY", "LY",
];

#[derive(Debug, Deserialize)]
struct Station {
    #[serde(default)]
    stationuuid: String,
    #[serde(default)]
    name: String,
    #[serde(default)]
    url_resolved: String,
    #[serde(default)]
    url: String,
    #[serde(default)]
    favicon: String,
    #[serde(default)]
    country: String,
    #[serde(default)]
    tags: String,
    #[serde(default)]
    bitrate: i64,
    #[serde(default)]
    codec: String,
    #[serde(default)]
    homepage: String,
}

pub async fn search(
    client: &reqwest::Client,
    query: &str,
    limit: u32,
    country: Option<&str>,
) -> Result<Vec<Track>> {
    let mut qs = vec![
        format!("name={}", urlencoding::encode(query)),
        format!("limit={limit}"),
        "hidebroken=true".to_string(),
        "order=clickcount".to_string(),
        "reverse=true".to_string(),
    ];
    if let Some(c) = country {
        if !c.is_empty() {
            qs.push(format!("countrycode={}", urlencoding::encode(c)));
        }
    }
    fetch(client, &format!("/json/stations/search?{}", qs.join("&"))).await
}

pub async fn popular(
    client: &reqwest::Client,
    limit: u32,
    country: Option<&str>,
    tag: Option<&str>,
) -> Result<Vec<Track>> {
    let mut qs = vec![
        format!("limit={limit}"),
        "hidebroken=true".to_string(),
        "order=clickcount".to_string(),
        "reverse=true".to_string(),
    ];
    if let Some(c) = country {
        if !c.is_empty() {
            qs.push(format!("countrycode={}", urlencoding::encode(c)));
        }
    }
    if let Some(t) = tag {
        if !t.is_empty() {
            qs.push(format!("tag={}", urlencoding::encode(t)));
        }
    }
    fetch(client, &format!("/json/stations/search?{}", qs.join("&"))).await
}

async fn fetch(client: &reqwest::Client, path: &str) -> Result<Vec<Track>> {
    let mut last_err: Option<anyhow::Error> = None;
    for mirror in MIRRORS {
        let url = format!("{mirror}{path}");
        match client.get(&url).send().await {
            Ok(resp) => match resp.error_for_status() {
                Ok(resp) => match resp.json::<Vec<Station>>().await {
                    Ok(stations) => return Ok(stations.into_iter().filter_map(to_track).collect()),
                    Err(e) => last_err = Some(e.into()),
                },
                Err(e) => last_err = Some(e.into()),
            },
            Err(e) => last_err = Some(e.into()),
        }
    }
    Err(last_err.unwrap_or_else(|| anyhow!("all radio-browser mirrors failed")))
}

fn to_track(station: Station) -> Option<Track> {
    let stream = if !station.url_resolved.trim().is_empty() {
        station.url_resolved.trim()
    } else {
        station.url.trim()
    };
    if stream.is_empty() || station.name.trim().is_empty() {
        return None;
    }

    let mut track = Track::new(
        PROVIDER,
        station.stationuuid,
        station.name.trim(),
        TrackKind::Radio,
    );
    track.artist = if station.country.is_empty() {
        "بث مباشر".into()
    } else {
        station.country
    };
    track.stream_url = Some(stream.to_string());
    if !station.favicon.trim().is_empty() {
        track.artwork_url = Some(station.favicon.trim().to_string());
    }
    if !station.tags.trim().is_empty() {
        track.album = Some(station.tags.clone());
    }
    if !station.homepage.trim().is_empty() {
        track.source_page = Some(station.homepage.clone());
    }
    let quality = match (station.codec.trim(), station.bitrate) {
        ("", 0) => None,
        (codec, 0) => Some(codec.to_uppercase()),
        ("", bitrate) => Some(format!("{bitrate} kbps")),
        (codec, bitrate) => Some(format!("{} · {bitrate} kbps", codec.to_uppercase())),
    };
    track.subtitle = quality;
    track.attribution = Some(format!(
        "بث مباشر من إذاعة {} — radio-browser.info",
        track.artist
    ));
    track.license = Some("بث عام".into());
    track.live = true;
    Some(track)
}
