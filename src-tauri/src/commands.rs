use crate::db::{Database, DownloadRow, Memorization, Playlist};
use crate::providers::{
    archive, dedupe, everyayah, matches, mp3quran, openverse, quran_text, radiobrowser, score,
    surah, surahs, Reciter, Surah, Track, TrackKind,
};
use crate::{downloads, hotkeys, library, media};
use parking_lot::Mutex;
use serde::Serialize;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tauri::{AppHandle, Manager, State};

pub struct AppState {
    pub db: Arc<Database>,
    pub http: reqwest::Client,
    /// Cancellation flags for in-flight downloads, keyed by track id.
    pub cancels: Arc<Mutex<HashMap<String, Arc<AtomicBool>>>>,
}

const RECITERS_TTL: i64 = 60 * 60 * 24; // 24h
const RADIO_TTL: i64 = 60 * 30; // 30m
const TEXT_TTL: i64 = 60 * 60 * 24 * 30; // 30d — scripture does not change

// ---------------------------------------------------------------------------
// Quran
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn get_surahs() -> Vec<Surah> {
    surahs().to_vec()
}

#[tauri::command]
pub async fn get_reciters(
    state: State<'_, AppState>,
    language: Option<String>,
) -> Result<Vec<Reciter>, String> {
    get_reciters_inner(&state, language.as_deref().unwrap_or("ar"))
        .await
        .map_err(|e| e.to_string())
}

async fn get_reciters_inner(
    state: &AppState,
    language: &str,
) -> anyhow::Result<Vec<Reciter>> {
    let key = format!("reciters:{language}");
    if let Some(cached) = state.db.cache_get(&key, RECITERS_TTL)? {
        if let Ok(list) = serde_json::from_str::<Vec<Reciter>>(&cached) {
            if !list.is_empty() {
                return Ok(list);
            }
        }
    }
    match mp3quran::fetch_reciters(&state.http, language).await {
        Ok(list) => {
            if let Ok(json) = serde_json::to_string(&list) {
                let _ = state.db.cache_put(&key, &json);
            }
            Ok(list)
        }
        Err(e) => {
            // Offline: serve a stale copy rather than an empty screen.
            if let Some((payload, _)) = state.db.stale_cache(&key)? {
                if let Ok(list) = serde_json::from_str::<Vec<Reciter>>(&payload) {
                    return Ok(list);
                }
            }
            Err(e)
        }
    }
}

#[tauri::command]
pub async fn get_moshaf_tracks(
    state: State<'_, AppState>,
    reciter_id: i64,
    moshaf_id: Option<i64>,
) -> Result<Vec<Track>, String> {
    let reciters = get_reciters_inner(&state, "ar")
        .await
        .map_err(|e| e.to_string())?;
    let reciter = reciters
        .into_iter()
        .find(|r| r.id == reciter_id)
        .ok_or_else(|| "reciter not found".to_string())?;

    let tracks = reciter
        .moshafs
        .iter()
        .filter(|m| moshaf_id.is_none() || Some(m.id) == moshaf_id)
        .flat_map(|m| mp3quran::moshaf_tracks(&reciter, m))
        .collect();
    Ok(tracks)
}

#[tauri::command]
pub async fn get_quran_radios(state: State<'_, AppState>) -> Result<Vec<Track>, String> {
    let key = "mp3quran:radios";
    if let Some(cached) = state.db.cache_get(key, RECITERS_TTL).map_err(|e| e.to_string())? {
        if let Ok(list) = serde_json::from_str::<Vec<Track>>(&cached) {
            if !list.is_empty() {
                return Ok(list);
            }
        }
    }
    let radios = mp3quran::fetch_radios(&state.http)
        .await
        .map_err(|e| e.to_string())?;
    let tracks: Vec<Track> = radios.iter().map(mp3quran::radio_track).collect();
    if let Ok(json) = serde_json::to_string(&tracks) {
        let _ = state.db.cache_put(key, &json);
    }
    Ok(tracks)
}

// ---------------------------------------------------------------------------
// Quran — ayah by ayah
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn get_ayah_reciters() -> Vec<everyayah::AyahReciter> {
    everyayah::reciters().to_vec()
}

/// The per-ayah queue for one surah. Text is fetched separately so playback can
/// start before the (larger) text payload arrives.
#[tauri::command]
pub fn get_ayah_tracks(surah_number: u16, reciter_id: String) -> Result<Vec<Track>, String> {
    let reciter =
        everyayah::reciter(&reciter_id).ok_or_else(|| format!("unknown reciter: {reciter_id}"))?;
    if surah(surah_number).is_none() {
        return Err(format!("unknown surah: {surah_number}"));
    }
    Ok(everyayah::ayah_tracks(surah_number, reciter.id, reciter.name))
}

#[tauri::command]
pub async fn get_surah_text(
    state: State<'_, AppState>,
    surah_number: u16,
    translation: Option<bool>,
) -> Result<Vec<quran_text::Ayah>, String> {
    let translation = translation.unwrap_or(false);
    let key = format!("text:{surah_number}:{}", if translation { "en" } else { "ar" });

    if let Some(cached) = state
        .db
        .cache_get(&key, TEXT_TTL)
        .map_err(|e| e.to_string())?
    {
        if let Ok(ayahs) = serde_json::from_str::<Vec<quran_text::Ayah>>(&cached) {
            if !ayahs.is_empty() {
                return Ok(ayahs);
            }
        }
    }

    match quran_text::fetch_surah(&state.http, surah_number, translation).await {
        Ok(ayahs) => {
            if let Ok(json) = serde_json::to_string(&ayahs) {
                let _ = state.db.cache_put(&key, &json);
            }
            Ok(ayahs)
        }
        Err(e) => {
            if let Some((payload, _)) = state.db.stale_cache(&key).map_err(|e| e.to_string())? {
                if let Ok(ayahs) = serde_json::from_str::<Vec<quran_text::Ayah>>(&payload) {
                    return Ok(ayahs);
                }
            }
            Err(e.to_string())
        }
    }
}

// ---------------------------------------------------------------------------
// Hifz: memorisation marks + resume position
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn get_memorized(
    state: State<'_, AppState>,
    surah_number: u16,
) -> Result<Vec<u16>, String> {
    state
        .db
        .get_memorized(surah_number)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn save_memorized(
    state: State<'_, AppState>,
    surah_number: u16,
    memorized: Vec<u16>,
) -> Result<(), String> {
    state
        .db
        .save_memorized(surah_number, &memorized)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_memorization(state: State<'_, AppState>) -> Result<Vec<Memorization>, String> {
    state.db.all_memorization().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_position(
    state: State<'_, AppState>,
    surah_number: u16,
    reciter_id: String,
) -> Result<Option<u16>, String> {
    state
        .db
        .get_position(surah_number, &reciter_id)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn save_position(
    state: State<'_, AppState>,
    surah_number: u16,
    reciter_id: String,
    last_ayah: u16,
) -> Result<(), String> {
    state
        .db
        .save_position(surah_number, &reciter_id, last_ayah)
        .map_err(|e| e.to_string())
}

// ---------------------------------------------------------------------------
// Radio
// ---------------------------------------------------------------------------

#[tauri::command]
pub async fn get_radios(
    state: State<'_, AppState>,
    limit: Option<u32>,
    country: Option<String>,
    tag: Option<String>,
) -> Result<Vec<Track>, String> {
    let limit = limit.unwrap_or(60).clamp(1, 200);
    let country = country.unwrap_or_default();
    let tag = tag.unwrap_or_default();
    let key = format!("radio:{country}:{tag}:{limit}");

    if let Some(cached) = state.db.cache_get(&key, RADIO_TTL).map_err(|e| e.to_string())? {
        if let Ok(list) = serde_json::from_str::<Vec<Track>>(&cached) {
            return Ok(list);
        }
    }
    let tracks = radiobrowser::popular(
        &state.http,
        limit,
        if country.is_empty() { None } else { Some(&country) },
        if tag.is_empty() { None } else { Some(&tag) },
    )
    .await
    .map_err(|e| e.to_string())?;

    if let Ok(json) = serde_json::to_string(&tracks) {
        let _ = state.db.cache_put(&key, &json);
    }
    Ok(tracks)
}

// ---------------------------------------------------------------------------
// Unified search
// ---------------------------------------------------------------------------

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SearchResults {
    pub reciters: Vec<Reciter>,
    pub surahs: Vec<Surah>,
    pub tracks: Vec<Track>,
}

#[tauri::command]
pub async fn search(
    state: State<'_, AppState>,
    query: String,
    kinds: Option<Vec<String>>,
) -> Result<SearchResults, String> {
    let q = query.trim().to_string();
    if q.is_empty() {
        return Ok(SearchResults {
            reciters: vec![],
            surahs: vec![],
            tracks: vec![],
        });
    }
    let kinds = kinds.unwrap_or_default();
    let wants = |k: &str| kinds.is_empty() || kinds.iter().any(|x| x == k);

    let (reciters_res, radio_res) = tokio::join!(
        async {
            if wants(TrackKind::Quran.as_str()) || wants(TrackKind::Anasheed.as_str()) {
                get_reciters_inner(&state, "ar").await.ok()
            } else {
                None
            }
        },
        async {
            if wants(TrackKind::Radio.as_str()) || wants(TrackKind::Music.as_str()) {
                radiobrowser::search(&state.http, &q, 20, None).await.ok()
            } else {
                None
            }
        }
    );

    let mut scored = reciters_res
        .unwrap_or_default()
        .into_iter()
        .filter_map(|r| {
            let s = score(&q, &r.name);
            (s >= 0.55).then_some((s, r))
        })
        .collect::<Vec<_>>();

    scored.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap_or(std::cmp::Ordering::Equal));

    let mut reciters: Vec<Reciter> = scored.into_iter().take(12).map(|(_, r)| r).collect();
    reciters.truncate(12);

    // Surah names are searched too, so "الكهف" lands on the right place.
    let surah_hits: Vec<Surah> = surahs()
        .iter()
        .filter(|s| {
            matches(&q, &s.name)
                || matches(&q, &s.english_name)
                || q == s.number.to_string()
        })
        .take(6)
        .cloned()
        .collect();

    let tracks = dedupe(radio_res.unwrap_or_default());

    Ok(SearchResults {
        reciters,
        surahs: surah_hits,
        tracks,
    })
}

// ---------------------------------------------------------------------------
// Creative Commons catalogue
// ---------------------------------------------------------------------------

/// Cross-provider search for free music (Openverse) and archive.org audio
/// (anasheed and public-domain recordings). Sections are `all`, `music` or
/// `anasheed`.
#[tauri::command]
pub async fn explore_cc(
    state: State<'_, AppState>,
    section: Option<String>,
    query: Option<String>,
    limit: Option<u32>,
) -> Result<Vec<Track>, String> {
    let section = section.unwrap_or_else(|| "all".into()).to_ascii_lowercase();
    let q = query.unwrap_or_default().trim().to_string();
    let limit = limit.unwrap_or(24).clamp(1, 60);
    let client = &state.http;

    let (music, anasheed) = tokio::join!(
        async {
            if section == "anasheed" {
                return Ok(Vec::new());
            }
            let text = if q.is_empty() { "arabic" } else { q.as_str() };
            let take = if section == "music" { limit.min(20) } else { (limit / 2 + 6).min(20) };
            openverse::search(client, text, take).await
        },
        async {
            if section == "music" {
                return Ok(Vec::new());
            }
            let text = if q.is_empty() { "" } else { q.as_str() };
            let items = if section == "anasheed" { 5 } else { 2 };
            archive::search(client, text, items, TrackKind::Anasheed).await
        }
    );

    let mut tracks = Vec::new();
    let mut failures = Vec::new();
    match music {
        Ok(mut list) => tracks.append(&mut list),
        Err(error) => failures.push(format!("openverse: {error}")),
    }
    match anasheed {
        Ok(mut list) => tracks.append(&mut list),
        Err(error) => failures.push(format!("archive: {error}")),
    }

    if tracks.is_empty() && !failures.is_empty() {
        return Err(failures.join("; "));
    }
    Ok(dedupe(tracks))
}

// ---------------------------------------------------------------------------
// Library / history
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn get_recent(state: State<'_, AppState>, limit: Option<u32>) -> Result<Vec<Track>, String> {
    state
        .db
        .recent(limit.unwrap_or(20))
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn record_play(state: State<'_, AppState>, track: Track) -> Result<(), String> {
    state.db.record_play(&track).map_err(|e| e.to_string())
}

// ---------------------------------------------------------------------------
// Favourites
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn get_favorites(state: State<'_, AppState>, limit: Option<u32>) -> Result<Vec<Track>, String> {
    state
        .db
        .favorites(limit.unwrap_or(200))
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_favorite_ids(state: State<'_, AppState>) -> Result<Vec<String>, String> {
    state.db.favorite_ids().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn add_favorite(state: State<'_, AppState>, track: Track) -> Result<(), String> {
    state.db.add_favorite(&track).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn remove_favorite(state: State<'_, AppState>, track_id: String) -> Result<(), String> {
    state
        .db
        .remove_favorite(&track_id)
        .map_err(|e| e.to_string())
}

// ---------------------------------------------------------------------------
// Playlists
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn get_playlists(state: State<'_, AppState>) -> Result<Vec<Playlist>, String> {
    state.db.playlists().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn create_playlist(state: State<'_, AppState>, name: String) -> Result<Playlist, String> {
    let name = name.trim();
    if name.is_empty() {
        return Err("playlist name is required".into());
    }
    state
        .db
        .create_playlist(&name.chars().take(80).collect::<String>())
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn rename_playlist(
    state: State<'_, AppState>,
    playlist_id: String,
    name: String,
) -> Result<(), String> {
    let name = name.trim();
    if name.is_empty() {
        return Err("playlist name is required".into());
    }
    state
        .db
        .rename_playlist(&playlist_id, &name.chars().take(80).collect::<String>())
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn delete_playlist(state: State<'_, AppState>, playlist_id: String) -> Result<(), String> {
    state
        .db
        .delete_playlist(&playlist_id)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_playlist_tracks(
    state: State<'_, AppState>,
    playlist_id: String,
) -> Result<Vec<Track>, String> {
    state
        .db
        .playlist_tracks(&playlist_id)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn add_to_playlist(
    state: State<'_, AppState>,
    playlist_id: String,
    track: Track,
) -> Result<(), String> {
    state
        .db
        .add_to_playlist(&playlist_id, &track)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn remove_from_playlist(
    state: State<'_, AppState>,
    playlist_id: String,
    track_id: String,
) -> Result<(), String> {
    state
        .db
        .remove_from_playlist(&playlist_id, &track_id)
        .map_err(|e| e.to_string())
}

// ---------------------------------------------------------------------------
// Downloads
// ---------------------------------------------------------------------------

#[tauri::command]
pub async fn start_download(
    app: AppHandle,
    state: State<'_, AppState>,
    track: Track,
) -> Result<Option<String>, String> {
    let cancel = Arc::new(AtomicBool::new(false));
    state
        .cancels
        .lock()
        .insert(track.id.clone(), cancel.clone());

    let artwork_dir = app
        .path()
        .app_data_dir()
        .map(|dir| dir.join("artwork"))
        .unwrap_or_else(|_| std::env::temp_dir().join("dandanah-artwork"));

    let result = downloads::run(
        app.clone(),
        state.http.clone(),
        state.db.clone(),
        track.clone(),
        cancel,
        artwork_dir,
    )
    .await;

    state.cancels.lock().remove(&track.id);
    result.map_err(|error| error.to_string())
}

#[tauri::command]
pub fn cancel_download(state: State<'_, AppState>, track_id: String) -> bool {
    match state.cancels.lock().get(&track_id) {
        Some(flag) => {
            flag.store(true, Ordering::Relaxed);
            true
        }
        None => false,
    }
}

#[tauri::command]
pub fn get_downloads(state: State<'_, AppState>) -> Result<Vec<DownloadRow>, String> {
    state.db.downloads().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn delete_download(state: State<'_, AppState>, track_id: String) -> Result<(), String> {
    let path = state
        .db
        .delete_download(&track_id)
        .map_err(|e| e.to_string())?;
    if let Some(path) = path {
        let _ = std::fs::remove_file(path);
    }
    Ok(())
}

// ---------------------------------------------------------------------------
// Local import
// ---------------------------------------------------------------------------

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportSummary {
    pub imported: usize,
    pub scanned_folders: usize,
    pub truncated: bool,
}

#[tauri::command]
pub async fn import_folder(
    app: AppHandle,
    state: State<'_, AppState>,
    paths: Vec<String>,
) -> Result<ImportSummary, String> {
    if paths.is_empty() {
        return Err("no folder selected".into());
    }
    let db = state.db.clone();
    let paths = paths.clone();
    let artwork_dir = app
        .path()
        .app_data_dir()
        .ok()
        .map(|dir| dir.join("artwork"));

    tauri::async_runtime::spawn_blocking(move || {
        let mut imported = 0usize;
        let mut truncated = false;
        for raw in &paths {
            let root = std::path::PathBuf::from(raw);
            if !root.is_dir() {
                continue;
            }
            let outcome = library::scan_folder(&root, 5000, artwork_dir.as_deref());
            truncated |= outcome.truncated;
            for track in &outcome.tracks {
                if db.upsert_track(track).is_ok() {
                    imported += 1;
                }
            }
        }
        ImportSummary {
            imported,
            scanned_folders: paths.len(),
            truncated,
        }
    })
    .await
    .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_local_tracks(state: State<'_, AppState>) -> Result<Vec<Track>, String> {
    state.db.local_tracks().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn forget_local_track(state: State<'_, AppState>, track_id: String) -> Result<(), String> {
    state
        .db
        .forget_local_track(&track_id)
        .map_err(|e| e.to_string())
}

// ---------------------------------------------------------------------------
// Global shortcuts
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn get_hotkeys(state: State<'_, AppState>) -> hotkeys::HotkeyMap {
    hotkeys::load(&state.db)
}

#[tauri::command]
pub fn set_hotkeys(
    app: AppHandle,
    state: State<'_, AppState>,
    hotkeys: hotkeys::HotkeyMap,
) -> Result<hotkeys::HotkeyMap, String> {
    let previous = hotkeys::load(&state.db);
    if let Err(error) = hotkeys::apply(&app, &hotkeys) {
        // Roll back so the user is never left without working shortcuts.
        let _ = hotkeys::apply(&app, &previous);
        return Err(error);
    }
    if let Err(error) = hotkeys::save(&state.db, &hotkeys) {
        let _ = hotkeys::apply(&app, &previous);
        return Err(error);
    }
    Ok(hotkeys)
}

// ---------------------------------------------------------------------------
// Windows media session
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn update_now_playing(app: AppHandle, info: media::NowPlaying) {
    media::update(&app, info);
}

// ---------------------------------------------------------------------------
// Settings & metadata
// ---------------------------------------------------------------------------

#[tauri::command]
pub fn get_settings(state: State<'_, AppState>) -> Result<Vec<(String, String)>, String> {
    state.db.all_settings().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn set_setting(state: State<'_, AppState>, key: String, value: String) -> Result<(), String> {
    state.db.set_setting(&key, &value).map_err(|e| e.to_string())
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AppInfo {
    pub version: String,
    pub providers: Vec<&'static str>,
    pub countries: Vec<&'static str>,
}

#[tauri::command]
pub fn app_info() -> AppInfo {
    AppInfo {
        version: env!("CARGO_PKG_VERSION").to_string(),
        providers: vec![
            mp3quran::PROVIDER,
            "mp3quran-radio",
            radiobrowser::PROVIDER,
            everyayah::PROVIDER,
            openverse::PROVIDER,
            archive::PROVIDER,
        ],
        countries: radiobrowser::ARAB_COUNTRIES.to_vec(),
    }
}
