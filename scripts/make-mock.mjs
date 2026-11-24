import fs from "node:fs";

const surahs = JSON.parse(fs.readFileSync("src-tauri/data/surahs.json", "utf8"));
const r = await (await fetch("https://mp3quran.net/api/v3/reciters?language=ar")).json();

const wanted = ["الحصري", "المنشاوي", "العفاسي", "عبد الباسط", "السديس", "الشريم", "الأخضر"];
const picked = [];
for (const name of wanted) {
  const hit = r.reciters.find((x) => x.name.includes(name) && picked.every((p) => p.id !== x.id));
  if (hit) picked.push(hit);
}
for (const rec of r.reciters) {
  if (picked.length >= 6) break;
  if (!picked.some((p) => p.id === rec.id)) picked.push(rec);
}

const reciters = picked.slice(0, 6).map((rec) => ({
  id: rec.id,
  name: rec.name,
  letter: rec.letter ?? "",
  moshafs: rec.moshaf.slice(0, 2).map((m) => ({
    id: m.id,
    name: m.name,
    server: m.server,
    surahTotal: m.surah_total,
    surahs: String(m.surah_list).split(",").map(Number).filter(Boolean),
  })),
}));

const rb = await (await fetch("https://de1.api.radio-browser.info/json/stations/search?countrycode=SA&limit=12&hidebroken=true&order=clickcount&reverse=true", { headers: { "User-Agent": "Dandanah/0.1" } })).json();
const stations = rb
  .filter((s) => s.url_resolved || s.url)
  .slice(0, 12)
  .map((s) => ({
    id: "radiobrowser:" + s.stationuuid,
    provider: "radiobrowser",
    providerId: s.stationuuid,
    title: s.name.trim(),
    artist: s.country || "بث مباشر",
    album: s.tags || undefined,
    streamUrl: s.url_resolved || s.url,
    artworkUrl: s.favicon || undefined,
    kind: "radio",
    live: true,
    subtitle: [s.codec, s.bitrate ? s.bitrate + " kbps" : ""].filter(Boolean).join(" · ") || undefined,
  }));

const file = `// Generated development fixture — used only when the UI runs in a plain browser.
// Regenerate with: node scripts/make-mock.mjs

import type { AppInfo, Reciter, SearchResults, Surah, Track } from "./types";

const SURAHS: Surah[] = ${JSON.stringify(surahs)};

const RECITERS: Reciter[] = ${JSON.stringify(reciters, null, 2)};

const STATIONS: Track[] = ${JSON.stringify(stations, null, 2)};

const pad = (n: number) => String(n).padStart(3, "0");

export function mockApi() {
  return {
    async surahs() {
      return SURAHS;
    },
    async reciters() {
      return RECITERS;
    },
    async moshafTracks(reciterId: number, moshafId?: number) {
      const reciter = RECITERS.find((r) => r.id === reciterId) ?? RECITERS[0];
      const moshaf = reciter.moshafs.find((m) => m.id === moshafId) ?? reciter.moshafs[0];
      const base = moshaf.server.endsWith("/") ? moshaf.server : moshaf.server + "/";
      return moshaf.surahs
        .map((n) => {
          const meta = SURAHS.find((s) => s.number === n);
          if (!meta) return null;
          return {
            id: \`mp3quran:\${moshaf.id}-\${n}\`,
            provider: "mp3quran",
            providerId: \`\${moshaf.id}-\${n}\`,
            title: meta.name,
            artist: reciter.name,
            album: moshaf.name,
            subtitle: \`\${moshaf.name} · \${meta.ayahs} آية\`,
            streamUrl: base + pad(n) + ".mp3",
            kind: "quran" as const,
            attribution: \`تلاوة \${reciter.name} — mp3quran.net\`,
          };
        })
        .filter(Boolean) as Track[];
    },
    async quranRadios() {
      return STATIONS.slice(0, 6).map((s, i) => ({
        ...s,
        id: "mp3quran-radio:" + i,
        provider: "mp3quran-radio",
        title: "إذاعة القرآن الكريم " + (i + 1),
        artist: "إذاعة القرآن الكريم",
      }));
    },
    async radios(limit = 80) {
      return STATIONS.slice(0, limit);
    },
    async search(query: string): Promise<SearchResults> {
      const q = query.trim();
      return {
        reciters: RECITERS.filter((r) => r.name.includes(q)),
        tracks: STATIONS.filter((s) => s.title.includes(q)),
      };
    },
    async recent() {
      return [] as Track[];
    },
    async recordPlay() {},
    async settings() {
      return [] as [string, string][];
    },
    async setSetting() {},
    async appInfo(): Promise<AppInfo> {
      return {
        version: "0.1.0-dev",
        providers: ["mp3quran", "mp3quran-radio", "radiobrowser"],
        countries: ["SA", "EG", "AE"],
      };
    },
  };
}
`;

fs.writeFileSync("src/lib/mock.ts", file, "utf8");
console.log("reciters:", reciters.map((r) => r.name).join(" | "));
console.log("stations:", stations.length, "surahs:", surahs.length);
