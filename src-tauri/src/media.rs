use serde::Deserialize;
use souvlaki::{
    MediaControlEvent, MediaControls, MediaMetadata, MediaPlayback, MediaPosition, PlatformConfig,
};
use std::cell::RefCell;
use std::ffi::c_void;
use std::time::Duration;
use tauri::{AppHandle, Emitter, Manager};

thread_local! {
    /// SMTC objects are WinRT interfaces; keeping them on the main thread avoids
    /// sending them across apartments.
    static CONTROLS: RefCell<Option<MediaControls>> = const { RefCell::new(None) };
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NowPlaying {
    pub title: String,
    pub artist: String,
    #[serde(default)]
    pub album: Option<String>,
    #[serde(default)]
    pub duration_s: Option<f64>,
    #[serde(default)]
    pub position_s: f64,
    #[serde(default)]
    pub playing: bool,
    #[serde(default)]
    pub artwork_url: Option<String>,
}

/// Registers a media session with Windows so the lock screen, the volume
/// flyout and hardware media keys control Dandanah.
pub fn init(app: &AppHandle) -> bool {
    let Some(window) = app.get_webview_window("main") else {
        return false;
    };
    let Ok(hwnd) = window.hwnd() else {
        return false;
    };

    let config = PlatformConfig {
        display_name: "Dandanah",
        dbus_name: "app.dandanah.desktop",
        hwnd: Some(hwnd.0 as isize as *mut c_void),
    };

    let mut controls = match MediaControls::new(config) {
        Ok(controls) => controls,
        Err(error) => {
            eprintln!("media controls unavailable: {error}");
            return false;
        }
    };

    let handle = app.clone();
    let attached = controls.attach(move |event| match event {
        MediaControlEvent::Play => {
            let _ = handle.emit("player:command", "play");
        }
        MediaControlEvent::Pause => {
            let _ = handle.emit("player:command", "pause");
        }
        MediaControlEvent::Toggle => {
            let _ = handle.emit("player:command", "toggle");
        }
        MediaControlEvent::Next => {
            let _ = handle.emit("player:command", "next");
        }
        MediaControlEvent::Previous => {
            let _ = handle.emit("player:command", "previous");
        }
        MediaControlEvent::Stop => {
            let _ = handle.emit("player:command", "stop");
        }
        MediaControlEvent::SetPosition(position) => {
            let _ = handle.emit("player:seek", position.0.as_secs_f64());
        }
        MediaControlEvent::Raise => {
            show_main(&handle);
        }
        _ => {}
    });

    if let Err(error) = attached {
        eprintln!("media controls attach failed: {error}");
        return false;
    }

    CONTROLS.with(|cell| *cell.borrow_mut() = Some(controls));
    true
}

/// Pushes the current track and playback state to the OS session.
pub fn update(app: &AppHandle, info: NowPlaying) {
    let _ = app.run_on_main_thread(move || {
        CONTROLS.with(|cell| {
            let mut guard = cell.borrow_mut();
            let Some(controls) = guard.as_mut() else {
                return;
            };

            let duration = info.duration_s.filter(|d| *d > 0.0).map(Duration::from_secs_f64);
            let artist = if info.artist.is_empty() {
                None
            } else {
                Some(info.artist.as_str())
            };
            let album = info.album.as_deref();
            let cover = info
                .artwork_url
                .as_deref()
                .filter(|url| url.starts_with("http"));

            let _ = controls.set_metadata(MediaMetadata {
                title: Some(info.title.as_str()),
                artist,
                album,
                cover_url: cover,
                duration,
            });

            let progress = Some(MediaPosition(Duration::from_secs_f64(
                info.position_s.max(0.0),
            )));
            let playback = if info.playing {
                MediaPlayback::Playing { progress }
            } else {
                MediaPlayback::Paused { progress }
            };
            let _ = controls.set_playback(playback);
        });
    });
}

pub fn show_main(app: &AppHandle) {
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.show();
        let _ = window.unminimize();
        let _ = window.set_focus();
    }
}

pub fn hide_main(app: &AppHandle) {
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.hide();
    }
}
