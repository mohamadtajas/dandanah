use super::{surah, Moshaf, Reciter, Track, TrackKind};
use anyhow::{Context, Result};
use serde::Deserialize;

pub const PROVIDER: &str = "quranicaudio";
/// QuranicAudio ids are offset to avoid clashing with mp3quran ids.
pub const ID_BASE: i64 = 1_000_000;
const API: &str = "https://quranicaudio.com/api/qaris";
const AUDIO_BASE: &str = "https://download.quranicaudio.com/quran";

#[derive(Debug, Deserialize)]
struct Qari {
    id: i64,
    #[serde(default)]
    name: Option<String>,
    #[serde(default)]
    arabic_name: Option<String>,
    #[serde(default)]
    relative_path: Option<String>,
}

/// Fetches the QuranicAudio catalogue (177+ reciters) and adapts it to the same
/// shape as mp3quran, so every existing Quran view keeps working.
pub async fn fetch_reciters(client: &reqwest::Client) -> Result<Vec<Reciter>> {
    let list: Vec<Qari> = client
        .get(API)
        .send()
        .await
        .context("requesting QuranicAudio reciters")?
        .error_for_status()
        .context("QuranicAudio returned an error")?
        .json()
        .await
        .context("decoding QuranicAudio reciters")?;

    Ok(list.into_iter().filter_map(to_reciter).collect())
}

fn to_reciter(qari: Qari) -> Option<Reciter> {
    let relative_path = qari.relative_path.unwrap_or_default();
    let relative = relative_path.trim().trim_matches('/');
    if relative.is_empty() {
        return None;
    }
    let english = qari.name.unwrap_or_default().trim().to_string();
    let arabic = qari.arabic_name.unwrap_or_default();
    let arabic = arabic.trim();
    let name = if arabic.is_empty() {
        english.clone()
    } else {
        arabic.to_string()
    };
    if name.is_empty() {
        return None;
    }

    let id = ID_BASE + qari.id;
    Some(Reciter {
        id,
        name: name.clone(),
        english_name: (!english.is_empty()).then_some(english),
        letter: name.chars().next().map(|c| c.to_string()).unwrap_or_default(),
        moshafs: vec![Moshaf {
            id,
            name: "مرتل".into(),
            server: format!("{AUDIO_BASE}/{relative}/"),
            surah_total: 114,
            surahs: (1..=114).collect(),
        }],
    })
}

pub fn moshaf_tracks(reciter: &Reciter, moshaf: &Moshaf) -> Vec<Track> {
    let base = if moshaf.server.ends_with('/') {
        moshaf.server.clone()
    } else {
        format!("{}/", moshaf.server)
    };

    moshaf
        .surahs
        .iter()
        .filter_map(|&number| {
            let meta = surah(number)?;
            let mut track = Track::new(
                PROVIDER,
                format!("{}-{}", moshaf.id, number),
                meta.name.clone(),
                TrackKind::Quran,
            );
            track.artist = reciter.name.clone();
            track.album = Some(meta.name.clone());
            track.subtitle = Some(format!("مرتل · {} آية", meta.ayahs));
            track.stream_url = Some(format!("{base}{number:03}.mp3"));
            track.source_page = Some("https://quranicaudio.com".into());
            track.attribution = Some(format!("تلاوة {} — QuranicAudio", reciter.name));
            track.license = Some("تلاوة متاحة للاستماع".into());
            Some(track)
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_qari_to_reciter_with_arabic_name() {
        let reciter = to_reciter(Qari {
            id: 79,
            name: Some("Muhammad Hassan".into()),
            arabic_name: Some("محمد حسان".into()),
            relative_path: Some("mu7ammad_7assan/".into()),
        })
        .unwrap();

        assert_eq!(reciter.id, ID_BASE + 79);
        assert_eq!(reciter.name, "محمد حسان");
        assert_eq!(reciter.english_name.as_deref(), Some("Muhammad Hassan"));
        assert_eq!(reciter.moshafs[0].surahs.len(), 114);
        assert!(reciter.moshafs[0].server.ends_with("mu7ammad_7assan/"));
    }

    #[test]
    fn tolerates_null_arabic_name() {
        let qari: Qari = serde_json::from_value(serde_json::json!({
            "id": 5,
            "name": "Some Reciter",
            "arabic_name": null,
            "relative_path": "some_reciter/"
        }))
        .unwrap();
        let reciter = to_reciter(qari).unwrap();
        assert_eq!(reciter.name, "Some Reciter");
        assert_eq!(reciter.english_name.as_deref(), Some("Some Reciter"));
    }

    #[test]
    fn builds_standard_surah_urls() {
        let reciter = to_reciter(Qari {
            id: 1,
            name: Some("Abdullah".into()),
            arabic_name: Some("عبدالله".into()),
            relative_path: Some("abdullaah_3awwaad_al-juhaynee/".into()),
        })
        .unwrap();
        let tracks = moshaf_tracks(&reciter, &reciter.moshafs[0]);
        assert_eq!(tracks.len(), 114);
        assert_eq!(
            tracks[0].stream_url.as_deref(),
            Some("https://download.quranicaudio.com/quran/abdullaah_3awwaad_al-juhaynee/001.mp3")
        );
    }
}
