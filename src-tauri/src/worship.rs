//! Offline worship helpers: prayer times, Hijri dates, qibla, prayer log streak.
//!
//! Everything here is calculated locally with no network access. The prayer
//! maths come from the `salah` crate (a port of Batoul Apps' Adhan library).

use crate::db::Database;
use anyhow::Result;
use adhan::{
    prayer_times, HighLatitudeRule, Madhab, Method, Parameters, PolarCircleResolution, Prayer,
    PrayerTimes,
};
use chrono::{DateTime, Datelike, Duration, NaiveDate, Timelike, Utc};
use chrono_tz::Tz;
use hijridate::{Gregorian, Language};
use serde::{Deserialize, Serialize};

/// The five obligatory prayers, in the order they occur.
pub const PRAYER_KEYS: [&str; 5] = ["fajr", "dhuhr", "asr", "maghrib", "isha"];

/// Settings key holding the serialised [`WorshipSettings`].
pub const SETTINGS_KEY: &str = "worship.settings";

const METHODS: [&str; 12] = [
    "muslimWorldLeague",
    "egyptian",
    "karachi",
    "ummAlQura",
    "dubai",
    "moonsightingCommittee",
    "northAmerica",
    "kuwait",
    "qatar",
    "singapore",
    "tehran",
    "turkey",
];

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WorshipSettings {
    pub latitude: f64,
    pub longitude: f64,
    /// IANA timezone, e.g. `Asia/Riyadh`.
    pub timezone: String,
    /// One of [`METHODS`].
    pub method: String,
    /// `shafi` or `hanafi` (affects Asr only).
    pub madhab: String,
    /// How Fajr/Isha are bounded when the sun misses the angle above ~48°.
    #[serde(default = "default_high_latitude")]
    pub high_latitude: String,
    /// Days added to the Gregorian date before Hijri conversion (-3..=3).
    pub hijri_adjustment: i32,
    /// Whether the user has explicitly picked a location.
    #[serde(default)]
    pub configured: bool,
}

impl Default for WorshipSettings {
    fn default() -> Self {
        let timezone = iana_time_zone::get_timezone()
            .ok()
            .filter(|zone| zone.parse::<Tz>().is_ok())
            .unwrap_or_else(|| "Asia/Riyadh".to_string());
        Self {
            latitude: 21.4225,
            longitude: 39.8262,
            timezone,
            method: "ummAlQura".to_string(),
            madhab: "shafi".to_string(),
            high_latitude: default_high_latitude(),
            hijri_adjustment: 0,
            configured: false,
        }
    }
}

fn default_high_latitude() -> String {
    "recommended".to_string()
}

impl WorshipSettings {
    pub fn timezone(&self) -> Tz {
        self.timezone.parse().unwrap_or(chrono_tz::UTC)
    }

    pub fn method(&self) -> Method {
        match self.method.as_str() {
            "muslimWorldLeague" => Method::MuslimWorldLeague,
            "egyptian" => Method::Egyptian,
            "karachi" => Method::Karachi,
            "dubai" => Method::Dubai,
            "moonsightingCommittee" => Method::MoonsightingCommittee,
            "northAmerica" => Method::NorthAmerica,
            "kuwait" => Method::Kuwait,
            "qatar" => Method::Qatar,
            "singapore" => Method::Singapore,
            "tehran" => Method::Tehran,
            "turkey" => Method::Turkey,
            _ => Method::UmmAlQura,
        }
    }

    pub fn madhab(&self) -> Madhab {
        if self.madhab == "hanafi" {
            Madhab::Hanafi
        } else {
            Madhab::Shafi
        }
    }

    pub fn high_latitude_rule(&self) -> HighLatitudeRule {
        match self.high_latitude.as_str() {
            "middleOfTheNight" => HighLatitudeRule::MiddleOfTheNight,
            "seventhOfTheNight" => HighLatitudeRule::SeventhOfTheNight,
            "twilightAngle" => HighLatitudeRule::TwilightAngle,
            _ => HighLatitudeRule::recommended(self.latitude),
        }
    }

    /// Clamp user input into values the calculation can trust.
    pub fn sanitized(mut self) -> Self {
        if !self.latitude.is_finite() {
            self.latitude = 21.4225;
        }
        if !self.longitude.is_finite() {
            self.longitude = 39.8262;
        }
        self.latitude = self.latitude.clamp(-90.0, 90.0);
        self.longitude = self.longitude.clamp(-180.0, 180.0);
        if self.timezone.parse::<Tz>().is_err() {
            self.timezone = "UTC".to_string();
        }
        if !METHODS.contains(&self.method.as_str()) {
            self.method = "ummAlQura".to_string();
        }
        if self.madhab != "hanafi" {
            self.madhab = "shafi".to_string();
        }
        if !matches!(
            self.high_latitude.as_str(),
            "recommended" | "middleOfTheNight" | "seventhOfTheNight" | "twilightAngle"
        ) {
            self.high_latitude = default_high_latitude();
        }
        self.hijri_adjustment = self.hijri_adjustment.clamp(-3, 3);
        self
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PrayerTime {
    pub key: String,
    /// Arabic name, useful for tray/tooltip text.
    pub name: String,
    /// Local wall-clock time, `HH:MM`.
    pub time: String,
    /// RFC 3339 instant including the local offset.
    pub iso: String,
    /// Minutes after local midnight.
    pub minutes: u32,
    pub passed: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct HijriDate {
    pub year: i32,
    pub month: u8,
    pub day: u8,
    pub month_name: String,
    pub month_name_en: String,
    pub day_name: String,
    pub day_name_en: String,
    /// `20 شعبان 1445 هـ`
    pub formatted: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PrayerDay {
    /// Local Gregorian date, `YYYY-MM-DD`.
    pub date: String,
    pub timezone: String,
    pub times: Vec<PrayerTime>,
    pub next: Option<PrayerTime>,
    pub remaining_s: i64,
    pub qibla: f64,
    pub hijri: Option<HijriDate>,
    /// Local now at calculation time, `YYYY-MM-DDTHH:MM:SS+HH:MM`.
    pub now: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PrayerLog {
    /// Local Gregorian date, `YYYY-MM-DD`.
    pub date: String,
    pub fajr: bool,
    pub dhuhr: bool,
    pub asr: bool,
    pub maghrib: bool,
    pub isha: bool,
    pub excused: bool,
}

impl PrayerLog {
    pub fn empty(date: impl Into<String>) -> Self {
        Self {
            date: date.into(),
            fajr: false,
            dhuhr: false,
            asr: false,
            maghrib: false,
            isha: false,
            excused: false,
        }
    }

    pub fn count(&self) -> u8 {
        [
            self.fajr, self.dhuhr, self.asr, self.maghrib, self.isha,
        ]
        .iter()
        .filter(|done| **done)
        .count() as u8
    }

    pub fn complete(&self) -> bool {
        self.count() == 5
    }

}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct QiblaInfo {
    pub bearing: f64,
    pub latitude: f64,
    pub longitude: f64,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Streak {
    pub current: u32,
    pub best: u32,
    pub today_complete: bool,
    pub today_excused: bool,
    pub today_count: u8,
}

// ---------------------------------------------------------------------------
// Calculations
// ---------------------------------------------------------------------------

/// Qibla bearing in degrees clockwise from true north.
pub fn qibla_bearing(latitude: f64, longitude: f64) -> f64 {
    const KAABA_LAT: f64 = 21.4225241;
    const KAABA_LON: f64 = 39.8261818;
    // The bearing is undefined at the Kaaba itself; within 50 m, say north.
    if distance_km(latitude, longitude, KAABA_LAT, KAABA_LON) < 0.05 {
        0.0
    } else {
        adhan::qibla(latitude, longitude)
    }
}

fn distance_km(lat1: f64, lon1: f64, lat2: f64, lon2: f64) -> f64 {
    let d_lat = (lat2 - lat1).to_radians();
    let d_lon = (lon2 - lon1).to_radians();
    let a = (d_lat / 2.0).sin().powi(2)
        + lat1.to_radians().cos() * lat2.to_radians().cos() * (d_lon / 2.0).sin().powi(2);
    6371.0088 * 2.0 * a.sqrt().atan2((1.0 - a).sqrt())
}

/// Convert a Gregorian date to the Umm al-Qura Hijri calendar.
pub fn hijri_date(date: NaiveDate, adjustment_days: i32) -> Option<HijriDate> {
    let adjusted = date.checked_add_signed(Duration::days(adjustment_days as i64))?;
    let gregorian = Gregorian::new(
        adjusted.year(),
        adjusted.month() as u8,
        adjusted.day() as u8,
    )
    .ok()?;
    let hijri = gregorian.to_hijri();
    let month_name = hijri.month_name_in(Language::Arabic).to_string();
    Some(HijriDate {
        year: hijri.year(),
        month: hijri.month(),
        day: hijri.day(),
        day_name: hijri.day_name_in(Language::Arabic).to_string(),
        day_name_en: hijri.day_name_in(Language::English).to_string(),
        formatted: format!("{} {} {} هـ", hijri.day(), month_name, hijri.year()),
        month_name,
        month_name_en: hijri.month_name_in(Language::English).to_string(),
    })
}

struct RawTime {
    key: &'static str,
    name: &'static str,
    at: DateTime<Tz>,
}

/// Turn a 0–24h UTC clock reading into an instant on a known UTC date.
fn instant(date: NaiveDate, (hour, minute, second): (i64, u32, u32)) -> DateTime<Utc> {
    let midnight = date
        .and_hms_opt(0, 0, 0)
        .expect("midnight is always a valid time")
        .and_utc();
    midnight
        + Duration::hours(hour)
        + Duration::minutes(minute as i64)
        + Duration::seconds(second as i64)
}

/// Pick the UTC date that makes Dhuhr fall on the requested local date.
///
/// `adhan` reduces each reading to a 0–24h UTC clock, so the day is lost. Dhuhr
/// is solar noon and therefore always near local noon; for UTC+13/14 its UTC
/// date is the previous day, and for UTC−11/12 it is the next one. Testing the
/// three candidates and preferring a local hour near 12 recovers the day.
fn resolve_dhuhr_utc_date(date: NaiveDate, tz: Tz, reading: (i64, u32, u32)) -> NaiveDate {
    let mut best = date;
    let mut best_score = i64::MAX;
    for shift in -1..=1 {
        let candidate = date + Duration::days(shift);
        let local = instant(candidate, reading).with_timezone(&tz);
        let day_gap = (local.date_naive() - date).num_days().abs();
        let score = day_gap * 1000 + (local.hour() as i64 - 12).abs();
        if score < best_score {
            best_score = score;
            best = candidate;
        }
    }
    best
}

fn raw_times(schedule: &PrayerTimes, date: NaiveDate, tz: Tz) -> Vec<RawTime> {
    let readings: Vec<(&'static str, &'static str, (i64, u32, u32))> = [
        ("fajr", "الفجر", Prayer::Fajr),
        ("sunrise", "الشروق", Prayer::Sunrise),
        ("dhuhr", "الظهر", Prayer::Dhuhr),
        ("asr", "العصر", Prayer::Asr),
        ("maghrib", "المغرب", Prayer::Maghrib),
        ("isha", "العشاء", Prayer::Isha),
    ]
    .into_iter()
    .filter_map(|(key, name, prayer)| schedule.time_for(prayer).map(|r| (key, name, r)))
    .collect();

    let dhuhr = readings
        .iter()
        .find(|(key, _, _)| *key == "dhuhr")
        .map(|(_, _, reading)| *reading);
    let dhuhr_date = dhuhr
        .map(|reading| resolve_dhuhr_utc_date(date, tz, reading))
        .unwrap_or(date);

    readings
        .into_iter()
        .map(|(key, name, reading)| {
            // Fajr and sunrise precede solar noon, so a clock reading later
            // than Dhuhr belongs to the previous UTC day. Asr and later follow
            // it, so a reading earlier than Dhuhr belongs to the next one.
            let utc_date = match (dhuhr, key) {
                (Some(anchor), "fajr" | "sunrise") if reading > anchor => {
                    dhuhr_date - Duration::days(1)
                }
                (Some(anchor), "asr" | "maghrib" | "isha") if reading < anchor => {
                    dhuhr_date + Duration::days(1)
                }
                _ => dhuhr_date,
            };
            RawTime {
                key,
                name,
                at: instant(utc_date, reading).with_timezone(&tz),
            }
        })
        .collect()
}

fn calculate_with(
    settings: &WorshipSettings,
    date: NaiveDate,
    resolution: PolarCircleResolution,
) -> PrayerTimes {
    let mut parameters = Parameters::for_method(settings.method())
        .with_madhab(settings.madhab())
        .with_high_latitude_rule(settings.high_latitude_rule());
    parameters.polar_circle_resolution = resolution;
    prayer_times(
        date.year(),
        date.month(),
        date.day(),
        settings.latitude,
        settings.longitude,
        &parameters,
    )
}

/// Times for one local date, falling back to a nearby latitude when borrowing
/// the nearest day produces a non-chronological polar schedule.
fn day_times(settings: &WorshipSettings, date: NaiveDate, tz: Tz) -> Vec<RawTime> {
    let mut times = raw_times(
        &calculate_with(settings, date, PolarCircleResolution::AqrabYaum),
        date,
        tz,
    );
    if !times.windows(2).all(|pair| pair[0].at <= pair[1].at) {
        times = raw_times(
            &calculate_with(settings, date, PolarCircleResolution::AqrabBalad),
            date,
            tz,
        );
    }
    times
}

/// Prayer times for one local date. `now` is passed in so tests are stable.
pub fn prayer_day(
    settings: &WorshipSettings,
    date: NaiveDate,
    now: DateTime<Utc>,
) -> Result<PrayerDay, String> {
    let tz = settings.timezone();
    let raw = day_times(settings, date, tz);

    let times: Vec<PrayerTime> = raw
        .iter()
        .map(|item| {
            let instant = item.at.with_timezone(&Utc);
            PrayerTime {
                key: item.key.to_string(),
                name: item.name.to_string(),
                time: item.at.format("%H:%M").to_string(),
                iso: item.at.to_rfc3339(),
                minutes: item.at.hour() * 60 + item.at.minute(),
                passed: instant <= now,
            }
        })
        .collect();

    let mut next = raw
        .iter()
        .filter(|item| PRAYER_KEYS.contains(&item.key) && item.at.with_timezone(&Utc) > now)
        .min_by_key(|item| item.at)
        .map(|item| (item.key, item.name, item.at));

    // After Isha the next prayer belongs to tomorrow's Fajr. Only roll over
    // when the requested day is the current local day; historical rows keep
    // their own day boundaries.
    if next.is_none() && date == now.with_timezone(&tz).date_naive() {
        let tomorrow_date = date + Duration::days(1);
        let tomorrow = day_times(settings, tomorrow_date, tz);
        next = tomorrow
            .iter()
            .find(|item| item.key == "fajr")
            .map(|item| (item.key, item.name, item.at));
    }

    let next_time = next.map(|(key, name, at)| PrayerTime {
        key: key.to_string(),
        name: name.to_string(),
        time: at.format("%H:%M").to_string(),
        iso: at.to_rfc3339(),
        minutes: at.hour() * 60 + at.minute(),
        passed: false,
    });

    let remaining_s = next
        .map(|(_, _, at)| (at.with_timezone(&Utc) - now).num_seconds().max(0))
        .unwrap_or(0);

    Ok(PrayerDay {
        date: date.format("%Y-%m-%d").to_string(),
        timezone: settings.timezone.clone(),
        times,
        next: next_time,
        remaining_s,
        qibla: qibla_bearing(settings.latitude, settings.longitude),
        hijri: hijri_date(date, settings.hijri_adjustment),
        now: now.with_timezone(&tz).to_rfc3339(),
    })
}

/// Consecutive-day streak from prayer-log rows, evaluated against `today`.
///
/// A day counts when all five prayers are logged, or when it is marked
/// excused. An unfinished today does not break a streak that is still running
/// (the day is not over), so counting starts at yesterday in that case.
pub fn compute_streak(logs: &[PrayerLog], today: NaiveDate) -> Streak {
    use std::collections::BTreeMap;

    let mut by_date: BTreeMap<NaiveDate, &PrayerLog> = BTreeMap::new();
    for log in logs {
        if let Ok(date) = NaiveDate::parse_from_str(&log.date, "%Y-%m-%d") {
            by_date.insert(date, log);
        }
    }

    let qualifies = |date: NaiveDate| {
        by_date
            .get(&date)
            .map(|log| log.complete() || log.excused)
            .unwrap_or(false)
    };

    // A day still in progress should not erase yesterday's streak.
    let mut cursor = if qualifies(today) {
        today
    } else {
        today - Duration::days(1)
    };
    let mut current: u32 = 0;
    while qualifies(cursor) {
        current += 1;
        cursor -= Duration::days(1);
    }

    let mut best: u32 = 0;
    let mut run: u32 = 0;
    let mut previous: Option<NaiveDate> = None;
    for (&date, log) in &by_date {
        if log.complete() || log.excused {
            run = if previous == Some(date - Duration::days(1)) {
                run + 1
            } else {
                1
            };
            best = best.max(run);
        } else {
            run = 0;
        }
        previous = Some(date);
    }

    let today_log = by_date.get(&today).copied();
    Streak {
        current,
        best,
        today_complete: today_log.map(PrayerLog::complete).unwrap_or(false),
        today_excused: today_log.map(|log| log.excused).unwrap_or(false),
        today_count: today_log.map(PrayerLog::count).unwrap_or(0),
    }
}

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------

pub fn load_settings(db: &Database) -> WorshipSettings {
    db.get_setting(SETTINGS_KEY)
        .ok()
        .flatten()
        .and_then(|raw| serde_json::from_str::<WorshipSettings>(&raw).ok())
        .unwrap_or_default()
        .sanitized()
}

pub fn save_settings(db: &Database, settings: &WorshipSettings) -> Result<WorshipSettings> {
    let settings = settings.clone().sanitized();
    let raw = serde_json::to_string(&settings)?;
    db.set_setting(SETTINGS_KEY, &raw)?;
    Ok(settings)
}

/// Decide whether a save is an explicit location choice.
///
/// Editing a calculation method or the Hijri offset must not turn the default
/// Makkah coordinates into "the user's location".
pub fn merge_settings(previous: &WorshipSettings, mut incoming: WorshipSettings) -> WorshipSettings {
    let moved = (incoming.latitude - previous.latitude).abs() > 1e-6
        || (incoming.longitude - previous.longitude).abs() > 1e-6;
    incoming.configured = incoming.configured || previous.configured || moved;
    incoming.sanitized()
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn settings(lat: f64, lon: f64, tz: &str, method: &str) -> WorshipSettings {
        WorshipSettings {
            latitude: lat,
            longitude: lon,
            timezone: tz.to_string(),
            method: method.to_string(),
            madhab: "shafi".to_string(),
            high_latitude: "recommended".to_string(),
            hijri_adjustment: 0,
            configured: true,
        }
    }

    fn local(tz: &str, y: i32, m: u32, d: u32, h: u32, min: u32) -> DateTime<Utc> {
        tz.parse::<Tz>()
            .unwrap()
            .with_ymd_and_hms(y, m, d, h, min, 0)
            .unwrap()
            .with_timezone(&Utc)
    }

    fn minutes_of(day: &PrayerDay, key: &str) -> u32 {
        day.times
            .iter()
            .find(|t| t.key == key)
            .unwrap_or_else(|| panic!("missing {key}"))
            .minutes
    }

    fn assert_time(day: &PrayerDay, key: &str, expected: &str, tolerance: i64) {
        let parts: Vec<i64> = expected.split(':').map(|p| p.parse().unwrap()).collect();
        let want = parts[0] * 60 + parts[1];
        let got = minutes_of(day, key) as i64;
        assert!(
            (got - want).abs() <= tolerance,
            "{key}: got {} minutes, want {want} ±{tolerance}",
            got
        );
    }

    #[test]
    fn saving_a_method_does_not_claim_the_default_location() {
        let previous = WorshipSettings::default();
        assert!(!previous.configured);

        let mut method_only = previous.clone();
        method_only.method = "muslimWorldLeague".to_string();
        let merged = merge_settings(&previous, method_only);
        assert!(!merged.configured, "coordinates did not change");

        let mut moved = previous.clone();
        moved.latitude = 30.0444;
        moved.longitude = 31.2357;
        assert!(merge_settings(&previous, moved).configured);

        let mut explicit = previous.clone();
        explicit.configured = true;
        assert!(merge_settings(&previous, explicit).configured);
    }

    #[test]
    fn settings_written_before_high_latitude_still_load() {
        // A settings row saved by an earlier D1 build has no highLatitude key.
        let json = r#"{
            "latitude": 21.4225,
            "longitude": 39.8262,
            "timezone": "Asia/Riyadh",
            "method": "ummAlQura",
            "madhab": "shafi",
            "hijriAdjustment": 0,
            "configured": true
        }"#;
        let settings: WorshipSettings = serde_json::from_str(json).unwrap();
        assert_eq!(settings.high_latitude, "recommended");
        assert_eq!(settings.method(), Method::UmmAlQura);
    }

    #[test]
    fn makkah_times_match_umm_al_qura() {
        // Reference: Aladhan API, 2024-03-01, Umm al-Qura.
        let s = settings(21.4225, 39.8262, "Asia/Riyadh", "ummAlQura");
        let day = prayer_day(
            &s,
            NaiveDate::from_ymd_opt(2024, 3, 1).unwrap(),
            local("Asia/Riyadh", 2024, 3, 1, 9, 0),
        )
        .unwrap();
        assert_time(&day, "fajr", "05:25", 2);
        assert_time(&day, "sunrise", "06:41", 2);
        assert_time(&day, "dhuhr", "12:33", 2);
        assert_time(&day, "asr", "15:54", 2);
        assert_time(&day, "maghrib", "18:25", 2);
        assert_time(&day, "isha", "19:55", 2);
        assert_eq!(day.date, "2024-03-01");
    }

    #[test]
    fn cairo_times_match_egyptian_method() {
        // Reference: Aladhan API, 2024-03-15, Egyptian General Authority.
        let s = settings(30.0444, 31.2357, "Africa/Cairo", "egyptian");
        let day = prayer_day(
            &s,
            NaiveDate::from_ymd_opt(2024, 3, 15).unwrap(),
            local("Africa/Cairo", 2024, 3, 15, 8, 0),
        )
        .unwrap();
        assert_time(&day, "fajr", "04:38", 2);
        assert_time(&day, "dhuhr", "12:04", 2);
        assert_time(&day, "asr", "15:28", 2);
        assert_time(&day, "maghrib", "18:04", 2);
        assert_time(&day, "isha", "19:21", 2);
    }

    #[test]
    fn new_york_times_match_isna() {
        // Reference: Aladhan API, 2024-03-15, ISNA (North America).
        let s = settings(40.7128, -74.0059, "America/New_York", "northAmerica");
        let day = prayer_day(
            &s,
            NaiveDate::from_ymd_opt(2024, 3, 15).unwrap(),
            local("America/New_York", 2024, 3, 15, 8, 0),
        )
        .unwrap();
        assert_time(&day, "fajr", "05:52", 2);
        assert_time(&day, "dhuhr", "13:05", 2);
        assert_time(&day, "asr", "16:26", 2);
        assert_time(&day, "maghrib", "19:03", 2);
        assert_time(&day, "isha", "20:19", 2);
    }

    fn assert_local_date(day: &PrayerDay, expected: &str) {
        for time in &day.times {
            assert!(
                time.iso.starts_with(expected),
                "{} should be on {expected}, got {}",
                time.key,
                time.iso
            );
        }
    }

    #[test]
    fn eastern_zones_keep_the_requested_local_date() {
        // References: Aladhan API, MWL, 2026-06-21.
        let jakarta = settings(-6.2088, 106.8456, "Asia/Jakarta", "muslimWorldLeague");
        let day = prayer_day(
            &jakarta,
            NaiveDate::from_ymd_opt(2026, 6, 21).unwrap(),
            local("Asia/Jakarta", 2026, 6, 21, 10, 0),
        )
        .unwrap();
        assert_time(&day, "fajr", "04:46", 2);
        assert_time(&day, "dhuhr", "11:54", 2);
        assert_time(&day, "maghrib", "17:47", 2);
        assert_time(&day, "isha", "18:58", 2);
        assert_local_date(&day, "2026-06-21");
        assert_eq!(day.next.as_ref().unwrap().key, "dhuhr");

        let sydney = settings(-33.8688, 151.2093, "Australia/Sydney", "muslimWorldLeague");
        let day = prayer_day(
            &sydney,
            NaiveDate::from_ymd_opt(2026, 11, 26).unwrap(),
            local("Australia/Sydney", 2026, 11, 26, 10, 0),
        )
        .unwrap();
        assert_time(&day, "fajr", "03:59", 2);
        assert_time(&day, "dhuhr", "12:42", 2);
        assert_time(&day, "maghrib", "19:46", 2);
        assert_local_date(&day, "2026-11-26");
        assert_eq!(day.next.as_ref().unwrap().key, "dhuhr");

        // UTC+14 is the far edge; Dhuhr's UTC clock reading belongs to D-1.
        let kiritimati = settings(1.8721, -157.4278, "Pacific/Kiritimati", "muslimWorldLeague");
        let day = prayer_day(
            &kiritimati,
            NaiveDate::from_ymd_opt(2026, 6, 21).unwrap(),
            local("Pacific/Kiritimati", 2026, 6, 21, 10, 0),
        )
        .unwrap();
        assert_time(&day, "fajr", "05:09", 2);
        assert_time(&day, "dhuhr", "12:32", 2);
        assert_local_date(&day, "2026-06-21");
        assert_eq!(day.next.as_ref().unwrap().key, "dhuhr");
    }

    #[test]
    fn western_evening_prayers_stay_on_the_same_day() {
        // Reference: Aladhan API, ISNA, 2026-06-21.
        let nyc = settings(40.7128, -74.0059, "America/New_York", "northAmerica");
        let day = prayer_day(
            &nyc,
            NaiveDate::from_ymd_opt(2026, 6, 21).unwrap(),
            local("America/New_York", 2026, 6, 21, 18, 0),
        )
        .unwrap();
        assert_time(&day, "maghrib", "20:31", 2);
        assert_time(&day, "isha", "22:11", 2);
        assert_local_date(&day, "2026-06-21");
        assert_eq!(day.next.as_ref().unwrap().key, "maghrib");
        assert!(
            (2 * 3600..3 * 3600).contains(&day.remaining_s),
            "maghrib is about 2.5h away, got {}",
            day.remaining_s
        );
    }

    #[test]
    fn isha_after_midnight_is_still_the_next_prayer() {
        // Reference: Aladhan API, MWL, middle of the night, 2026-06-21.
        let mut paris = settings(48.8566, 2.3522, "Europe/Paris", "muslimWorldLeague");
        paris.high_latitude = "middleOfTheNight".to_string();
        let day = prayer_day(
            &paris,
            NaiveDate::from_ymd_opt(2026, 6, 21).unwrap(),
            local("Europe/Paris", 2026, 6, 21, 23, 30),
        )
        .unwrap();
        assert_time(&day, "fajr", "01:52", 2);
        assert_time(&day, "isha", "01:07", 2);
        let next = day.next.as_ref().unwrap();
        assert_eq!(next.key, "isha");
        assert!(next.iso.starts_with("2026-06-22"), "got {}", next.iso);
        assert!(day.remaining_s > 0);
    }

    #[test]
    fn after_isha_rolls_to_tomorrow_fajr() {
        let jakarta = settings(-6.2088, 106.8456, "Asia/Jakarta", "muslimWorldLeague");
        let day = prayer_day(
            &jakarta,
            NaiveDate::from_ymd_opt(2026, 6, 21).unwrap(),
            local("Asia/Jakarta", 2026, 6, 21, 20, 0),
        )
        .unwrap();
        let next = day.next.as_ref().unwrap();
        assert_eq!(next.key, "fajr");
        assert!(next.iso.starts_with("2026-06-22"), "got {}", next.iso);
        assert!(day.remaining_s > 0);
    }

    #[test]
    fn polar_times_stay_chronological() {
        let tromso = settings(69.6492, 18.9553, "Europe/Oslo", "muslimWorldLeague");
        let day = prayer_day(
            &tromso,
            NaiveDate::from_ymd_opt(2026, 12, 21).unwrap(),
            local("Europe/Oslo", 2026, 12, 21, 12, 0),
        )
        .unwrap();
        assert!(
            day.times.iter().any(|time| time.key == "dhuhr"),
            "Dhuhr always exists"
        );
        let mut previous = None;
        for time in &day.times {
            let instant = DateTime::parse_from_rfc3339(&time.iso).unwrap();
            if let Some(previous) = previous {
                assert!(
                    instant >= previous,
                    "{} at {} is before the previous prayer",
                    time.key,
                    time.iso
                );
            }
            previous = Some(instant);
        }
    }

    #[test]
    fn qibla_at_the_kaaba_is_zero() {
        assert!(qibla_bearing(21.4225, 39.8262) < 0.1);
    }

    #[test]
    fn london_high_latitude_rule_matches_reference() {
        // Reference: Aladhan API, 2024-06-21, MWL, one-seventh of the night.
        let s = settings(51.5074, -0.1278, "Europe/London", "muslimWorldLeague");
        let day = prayer_day(
            &s,
            NaiveDate::from_ymd_opt(2024, 6, 21).unwrap(),
            local("Europe/London", 2024, 6, 21, 8, 0),
        )
        .unwrap();
        assert_time(&day, "fajr", "03:40", 2);
        assert_time(&day, "isha", "22:25", 2);

        // Middle-of-the-night gives a much earlier Fajr; the setting is wired.
        let mut night = s.clone();
        night.high_latitude = "middleOfTheNight".to_string();
        let other = prayer_day(
            &night,
            NaiveDate::from_ymd_opt(2024, 6, 21).unwrap(),
            local("Europe/London", 2024, 6, 21, 8, 0),
        )
        .unwrap();
        assert!(
            minutes_of(&other, "fajr") < minutes_of(&day, "fajr"),
            "middle-of-night Fajr should be earlier"
        );
    }

    #[test]
    fn qibla_matches_known_bearings() {
        // The `salah` crate ships these reference bearings.
        assert!((qibla_bearing(40.7128, -74.0059) - 58.4817635).abs() < 0.05);
        assert!((qibla_bearing(-33.8688, 151.2093) - 277.4996).abs() < 0.05);
        // Due south of the Kaaba the bearing is due north, and due west of it
        // the bearing is due east. These avoid the degenerate exact-centre case.
        let kaaba_lon = 39.8261818;
        assert!(qibla_bearing(20.0, kaaba_lon).abs() < 0.1);
        let due_east = qibla_bearing(21.4225241, 38.8261818);
        assert!((85.0..95.0).contains(&due_east), "got {due_east}");
    }

    #[test]
    fn hijri_conversion_and_adjustment() {
        let date = NaiveDate::from_ymd_opt(2024, 3, 15).unwrap();
        let hijri = hijri_date(date, 0).unwrap();
        assert_eq!((hijri.year, hijri.month, hijri.day), (1445, 9, 5));
        assert!(hijri.month_name.contains("رمضان"));
        assert_eq!(hijri.month_name_en, "Ramadan");
        assert!(hijri.formatted.contains("1445"));

        let ahead = hijri_date(date, 1).unwrap();
        assert_eq!((ahead.year, ahead.month, ahead.day), (1445, 9, 6));
        let behind = hijri_date(date, -1).unwrap();
        assert_eq!((behind.year, behind.month, behind.day), (1445, 9, 4));
    }

    #[test]
    fn next_prayer_moves_through_the_day_and_rolls_over() {
        let s = settings(21.4225, 39.8262, "Asia/Riyadh", "ummAlQura");
        let date = NaiveDate::from_ymd_opt(2024, 3, 1).unwrap();

        let noon = prayer_day(&s, date, local("Asia/Riyadh", 2024, 3, 1, 13, 0)).unwrap();
        assert_eq!(noon.next.as_ref().unwrap().key, "asr");
        assert!(noon.remaining_s > 0);

        let night = prayer_day(&s, date, local("Asia/Riyadh", 2024, 3, 1, 22, 0)).unwrap();
        let next = night.next.as_ref().unwrap();
        assert_eq!(next.key, "fajr");
        assert!(next.iso.contains("2024-03-02"));
        assert!(night.remaining_s > 0);
    }

    #[test]
    fn streak_keeps_running_while_today_is_unfinished() {
        let today = NaiveDate::from_ymd_opt(2026, 11, 25).unwrap();
        let mut logs = Vec::new();
        for offset in 1..=5 {
            let date = today - Duration::days(offset);
            let mut log = PrayerLog::empty(date.format("%Y-%m-%d").to_string());
            log.fajr = true;
            log.dhuhr = true;
            log.asr = true;
            log.maghrib = true;
            log.isha = true;
            logs.push(log);
        }
        // Today's row exists but is still empty.
        logs.push(PrayerLog::empty("2026-11-25".to_string()));

        let streak = compute_streak(&logs, today);
        assert_eq!(streak.current, 5, "yesterday and the four days before it");
        assert_eq!(streak.best, 5);
        assert!(!streak.today_complete);
        assert_eq!(streak.today_count, 0);
    }

    #[test]
    fn excused_days_preserve_the_chain_and_gaps_break_it() {
        let today = NaiveDate::from_ymd_opt(2026, 11, 25).unwrap();
        let complete = |date: NaiveDate| {
            let mut log = PrayerLog::empty(date.format("%Y-%m-%d").to_string());
            log.fajr = true;
            log.dhuhr = true;
            log.asr = true;
            log.maghrib = true;
            log.isha = true;
            log
        };

        let mut logs = vec![complete(today)];
        let mut excused = PrayerLog::empty((today - Duration::days(1)).format("%Y-%m-%d").to_string());
        excused.excused = true;
        logs.push(excused);
        logs.push(complete(today - Duration::days(2)));

        let streak = compute_streak(&logs, today);
        assert_eq!(streak.current, 3);
        assert!(streak.today_complete);
        assert!(!streak.today_excused);

        // A missing day before that stops the count.
        logs.push(complete(today - Duration::days(4)));
        let streak = compute_streak(&logs, today);
        assert_eq!(streak.current, 3, "day -3 is missing");
        assert_eq!(streak.best, 3);
    }

    #[test]
    fn streak_survives_a_local_date_shift() {
        // Logs are keyed by the local date at logging time. If the timezone
        // moves the local date forward by a day, today simply becomes
        // unfinished and the streak is counted from yesterday.
        let complete = |date: NaiveDate| {
            let mut log = PrayerLog::empty(date.format("%Y-%m-%d").to_string());
            log.fajr = true;
            log.dhuhr = true;
            log.asr = true;
            log.maghrib = true;
            log.isha = true;
            log
        };
        let logs = vec![
            complete(NaiveDate::from_ymd_opt(2026, 11, 24).unwrap()),
            complete(NaiveDate::from_ymd_opt(2026, 11, 25).unwrap()),
        ];
        let before = NaiveDate::from_ymd_opt(2026, 11, 25).unwrap();
        assert_eq!(compute_streak(&logs, before).current, 2);

        let shifted = NaiveDate::from_ymd_opt(2026, 11, 26).unwrap();
        let after = compute_streak(&logs, shifted);
        assert_eq!(after.current, 2);
        assert!(!after.today_complete);
    }

    #[test]
    fn best_streak_survives_a_break() {
        let today = NaiveDate::from_ymd_opt(2026, 11, 25).unwrap();
        let complete = |date: NaiveDate| {
            let mut log = PrayerLog::empty(date.format("%Y-%m-%d").to_string());
            log.fajr = true;
            log.dhuhr = true;
            log.asr = true;
            log.maghrib = true;
            log.isha = true;
            log
        };
        let mut logs = Vec::new();
        for offset in [1, 2, 3] {
            logs.push(complete(today - Duration::days(offset)));
        }
        for offset in [5, 6, 7, 8] {
            logs.push(complete(today - Duration::days(offset)));
        }
        let streak = compute_streak(&logs, today);
        assert_eq!(streak.current, 3);
        assert_eq!(streak.best, 4);
    }

}