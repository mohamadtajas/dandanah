import { invoke } from "@tauri-apps/api/core";
import type { AppInfo, Reciter, SearchResults, Surah, Track } from "./types";

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

  radios: async (limit?: number, country?: string, tag?: string): Promise<Track[]> =>
    isTauri
      ? invoke<Track[]>("get_radios", { limit, country, tag })
      : (await mock()).radios(limit),

  search: async (query: string, kinds?: string[]): Promise<SearchResults> =>
    isTauri ? invoke<SearchResults>("search", { query, kinds }) : (await mock()).search(query),

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
};
