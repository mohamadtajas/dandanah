use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use serde_json::Value;

const API: &str = "https://api.alquran.cloud/v1";

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Ayah {
    /// Ayah number inside its surah.
    pub number: u16,
    /// Surah number, 1-based.
    #[serde(default)]
    pub surah: u16,
    /// Uthmani script, verbatim.
    pub text: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub translation: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub juz: Option<u16>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub page: Option<u16>,
    /// Tanzil keeps the basmala separate from the first ayah (except
    /// Al-Fatiha, where it is ayah 1, and At-Tawbah, which has none).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bismillah: Option<String>,
    #[serde(default)]
    pub sajda: bool,
}

/// Fetches the Sahih International translation for one surah.
pub async fn fetch_translation(client: &reqwest::Client, surah: u16) -> Result<Vec<String>> {
    let url = format!("{API}/surah/{surah}/en.sahih");
    let body: Value = client
        .get(&url)
        .send()
        .await
        .context("requesting surah translation")?
        .error_for_status()
        .context("translation endpoint returned an error")?
        .json()
        .await
        .context("decoding surah translation")?;
    parse_translation(&body).context("translation payload missing ayahs")
}

pub fn parse_translation(body: &Value) -> Option<Vec<String>> {
    body.pointer("/data/ayahs")
        .and_then(Value::as_array)
        .map(|ayahs| {
            ayahs
                .iter()
                .filter_map(|ayah| ayah.get("text").and_then(Value::as_str))
                .map(|text| text.trim().to_string())
                .collect()
        })
        .filter(|translations: &Vec<String>| !translations.is_empty())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_translation_payload() {
        let payload = serde_json::json!({
            "code": 200,
            "data": {
                "ayahs": [
                    { "numberInSurah": 1, "text": "In the name of Allah" },
                    { "numberInSurah": 2, "text": "All praise is due to Allah" }
                ]
            }
        });
        let translations = parse_translation(&payload).unwrap();
        assert_eq!(translations.len(), 2);
        assert_eq!(translations[0], "In the name of Allah");
    }

    #[test]
    fn rejects_an_empty_translation_payload() {
        assert!(parse_translation(&serde_json::json!({ "data": { "ayahs": [] } })).is_none());
        assert!(parse_translation(&serde_json::json!({})).is_none());
    }
}
