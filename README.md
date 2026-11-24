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
| Ayah-by-ayah playback with Uthmani text and translation | ✅ |
| Hifz loops: repeat an ayah range N times, mark memorised | ✅ |
| Favorites, playlists, downloads, local folder import | ✅ |
| Openverse + archive.org catalogue with licence badges | ✅ |
| Windows media session, tray, global hotkeys | ✅ |
| Installer, auto-update pipeline, GitHub Actions | ✅ |
| Code signing | ⏳ needs a certificate (see *Shipping*) |

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

Signed updater artifacts are produced when the key is present:

```powershell
$env:TAURI_SIGNING_PRIVATE_KEY = Get-Content "$env:USERPROFILE\.tauri\dandanah.key" -Raw
$env:TAURI_SIGNING_PRIVATE_KEY_PASSWORD = ""
npm run dist
```

If you have no signing key, use `npm run dist:unsigned` — same installer, no update
signature. Tauri refuses to bundle with a public key configured and no private key, which is
why the two scripts exist.

Frontend-only checks:

```bash
npm run build              # vite production build
npx svelte-check --tsconfig ./tsconfig.json
cargo check --manifest-path src-tauri/Cargo.toml
```

Desktop smoke test against the real window (import, favourites, playlists, download):

```powershell
$env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS = "--remote-debugging-port=9333"
.\src-tauri\target\release\dandanah.exe
node scripts\desktop-smoke.mjs "C:\path\to\music"
```

---

## Architecture

```
src/                         Svelte 5 frontend (runes, no router dependency)
├─ lib/
│  ├─ components/            Icon, Artwork, SeekBar, TrackRow, PlayerBar, Sidebar…
│  ├─ views/                 Home, Quran, Radio, Search, Library, Settings, Credits
│  ├─ stores/                player, hifz, library, nav, ui — runes-based, no store library
│  ├─ i18n/                  ar/en dictionaries + locale-aware formatters
│  ├─ data/                  country list
│  ├─ api.ts                 typed wrappers over Tauri commands
│  └─ fonts.css              self-hosted Tajawal + Amiri Quran (113 KB total)
└─ app.css                   Tailwind theme tokens, RTL-aware primitives

src-tauri/src/               Rust backend
├─ providers/                one module per content source
│  ├─ mod.rs                 Track model, metadata, Arabic normalisation, dedupe
│  ├─ mp3quran.rs            reciters, surah servers, Quran radio
│  ├─ everyayah.rs           per-ayah recitation catalogue and URL builder
│  ├─ quran_text.rs          Uthmani text + translation from AlQuran Cloud
│  ├─ openverse.rs           CC audio index (includes Jamendo), no API key
│  ├─ archive.rs             archive.org audio items expanded into tracks
│  └─ radiobrowser.rs        live station directory with mirror fallback
├─ db/mod.rs                 SQLite schema, migrations, cache, history
├─ downloads.rs              streaming downloader with progress events
├─ library.rs                folder scan + tag reading for local files
├─ media.rs                  Windows SMTC session (metadata, transport buttons)
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

## Quran mode

Two ways to listen, both under the Quran tab.

**Full surah** — 200+ reciters from mp3quran, each with the riwayat they have recorded.

**Ayah by ayah** — 26 curated EveryAyah recitations covering murattal, mujawwad and
teaching styles. Every ayah is its own track, so next/previous, speed and repeat all work
at verse level.

The follow-along view shows the Uthmani text, highlights the ayah being played, scrolls it
into view, and can show the Sahih International translation underneath. Memorisation is
stored per surah in SQLite:

- choose a start and end ayah, pick 1–10 passes and press **Repeat** — the range loops,
  then stops and offers to mark it;
- tap the bookmark under an ayah, or mark the whole range at once;
- **Library → Memorisation** lists every surah with a progress bar;
- the last ayah you played is remembered per surah and reciter, and the view reopens there.

The loop is frontend-only: it takes over the `<audio>` `ended` event instead of building a
second queue, so there is no duplicate playback engine to keep in sync.

---

## Library

**Favorites** — the heart on any row or in the player bar. Stored in SQLite with the whole
track payload, so a favorite survives provider outages.

**Playlists** — create, rename, delete, add from the `+` action on any row, remove in the
playlist view. Ordering is insertion order.

**Downloads** — one click on a surah row (or any non-live track) streams the file into
`%APPDATA%\app.dandanah.desktop\downloads`, emitting progress events that drive the
downloads tab. Playback prefers the downloaded file over the network, so a downloaded
track works offline.

**Local import** — pick one or more folders; Dandanah walks them (8 levels deep, 5000 files
per import), reads ID3/FLAC/MP4 tags with `lofty`, and falls back to filename + folder name
when tags are missing. Imported files are played through Tauri's asset protocol, which
supports range requests, so seeking works.

Downloads are a single track at a time and cannot be cancelled yet. Embedded artwork is
read for display but not extracted into the cache.

---

## Explore — free music and anasheed

The Explore tab searches two openly licensed catalogues at once:

- **Openverse** — a CC audio index that already aggregates Jamendo and Freesound, so the
  app needs no Jamendo API key.
- **Internet Archive** — audio items expanded into their individual files, with the item's
  licence URL mapped to a short label (`CC BY`, `CC BY-SA`, `CC0`, `Public domain`).

Every row shows its licence. Downloads are refused when a music or anasheed track has no
known licence, and the credits screen lists every source. Searches run in parallel; if one
provider fails the other's results are still shown.

---

## Windows integration

- **System Media Transport Controls** — the lock screen, volume flyout and hardware media
  keys show Dandanah's current track and control play/pause, previous and next. Implemented
  with `souvlaki` against the window's HWND; playback position is mirrored every few seconds
  so seeking from the OS works.
- **Tray icon** — left click restores the window; the menu offers show/hide, play/pause,
  previous, next and quit. Hiding the window keeps playback running.
- **Global hotkeys** — `Ctrl+Alt+Space` toggles playback, `Ctrl+Alt+→` / `Ctrl+Alt+←` skip.
  Tray menu labels are Arabic-first; hotkeys are fixed (not configurable yet).
- **Second launch** — starting the app again focuses the existing instance instead of
  opening a second copy.

---

## Shipping

**How an update reaches users**

1. Settings → Updates calls the updater plugin, which fetches
   `latest.json` from the GitHub release endpoint in `src-tauri/tauri.conf.json`.
2. If the version is newer, the app downloads the signed `.nsis.zip`, verifies the signature
   against the public key in the config, installs it, and relaunches.

**Publish a release**

```bash
git tag v0.1.1
git push origin v0.1.1
```

`.github/workflows/release.yml` builds on a Windows runner, signs the updater artifacts and
opens a **draft** GitHub release. Review it, then publish — publishing is what makes the
update visible to installed copies.

Required repository secrets:

| Secret | Value |
|---|---|
| `TAURI_SIGNING_PRIVATE_KEY` | contents of `~/.tauri/dandanah.key` |
| `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` | the key password (empty here) |

The endpoint currently points at `github.com/mohamadtajas/dandanah`. If the repository lives
elsewhere, change the URL in `src-tauri/tauri.conf.json` — it must serve `latest.json` from
the latest release.

**Code signing** is not configured. The installer is unsigned, so Windows SmartScreen will
warn on first run. Removing that requires an Authenticode certificate; Azure Trusted Signing
(~$10/month) is the cheapest realistic option for an open-source project. The updater
signature is separate and already in place — it protects update integrity, not the first
download.

**Verified locally:** the installer is 2.96 MiB, the app starts, fetches live data, migrates
its database, and responds to Windows media keys. The release workflow has not been executed
on GitHub yet because the repository has no remote.

---

## Content sources

| Source | Content | License |
|---|---|---|
| [mp3quran.net](https://mp3quran.net) | Quran recitations, 200+ reciters, radio | Freely available |
| [EveryAyah](https://everyayah.com) | Ayah-by-ayah recitation audio | Freely available |
| [AlQuran Cloud](https://alquran.cloud) | Surah names, ayah counts | Open data |
| [radio-browser.info](https://www.radio-browser.info) | Live radio directory | CC0 metadata |
| [Jamendo](https://www.jamendo.com) | Creative Commons music | CC — attribution required |
| [Openverse](https://openverse.org) | CC audio index (includes Jamendo) | CC — per work |
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

Global (work when the window is unfocused):

| Key | Action |
|---|---|
| `Ctrl+Alt+Space` | Play / pause |
| `Ctrl+Alt+→` / `Ctrl+Alt+←` | Next / previous |
| Media keys | Routed through the Windows media session |

---

## Roadmap

1. ~~**Quran depth**~~ — shipped: ayah mode, repeat ranges, memorisation tracker, Uthmani follow-along.
2. ~~**Library**~~ — shipped: favorites, playlists, downloads, local folder import.
3. ~~**Creative Commons catalog**~~ — shipped: Openverse and archive.org with licence badges.
4. ~~**Windows integration**~~ — shipped: SMTC, tray and global hotkeys.
5. ~~**Ship**~~ — shipped: NSIS installer, signed updater pipeline, GitHub Actions, CI.
6. **Sign** — Authenticode certificate to clear SmartScreen.

## License

Code: MIT. Content: see each source above.
