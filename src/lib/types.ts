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
  tracks: Track[];
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
  | "radio"
  | "library"
  | "settings"
  | "credits";
