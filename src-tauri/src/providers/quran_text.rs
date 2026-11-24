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
        // The Arabic text is bundled, so a slow/blocked translation must not
        // hold the reader hostage when offline.
        .timeout(std::time::Duration::from_secs(8))
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
    let ayahs = body.pointer("/data/ayahs").and_then(Value::as_array)?;
    if ayahs.is_empty() {
        return None;
    }
    // Preserve positions: a malformed/missing ayah must leave an empty slot
    // rather than shift every subsequent translation by one.
    let mut max = ayahs.len();
    for ayah in ayahs {
        if let Some(number) = ayah.get("numberInSurah").and_then(Value::as_u64) {
            max = max.max(number as usize);
        }
    }
    let mut out = vec![String::new(); max];
    for (index, ayah) in ayahs.iter().enumerate() {
        let number = ayah
            .get("numberInSurah")
            .and_then(Value::as_u64)
            .map(|value| value as usize)
            .unwrap_or(index + 1);
        if number == 0 || number > max {
            continue;
        }
        if let Some(text) = ayah.get("text").and_then(Value::as_str) {
            out[number - 1] = text.trim().to_string();
        }
    }
    Some(out)
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

    #[test]
    fn missing_translation_entries_keep_their_position() {
        let payload = serde_json::json!({
            "data": { "ayahs": [
                { "numberInSurah": 1, "text": "A" },
                { "numberInSurah": 3, "text": "C" }
            ]}
        });
        let translations = parse_translation(&payload).unwrap();
        assert_eq!(translations, vec!["A".to_string(), String::new(), "C".to_string()]);
    }
}
