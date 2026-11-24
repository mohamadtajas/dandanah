export type TrackKind = "quran" | "anasheed" | "music" | "radio" | "local";

export interface Track {
  id: string;
  provider: string;
  providerId: string;
  title: string;
  artist: string;
  album?: string;
  durationS?: number;
  artworkUrl?: string;
  streamUrl?: string;
  license?: string;
  licenseUrl?: string;
  attribution?: string;
  sourcePage?: string;
  kind: TrackKind;
  subtitle?: string;
  live?: boolean;
  /** Absolute file path for an imported or downloaded track. */
  localPath?: string;
}

export interface Moshaf {
  id: number;
  name: string;
  server: string;
  surahTotal: number;
  surahs: number[];
}

export interface Reciter {
  id: number;
  name: string;
  letter: string;
  moshafs: Moshaf[];
}

export interface Surah {
  number: number;
  name: string;
  englishName: string;
  meaning: string;
  ayahs: number;
  revelation: "makkah" | "madinah";
}

export interface SearchResults {
  reciters: Reciter[];
  surahs: Surah[];
  tracks: Track[];
}

export interface AyahReciter {
  id: string;
  name: string;
  english: string;
  /** مرتل · مجود · معلم */
  style: string;
  bitrate: number;
}

export interface Ayah {
  number: number;
  text: string;
  translation?: string;
  juz?: number;
  page?: number;
  sajda?: boolean;
}

export interface Memorization {
  surah: number;
  memorized: number[];
  updatedAt: number;
}

export interface Playlist {
  id: string;
  name: string;
  createdAt: number;
  trackCount: number;
}

export type DownloadStatus = "queued" | "downloading" | "done" | "error" | "cancelled";

export interface DownloadRow {
  track: Track;
  status: DownloadStatus;
  bytesTotal: number;
  bytesDone: number;
  filePath?: string;
  error?: string;
  createdAt: number;
}

export interface ImportSummary {
  imported: number;
  scannedFolders: number;
  truncated: boolean;
}

/** Payload pushed to the native media session. */
export interface NowPlaying {
  title: string;
  artist: string;
  album?: string | null;
  durationS?: number | null;
  positionS: number;
  playing: boolean;
  artworkUrl?: string | null;
}

/** Global shortcuts, as accelerator strings understood by Tauri. */
export interface HotkeyMap {
  toggle: string;
  next: string;
  previous: string;
}

export interface AppInfo {
  version: string;
  providers: string[];
  countries: string[];
}

export type View =
  | "home"
  | "search"
  | "quran"
  | "explore"
  | "radio"
  | "library"
  | "settings"
  | "credits";
