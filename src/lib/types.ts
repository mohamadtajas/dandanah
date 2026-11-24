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
  englishName?: string;
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

// ---------------------------------------------------------------------------
// Worship: prayer times, Hijri, qibla, prayer log
// ---------------------------------------------------------------------------

export type PrayerKey = "fajr" | "dhuhr" | "asr" | "maghrib" | "isha";

export type PrayerMethod =
  | "muslimWorldLeague"
  | "egyptian"
  | "karachi"
  | "ummAlQura"
  | "dubai"
  | "moonsightingCommittee"
  | "northAmerica"
  | "kuwait"
  | "qatar"
  | "singapore"
  | "tehran"
  | "turkey";

export type HighLatitudeRule =
  | "recommended"
  | "middleOfTheNight"
  | "seventhOfTheNight"
  | "twilightAngle";

export interface WorshipSettings {
  latitude: number;
  longitude: number;
  timezone: string;
  method: PrayerMethod;
  madhab: "shafi" | "hanafi";
  highLatitude: HighLatitudeRule;
  hijriAdjustment: number;
  configured: boolean;
}

export interface PrayerTime {
  key: string;
  name: string;
  /** Local wall-clock time, `HH:MM`. */
  time: string;
  iso: string;
  minutes: number;
  passed: boolean;
}

export interface HijriDate {
  year: number;
  month: number;
  day: number;
  monthName: string;
  monthNameEn: string;
  dayName: string;
  dayNameEn: string;
  formatted: string;
}

export interface PrayerDay {
  date: string;
  timezone: string;
  times: PrayerTime[];
  next: PrayerTime | null;
  remainingS: number;
  qibla: number;
  hijri: HijriDate | null;
  now: string;
}

export interface PrayerLog {
  date: string;
  fajr: boolean;
  dhuhr: boolean;
  asr: boolean;
  maghrib: boolean;
  isha: boolean;
  excused: boolean;
}

export interface PrayerStreak {
  current: number;
  best: number;
  todayComplete: boolean;
  todayExcused: boolean;
  todayCount: number;
}

export interface QiblaInfo {
  bearing: number;
  latitude: number;
  longitude: number;
}

// ---------------------------------------------------------------------------
// Adhkar
// ---------------------------------------------------------------------------

export interface AdhkarItem {
  id: string;
  text: string;
  count: number;
  reference: string;
}

export interface AdhkarCategory {
  id: string;
  title: string;
  featured: boolean;
  streakKey?: "morning" | "evening";
  items: AdhkarItem[];
}

export interface AdhkarData {
  source: {
    title: string;
    author: string;
    repository: string;
    commit: string;
    license: string;
    generated: string;
  };
  categories: AdhkarCategory[];
}

export interface AdhkarProgress {
  date: string;
  categoryId: string;
  itemId: string;
  remaining: number;
}

export interface AdhkarDay {
  date: string;
  morning: boolean;
  evening: boolean;
}

export interface AdhkarStreak {
  current: number;
  best: number;
  todayMorning: boolean;
  todayEvening: boolean;
}

export type View =
  | "home"
  | "worship"
  | "adhkar"
  | "search"
  | "quran"
  | "explore"
  | "radio"
  | "library"
  | "settings"
  | "credits";
