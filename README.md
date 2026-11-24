# دندنة · Dandanah

**A light Arabic audio app for Windows** — Quran recitations, anasheed, and live Arabic radio.
Free, ad-free, account-free, and built to stay under 10 MB installed.

Dandanah hosts no content. Every stream is played from its original source, and all rights
belong to their owners.

---

## Status

Week 1 of the build plan is complete and working:

| Area | State |
|---|---|
| Tauri v2 + Svelte 5 + Tailwind v4 shell | ✅ |
| Arabic-first RTL UI, dark & light themes, Arabic/English | ✅ |
| SQLite library + migration runner | ✅ |
| mp3quran.net provider (200+ reciters, all 114 surahs) | ✅ |
| Quran radio + radio-browser.info (live stations, country/tag filters) | ✅ |
| Unified search with Arabic-aware normalisation and dedupe | ✅ |
| Player: queue, shuffle, repeat, speed, seek, volume, media keys | ✅ |
| Recently played (persisted history) | ✅ |
| Ayah-by-ayah mode, hifz loops | ⏳ week 2 |
| Playlists, favorites, downloads, local import | ⏳ week 3 |
| Jamendo / archive.org / Creative Commons providers | ⏳ week 4 |
| Windows SMTC integration, tray, hotkeys | ⏳ week 5 |
| Installer, auto-update, code signing | ⏳ week 6 |

---

## Requirements

- **Node.js** 20 or newer
- **Rust** stable (MSVC toolchain)
- **Visual Studio Build Tools** with the *Desktop development with C++* workload
- **WebView2 runtime** (preinstalled on Windows 11 and up-to-date Windows 10)

## Run it

```bash
npm install
npm run app        # tauri dev — opens the desktop window with hot reload
```

## Build the installer

```bash
npm run dist       # produces an NSIS installer in src-tauri/target/release/bundle/
```

Frontend-only checks:

```bash
npm run build              # vite production build
npx svelte-check --tsconfig ./tsconfig.json
cargo check --manifest-path src-tauri/Cargo.toml
```

---

## Architecture

```
src/                         Svelte 5 frontend (runes, no router dependency)
├─ lib/
│  ├─ components/            Icon, Artwork, SeekBar, TrackRow, PlayerBar, Sidebar…
│  ├─ views/                 Home, Quran, Radio, Search, Library, Settings, Credits
│  ├─ stores/                player, nav, ui — all runes-based, no store library
│  ├─ i18n/                  ar/en dictionaries + locale-aware formatters
│  ├─ data/                  country list
│  ├─ api.ts                 typed wrappers over Tauri commands
│  └─ fonts.css              self-hosted Tajawal + Amiri Quran (113 KB total)
└─ app.css                   Tailwind theme tokens, RTL-aware primitives

src-tauri/src/               Rust backend
├─ providers/                one module per content source
│  ├─ mod.rs                 Track model, metadata, Arabic normalisation, dedupe
│  ├─ mp3quran.rs            reciters, surah servers, Quran radio
│  └─ radiobrowser.rs        live station directory with mirror fallback
├─ db/mod.rs                 SQLite schema, migrations, cache, history
├─ commands.rs               the IPC surface
└─ lib.rs                    app wiring
```

### Design decisions

- **No audio engine in Rust.** WebView2 is Chromium: `<audio>` plays MP3/AAC/FLAC/Opus natively
  and gives us the Media Session API for free. Wins ~1 s of startup and a lot of code.
- **Providers are pure functions**, not a trait object registry. Each returns `Vec<Track>`;
  the command layer merges, dedupes and caches. Adding a source is one file plus one match arm.
- **Stream URLs are resolved at play time**, never stored — providers like Jamendo issue
  short-lived URLs.
- **Offline-first metadata.** Reciter lists and station lists are cached in SQLite with a TTL,
  and stale copies are served when the network is down.
- **Attribution is a data field, not a footer.** Every `Track` carries `license`,
  `licenseUrl` and `attribution` so the UI can never display CC content without credit.

### Arabic text handling

`providers::normalize_arabic` strips tashkeel, tatweel and Quranic annotation marks and folds
alef/ya/ta-marbuta variants, so `الأَنصَار` and `الانصار` match. Search ranking uses a Dice
coefficient over character bigrams — no search index, no extra dependency.

---

## Content sources

| Source | Content | License |
|---|---|---|
| [mp3quran.net](https://mp3quran.net) | Quran recitations, 200+ reciters, radio | Freely available |
| [EveryAyah](https://everyayah.com) | Ayah-by-ayah recitation audio | Freely available |
| [AlQuran Cloud](https://alquran.cloud) | Surah names, ayah counts | Open data |
| [radio-browser.info](https://www.radio-browser.info) | Live radio directory | CC0 metadata |
| [Jamendo](https://www.jamendo.com) | Creative Commons music | CC — attribution required |
| [Internet Archive](https://archive.org) | Anasheed, public-domain recordings | Per item |

Dandanah deliberately has **no YouTube or stream-ripping provider**. That keeps the app
distributable, the installer small, and the project on solid legal ground.

---

## Keyboard shortcuts

| Key | Action |
|---|---|
| `Space` | Play / pause |
| `→` / `←` | Next / previous |
| `↑` / `↓` | Volume |
| `M` | Mute |

---

## Roadmap

1. **Quran depth** — ayah mode, repeat ranges, memorisation tracker, Uthmani text follow-along.
2. **Library** — playlists, favorites, offline downloads, local folder import.
3. **Creative Commons catalog** — Jamendo, Openverse, archive.org with license badges.
4. **Windows integration** — SMTC lock-screen controls, tray, global hotkeys.
5. **Ship** — installer, GitHub Releases auto-update, code signing.

## License

Code: MIT. Content: see each source above.
