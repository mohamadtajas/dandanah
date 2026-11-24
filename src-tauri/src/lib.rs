mod commands;
mod db;
mod downloads;
mod hotkeys;
mod library;
mod media;
mod migrate;
mod providers;
mod worship;

use commands::AppState;
use db::Database;
use std::sync::Arc;
use tauri::menu::{Menu, MenuItem, PredefinedMenuItem};
use tauri::tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent};
use tauri::{Emitter, Manager};

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, _argv, _cwd| {
            media::show_main(app);
        }))
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_process::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .setup(|app| {
            let data_dir = app.path().app_data_dir()?;
            match migrate::migrate_legacy(&data_dir) {
                Ok(Some(old_dir)) => {
                    eprintln!("migrated library data from {}", old_dir.display());
                }
                Ok(None) => {}
                Err(error) => {
                    eprintln!("legacy data migration failed: {error:#}");
                }
            }
            let db = Database::open(&data_dir.join(migrate::NEW_DB))?;

            let http = reqwest::Client::builder()
                .user_agent(concat!(
                    "Sakeenah/",
                    env!("CARGO_PKG_VERSION"),
                    " (+https://github.com/mohamadtajas/sakeenah)"
                ))
                .connect_timeout(std::time::Duration::from_secs(10))
                .timeout(std::time::Duration::from_secs(30))
                .build()?;

            app.manage(AppState {
                db: Arc::new(db),
                http,
                cancels: Arc::new(parking_lot::Mutex::new(std::collections::HashMap::new())),
            });

            if !media::init(app.handle()) {
                eprintln!("SMTC unavailable; hardware media keys will not control the app");
            }

            build_tray(app.handle())?;

            let bindings = hotkeys::load(&app.state::<AppState>().db);
            if let Err(error) = hotkeys::apply(app.handle(), &bindings) {
                eprintln!("could not register global shortcuts: {error}");
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::get_surahs,
            commands::get_reciters,
            commands::get_moshaf_tracks,
            commands::get_ayah_reciters,
            commands::get_ayah_tracks,
            commands::get_surah_text,
            commands::get_memorized,
            commands::save_memorized,
            commands::get_memorization,
            commands::get_position,
            commands::save_position,
            commands::get_quran_radios,
            commands::get_radios,
            commands::search,
            commands::explore_cc_stream,
            commands::get_recent,
            commands::record_play,
            commands::get_favorites,
            commands::get_favorite_ids,
            commands::add_favorite,
            commands::remove_favorite,
            commands::get_playlists,
            commands::create_playlist,
            commands::rename_playlist,
            commands::delete_playlist,
            commands::get_playlist_tracks,
            commands::add_to_playlist,
            commands::remove_from_playlist,
            commands::start_download,
            commands::cancel_download,
            commands::get_downloads,
            commands::delete_download,
            commands::import_folder,
            commands::get_local_tracks,
            commands::forget_local_track,
            commands::get_hotkeys,
            commands::set_hotkeys,
            commands::update_now_playing,
            commands::get_settings,
            commands::set_setting,
            commands::app_info,
            commands::get_worship_settings,
            commands::set_worship_settings,
            commands::get_prayer_day,
            commands::get_hijri_date,
            commands::get_qibla,
            commands::get_prayer_log,
            commands::get_prayer_logs,
            commands::set_prayer_done,
            commands::set_prayer_excused,
            commands::get_prayer_streak,
        ])
        .run(tauri::generate_context!())
        .expect("error while running the Sakeenah application");
}

fn build_tray(app: &tauri::AppHandle) -> tauri::Result<()> {
    let show = MenuItem::with_id(app, "show", "إظهار Sakeenah", true, None::<&str>)?;
    let hide = MenuItem::with_id(app, "hide", "إخفاء النافذة", true, None::<&str>)?;
    let toggle = MenuItem::with_id(app, "toggle", "تشغيل / إيقاف", true, None::<&str>)?;
    let previous = MenuItem::with_id(app, "previous", "السابق", true, None::<&str>)?;
    let next = MenuItem::with_id(app, "next", "التالي", true, None::<&str>)?;
    let quit = MenuItem::with_id(app, "quit", "خروج", true, None::<&str>)?;
    let menu = Menu::with_items(
        app,
        &[
            &show,
            &hide,
            &toggle,
            &previous,
            &next,
            &PredefinedMenuItem::separator(app)?,
            &quit,
        ],
    )?;

    let mut builder = TrayIconBuilder::with_id("main")
        .tooltip("سَكينة · Sakeenah")
        .menu(&menu)
        .show_menu_on_left_click(false)
        .on_menu_event(|app, event| match event.id.as_ref() {
            "show" => media::show_main(app),
            "hide" => media::hide_main(app),
            "toggle" => {
                let _ = app.emit("player:command", "toggle");
            }
            "previous" => {
                let _ = app.emit("player:command", "previous");
            }
            "next" => {
                let _ = app.emit("player:command", "next");
            }
            "quit" => app.exit(0),
            _ => {}
        })
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event
            {
                media::show_main(tray.app_handle());
            }
        });

    if let Some(icon) = app.default_window_icon() {
        builder = builder.icon(icon.clone());
    }
    builder.build(app)?;
    Ok(())
}
