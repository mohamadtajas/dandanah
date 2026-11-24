mod commands;
mod db;
mod downloads;
mod library;
mod providers;

use commands::AppState;
use db::Database;
use std::sync::Arc;
use tauri::Manager;

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, _argv, _cwd| {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.show();
                let _ = window.unminimize();
                let _ = window.set_focus();
            }
        }))
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_process::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .setup(|app| {
            let data_dir = app.path().app_data_dir()?;
            let db = Database::open(&data_dir.join("dandanah.db"))?;

            let http = reqwest::Client::builder()
                .user_agent(concat!(
                    "Dandanah/",
                    env!("CARGO_PKG_VERSION"),
                    " (+https://github.com/dandanah/dandanah)"
                ))
                .connect_timeout(std::time::Duration::from_secs(10))
                .timeout(std::time::Duration::from_secs(30))
                .build()?;

            app.manage(AppState {
                db: Arc::new(db),
                http,
            });
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
            commands::get_downloads,
            commands::delete_download,
            commands::import_folder,
            commands::get_local_tracks,
            commands::forget_local_track,
            commands::get_settings,
            commands::set_setting,
            commands::app_info,
        ])
        .run(tauri::generate_context!())
        .expect("error while running the Dandanah application");
}
