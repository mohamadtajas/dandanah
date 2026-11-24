use super::{surah, Track, TrackKind};
use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use serde_json::Value;

const API: &str = "https://mp3quran.net/api/v3";
pub const PROVIDER: &str = "mp3quran";

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Moshaf {
    pub id: i64,
    pub name: String,
    pub server: String,
    pub surah_total: u32,
    pub surahs: Vec<u16>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Reciter {
    pub id: i64,
    pub name: String,
    pub letter: String,
    pub moshafs: Vec<Moshaf>,
}

/// Fetches every available reciter. The response is large (~160 KB) and rarely
/// changes, so callers should cache it in the `cache` table.
pub async fn fetch_reciters(client: &reqwest::Client, language: &str) -> Result<Vec<Reciter>> {
    let url = format!("{API}/reciters?language={language}");
    let body: Value = client
        .get(&url)
        .send()
        .await
        .context("requesting reciters")?
        .error_for_status()
        .context("reciters endpoint returned an error")?
        .json()
        .await
        .context("decoding reciters json")?;

    let list = body
        .get("reciters")
        .and_then(Value::as_array)
        .context("reciters payload missing `reciters` array")?;

    let mut reciters = Vec::with_capacity(list.len());
    for raw in list {
        let Some(id) = raw.get("id").and_then(Value::as_i64) else {
            continue;
        };
        let name = text(raw.get("name"));
        if name.is_empty() {
            continue;
        }
        let moshafs = raw
            .get("moshaf")
            .and_then(Value::as_array)
            .map(|arr| arr.iter().filter_map(parse_moshaf).collect::<Vec<Moshaf>>())
            .unwrap_or_default();
        if moshafs.is_empty() {
            continue;
        }
        reciters.push(Reciter {
            id,
            name,
            letter: text(raw.get("letter")),
            moshafs,
        });
    }
    reciters.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(reciters)
}

fn parse_moshaf(raw: &Value) -> Option<Moshaf> {
    let server = text(raw.get("server"));
    if server.is_empty() {
        return None;
    }
    let surahs = text(raw.get("surah_list"))
        .split(',')
        .filter_map(|s| s.trim().parse::<u16>().ok())
        .collect::<Vec<_>>();
    Some(Moshaf {
        id: raw.get("id").and_then(Value::as_i64).unwrap_or(0),
        name: text(raw.get("name")),
        server,
        surah_total: raw
            .get("surah_total")
            .and_then(|v| v.as_u64().or_else(|| v.as_str().and_then(|s| s.parse().ok())))
            .unwrap_or(surahs.len() as u64) as u32,
        surahs,
    })
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct QuranRadio {
    pub id: i64,
    pub name: String,
    pub url: String,
}

pub async fn fetch_radios(client: &reqwest::Client) -> Result<Vec<QuranRadio>> {
    let body: Value = client
        .get(format!("{API}/radios?language=ar"))
        .send()
        .await
        .context("requesting quran radios")?
        .error_for_status()?
        .json()
        .await?;
    let list = body
        .get("radios")
        .and_then(Value::as_array)
        .context("radios payload missing `radios` array")?;
    Ok(list
        .iter()
        .filter_map(|raw| {
            let url = text(raw.get("url"));
            let name = text(raw.get("name"));
            if url.is_empty() || name.is_empty() {
                return None;
            }
            Some(QuranRadio {
                id: raw.get("id").and_then(Value::as_i64).unwrap_or(0),
                name,
                url,
            })
        })
        .collect())
}

fn text(v: Option<&Value>) -> String {
    match v {
        Some(Value::String(s)) => s.trim().to_string(),
        Some(Value::Number(n)) => n.to_string(),
        _ => String::new(),
    }
}

/// Builds one playable track per surah available in this moshaf.
pub fn moshaf_tracks(reciter: &Reciter, moshaf: &Moshaf) -> Vec<Track> {
    let base = if moshaf.server.ends_with('/') {
        moshaf.server.clone()
    } else {
        format!("{}/", moshaf.server)
    };

    moshaf
        .surahs
        .iter()
        .filter_map(|&n| {
            let meta = surah(n)?;
            let mut track = Track::new(
                PROVIDER,
                format!("{}-{}", moshaf.id, n),
                meta.name.clone(),
                TrackKind::Quran,
            );
            track.artist = reciter.name.clone();
            track.album = Some(moshaf.name.clone());
            track.subtitle = Some(if moshaf.name.is_empty() {
                format!("سورة {} · آية {}", meta.number, meta.ayahs)
            } else {
                format!("{} · {} آية", moshaf.name, meta.ayahs)
            });
            track.stream_url = Some(format!("{base}{n:03}.mp3"));
            track.source_page = Some("https://mp3quran.net".into());
            track.attribution = Some(format!("تلاوة {} — mp3quran.net", reciter.name));
            track.license = Some("تلاوة مجانية الاستخدام".into());
            Some(track)
        })
        .collect()
}

pub fn radio_track(station: &QuranRadio) -> Track {
    let mut track = Track::new(
        "mp3quran-radio",
        station.id.to_string(),
        station.name.clone(),
        TrackKind::Radio,
    );
    track.artist = "إذاعة القرآن الكريم".into();
    track.stream_url = Some(station.url.clone());
    track.source_page = Some("https://mp3quran.net".into());
    track.attribution = Some("mp3quran.net".into());
    track.live = true;
    track
}
