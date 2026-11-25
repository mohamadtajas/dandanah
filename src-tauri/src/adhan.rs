use crate::commands::AppState;
use crate::db::Database;
use crate::worship::{self, PrayerTime, WorshipSettings, PRAYER_KEYS};
use chrono::{DateTime, Duration as ChronoDuration, Utc};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, HashSet};
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;
use tauri::menu::MenuItem;
use tauri::{AppHandle, Emitter, Manager, State};
use tauri_plugin_notification::NotificationExt;

/// Serialised [`AdhanSettings`] in the settings table.
pub const SETTINGS_KEY: &str = "worship.adhan.v1";
/// Emitted to the webview so it can play the bundled CC0 recording.
pub const PLAY_EVENT: &str = "adhan:play";
/// Emitted by the tray so the webview can stop a playing adhan.
pub const STOP_EVENT: &str = "adhan:stop";
const CLOSE_TO_TRAY_KEY: &str = "desktop.closeToTray";
const LOCALE_KEY: &str = "ui.locale";
/// How late an alert may be and still fire. This is deliberately short so a
/// laptop waking hours after a prayer does not play a stale adhan.
pub const ALERT_WINDOW_S: i64 = 90;

static QUITTING: AtomicBool = AtomicBool::new(false);

pub fn mark_quitting() {
    QUITTING.store(true, Ordering::Relaxed);
}

pub fn is_quitting() -> bool {
    QUITTING.load(Ordering::Relaxed)
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PrayerAlert {
    pub adhan: bool,
    pub notify: bool,
}

impl Default for PrayerAlert {
    fn default() -> Self {
        Self {
            adhan: true,
            notify: true,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AdhanSettings {
    pub enabled: bool,
    /// Per-prayer switches, keyed by `fajr`..`isha`.
    pub prayers: BTreeMap<String, PrayerAlert>,
    pub pre_alert_enabled: bool,
    pub pre_alert_minutes: u32,
    /// 0.0..=1.0.
    pub volume: f64,
}

impl Default for AdhanSettings {
    fn default() -> Self {
        Self {
            enabled: true,
            prayers: PRAYER_KEYS
                .iter()
                .map(|key| (key.to_string(), PrayerAlert::default()))
                .collect(),
            pre_alert_enabled: false,
            pre_alert_minutes: 10,
            volume: 0.8,
        }
    }
}

impl AdhanSettings {
    pub fn sanitized(mut self) -> Self {
        if !self.volume.is_finite() {
            self.volume = 0.8;
        }
        self.volume = self.volume.clamp(0.0, 1.0);
        if !matches!(self.pre_alert_minutes, 0 | 5 | 10 | 15 | 20 | 30) {
            self.pre_alert_minutes = 10;
        }
        // 0 means "off"; keep the select valid and make the state explicit.
        if self.pre_alert_minutes == 0 {
            self.pre_alert_enabled = false;
            self.pre_alert_minutes = 10;
        }
        self.prayers.retain(|key, _| PRAYER_KEYS.contains(&key.as_str()));
        for key in PRAYER_KEYS {
            self.prayers
                .entry(key.to_string())
                .or_insert_with(PrayerAlert::default);
        }
        self
    }
}

pub fn load_settings(db: &Database) -> AdhanSettings {
    db.get_setting(SETTINGS_KEY)
        .ok()
        .flatten()
        .and_then(|raw| serde_json::from_str::<AdhanSettings>(&raw).ok())
        .unwrap_or_default()
        .sanitized()
}

pub fn save_settings(db: &Database, settings: AdhanSettings) -> anyhow::Result<AdhanSettings> {
    let settings = settings.sanitized();
    db.set_setting(SETTINGS_KEY, &serde_json::to_string(&settings)?)?;
    Ok(settings)
}

pub fn close_to_tray(db: &Database) -> bool {
    db.get_setting(CLOSE_TO_TRAY_KEY)
        .ok()
        .flatten()
        .map(|value| value != "0")
        .unwrap_or(true)
}

pub fn locale(db: &Database) -> String {
    db.get_setting(LOCALE_KEY)
        .ok()
        .flatten()
        .filter(|value| value == "en" || value == "ar")
        .unwrap_or_else(|| "ar".to_string())
}

fn english(locale: &str) -> bool {
    locale == "en"
}

fn prayer_label(locale: &str, key: &str, arabic: &str) -> String {
    if !english(locale) {
        return arabic.to_string();
    }
    match key {
        "fajr" => "Fajr",
        "dhuhr" => "Dhuhr",
        "asr" => "Asr",
        "maghrib" => "Maghrib",
        "isha" => "Isha",
        _ => key,
    }
    .to_string()
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AlertKind {
    Adhan,
    Pre,
}

impl AlertKind {
    fn as_str(self) -> &'static str {
        match self {
            AlertKind::Adhan => "adhan",
            AlertKind::Pre => "pre",
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct Alert {
    pub kind: AlertKind,
    pub prayer_key: String,
    pub prayer_name: String,
    pub time: String,
    /// Local ISO timestamp of the prayer itself, used as a dedupe key.
    pub date: String,
    /// The instant that triggers this alert (the prayer, or the pre-alert).
    pub trigger_at: DateTime<Utc>,
    pub lead_minutes: u32,
}

impl Alert {
    /// The prayer's own instant, not the pre-alert trigger.
    pub fn prayer_at(&self) -> DateTime<Utc> {
        self.trigger_at + ChronoDuration::minutes(i64::from(self.lead_minutes))
    }
}

/// A due alert after applying the user's switches. Kept pure so the gating
/// rules are testable without a running app.
#[derive(Debug, Clone, PartialEq)]
pub struct PlannedAlert {
    pub alert: Alert,
    pub toast: bool,
    pub sound: bool,
    /// Suppress the toast's default ding when the adhan itself plays.
    pub silent_toast: bool,
}

pub fn plan_alert(alert: Alert, settings: &AdhanSettings) -> Option<PlannedAlert> {
    if !settings.enabled {
        return None;
    }
    let switches = settings
        .prayers
        .get(&alert.prayer_key)
        .cloned()
        .unwrap_or_default();
    match alert.kind {
        AlertKind::Pre => {
            if !settings.pre_alert_enabled || !switches.notify {
                return None;
            }
            Some(PlannedAlert {
                alert,
                toast: true,
                sound: false,
                silent_toast: false,
            })
        }
        AlertKind::Adhan => {
            if !switches.notify && !switches.adhan {
                return None;
            }
            Some(PlannedAlert {
                alert,
                toast: switches.notify,
                sound: switches.adhan,
                silent_toast: switches.adhan,
            })
        }
    }
}

/// Pure scheduling rule: a prayer fires once when its instant has just passed,
/// and a pre-alert fires once when its lead time has just been crossed.
pub fn due_alerts(
    times: &[PrayerTime],
    now: DateTime<Utc>,
    pre_minutes: u32,
    window_s: i64,
) -> Vec<Alert> {
    let mut due = Vec::new();
    for prayer in times {
        if !PRAYER_KEYS.contains(&prayer.key.as_str()) {
            continue;
        }
        let Ok(at) = DateTime::parse_from_rfc3339(&prayer.iso) else {
            continue;
        };
        let at = at.with_timezone(&Utc);
        let date = prayer.iso.split('T').next().unwrap_or("").to_string();

        let age = (now - at).num_seconds();
        if (0..=window_s).contains(&age) {
            due.push(Alert {
                kind: AlertKind::Adhan,
                prayer_key: prayer.key.clone(),
                prayer_name: prayer.name.clone(),
                time: prayer.time.clone(),
                date: date.clone(),
                trigger_at: at,
                lead_minutes: 0,
            });
        }

        if pre_minutes > 0 {
            let trigger = at - ChronoDuration::minutes(i64::from(pre_minutes));
            let age = (now - trigger).num_seconds();
            if (0..=window_s).contains(&age) && now < at {
                due.push(Alert {
                    kind: AlertKind::Pre,
                    prayer_key: prayer.key.clone(),
                    prayer_name: prayer.name.clone(),
                    time: prayer.time.clone(),
                    date,
                    trigger_at: trigger,
                    lead_minutes: pre_minutes,
                });
            }
        }
    }
    due
}

/// Remembers what has already fired. The start instant prevents an alert that
/// happened before the app launched from firing on the first tick.
pub struct AlertTracker {
    fired: HashSet<String>,
    started: DateTime<Utc>,
}

impl AlertTracker {
    pub fn new(started: DateTime<Utc>) -> Self {
        Self {
            fired: HashSet::new(),
            started,
        }
    }

    pub fn due(
        &mut self,
        times: &[PrayerTime],
        now: DateTime<Utc>,
        pre_minutes: u32,
    ) -> Vec<Alert> {
        let mut fresh = Vec::new();
        for alert in due_alerts(times, now, pre_minutes, ALERT_WINDOW_S) {
            if alert.trigger_at < self.started {
                continue;
            }
            let key = format!(
                "{}:{}",
                alert.kind.as_str(),
                alert.trigger_at.timestamp()
            );
            if self.fired.insert(key) {
                fresh.push(alert);
            }
        }
        // Keep the set tiny on long-running sessions.
        if self.fired.len() > 100 {
            let cutoff = (now - ChronoDuration::days(2)).timestamp();
            self.fired.retain(|key| {
                key.split(':')
                    .nth(1)
                    .and_then(|stamp| stamp.parse::<i64>().ok())
                    .map(|stamp| stamp >= cutoff)
                    .unwrap_or(false)
            });
        }
        fresh
    }
}

pub fn format_tray_text(next: &PrayerTime, remaining_s: i64, locale: &str) -> String {
    let minutes = if remaining_s <= 0 {
        0
    } else {
        (remaining_s + 59) / 60
    };
    let left = if english(locale) {
        if minutes >= 60 {
            format!("{}h {}m", minutes / 60, minutes % 60)
        } else {
            format!("{minutes}m")
        }
    } else if minutes >= 60 {
        format!("{}س {}د", minutes / 60, minutes % 60)
    } else {
        format!("{minutes}د")
    };
    let name = prayer_label(locale, &next.key, &next.name);
    if english(locale) {
        format!("Next prayer: {name} · {} — in {left}", next.time)
    } else {
        format!("الصلاة القادمة: {name} · {} — بعد {left}", next.time)
    }
}

#[derive(Default)]
pub struct TrayHandles {
    pub next_prayer: parking_lot::Mutex<Option<MenuItem<tauri::Wry>>>,
    /// Static menu labels that follow the UI language.
    pub items: parking_lot::Mutex<Vec<(MenuItem<tauri::Wry>, &'static str, &'static str)>>,
    pub last_text: parking_lot::Mutex<String>,
}

pub fn refresh_labels(app: &AppHandle) {
    let locale = locale(&app.state::<AppState>().db);
    let handles = app.state::<TrayHandles>();
    for (item, arabic, english_text) in handles.items.lock().iter() {
        let _ = item.set_text(if english(&locale) { *english_text } else { *arabic });
    }
}

fn update_tray(app: &AppHandle, next: Option<&PrayerTime>, remaining_s: i64, locale: &str) {
    let text = match next {
        Some(prayer) => format_tray_text(prayer, remaining_s, locale),
        None => {
            if english(locale) {
                "Next prayer: —".to_string()
            } else {
                "الصلاة القادمة: —".to_string()
            }
        }
    };
    let handles = app.state::<TrayHandles>();
    let mut last = handles.last_text.lock();
    if *last != text {
        let updated = match handles.next_prayer.lock().as_ref() {
            Some(item) => item.set_text(&text).is_ok(),
            None => true,
        };
        if updated {
            if let Some(tray) = app.tray_by_id("main") {
                let prefix = if english(locale) { "Sakeenah" } else { "سَكينة" };
                let _ = tray.set_tooltip(Some(&format!("{prefix} — {text}")));
            }
            *last = text;
        }
    }
}

/// Recomputes the tray line immediately after a language change.
pub fn refresh_tray_now(app: &AppHandle) {
    let db = app.state::<AppState>().db.clone();
    let settings = worship::load_settings(&db);
    let locale = locale(&db);
    let now = Utc::now();
    if !settings.configured {
        update_tray(app, None, 0, &locale);
        return;
    }
    let date = now.with_timezone(&settings.timezone()).date_naive();
    if let Ok(day) = worship::prayer_day(&settings, date, now) {
        update_tray(app, day.next.as_ref(), day.remaining_s, &locale);
    }
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AdhanPlayback {
    pub prayer: String,
    pub name: String,
    pub volume: f64,
}

fn notify(app: &AppHandle, title: &str, body: &str, silent: bool) {
    let mut builder = app.notification().builder().title(title).body(body);
    if silent {
        // `notify-rust` treats an unknown sound name as "no sound", which is
        // exactly what we want while the adhan recording is playing.
        builder = builder.sound("silent");
    }
    if let Err(error) = builder.show() {
        eprintln!("prayer notification failed: {error}");
    }
}

/// Runs once every 15 seconds for the whole process lifetime. It is the only
/// source of prayer alerts, so hiding the window does not stop them.
pub fn start(app: AppHandle) {
    tauri::async_runtime::spawn(async move {
        let mut tracker = AlertTracker::new(Utc::now());
        loop {
            tick(&app, &mut tracker);
            tokio::time::sleep(Duration::from_secs(15)).await;
        }
    });
}

fn tick(app: &AppHandle, tracker: &mut AlertTracker) {
    let db = app.state::<AppState>().db.clone();
    let settings = worship::load_settings(&db);
    let adhan = load_settings(&db);
    let locale = locale(&db);
    let now = Utc::now();

    if !settings.configured {
        update_tray(app, None, 0, &locale);
        return;
    }

    let date = now.with_timezone(&settings.timezone()).date_naive();
    let Ok(day) = worship::prayer_day(&settings, date, now) else {
        update_tray(app, None, 0, &locale);
        return;
    };
    update_tray(app, day.next.as_ref(), day.remaining_s, &locale);

    if !adhan.enabled {
        return;
    }
    let pre_minutes = if adhan.pre_alert_enabled {
        adhan.pre_alert_minutes
    } else {
        0
    };

    // Include the adjacent local days so a pre-alert crossing midnight and an
    // Isha window that spills into the new day are still seen.
    let mut candidates = Vec::with_capacity(15);
    if let Ok(previous) = worship::prayer_day(&settings, date - ChronoDuration::days(1), now) {
        candidates.extend(previous.times);
    }
    candidates.extend(day.times.clone());
    if let Ok(tomorrow) = worship::prayer_day(&settings, date + ChronoDuration::days(1), now) {
        candidates.extend(tomorrow.times);
    }

    for planned in tracker
        .due(&candidates, now, pre_minutes)
        .into_iter()
        .filter_map(|alert| plan_alert(alert, &adhan))
    {
        let alert = &planned.alert;
        let name = prayer_label(&locale, &alert.prayer_key, &alert.prayer_name);
        if planned.toast {
            match alert.kind {
                AlertKind::Pre => {
                    let remaining = ((alert.prayer_at() - now).num_seconds() + 59) / 60;
                    if english(&locale) {
                        notify(
                            app,
                            &format!("In {} minutes: {name}", remaining.max(1)),
                            &format!("{name} is at {}", alert.time),
                            false,
                        );
                    } else {
                        notify(
                            app,
                            &format!("بعد {} دقائق: {name}", remaining.max(1)),
                            &format!("اقترب موعد صلاة {name} الساعة {}", alert.time),
                            false,
                        );
                    }
                }
                AlertKind::Adhan => {
                    if english(&locale) {
                        notify(
                            app,
                            &format!("It is time for {name}"),
                            &format!("{name} · {}", alert.time),
                            planned.silent_toast,
                        );
                    } else {
                        notify(
                            app,
                            &format!("حان وقت صلاة {name}"),
                            &format!("{name} · {}", alert.time),
                            planned.silent_toast,
                        );
                    }
                }
            }
        }
        if planned.sound {
            let _ = app.emit(
                PLAY_EVENT,
                AdhanPlayback {
                    prayer: alert.prayer_key.clone(),
                    name,
                    volume: adhan.volume,
                },
            );
        }
    }
}

#[tauri::command]
pub fn get_adhan_settings(state: State<'_, AppState>) -> AdhanSettings {
    load_settings(&state.db)
}

#[tauri::command]
pub fn set_adhan_settings(
    state: State<'_, AppState>,
    settings: AdhanSettings,
) -> Result<AdhanSettings, String> {
    save_settings(&state.db, settings).map_err(|error| error.to_string())
}

#[tauri::command]
pub fn get_autostart(app: AppHandle) -> bool {
    use tauri_plugin_autostart::ManagerExt;
    app.autolaunch().is_enabled().unwrap_or(false)
}

/// `auto-launch` writes `path with spaces --minimized` unquoted, which Windows
/// may parse as a different executable. Rewrite the Run value with quotes.
#[cfg(windows)]
fn quote_autostart_entry() {
    use winreg::enums::{HKEY_CURRENT_USER, KEY_READ, KEY_WRITE};
    use winreg::types::FromRegValue;
    let hkcu = winreg::RegKey::predef(HKEY_CURRENT_USER);
    let Ok(run) = hkcu.open_subkey_with_flags(
        "Software\\Microsoft\\Windows\\CurrentVersion\\Run",
        KEY_READ | KEY_WRITE,
    ) else {
        return;
    };
    let entries: Vec<(String, String)> = run
        .enum_values()
        .flatten()
        .filter_map(|(name, value)| {
            String::from_reg_value(&value)
                .ok()
                .map(|value| (name, value))
        })
        .filter(|(_, value)| value.to_ascii_lowercase().contains("sakeenah.exe"))
        .collect();
    for (name, value) in entries {
        if value.starts_with('"') {
            continue;
        }
        if let Some(position) = value.to_ascii_lowercase().find(".exe") {
            let end = position + 4;
            let quoted = format!("\"{}\"{}", &value[..end], &value[end..]);
            let _ = run.set_value(&name, &quoted);
        }
    }
}

#[cfg(not(windows))]
fn quote_autostart_entry() {}

#[tauri::command]
pub fn set_autostart(app: AppHandle, enabled: bool) -> Result<bool, String> {
    use tauri_plugin_autostart::ManagerExt;
    let manager = app.autolaunch();
    if enabled {
        manager.enable().map_err(|error| error.to_string())?;
        quote_autostart_entry();
    } else {
        manager.disable().map_err(|error| error.to_string())?;
    }
    manager.is_enabled().map_err(|error| error.to_string())
}

#[tauri::command]
pub fn get_close_to_tray(state: State<'_, AppState>) -> bool {
    close_to_tray(&state.db)
}

#[tauri::command]
pub fn set_close_to_tray(
    state: State<'_, AppState>,
    enabled: bool,
) -> Result<bool, String> {
    state
        .db
        .set_setting(CLOSE_TO_TRAY_KEY, if enabled { "1" } else { "0" })
        .map_err(|error| error.to_string())?;
    Ok(enabled)
}

/// Settings preview: shows the same toast the scheduler would use; the
/// webview plays the recording from the user gesture. Works even when the
/// schedule is disabled so the sound can be checked before enabling alerts.
#[tauri::command]
pub fn test_adhan(app: AppHandle, state: State<'_, AppState>) -> AdhanSettings {
    let settings = load_settings(&state.db);
    if english(&locale(&state.db)) {
        notify(&app, "Adhan test", "The adhan will play now", true);
    } else {
        notify(&app, "اختبار الأذان", "سيُسمع الأذان الآن", true);
    }
    settings
}

#[tauri::command]
pub fn get_ui_locale(state: State<'_, AppState>) -> String {
    locale(&state.db)
}

#[tauri::command]
pub fn set_ui_locale(
    app: AppHandle,
    state: State<'_, AppState>,
    locale: String,
) -> Result<String, String> {
    if locale != "ar" && locale != "en" {
        return Err("unsupported locale".into());
    }
    state
        .db
        .set_setting(LOCALE_KEY, &locale)
        .map_err(|error| error.to_string())?;
    refresh_labels(&app);
    refresh_tray_now(&app);
    Ok(locale)
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn prayer(key: &str, name: &str, iso: &str) -> PrayerTime {
        PrayerTime {
            key: key.into(),
            name: name.into(),
            time: iso[11..16].to_string(),
            iso: iso.into(),
            minutes: 0,
            passed: false,
        }
    }

    fn utc(y: i32, m: u32, d: u32, h: u32, min: u32, s: u32) -> DateTime<Utc> {
        Utc.with_ymd_and_hms(y, m, d, h, min, s).unwrap()
    }

    fn day() -> Vec<PrayerTime> {
        vec![
            prayer("fajr", "الفجر", "2026-11-25T05:20:00+03:00"),
            prayer("dhuhr", "الظهر", "2026-11-25T12:05:00+03:00"),
            prayer("asr", "العصر", "2026-11-25T15:10:00+03:00"),
            prayer("maghrib", "المغرب", "2026-11-25T17:35:00+03:00"),
            prayer("isha", "العشاء", "2026-11-25T19:05:00+03:00"),
        ]
    }

    #[test]
    fn adhan_fires_only_just_after_the_prayer() {
        let at = utc(2026, 11, 25, 9, 6, 0); // 12:06 in +03:00
        let due = due_alerts(&day(), at, 0, ALERT_WINDOW_S);
        assert_eq!(due.len(), 1);
        assert_eq!(due[0].kind, AlertKind::Adhan);
        assert_eq!(due[0].prayer_key, "dhuhr");

        // Two hours later must not replay a missed adhan (sleep/resume).
        let later = utc(2026, 11, 25, 11, 10, 0);
        assert!(due_alerts(&day(), later, 0, ALERT_WINDOW_S).is_empty());
    }

    #[test]
    fn pre_alert_fires_once_at_the_lead_time() {
        let at = utc(2026, 11, 25, 8, 55, 0); // 10 minutes before Dhuhr
        let due = due_alerts(&day(), at, 10, ALERT_WINDOW_S);
        assert_eq!(due.len(), 1);
        assert_eq!(due[0].kind, AlertKind::Pre);
        assert_eq!(due[0].prayer_key, "dhuhr");
        assert_eq!(due[0].lead_minutes, 10);
    }

    #[test]
    fn tracker_deduplicates_and_ignores_alerts_before_start() {
        let at = utc(2026, 11, 25, 9, 6, 0);
        let mut tracker = AlertTracker::new(at - ChronoDuration::minutes(1));
        assert_eq!(tracker.due(&day(), at, 0).len(), 1);
        assert_eq!(tracker.due(&day(), at, 0).len(), 0, "same prayer twice");

        // Launching after the prayer must not replay it.
        let later = utc(2026, 11, 25, 9, 6, 30);
        let mut fresh = AlertTracker::new(later);
        assert!(fresh.due(&day(), later, 0).is_empty());
    }

    #[test]
    fn timezone_change_recomputes_the_same_instant() {
        // 12:10 UTC is 15:10 in Riyadh (Asr) and 13:10 in Cairo (Dhuhr).
        let now = utc(2026, 11, 25, 12, 10, 0);
        let riyadh = WorshipSettings {
            timezone: "Asia/Riyadh".into(),
            configured: true,
            ..WorshipSettings::default()
        };
        let cairo = WorshipSettings {
            timezone: "Africa/Cairo".into(),
            configured: true,
            ..WorshipSettings::default()
        };
        let rday = worship::prayer_day(&riyadh, now.date_naive(), now).unwrap();
        let cday = worship::prayer_day(&cairo, now.date_naive(), now).unwrap();
        assert!(rday.next.is_some());
        assert!(cday.next.is_some());
        // The scheduler always reads the current settings, so a zone change
        // moves the next prayer rather than leaving a stale one in the tray.
        assert_ne!(rday.next.unwrap().time, cday.next.unwrap().time);
    }

    #[test]
    fn settings_are_sanitized() {
        let settings = AdhanSettings {
            volume: 4.0,
            pre_alert_minutes: 7,
            prayers: BTreeMap::from([("fajr".to_string(), PrayerAlert::default())]),
            ..AdhanSettings::default()
        }
        .sanitized();
        assert_eq!(settings.volume, 1.0);
        assert_eq!(settings.pre_alert_minutes, 10);
        assert_eq!(settings.prayers.len(), 5);

        // 0 is not a selectable lead time: it means "off".
        let zero = AdhanSettings {
            pre_alert_enabled: true,
            pre_alert_minutes: 0,
            ..AdhanSettings::default()
        }
        .sanitized();
        assert!(!zero.pre_alert_enabled);
        assert_eq!(zero.pre_alert_minutes, 10);
    }

    #[test]
    fn alert_window_accepts_ninety_seconds_but_not_ninety_one() {
        let at = utc(2026, 11, 25, 9, 5, 0); // Dhuhr 12:05 +03
        assert_eq!(
            due_alerts(&day(), at + ChronoDuration::seconds(90), 0, ALERT_WINDOW_S).len(),
            1
        );
        assert!(due_alerts(
            &day(),
            at + ChronoDuration::seconds(91),
            0,
            ALERT_WINDOW_S
        )
        .is_empty());
    }

    #[test]
    fn crossing_midnight_keeps_isha_and_early_fajr_alerts() {
        // Yesterday's Isha at 23:59:30 and tomorrow's Fajr at 00:08.
        let isha = prayer("isha", "العشاء", "2026-11-25T23:59:30+03:00");
        let fajr = prayer("fajr", "الفجر", "2026-11-26T00:08:00+03:00");

        // 00:00:10 local: yesterday's Isha is still inside its window.
        let just_after_midnight = utc(2026, 11, 25, 21, 0, 10);
        let due = due_alerts(&[isha], just_after_midnight, 0, ALERT_WINDOW_S);
        assert_eq!(due.len(), 1);
        assert_eq!(due[0].prayer_key, "isha");

        // 23:58 local: the 10-minute pre-alert for tomorrow's Fajr is due.
        let before_midnight = utc(2026, 11, 25, 20, 58, 0);
        let due = due_alerts(&[fajr], before_midnight, 10, ALERT_WINDOW_S);
        assert_eq!(due.len(), 1);
        assert_eq!(due[0].kind, AlertKind::Pre);
        assert_eq!(due[0].prayer_key, "fajr");
    }

    #[test]
    fn per_prayer_and_master_switches_plan_the_right_actions() {
        let at = utc(2026, 11, 25, 9, 6, 0);
        let due = due_alerts(&day(), at, 0, ALERT_WINDOW_S);
        let adhan = due.into_iter().next().unwrap();

        let mut settings = AdhanSettings::default();
        settings.prayers.insert(
            "dhuhr".into(),
            PrayerAlert {
                adhan: true,
                notify: false,
            },
        );
        let plan = plan_alert(adhan.clone(), &settings).unwrap();
        assert!(plan.sound);
        assert!(!plan.toast);
        assert!(plan.silent_toast, "silent flag follows the sound switch");

        settings.prayers.insert(
            "dhuhr".into(),
            PrayerAlert {
                adhan: false,
                notify: false,
            },
        );
        assert!(plan_alert(adhan.clone(), &settings).is_none());

        settings.enabled = false;
        assert!(plan_alert(adhan, &settings).is_none());
    }

    #[test]
    fn pre_alert_respects_master_and_per_prayer_switches() {
        let at = utc(2026, 11, 25, 8, 55, 0); // 10 minutes before Dhuhr
        let pre = due_alerts(&day(), at, 10, ALERT_WINDOW_S)
            .into_iter()
            .find(|alert| alert.kind == AlertKind::Pre)
            .unwrap();
        let settings = AdhanSettings {
            pre_alert_enabled: true,
            ..AdhanSettings::default()
        };
        assert!(plan_alert(pre.clone(), &settings).unwrap().toast);

        let off = AdhanSettings {
            pre_alert_enabled: false,
            ..AdhanSettings::default()
        };
        assert!(plan_alert(pre.clone(), &off).is_none());

        let mut muted = settings.clone();
        muted.prayers.insert(
            "dhuhr".into(),
            PrayerAlert {
                adhan: true,
                notify: false,
            },
        );
        assert!(plan_alert(pre, &muted).is_none());
    }

    #[test]
    fn dst_changes_the_local_offsets_but_keeps_prayer_order() {
        let settings = WorshipSettings {
            latitude: 40.7128,
            longitude: -74.006,
            timezone: "America/New_York".into(),
            method: "northAmerica".into(),
            configured: true,
            ..WorshipSettings::default()
        };
        // US DST starts 2026-03-08 and ends 2026-11-01.
        let winter = worship::prayer_day(
            &settings,
            chrono::NaiveDate::from_ymd_opt(2026, 3, 7).unwrap(),
            utc(2026, 3, 7, 17, 0, 0),
        )
        .unwrap();
        let summer = worship::prayer_day(
            &settings,
            chrono::NaiveDate::from_ymd_opt(2026, 3, 9).unwrap(),
            utc(2026, 3, 9, 16, 0, 0),
        )
        .unwrap();
        assert!(winter.times[0].iso.contains("-05:00"));
        assert!(summer.times[0].iso.contains("-04:00"));
        assert!(winter
            .times
            .windows(2)
            .all(|pair| pair[0].iso <= pair[1].iso));
        assert!(summer
            .times
            .windows(2)
            .all(|pair| pair[0].iso <= pair[1].iso));
    }

    #[test]
    fn tray_text_includes_name_time_and_countdown() {
        let next = prayer("asr", "العصر", "2026-11-25T15:10:00+03:00");
        let text = format_tray_text(&next, 2 * 3600 + 14 * 60, "ar");
        assert!(text.contains("العصر"));
        assert!(text.contains("15:10"));
        assert!(text.contains("2س 14د"));

        let english = format_tray_text(&next, 14 * 60, "en");
        assert!(english.contains("Next prayer: Asr"));
        assert!(english.contains("15:10"));
        assert!(english.contains("14m"));
    }

    #[test]
    fn locale_labels_and_prayer_names_switch() {
        assert_eq!(prayer_label("ar", "fajr", "الفجر"), "الفجر");
        assert_eq!(prayer_label("en", "fajr", "الفجر"), "Fajr");
        assert_eq!(prayer_label("en", "maghrib", "المغرب"), "Maghrib");
    }
}
