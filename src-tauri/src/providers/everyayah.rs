use super::{surah, Track, TrackKind};
use serde::Serialize;

pub const PROVIDER: &str = "everyayah";
const BASE: &str = "https://everyayah.com/data";

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AyahReciter {
    /// EveryAyah folder slug, also used as the provider id.
    pub id: &'static str,
    pub name: &'static str,
    pub english: &'static str,
    /// مرتل · مجود · معلم
    pub style: &'static str,
    pub bitrate: u32,
}

macro_rules! reciter {
    ($id:literal, $name:literal, $english:literal, $style:literal, $bitrate:literal) => {
        AyahReciter {
            id: $id,
            name: $name,
            english: $english,
            style: $style,
            bitrate: $bitrate,
        }
    };
}

/// Curated ayah-by-ayah recitations. Every folder is verified to exist under
/// <https://everyayah.com/data/>.
static RECITERS: &[AyahReciter] = &[
    reciter!("Husary_Muallim_128kbps", "محمود خليل الحصري (المعلّم)", "Al-Husary (teaching)", "معلم", 128),
    reciter!("Husary_128kbps", "محمود خليل الحصري", "Mahmoud Al-Husary", "مرتل", 128),
    reciter!("Husary_128kbps_Mujawwad", "محمود خليل الحصري (مجوّد)", "Al-Husary (mujawwad)", "مجود", 128),
    reciter!("Minshawy_Teacher_128kbps", "محمد صديق المنشاوي (المعلّم)", "Al-Minshawi (teaching)", "معلم", 128),
    reciter!("Minshawy_Murattal_128kbps", "محمد صديق المنشاوي", "Al-Minshawi", "مرتل", 128),
    reciter!("Minshawy_Mujawwad_192kbps", "محمد صديق المنشاوي (مجوّد)", "Al-Minshawi (mujawwad)", "مجود", 192),
    reciter!("Alafasy_128kbps", "مشاري العفاسي", "Mishary Alafasy", "مرتل", 128),
    reciter!("Abdul_Basit_Murattal_192kbps", "عبد الباسط عبد الصمد", "Abdul Basit", "مرتل", 192),
    reciter!("Abdul_Basit_Mujawwad_128kbps", "عبد الباسط عبد الصمد (مجوّد)", "Abdul Basit (mujawwad)", "مجود", 128),
    reciter!("Abdurrahmaan_As-Sudais_192kbps", "عبد الرحمن السديس", "Abdurrahman As-Sudais", "مرتل", 192),
    reciter!("Saood_ash-Shuraym_128kbps", "سعود الشريم", "Saud Ash-Shuraym", "مرتل", 128),
    reciter!("MaherAlMuaiqly128kbps", "ماهر المعيقلي", "Maher Al-Muaiqly", "مرتل", 128),
    reciter!("Hudhaify_128kbps", "علي الحذيفي", "Ali Al-Hudhaify", "مرتل", 128),
    reciter!("Ghamadi_40kbps", "سعد الغامدي", "Saad Al-Ghamdi", "مرتل", 40),
    reciter!("Muhammad_Ayyoub_128kbps", "محمد أيوب", "Muhammad Ayyoub", "مرتل", 128),
    reciter!("Yasser_Ad-Dussary_128kbps", "ياسر الدوسري", "Yasser Ad-Dussary", "مرتل", 128),
    reciter!("Nasser_Alqatami_128kbps", "ناصر القطامي", "Nasser Al-Qatami", "مرتل", 128),
    reciter!("Abu_Bakr_Ash-Shaatree_128kbps", "أبو بكر الشاطري", "Abu Bakr Ash-Shaatree", "مرتل", 128),
    reciter!("Hani_Rifai_192kbps", "هاني الرفاعي", "Hani Ar-Rifai", "مرتل", 192),
    reciter!("Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net", "أحمد بن علي العجمي", "Ahmed Al-Ajamy", "مرتل", 128),
    reciter!("Abdullah_Basfar_192kbps", "عبد الله بصفر", "Abdullah Basfar", "مرتل", 192),
    reciter!("Ali_Jaber_64kbps", "علي جابر", "Ali Jaber", "مرتل", 64),
    reciter!("Ibrahim_Akhdar_64kbps", "إبراهيم الأخضر", "Ibrahim Al-Akhdar", "مرتل", 64),
    reciter!("Ayman_Sowaid_64kbps", "أيمن سويد", "Ayman Sowaid", "مرتل", 64),
    reciter!("Salah_Al_Budair_128kbps", "صلاح البدير", "Salah Al-Budair", "مرتل", 128),
    reciter!("Karim_Mansoori_40kbps", "كريم منصوري", "Karim Mansoori", "مرتل", 40),
];

pub fn reciters() -> &'static [AyahReciter] {
    RECITERS
}

pub fn reciter(id: &str) -> Option<&'static AyahReciter> {
    RECITERS.iter().find(|r| r.id == id)
}

/// EveryAyah serves one file per ayah named `SSSAAA.mp3`.
pub fn ayah_url(folder: &str, surah: u16, ayah: u16) -> String {
    format!("{BASE}/{folder}/{surah:03}{ayah:03}.mp3")
}

/// Builds the ayah queue for one surah. Index `i` is ayah `i + 1`, matching
/// the array returned by the Quran text provider.
pub fn ayah_tracks(surah_number: u16, folder: &str, reciter_name: &str) -> Vec<Track> {
    let Some(meta) = surah(surah_number) else {
        return Vec::new();
    };
    let short = meta
        .name
        .replace("سُورَةُ ", "")
        .replace("سُورَةُ", "")
        .trim()
        .to_string();

    (1..=meta.ayahs)
        .map(|ayah| {
            let mut track = Track::new(
                PROVIDER,
                format!("{folder}:{surah_number:03}{ayah:03}"),
                meta.name.clone(),
                TrackKind::Quran,
            );
            track.artist = reciter_name.to_string();
            track.album = Some(meta.name.clone());
            track.subtitle = Some(format!("{short} · آية {ayah}"));
            track.stream_url = Some(ayah_url(folder, surah_number, ayah));
            track.source_page = Some("https://everyayah.com".into());
            track.attribution = Some(format!("تلاوة {reciter_name} — everyayah.com"));
            track.license = Some("تلاوة مجانية الاستخدام".into());
            track
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builds_zero_padded_urls() {
        assert_eq!(
            ayah_url("Alafasy_128kbps", 1, 1),
            "https://everyayah.com/data/Alafasy_128kbps/001001.mp3"
        );
        assert_eq!(
            ayah_url("Husary_128kbps", 2, 255),
            "https://everyayah.com/data/Husary_128kbps/002255.mp3"
        );
    }

    #[test]
    fn ayah_queue_matches_surah_length() {
        let tracks = ayah_tracks(1, "Alafasy_128kbps", "مشاري العفاسي");
        assert_eq!(tracks.len(), 7);
        assert_eq!(tracks[6].subtitle.as_deref(), Some("ٱلْفَاتِحَةِ · آية 7"));

        let long = ayah_tracks(2, "Alafasy_128kbps", "مشاري العفاسي");
        assert_eq!(long.len(), 286);
    }

    #[test]
    fn reciter_ids_are_unique() {
        let mut ids: Vec<_> = reciters().iter().map(|r| r.id).collect();
        let before = ids.len();
        ids.sort_unstable();
        ids.dedup();
        assert_eq!(ids.len(), before);
    }
}
