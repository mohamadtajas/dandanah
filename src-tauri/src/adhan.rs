use crate::commands::AppState;
use crate::db::Database;
use crate::worship::{self, PrayerTime, WorshipSettings};
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
const CLOSE_TO_TRAY_KEY: &str = "desktop.closeToTray";
const PRAYERS: [&str; 5] = ["fajr", "dhuhr", "asr", "maghrib", "isha"];
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
            prayers: PRAYERS
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
        self.prayers.retain(|key, _| PRAYERS.contains(&key.as_str()));
        for key in PRAYERS {
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
        if !PRAYERS.contains(&prayer.key.as_str()) {
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
                "{}:{}:{}",
                alert.kind.as_str(),
                alert.date,
                alert.prayer_key
            );
            if self.fired.insert(key) {
                fresh.push(alert);
            }
        }
        // Keep the set tiny on long-running sessions.
        if self.fired.len() > 100 {
            let keep_after = (now - ChronoDuration::days(2)).format("%Y-%m-%d").to_string();
            self.fired.retain(|key| {
                key.split(':')
                    .nth(1)
                    .map(|date| date >= keep_after.as_str())
                    .unwrap_or(false)
            });
        }
        fresh
    }
}

pub fn format_tray_text(next: &PrayerTime, remaining_s: i64) -> String {
    let minutes = if remaining_s <= 0 {
        0
    } else {
        (remaining_s + 59) / 60
    };
    let left = if minutes >= 60 {
        format!("{}س {}د", minutes / 60, minutes % 60)
    } else {
        format!("{minutes}د")
    };
    format!(
        "الصلاة القادمة: {} · {} — بعد {}",
        next.name, next.time, left
    )
}

#[derive(Default)]
pub struct TrayHandles {
    pub next_prayer: parking_lot::Mutex<Option<MenuItem<tauri::Wry>>>,
    pub last_text: parking_lot::Mutex<String>,
}

fn update_tray(app: &AppHandle, next: Option<&PrayerTime>, remaining_s: i64) {
    let text = match next {
        Some(prayer) => format_tray_text(prayer, remaining_s),
        None => "الصلاة القادمة: —".to_string(),
    };
    let handles = app.state::<TrayHandles>();
    let mut last = handles.last_text.lock();
    if *last != text {
        if let Some(item) = handles.next_prayer.lock().as_ref() {
            let _ = item.set_text(&text);
        }
        if let Some(tray) = app.tray_by_id("main") {
            let _ = tray.set_tooltip(Some(&format!("سَكينة — {text}")));
        }
        *last = text;
    }
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AdhanPlayback {
    pub prayer: String,
    pub name: String,
    pub volume: f64,
}

fn notify(app: &AppHandle, title: &str, body: &str) {
    let _ = app
        .notification()
        .builder()
        .title(title)
        .body(body)
        .show();
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
    let now = Utc::now();

    if !settings.configured {
        update_tray(app, None, 0);
        return;
    }

    let date = now.with_timezone(&settings.timezone()).date_naive();
    let Ok(day) = worship::prayer_day(&settings, date, now) else {
        return;
    };
    update_tray(app, day.next.as_ref(), day.remaining_s);

    if !adhan.enabled {
        return;
    }
    let pre_minutes = if adhan.pre_alert_enabled {
        adhan.pre_alert_minutes
    } else {
        0
    };
    for alert in tracker.due(&day.times, now, pre_minutes) {
        let switches = adhan
            .prayers
            .get(&alert.prayer_key)
            .cloned()
            .unwrap_or_default();
        match alert.kind {
            AlertKind::Pre => {
                if switches.notify {
                    notify(
                        app,
                        &format!(
                            "بعد {} دقائق: {}",
                            alert.lead_minutes, alert.prayer_name
                        ),
                        &format!("حان وقت صلاة {} الساعة {}", alert.prayer_name, alert.time),
                    );
                }
            }
            AlertKind::Adhan => {
                if switches.notify {
                    notify(
                        app,
                        &format!("حان وقت صلاة {}", alert.prayer_name),
                        &format!("{} · {}", alert.prayer_name, alert.time),
                    );
                }
                if switches.adhan {
                    let _ = app.emit("player:command", "pause");
                    let _ = app.emit(
                        PLAY_EVENT,
                        AdhanPlayback {
                            prayer: alert.prayer_key,
                            name: alert.prayer_name,
                            volume: adhan.volume,
                        },
                    );
                }
            }
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

#[tauri::command]
pub fn set_autostart(app: AppHandle, enabled: bool) -> Result<bool, String> {
    use tauri_plugin_autostart::ManagerExt;
    let manager = app.autolaunch();
    if enabled {
        manager.enable().map_err(|error| error.to_string())?;
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

/// Settings preview: plays the bundled recording and shows the same toast the
/// scheduler would use, without touching the prayer log or schedule.
#[tauri::command]
pub fn test_adhan(app: AppHandle, state: State<'_, AppState>) -> AdhanSettings {
    let settings = load_settings(&state.db);
    notify(&app, "اختبار الأذان", "سيُسمع الأذان الآن");
    settings
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
    }

    #[test]
    fn tray_text_includes_name_time_and_countdown() {
        let next = prayer("asr", "العصر", "2026-11-25T15:10:00+03:00");
        let text = format_tray_text(&next, 2 * 3600 + 14 * 60);
        assert!(text.contains("العصر"));
        assert!(text.contains("15:10"));
        assert!(text.contains("2س 14د"));
    }
}
