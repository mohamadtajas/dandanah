import { invoke } from "@tauri-apps/api/core";
import type {
  AppInfo,
  Ayah,
  AyahReciter,
  DownloadRow,
  HotkeyMap,
  ImportSummary,
  Memorization,
  NowPlaying,
  Playlist,
  Reciter,
  SearchResults,
  Surah,
  Track,
} from "./types";

export const isTauri =
  typeof window !== "undefined" && "__TAURI_INTERNALS__" in window;

type MockApi = ReturnType<typeof import("./mock").mockApi>;

let mockPromise: Promise<MockApi> | null = null;

/** In a plain browser (`npm run dev`) we fall back to a generated fixture. */
async function mock(): Promise<MockApi> {
  if (!mockPromise) mockPromise = import("./mock").then((m) => m.mockApi());
  return mockPromise;
}

/** Typed wrappers around the Rust commands exposed in `commands.rs`. */
export const api = {
  surahs: async (): Promise<Surah[]> =>
    isTauri ? invoke<Surah[]>("get_surahs") : (await mock()).surahs(),

  reciters: async (language = "ar"): Promise<Reciter[]> =>
    isTauri ? invoke<Reciter[]>("get_reciters", { language }) : (await mock()).reciters(),

  moshafTracks: async (reciterId: number, moshafId?: number): Promise<Track[]> =>
    isTauri
      ? invoke<Track[]>("get_moshaf_tracks", { reciterId, moshafId })
      : (await mock()).moshafTracks(reciterId, moshafId),

  quranRadios: async (): Promise<Track[]> =>
    isTauri ? invoke<Track[]>("get_quran_radios") : (await mock()).quranRadios(),

  ayahReciters: async (): Promise<AyahReciter[]> =>
    isTauri ? invoke<AyahReciter[]>("get_ayah_reciters") : (await mock()).ayahReciters(),

  ayahTracks: async (surahNumber: number, reciterId: string): Promise<Track[]> =>
    isTauri
      ? invoke<Track[]>("get_ayah_tracks", { surahNumber, reciterId })
      : (await mock()).ayahTracks(surahNumber, reciterId),

  surahText: async (surahNumber: number, translation = false): Promise<Ayah[]> =>
    isTauri
      ? invoke<Ayah[]>("get_surah_text", { surahNumber, translation })
      : (await mock()).surahText(surahNumber, translation),

  memorized: async (surahNumber: number): Promise<number[]> =>
    isTauri
      ? invoke<number[]>("get_memorized", { surahNumber })
      : (await mock()).memorized(surahNumber),

  saveMemorized: async (surahNumber: number, memorized: number[]): Promise<void> => {
    if (!isTauri) {
      await (await mock()).saveMemorized(surahNumber, memorized);
      return;
    }
    await invoke<void>("save_memorized", { surahNumber, memorized });
  },

  memorization: async (): Promise<Memorization[]> =>
    isTauri ? invoke<Memorization[]>("get_memorization") : (await mock()).memorization(),

  position: async (surahNumber: number, reciterId: string): Promise<number | null> =>
    isTauri
      ? invoke<number | null>("get_position", { surahNumber, reciterId })
      : (await mock()).position(surahNumber, reciterId),

  savePosition: async (
    surahNumber: number,
    reciterId: string,
    lastAyah: number,
  ): Promise<void> => {
    if (!isTauri) {
      await (await mock()).savePosition(surahNumber, reciterId, lastAyah);
      return;
    }
    await invoke<void>("save_position", { surahNumber, reciterId, lastAyah });
  },

  radios: async (limit?: number, country?: string, tag?: string): Promise<Track[]> =>
    isTauri
      ? invoke<Track[]>("get_radios", { limit, country, tag })
      : (await mock()).radios(limit),

  search: async (query: string, kinds?: string[]): Promise<SearchResults> =>
    isTauri ? invoke<SearchResults>("search", { query, kinds }) : (await mock()).search(query),

  exploreCc: async (query = "", section = "all", limit = 24): Promise<Track[]> =>
    isTauri
      ? invoke<Track[]>("explore_cc", { query, section, limit })
      : (await mock()).exploreCc(query, section, limit),

  recent: async (limit?: number): Promise<Track[]> =>
    isTauri ? invoke<Track[]>("get_recent", { limit }) : (await mock()).recent(),

  recordPlay: async (track: Track): Promise<void> => {
    if (!isTauri) return;
    await invoke<void>("record_play", { track });
  },

  settings: async (): Promise<[string, string][]> =>
    isTauri ? invoke<[string, string][]>("get_settings") : (await mock()).settings(),

  setSetting: async (key: string, value: string): Promise<void> => {
    if (!isTauri) return;
    await invoke<void>("set_setting", { key, value });
  },

  appInfo: async (): Promise<AppInfo> =>
    isTauri ? invoke<AppInfo>("app_info") : (await mock()).appInfo(),

  updateNowPlaying: async (info: NowPlaying): Promise<void> => {
    if (!isTauri) return;
    await invoke<void>("update_now_playing", { info });
  },

  // --- library ---------------------------------------------------------

  favorites: async (limit = 200): Promise<Track[]> =>
    isTauri ? invoke<Track[]>("get_favorites", { limit }) : (await mock()).favorites(limit),

  favoriteIds: async (): Promise<string[]> =>
    isTauri ? invoke<string[]>("get_favorite_ids") : (await mock()).favoriteIds(),

  addFavorite: async (track: Track): Promise<void> => {
    if (!isTauri) return (await mock()).addFavorite(track);
    await invoke<void>("add_favorite", { track });
  },

  removeFavorite: async (trackId: string): Promise<void> => {
    if (!isTauri) return (await mock()).removeFavorite(trackId);
    await invoke<void>("remove_favorite", { trackId });
  },

  playlists: async (): Promise<Playlist[]> =>
    isTauri ? invoke<Playlist[]>("get_playlists") : (await mock()).playlists(),

  createPlaylist: async (name: string): Promise<Playlist> =>
    isTauri ? invoke<Playlist>("create_playlist", { name }) : (await mock()).createPlaylist(name),

  renamePlaylist: async (playlistId: string, name: string): Promise<void> => {
    if (!isTauri) return (await mock()).renamePlaylist(playlistId, name);
    await invoke<void>("rename_playlist", { playlistId, name });
  },

  deletePlaylist: async (playlistId: string): Promise<void> => {
    if (!isTauri) return (await mock()).deletePlaylist(playlistId);
    await invoke<void>("delete_playlist", { playlistId });
  },

  playlistTracks: async (playlistId: string): Promise<Track[]> =>
    isTauri
      ? invoke<Track[]>("get_playlist_tracks", { playlistId })
      : (await mock()).playlistTracks(playlistId),

  addToPlaylist: async (playlistId: string, track: Track): Promise<void> => {
    if (!isTauri) return (await mock()).addToPlaylist(playlistId, track);
    await invoke<void>("add_to_playlist", { playlistId, track });
  },

  removeFromPlaylist: async (playlistId: string, trackId: string): Promise<void> => {
    if (!isTauri) return (await mock()).removeFromPlaylist(playlistId, trackId);
    await invoke<void>("remove_from_playlist", { playlistId, trackId });
  },

  // --- downloads & local files -----------------------------------------

  startDownload: async (track: Track): Promise<string | null> =>
    isTauri
      ? invoke<string | null>("start_download", { track })
      : (await mock()).startDownload(track),

  cancelDownload: async (trackId: string): Promise<boolean> => {
    if (!isTauri) return (await mock()).cancelDownload(trackId);
    return invoke<boolean>("cancel_download", { trackId });
  },

  downloads: async (): Promise<DownloadRow[]> =>
    isTauri ? invoke<DownloadRow[]>("get_downloads") : (await mock()).downloads(),

  deleteDownload: async (trackId: string): Promise<void> => {
    if (!isTauri) return (await mock()).deleteDownload(trackId);
    await invoke<void>("delete_download", { trackId });
  },

  importFolder: async (paths: string[]): Promise<ImportSummary> =>
    isTauri
      ? invoke<ImportSummary>("import_folder", { paths })
      : (await mock()).importFolder(),

  localTracks: async (): Promise<Track[]> =>
    isTauri ? invoke<Track[]>("get_local_tracks") : (await mock()).localTracks(),

  forgetLocalTrack: async (trackId: string): Promise<void> => {
    if (!isTauri) return (await mock()).forgetLocalTrack(trackId);
    await invoke<void>("forget_local_track", { trackId });
  },

  // --- global shortcuts -------------------------------------------------

  getHotkeys: async (): Promise<HotkeyMap> =>
    isTauri ? invoke<HotkeyMap>("get_hotkeys") : (await mock()).getHotkeys(),

  setHotkeys: async (hotkeys: HotkeyMap): Promise<HotkeyMap> =>
    isTauri
      ? invoke<HotkeyMap>("set_hotkeys", { hotkeys })
      : (await mock()).setHotkeys(hotkeys),
};
