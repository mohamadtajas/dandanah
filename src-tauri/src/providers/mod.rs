use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::sync::OnceLock;

pub mod archive;
pub mod everyayah;
pub mod mp3quran;
pub mod openverse;
pub mod quran_text;
pub mod radiobrowser;

pub use mp3quran::Reciter;

/// What kind of audio a track is. Drives UI grouping and licensing rules.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TrackKind {
    Quran,
    Anasheed,
    Music,
    Radio,
    Local,
}

impl std::fmt::Display for TrackKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}

impl TrackKind {
    pub fn as_str(&self) -> &'static str {
        match self {
            TrackKind::Quran => "quran",
            TrackKind::Anasheed => "anasheed",
            TrackKind::Music => "music",
            TrackKind::Radio => "radio",
            TrackKind::Local => "local",
        }
    }
}

/// The one shape every provider normalises into.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Track {
    /// `provider:providerId` — globally unique inside the app.
    pub id: String,
    pub provider: String,
    pub provider_id: String,
    pub title: String,
    pub artist: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub album: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub duration_s: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub artwork_url: Option<String>,
    /// Direct stream URL. Resolved at play time for providers that expire URLs.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stream_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub license: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub license_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub attribution: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub source_page: Option<String>,
    pub kind: TrackKind,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub subtitle: Option<String>,
    /// True when the track is a continuous live stream (no seek, no duration).
    #[serde(default)]
    pub live: bool,
    /// Absolute path for an imported or downloaded file. The UI plays this via
    /// the Tauri asset protocol instead of the remote URL.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub local_path: Option<String>,
}

impl Track {
    pub fn new(provider: &str, provider_id: impl Into<String>, title: impl Into<String>, kind: TrackKind) -> Self {
        let provider_id = provider_id.into();
        Self {
            id: format!("{provider}:{provider_id}"),
            provider: provider.to_string(),
            provider_id,
            title: title.into(),
            artist: String::new(),
            album: None,
            duration_s: None,
            artwork_url: None,
            stream_url: None,
            license: None,
            license_url: None,
            attribution: None,
            source_page: None,
            kind,
            subtitle: None,
            live: false,
            local_path: None,
        }
    }
}

// ---------------------------------------------------------------------------
// Quran metadata (static)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Surah {
    pub number: u16,
    pub name: String,
    pub english_name: String,
    pub meaning: String,
    pub ayahs: u16,
    /// `makkah` | `madinah`
    pub revelation: String,
}

static SURAHS: OnceLock<Vec<Surah>> = OnceLock::new();

pub fn surahs() -> &'static [Surah] {
    SURAHS.get_or_init(|| {
        serde_json::from_str(include_str!("../../data/surahs.json"))
            .expect("bundled surahs.json is valid")
    })
}

pub fn surah(number: u16) -> Option<&'static Surah> {
    surahs().iter().find(|s| s.number == number)
}

// ---------------------------------------------------------------------------
// Arabic-aware text normalisation (used for dedupe + fuzzy matching)
// ---------------------------------------------------------------------------

/// Strips tashkeel/tatweel and folds alef, ya and ta-marbuta variants so that
/// "الأَنصَار" and "الانصار" compare equal.
pub fn normalize_arabic(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    for ch in input.chars() {
        match ch {
            '\u{064B}'..='\u{065F}'   // harakat
            | '\u{0670}'              // superscript alef
            | '\u{06D6}'..='\u{06ED}' // Quranic annotation marks
            | '\u{0640}'              // tatweel
            => {}
            '\u{0622}' | '\u{0623}' | '\u{0625}' | '\u{0671}' => out.push('\u{0627}'),
            '\u{0649}' | '\u{0626}' => out.push('\u{064A}'),
            '\u{0629}' => out.push('\u{0647}'),
            _ => {
                for lower in ch.to_lowercase() {
                    out.push(lower);
                }
            }
        }
    }
    out.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// Dice coefficient over character bigrams. Cheap, and good enough to rank
/// provider results against a query without pulling in a search library.
pub fn similarity(a: &str, b: &str) -> f32 {
    let a = normalize_arabic(a);
    let b = normalize_arabic(b);
    if a.is_empty() || b.is_empty() {
        return 0.0;
    }
    if a == b {
        return 1.0;
    }
    if a.len() < 2 || b.len() < 2 {
        return if a.contains(&b) || b.contains(&a) { 0.8 } else { 0.0 };
    }
    let bigrams = |s: &str| -> HashSet<(char, char)> {
        let chars: Vec<char> = s.chars().collect();
        chars.windows(2).map(|w| (w[0], w[1])).collect()
    };
    let (ba, bb) = (bigrams(&a), bigrams(&b));
    let overlap = ba.intersection(&bb).count();
    (2 * overlap) as f32 / (ba.len() + bb.len()) as f32
}

/// Scores a candidate string against a query. Substring and word matches beat
/// raw bigram similarity, which is noisy for short Arabic names
/// ("الحصري" vs "الشريم" share 40% of their bigrams).
pub fn score(query: &str, candidate: &str) -> f32 {
    let q = normalize_arabic(query);
    let c = normalize_arabic(candidate);
    if q.is_empty() || c.is_empty() {
        return 0.0;
    }
    if c == q {
        return 1.0;
    }
    if c.starts_with(&q) {
        return 0.95;
    }
    if c.split_whitespace().any(|w| w == q) {
        return 0.9;
    }
    if c.contains(&q) {
        return 0.8;
    }
    similarity(&q, &c)
}

/// Whether a candidate is relevant enough to show for a query.
pub fn matches(query: &str, candidate: &str) -> bool {
    score(query, candidate) >= 0.55
}

/// Turns a Creative Commons code or licence URL into a short human label.
pub fn license_label(value: &str) -> String {
    let trimmed = value.trim();
    let v = trimmed.to_ascii_lowercase();
    if v.is_empty() {
        return String::new();
    }
    if v.contains("publicdomain/zero") || v == "cc0" || v.contains("/cc0/") {
        return "CC0".into();
    }
    if v.contains("publicdomain") || v == "pdm" {
        return "Public domain".into();
    }
    for (needle, label) in [
        ("by-nc-nd", "CC BY-NC-ND"),
        ("by-nc-sa", "CC BY-NC-SA"),
        ("by-nc", "CC BY-NC"),
        ("by-sa", "CC BY-SA"),
        ("by-nd", "CC BY-ND"),
        ("by", "CC BY"),
    ] {
        if v == needle || v.contains(&format!("/{needle}/")) || v == format!("cc-{needle}") {
            return label.into();
        }
    }
    trimmed.to_string()
}

/// Merges provider results, dropping near-duplicate tracks while keeping the
/// higher-ranked (earlier) copy.
pub fn dedupe(mut tracks: Vec<Track>) -> Vec<Track> {
    let mut kept: Vec<Track> = Vec::with_capacity(tracks.len());
    for track in tracks.drain(..) {
        let is_dup = kept.iter().any(|k| {
            if k.provider == track.provider && k.provider_id == track.provider_id {
                return true;
            }
            let title_match = similarity(&k.title, &track.title) > 0.86;
            let artist_match = k.artist.is_empty()
                || track.artist.is_empty()
                || similarity(&k.artist, &track.artist) > 0.8;
            let duration_match = match (k.duration_s, track.duration_s) {
                (Some(a), Some(b)) => a.abs_diff(b) <= 4,
                _ => true,
            };
            title_match && artist_match && duration_match
        });
        if !is_dup {
            kept.push(track);
        }
    }
    kept
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalises_tashkeel_and_alef_variants() {
        assert_eq!(normalize_arabic("الأَنصَار"), normalize_arabic("الانصار"));
        assert_eq!(normalize_arabic("مُحَمَّد"), "محمد");
        assert_eq!(normalize_arabic("عَلِيّ"), normalize_arabic("علي"));
        assert_eq!(normalize_arabic("سُورَةُ  ٱلْفَاتِحَةِ"), "سوره الفاتحه");
    }

    #[test]
    fn similarity_ranks_prefixes_highly() {
        assert!(similarity("الحصري", "محمود خليل الحصري") > 0.3);
        assert!(similarity("الحصري", "الحصري") > 0.99);
        assert!(similarity("الحصري", "الشريم") < 0.55);
    }

    #[test]
    fn score_prefers_word_matches_over_bigrams() {
        assert_eq!(score("الحصري", "الحصري"), 1.0);
        assert!(score("الحصري", "محمود خليل الحصري") > 0.75);
        assert!(!matches("الحصري", "الشريم"));
        assert!(matches("مشاري", "مشاري العفاسي"));
    }

    #[test]
    fn license_labels_cover_common_codes() {
        assert_eq!(license_label("by"), "CC BY");
        assert_eq!(license_label("by-sa"), "CC BY-SA");
        assert_eq!(
            license_label("https://creativecommons.org/licenses/by-nc-nd/4.0/"),
            "CC BY-NC-ND"
        );
        assert_eq!(license_label("cc0"), "CC0");
        assert_eq!(license_label("pdm"), "Public domain");
        assert_eq!(license_label(""), "");
        assert_eq!(license_label("All rights reserved"), "All rights reserved");
    }

    #[test]
    fn dedupe_drops_same_track_from_two_providers() {
        let mut a = Track::new("mp3quran", "1-1", "سورة الفاتحة", TrackKind::Quran);
        a.artist = "محمود خليل الحصري".into();
        a.duration_s = Some(60);
        let mut b = Track::new("other", "x", "سورة الفاتحه", TrackKind::Quran);
        b.artist = "محمود خليل الحصري".into();
        b.duration_s = Some(62);
        let c = Track::new("other", "y", "سورة البقرة", TrackKind::Quran);
        let out = dedupe(vec![a, b, c]);
        assert_eq!(out.len(), 2);
    }

    #[test]
    fn surah_table_is_complete() {
        let all = surahs();
        assert_eq!(all.len(), 114);
        assert_eq!(all[0].ayahs, 7);
        assert_eq!(all[113].number, 114);
        assert!(surah(2).is_some_and(|s| s.ayahs == 286));
    }
}
