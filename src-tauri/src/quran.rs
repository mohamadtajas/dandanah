//! Offline Uthmani Quran reader data.
//!
//! The bundle is generated from the verbatim Tanzil XML by
//! `scripts/build-quran.mjs`. The text is never edited here; this module only
//! slices it by surah/juz and attaches the basmala that Tanzil keeps separate.

use crate::providers::quran_text::Ayah;
use chrono::{Datelike, NaiveDate};
use serde::{Deserialize, Serialize};
use std::sync::OnceLock;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
#[allow(dead_code)] // surah metadata is exposed through the existing get_surahs command
pub struct QuranSurah {
    pub number: u16,
    pub name: String,
    pub english_name: String,
    pub meaning: String,
    pub ayahs: u16,
    pub revelation: String,
    #[serde(default)]
    pub bismillah: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Juz {
    pub number: u16,
    pub surah: u16,
    pub ayah: u16,
    pub ayahs: u16,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Page {
    pub number: u16,
    pub surah: u16,
    pub ayah: u16,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct RawAyah {
    surah: u16,
    ayah: u16,
    juz: u16,
    page: u16,
    text: String,
    #[serde(default)]
    bismillah: Option<String>,
    #[serde(default)]
    sajda: bool,
}

#[derive(Debug, Deserialize)]
struct QuranData {
    surahs: Vec<QuranSurah>,
    juzs: Vec<Juz>,
    pages: Vec<Page>,
    ayahs: Vec<RawAyah>,
}

static DATA: OnceLock<QuranData> = OnceLock::new();

fn data() -> &'static QuranData {
    DATA.get_or_init(|| {
        serde_json::from_str(include_str!("../data/quran.json"))
            .expect("bundled quran.json is valid")
    })
}

#[cfg(test)]
pub fn total_surahs() -> usize {
    data().surahs.len()
}

#[cfg(test)]
pub fn total_ayahs() -> usize {
    data().ayahs.len()
}

pub fn surah_meta(number: u16) -> Option<&'static QuranSurah> {
    data().surahs.iter().find(|surah| surah.number == number)
}

fn surah_bismillah(number: u16) -> Option<String> {
    surah_meta(number).and_then(|surah| surah.bismillah.clone())
}

fn to_ayah(raw: &RawAyah) -> Ayah {
    Ayah {
        number: raw.ayah,
        surah: raw.surah,
        text: raw.text.clone(),
        translation: None,
        juz: Some(raw.juz),
        page: Some(raw.page),
        bismillah: if raw.ayah == 1 {
            raw.bismillah.clone().or_else(|| surah_bismillah(raw.surah))
        } else {
            None
        },
        sajda: raw.sajda,
    }
}

/// An entire surah, in order.
pub fn surah_ayahs(surah: u16) -> Vec<Ayah> {
    data()
        .ayahs
        .iter()
        .filter(|ayah| ayah.surah == surah)
        .map(to_ayah)
        .collect()
}

/// One juz, from its start through the ayah before the next juz.
pub fn juz_ayahs(juz: u16) -> Vec<Ayah> {
    let juzs = &data().juzs;
    let Some(index) = juzs.iter().position(|entry| entry.number == juz) else {
        return Vec::new();
    };
    let start = &juzs[index];
    let start_at = data()
        .ayahs
        .iter()
        .position(|ayah| ayah.surah == start.surah && ayah.ayah == start.ayah);
    let Some(start_at) = start_at else {
        return Vec::new();
    };
    let end_at = juzs
        .get(index + 1)
        .and_then(|next| {
            data().ayahs.iter().position(|ayah| {
                ayah.surah == next.surah && ayah.ayah == next.ayah
            })
        })
        .unwrap_or(data().ayahs.len());

    data().ayahs[start_at..end_at]
        .iter()
        .map(to_ayah)
        .collect()
}

pub fn juzs() -> &'static [Juz] {
    &data().juzs
}

pub fn pages() -> &'static [Page] {
    &data().pages
}

/// A stable ayah for a local date; advances by one ayah each day.
pub fn daily(date: NaiveDate) -> Option<Ayah> {
    let ayahs = &data().ayahs;
    if ayahs.is_empty() {
        return None;
    }
    let index = (date.num_days_from_ce() as i64).rem_euclid(ayahs.len() as i64) as usize;
    Some(to_ayah(&ayahs[index]))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bundle_has_the_full_quran() {
        assert_eq!(total_surahs(), 114);
        assert_eq!(total_ayahs(), 6236);
        let sum: usize = data()
            .surahs
            .iter()
            .map(|surah| surah.ayahs as usize)
            .sum();
        assert_eq!(sum, 6236);

        let fatiha = surah_ayahs(1);
        assert_eq!(fatiha.len(), 7);
        assert!(fatiha[0].text.starts_with("بِسْمِ"));
        assert_eq!(fatiha[0].surah, 1);

        let baqarah = surah_ayahs(2);
        assert_eq!(baqarah.len(), 286);
        assert_eq!(baqarah[0].text, "الٓمٓ");
        assert!(baqarah[0].bismillah.as_deref().unwrap_or("").starts_with("بِسْمِ"));

        let nas = surah_ayahs(114);
        assert_eq!(nas.len(), 6);
        assert_eq!(nas.last().unwrap().text, "مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ");
    }

    #[test]
    fn basmala_is_separate_except_fatiha_and_tawbah() {
        assert!(surah_meta(1).unwrap().bismillah.is_none());
        assert!(surah_meta(9).unwrap().bismillah.is_none());
        assert!(surah_meta(2).unwrap().bismillah.is_some());
        let count = data()
            .surahs
            .iter()
            .filter(|surah| surah.bismillah.is_some())
            .count();
        assert_eq!(count, 112);

        let tawbah = surah_ayahs(9);
        assert!(tawbah[0].text.starts_with("بَرَآءَةٌ"));
        assert!(tawbah[0].bismillah.is_none());
    }

    #[test]
    fn juz_boundaries_cover_every_ayah_once() {
        assert_eq!(juzs().len(), 30);
        let total: u16 = juzs().iter().map(|juz| juz.ayahs).sum();
        assert_eq!(total, 6236);

        let first = juz_ayahs(1);
        assert_eq!((first[0].surah, first[0].number), (1, 1));
        assert_eq!(first.len(), 148);

        let second = juz_ayahs(2);
        assert_eq!((second[0].surah, second[0].number), (2, 142));

        let last = juz_ayahs(30);
        assert_eq!((last[0].surah, last[0].number), (78, 1));
        assert_eq!((last.last().unwrap().surah, last.last().unwrap().number), (114, 6));
        assert_eq!(last.len(), 564);
    }

    #[test]
    fn known_ayahs_and_pages_are_correct() {
        let kursi = &surah_ayahs(2)[254];
        assert_eq!((kursi.surah, kursi.number), (2, 255));
        assert!(kursi.text.starts_with("ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ"));
        assert_eq!(kursi.juz, Some(3));
        assert_eq!(kursi.page, Some(42));

        assert_eq!(pages().len(), 604);
        assert_eq!(
            (pages()[0].number, pages()[0].surah, pages()[0].ayah),
            (1, 1, 1)
        );
        assert_eq!(
            (pages().last().unwrap().number, pages().last().unwrap().surah),
            (604, 112)
        );
    }

    #[test]
    fn sajda_ayahs_are_flagged() {
        let count = data()
            .ayahs
            .iter()
            .filter(|ayah| to_ayah(ayah).sajda)
            .count();
        assert_eq!(count, 15);
        assert!(surah_ayahs(7)[205].sajda);
        assert!(!surah_ayahs(2)[0].sajda);
    }

    #[test]
    fn daily_ayah_is_stable_and_in_range() {
        let date = NaiveDate::from_ymd_opt(2026, 11, 26).unwrap();
        let first = daily(date).unwrap();
        let again = daily(date).unwrap();
        assert_eq!(
            (first.surah, first.number, &first.text),
            (again.surah, again.number, &again.text)
        );
        assert!((1..=114).contains(&first.surah));
        assert!(!first.text.is_empty());

        let tomorrow = daily(date + chrono::Duration::days(1)).unwrap();
        assert_ne!(
            (first.surah, first.number),
            (tomorrow.surah, tomorrow.number)
        );
    }
}
