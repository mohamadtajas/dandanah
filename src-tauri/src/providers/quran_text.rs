use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use serde_json::Value;

const API: &str = "https://api.alquran.cloud/v1";

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Ayah {
    pub number: u16,
    /// Uthmani script, without the leading BOM that the API sometimes sends.
    pub text: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub translation: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub juz: Option<u16>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub page: Option<u16>,
    #[serde(default)]
    pub sajda: bool,
}

/// Fetches Uthmani text for a surah, optionally with the Sahih International
/// translation. Both editions arrive in a single request.
pub async fn fetch_surah(
    client: &reqwest::Client,
    surah: u16,
    with_translation: bool,
) -> Result<Vec<Ayah>> {
    let editions = if with_translation {
        "quran-uthmani,en.sahih"
    } else {
        "quran-uthmani"
    };
    let url = format!("{API}/surah/{surah}/editions/{editions}");
    let body: Value = client
        .get(&url)
        .send()
        .await
        .context("requesting surah text")?
        .error_for_status()
        .context("surah text endpoint returned an error")?
        .json()
        .await
        .context("decoding surah text")?;

    let editions = body
        .get("data")
        .and_then(Value::as_array)
        .context("surah text payload missing `data` array")?;

    let arabic = editions
        .iter()
        .find(|e| {
            e.pointer("/edition/identifier")
                .and_then(Value::as_str)
                .is_some_and(|id| id.starts_with("quran-uthmani"))
        })
        .or_else(|| editions.first())
        .context("no Arabic edition in payload")?;

    let ayahs = arabic
        .get("ayahs")
        .and_then(Value::as_array)
        .context("Arabic edition missing `ayahs`")?;

    let translations: Option<&Vec<Value>> = editions
        .iter()
        .find(|e| {
            e.pointer("/edition/identifier")
                .and_then(Value::as_str)
                .is_some_and(|id| id.starts_with("en."))
        })
        .and_then(|e| e.get("ayahs"))
        .and_then(Value::as_array);

    Ok(ayahs
        .iter()
        .enumerate()
        .filter_map(|(i, raw)| {
            let text = raw.get("text").and_then(Value::as_str)?;
            let number = raw
                .get("numberInSurah")
                .and_then(Value::as_u64)
                .unwrap_or(i as u64 + 1) as u16;
            Some(Ayah {
                number,
                text: text.trim_start_matches('\u{feff}').trim().to_string(),
                translation: translations
                    .and_then(|t| t.get(i))
                    .and_then(|a| a.get("text"))
                    .and_then(Value::as_str)
                    .map(|s| s.trim().to_string()),
                juz: raw.get("juz").and_then(Value::as_u64).map(|v| v as u16),
                page: raw.get("page").and_then(Value::as_u64).map(|v| v as u16),
                sajda: raw.get("sajda").map(|v| !v.is_null() && v != &Value::Bool(false)).unwrap_or(false),
            })
        })
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_editions_payload() {
        let payload = serde_json::json!({
            "code": 200,
            "data": [
                {
                    "edition": { "identifier": "quran-uthmani" },
                    "ayahs": [
                        { "number": 1, "text": "\u{feff}بِسْمِ ٱللَّهِ", "numberInSurah": 1, "juz": 1, "page": 1, "sajda": false },
                        { "number": 2, "text": "ٱلْحَمْدُ لِلَّهِ", "numberInSurah": 2, "juz": 1, "page": 1, "sajda": false }
                    ]
                },
                {
                    "edition": { "identifier": "en.sahih" },
                    "ayahs": [
                        { "text": "In the name of Allah" },
                        { "text": "All praise is due to Allah" }
                    ]
                }
            ]
        });

        let editions = payload.get("data").unwrap().as_array().unwrap();
        let arabic = editions
            .iter()
            .find(|e| {
                e.pointer("/edition/identifier")
                    .and_then(Value::as_str)
                    .is_some_and(|id| id.starts_with("quran-uthmani"))
            })
            .unwrap();
        let ayahs = arabic.get("ayahs").unwrap().as_array().unwrap();
        let text = ayahs[0].get("text").unwrap().as_str().unwrap();
        assert_eq!(text.trim_start_matches('\u{feff}'), "بِسْمِ ٱللَّهِ");
        assert_eq!(ayahs[1].get("numberInSurah").unwrap().as_u64(), Some(2));
    }
}
