use crate::db::Database;
use crate::providers::{
    dedupe, mp3quran, radiobrowser, similarity, surahs, Reciter, Surah, Track, TrackKind,
};
use serde::Serialize;
use std::sync::Arc;
use tauri::State;

pub struct AppState {
    pub db: Arc<Database>,
    pub http: reqwest::Client,
}

const RECITERS_TTL: i64 = 60 * 60 * 24; // 24h
const RADIO_TTL: i64 = 60 * 30; // 30m

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

    let reciters = reciters_res
        .unwrap_or_default()
        .into_iter()
        .filter_map(|r| {
            let score = similarity(&r.name, &q);
            let contains = crate::providers::normalize_arabic(&r.name)
                .contains(&crate::providers::normalize_arabic(&q));
            (score > 0.34 || contains).then_some((score, r))
        })
        .collect::<Vec<_>>();

    let mut reciters: Vec<Reciter> = reciters.into_iter().map(|(_, r)| r).collect();
    reciters.truncate(12);

    let tracks = dedupe(radio_res.unwrap_or_default());

    Ok(SearchResults { reciters, tracks })
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
        ],
        countries: radiobrowser::ARAB_COUNTRIES.to_vec(),
    }
}
