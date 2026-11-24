use crate::db::{
    Database, DownloadRow, Memorization, Playlist, QuranBookmark, ReaderPosition,
};
use crate::quran::{self, Juz, Page};
use crate::providers::{
    archive, audius, dedupe, everyayah, matches, mp3quran, openverse, quran_text, quranicaudio,
    radiobrowser, score, surah, surahs, Reciter, Surah, Track, TrackKind,
};
use crate::adhkar::{self, AdhkarDay, AdhkarProgress, AdhkarStreak};
use crate::worship::{self, HijriDate, PrayerDay, PrayerLog, QiblaInfo, Streak, WorshipSettings};
use crate::{downloads, hotkeys, library, media};
use parking_lot::Mutex;
use serde::Serialize;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tauri::{AppHandle, Emitter, Manager, State};

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
    // v2: the cache now holds mp3quran + QuranicAudio merged.
    let key = format!("reciters:v2:{language}");
    if let Some(cached) = state.db.cache_get(&key, RECITERS_TTL)? {
        if let Ok(list) = serde_json::from_str::<Vec<Reciter>>(&cached) {
            if !list.is_empty() {
                return Ok(list);
            }
        }
    }

    let (mp3quran_result, quranicaudio_result) = tokio::join!(
        mp3quran::fetch_reciters(&state.http, language),
        quranicaudio::fetch_reciters(&state.http),
    );

    let mut list = Vec::new();
    let mut errors: Vec<String> = Vec::new();
    match mp3quran_result {
        Ok(mut reciters) => list.append(&mut reciters),
        Err(error) => {
            eprintln!("reciters: mp3quran failed: {error:#}");
            errors.push(format!("mp3quran: {error:#}"));
        }
    }
    match quranicaudio_result {
        Ok(mut reciters) => list.append(&mut reciters),
        Err(error) => {
            eprintln!("reciters: quranicaudio failed: {error:#}");
            errors.push(format!("quranicaudio: {error:#}"));
        }
    }

    if !list.is_empty() {
        list.sort_by(|a, b| a.name.cmp(&b.name));
        // Never cache a partial catalogue for a day: a transient failure would
        // hide a whole source until the TTL expires.
        if errors.is_empty() {
            if let Ok(json) = serde_json::to_string(&list) {
                let _ = state.db.cache_put(&key, &json);
            }
        }
        return Ok(list);
    }

    // Offline: serve a stale copy rather than an empty screen.
    if let Some((payload, _)) = state.db.stale_cache(&key)? {
        if let Ok(list) = serde_json::from_str::<Vec<Reciter>>(&payload) {
            if !list.is_empty() {
                return Ok(list);
            }
        }
    }

    Err(anyhow::anyhow!(errors.join("; ")))
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
        .flat_map(|m| {
            if reciter.id >= quranicaudio::ID_BASE {
                quranicaudio::moshaf_tracks(&reciter, m)
            } else {
                mp3quran::moshaf_tracks(&reciter, m)
            }
        })
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

/// Sahih International for one surah, cached. `None` keeps the Arabic usable
/// offline when the translation cannot be fetched.
async fn translation_for(
    db: &Database,
    client: &reqwest::Client,
    surah: u16,
) -> Option<Vec<String>> {
    let key = format!("quran-translation:v1:{surah}");
    if let Ok(Some(cached)) = db.cache_get(&key, TEXT_TTL) {
        if let Ok(list) = serde_json::from_str::<Vec<String>>(&cached) {
            if !list.is_empty() {
                return Some(list);
            }
        }
    }
    match quran_text::fetch_translation(client, surah).await {
        Ok(list) if !list.is_empty() => {
            if let Ok(json) = serde_json::to_string(&list) {
                let _ = db.cache_put(&key, &json);
            }
            Some(list)
        }
        _ => db
            .stale_cache(&key)
            .ok()
            .flatten()
            .and_then(|(payload, _)| serde_json::from_str::<Vec<String>>(&payload).ok()),
    }
}

#[tauri::command]
pub fn get_surah_text(surah_number: u16) -> Result<Vec<quran_text::Ayah>, String> {
    let ayahs = quran::surah_ayahs(surah_number);
    if ayahs.is_empty() {
        return Err(format!("surah {surah_number} not found"));
    }
    Ok(ayahs)
}

#[tauri::command]
pub fn get_juz_ayahs(juz: u16) -> Result<Vec<quran_text::Ayah>, String> {
    let ayahs = quran::juz_ayahs(juz);
    if ayahs.is_empty() {
        return Err(format!("juz {juz} not found"));
    }
    Ok(ayahs)
}

/// Translations are a separate request so the bundled Arabic never waits for
/// the network (or a VPN) when the reader opens a surah offline.
#[tauri::command]
pub async fn get_surah_translation(
    state: State<'_, AppState>,
    surah_number: u16,
) -> Result<Vec<String>, String> {
    let expected = quran::surah_meta(surah_number)
        .map(|surah| surah.ayahs as usize)
        .unwrap_or(0);
    Ok(match translation_for(&state.db, &state.http, surah_number).await {
        Some(list) if list.len() == expected => list,
        _ => Vec::new(),
    })
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct JuzTranslation {
    pub surah: u16,
    pub translations: Vec<String>,
}

#[tauri::command]
pub async fn get_juz_translation(
    state: State<'_, AppState>,
    juz: u16,
) -> Result<Vec<JuzTranslation>, String> {
    let ayahs = quran::juz_ayahs(juz);
    let mut surahs: Vec<u16> = ayahs.iter().map(|ayah| ayah.surah).collect();
    surahs.sort_unstable();
    surahs.dedup();
    if surahs.is_empty() {
        return Ok(Vec::new());
    }

    // A juz can span many surahs; fetch them together so a slow link costs one
    // timeout in total rather than one per surah.
    let mut set = tokio::task::JoinSet::new();
    for surah in surahs {
        let db = state.db.clone();
        let client = state.http.clone();
        set.spawn(async move { (surah, translation_for(&db, &client, surah).await) });
    }

    let mut out = Vec::new();
    while let Some(result) = set.join_next().await {
        if let Ok((surah, Some(list))) = result {
            let expected = quran::surah_meta(surah)
                .map(|meta| meta.ayahs as usize)
                .unwrap_or(0);
            if list.len() == expected {
                out.push(JuzTranslation {
                    surah,
                    translations: list,
                });
            }
        }
    }
    out.sort_by_key(|entry| entry.surah);
    Ok(out)
}

#[tauri::command]
pub fn get_juzs() -> Vec<Juz> {
    quran::juzs().to_vec()
}

#[tauri::command]
pub fn get_quran_pages() -> Vec<Page> {
    quran::pages().to_vec()
}

#[tauri::command]
pub fn get_daily_ayah(
    state: State<'_, AppState>,
    date: Option<String>,
) -> Result<quran_text::Ayah, String> {
    let date = match date {
        Some(raw) => chrono::NaiveDate::parse_from_str(&raw, "%Y-%m-%d")
            .map_err(|error| format!("invalid date {raw}: {error}"))?,
        None => {
            let settings = worship::load_settings(&state.db);
            local_today(&settings)
        }
    };
    quran::daily(date).ok_or_else(|| "no daily ayah available".to_string())
}

fn validate_ayah_ref(surah: u16, ayah: u16) -> Result<(), String> {
    let meta = quran::surah_meta(surah)
        .ok_or_else(|| format!("surah {surah} not found"))?;
    if ayah == 0 || ayah > meta.ayahs {
        return Err(format!("ayah {ayah} is outside surah {surah}"));
    }
    Ok(())
}

#[tauri::command]
pub fn get_quran_bookmarks(state: State<'_, AppState>) -> Result<Vec<QuranBookmark>, String> {
    state.db.quran_bookmarks().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn add_quran_bookmark(
    state: State<'_, AppState>,
    surah: u16,
    ayah: u16,
) -> Result<QuranBookmark, String> {
    validate_ayah_ref(surah, ayah)?;
    state
        .db
        .add_quran_bookmark(surah, ayah)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn remove_quran_bookmark(
    state: State<'_, AppState>,
    surah: u16,
    ayah: u16,
) -> Result<(), String> {
    state
        .db
        .remove_quran_bookmark(surah, ayah)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_reader_position(
    state: State<'_, AppState>,
) -> Result<Option<ReaderPosition>, String> {
    state.db.reader_position().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn save_reader_position(
    state: State<'_, AppState>,
    mode: String,
    juz: u16,
    surah: u16,
    ayah: u16,
) -> Result<ReaderPosition, String> {
    validate_ayah_ref(surah, ayah)?;
    if mode != "surah" && mode != "juz" {
        return Err(format!("invalid reader mode: {mode}"));
    }
    if mode == "juz" && !(1..=30).contains(&juz) {
        return Err(format!("invalid juz: {juz}"));
    }
    state
        .db
        .save_reader_position(&mode, juz, surah, ayah)
        .map_err(|e| e.to_string())
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

    let (reciters_res, radio_res, cc_tracks) = tokio::join!(
        async {
            if wants(TrackKind::Quran.as_str()) || wants(TrackKind::Anasheed.as_str()) {
                get_reciters_inner(&state, "ar").await.ok()
            } else {
                None
            }
        },
        async {
            if wants(TrackKind::Radio.as_str()) {
                radiobrowser::search(&state.http, &q, 20, None).await.ok()
            } else {
                None
            }
        },
        async {
            if !(kinds.is_empty() || wants(TrackKind::Music.as_str())) {
                return Vec::new();
            }
            let cc = async {
                let (openverse_result, audius_result) = tokio::join!(
                    openverse::search(&state.http, &q, 10),
                    audius::search(&state.http, &q, 8),
                );
                let mut list = Vec::new();
                match openverse_result {
                    Ok(mut tracks) => {
                        eprintln!("search: openverse returned {}", tracks.len());
                        list.append(&mut tracks);
                    }
                    Err(error) => eprintln!("search: openverse failed: {error}"),
                }
                match audius_result {
                    Ok(mut tracks) => {
                        eprintln!("search: audius returned {}", tracks.len());
                        list.append(&mut tracks);
                    }
                    Err(error) => eprintln!("search: audius failed: {error}"),
                }
                list
            };
            // Free sources are slower than radio; never hold the whole search
            // for more than 1.5s. Whatever arrived is merged in.
            tokio::time::timeout(Duration::from_millis(1500), cc)
                .await
                .unwrap_or_default()
        }
    );

    let mut scored = reciters_res
        .unwrap_or_default()
        .into_iter()
        .filter_map(|r| {
            let latin = r
                .english_name
                .as_deref()
                .map(|name| score(&q, name))
                .unwrap_or(0.0);
            let s = score(&q, &r.name).max(latin);
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

    let mut merged = radio_res.unwrap_or_default();
    merged.extend(cc_tracks);
    let tracks = dedupe(merged);

    Ok(SearchResults {
        reciters,
        surahs: surah_hits,
        tracks,
    })
}

// ---------------------------------------------------------------------------
// Creative Commons catalogue
// ---------------------------------------------------------------------------

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct CcBatch {
    request_id: String,
    source: String,
    tracks: Vec<Track>,
    done: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

const ARCHIVE_ITEM_TTL: i64 = 60 * 60 * 12;

fn emit_cc(app: &AppHandle, request_id: &str, source: &str, batch: anyhow::Result<Vec<Track>>) {
    let (tracks, error) = match batch {
        Ok(tracks) => (tracks, None),
        Err(error) => (Vec::new(), Some(error.to_string())),
    };
    if tracks.is_empty() && error.is_none() {
        return;
    }
    let _ = app.emit(
        "cc:batch",
        CcBatch {
            request_id: request_id.to_string(),
            source: source.to_string(),
            tracks,
            done: false,
            error,
        },
    );
}

/// Starts a progressive catalogue search. Results stream back as `cc:batch`
/// events, one source (or one archive.org item) at a time, so the UI never
/// waits for the slowest provider.
#[tauri::command]
pub async fn explore_cc_stream(
    app: AppHandle,
    state: State<'_, AppState>,
    section: Option<String>,
    query: Option<String>,
) -> Result<String, String> {
    let request_id = uuid::Uuid::new_v4().to_string();
    let section = section.unwrap_or_else(|| "all".into()).to_ascii_lowercase();
    let query = query.unwrap_or_default().trim().to_string();
    let http = state.http.clone();
    let db = state.db.clone();
    let rid = request_id.clone();

    tauri::async_runtime::spawn(async move {
        let mut tasks = tokio::task::JoinSet::new();

        if section != "anasheed" {
            let app_music = app.clone();
            let client = http.clone();
            let request = rid.clone();
            let text = if query.is_empty() {
                "arabic".to_string()
            } else {
                query.clone()
            };
            tasks.spawn(async move {
                let result = openverse::search(&client, &text, 16).await;
                emit_cc(&app_music, &request, "openverse", result);
            });

            let app_audius = app.clone();
            let client = http.clone();
            let request = rid.clone();
            let text = query.clone();
            tasks.spawn(async move {
                let result = audius::search(&client, &text, 10).await;
                emit_cc(&app_audius, &request, "audius", result);
            });
        }

        let app_archive = app.clone();
        let client = http.clone();
        let cache = db.clone();
        let request = rid.clone();
        let user_query = query.clone();
        let archive_section = section.clone();
        tasks.spawn(async move {
            let (kind, archive_query, items) = match archive_section.as_str() {
                "music" => (
                    TrackKind::Music,
                    if user_query.is_empty() {
                        "subject:(music) AND licenseurl:(*)".to_string()
                    } else {
                        format!("({user_query}) AND subject:(music) AND licenseurl:(*)")
                    },
                    2,
                ),
                "anasheed" => (
                    TrackKind::Anasheed,
                    if user_query.is_empty() {
                        "subject:(anasheed)".to_string()
                    } else {
                        user_query.clone()
                    },
                    6,
                ),
                _ => (
                    TrackKind::Anasheed,
                    if user_query.is_empty() {
                        "subject:(anasheed)".to_string()
                    } else {
                        user_query.clone()
                    },
                    3,
                ),
            };

            let items = match archive::search_items(&client, &archive_query, items).await {
                Ok(items) => items,
                Err(error) => {
                    emit_cc(&app_archive, &request, "archive", Err(error));
                    return;
                }
            };

            for item in items {
                let cache_key = format!("archive:item:{}", item.identifier);
                let cached = cache
                    .cache_get(&cache_key, ARCHIVE_ITEM_TTL)
                    .ok()
                    .flatten()
                    .and_then(|json| serde_json::from_str::<Vec<Track>>(&json).ok());

                let tracks = match cached {
                    Some(tracks) => tracks,
                    None => {
                        let fetched = tokio::time::timeout(
                            Duration::from_secs(12),
                            archive::item_tracks(&client, &item, kind),
                        )
                        .await;
                        match fetched {
                            Ok(Ok(tracks)) => {
                                if let Ok(json) = serde_json::to_string(&tracks) {
                                    let _ = cache.cache_put(&cache_key, &json);
                                }
                                tracks
                            }
                            Ok(Err(error)) => {
                                emit_cc(&app_archive, &request, "archive", Err(error));
                                continue;
                            }
                            Err(_) => continue,
                        }
                    }
                };
                emit_cc(&app_archive, &request, "archive", Ok(tracks));
            }
        });

        while tasks.join_next().await.is_some() {}
        let _ = app.emit(
            "cc:batch",
            CcBatch {
                request_id: rid,
                source: "done".into(),
                tracks: Vec::new(),
                done: true,
                error: None,
            },
        );
    });

    Ok(request_id)
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
        .unwrap_or_else(|_| std::env::temp_dir().join("sakeenah-artwork"));

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
            audius::PROVIDER,
            archive::PROVIDER,
            quranicaudio::PROVIDER,
        ],
        countries: radiobrowser::ARAB_COUNTRIES.to_vec(),
    }
}

// ---------------------------------------------------------------------------
// Worship: prayer times, Hijri date, qibla, prayer log and streak
// ---------------------------------------------------------------------------

fn local_today(settings: &WorshipSettings) -> chrono::NaiveDate {
    chrono::Utc::now()
        .with_timezone(&settings.timezone())
        .date_naive()
}

#[tauri::command]
pub fn get_worship_settings(state: State<'_, AppState>) -> WorshipSettings {
    worship::load_settings(&state.db)
}

#[tauri::command]
pub fn set_worship_settings(
    state: State<'_, AppState>,
    settings: WorshipSettings,
) -> Result<WorshipSettings, String> {
    let previous = worship::load_settings(&state.db);
    let settings = worship::merge_settings(&previous, settings);
    worship::save_settings(&state.db, &settings).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_prayer_day(
    state: State<'_, AppState>,
    date: Option<String>,
) -> Result<PrayerDay, String> {
    let settings = worship::load_settings(&state.db);
    let now = chrono::Utc::now();
    let date = match date {
        Some(raw) => chrono::NaiveDate::parse_from_str(&raw, "%Y-%m-%d")
            .map_err(|error| format!("invalid date {raw}: {error}"))?,
        None => now.with_timezone(&settings.timezone()).date_naive(),
    };
    worship::prayer_day(&settings, date, now)
}

#[tauri::command]
pub fn get_hijri_date(
    state: State<'_, AppState>,
    date: Option<String>,
) -> Option<HijriDate> {
    let settings = worship::load_settings(&state.db);
    let date = match date {
        Some(raw) => chrono::NaiveDate::parse_from_str(&raw, "%Y-%m-%d").ok()?,
        None => local_today(&settings),
    };
    worship::hijri_date(date, settings.hijri_adjustment)
}

#[tauri::command]
pub fn get_qibla(state: State<'_, AppState>) -> QiblaInfo {
    let settings = worship::load_settings(&state.db);
    QiblaInfo {
        bearing: worship::qibla_bearing(settings.latitude, settings.longitude),
        latitude: settings.latitude,
        longitude: settings.longitude,
    }
}

#[tauri::command]
pub fn get_prayer_log(
    state: State<'_, AppState>,
    date: String,
) -> Result<PrayerLog, String> {
    state.db.prayer_log(&date).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_prayer_logs(state: State<'_, AppState>) -> Result<Vec<PrayerLog>, String> {
    state.db.prayer_logs().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn set_prayer_done(
    state: State<'_, AppState>,
    date: String,
    prayer: String,
    done: bool,
) -> Result<PrayerLog, String> {
    state
        .db
        .set_prayer_done(&date, &prayer, done)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn set_prayer_excused(
    state: State<'_, AppState>,
    date: String,
    excused: bool,
) -> Result<PrayerLog, String> {
    state
        .db
        .set_prayer_excused(&date, excused)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_prayer_streak(state: State<'_, AppState>) -> Result<Streak, String> {
    let settings = worship::load_settings(&state.db);
    let logs = state.db.prayer_logs().map_err(|e| e.to_string())?;
    Ok(worship::compute_streak(&logs, local_today(&settings)))
}

// ---------------------------------------------------------------------------
// Adhkar: progress, completion and the adhkar streak
// ---------------------------------------------------------------------------

fn adhkar_today(state: &AppState) -> String {
    let settings = worship::load_settings(&state.db);
    local_today(&settings).format("%Y-%m-%d").to_string()
}

#[tauri::command]
pub fn get_adhkar_progress(
    state: State<'_, AppState>,
    date: Option<String>,
) -> Result<Vec<AdhkarProgress>, String> {
    let date = date.unwrap_or_else(|| adhkar_today(&state));
    state.db.adhkar_progress(&date).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_adhkar_day(
    state: State<'_, AppState>,
    date: Option<String>,
) -> Result<AdhkarDay, String> {
    let date = date.unwrap_or_else(|| adhkar_today(&state));
    state.db.adhkar_day(&date).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_adhkar_logs(state: State<'_, AppState>) -> Result<Vec<AdhkarDay>, String> {
    state.db.adhkar_logs().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn set_adhkar_remaining(
    state: State<'_, AppState>,
    date: String,
    category_id: String,
    item_id: String,
    remaining: u32,
) -> Result<AdhkarProgress, String> {
    state
        .db
        .set_adhkar_remaining(&date, &category_id, &item_id, remaining)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn mark_adhkar_done(
    state: State<'_, AppState>,
    date: String,
    category_id: String,
) -> Result<AdhkarDay, String> {
    state
        .db
        .mark_adhkar_done(&date, &category_id)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn clear_adhkar_category(
    state: State<'_, AppState>,
    date: String,
    category_id: String,
) -> Result<AdhkarDay, String> {
    state
        .db
        .clear_adhkar_category(&date, &category_id)
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_adhkar_streak(state: State<'_, AppState>) -> Result<AdhkarStreak, String> {
    let logs = state.db.adhkar_logs().map_err(|e| e.to_string())?;
    let today = chrono::NaiveDate::parse_from_str(&adhkar_today(&state), "%Y-%m-%d")
        .unwrap_or_else(|_| chrono::Utc::now().date_naive());
    Ok(adhkar::compute_adhkar_streak(&logs, today))
}
