# Mobile Audio Implementation Plan

**Goal:** Add an offline-friendly Quran audio catalog with an ayah queue, a mini-player and a full player; wrap background playback behind a service boundary.

**Architecture:** `QuranAudioCatalog` builds EveryAyah URLs from the existing surah metadata. A testable `AudioEngine` interface wraps `just_audio`; `PlaybackController` owns queue/state for the UI. `audio_service` background wiring is added after the foreground player is green.

**Spec:** `docs/plans/sakeenah-plan.md` (M5) and `docs/superpowers/owner-actions.md`.

## Tasks

### Task 1: Catalog and controller

**Files:** `lib/data/models/audio.dart`, `lib/data/audio/quran_audio_catalog.dart`, `lib/data/audio/audio_engine.dart`, `lib/data/audio/playback_controller.dart`, `lib/data/audio/just_audio_engine.dart`, `lib/data/app_services.dart`; tests `test/quran_audio_catalog_test.dart`, `test/playback_controller_test.dart`.

`AudioTrack`, `QuranAudioCatalog`, `AudioEngine`, `JustAudioEngine`, `PlaybackController`, AppServices wiring, unit tests.

### Task 2: Audio UI

**Files:** `lib/features/audio/audio_page.dart`, `lib/features/audio/player_page.dart`, `lib/shell/app_shell.dart`, l10n; test `test/audio_page_test.dart`.

Reciter picker, surah picker, mini-player in the shell, full player with seek/speed/repeat, widget tests.

### Task 3: Background service

`audio_service` handler, notification/lock-screen controls, manifest entries, device test.

### Task 4: Downloads/storage

Deferred until the owner confirms a storage budget; document only.

## Global constraints

- Reuse the desktop-approved EveryAyah source; keep provider attribution.
- No autoplay/download on cellular; downloads are explicit.
- Arabic UI, existing theme.
- Every track URL is `https://everyayah.com/data/<reciter>/<SSS><AAA>.mp3`.
- Do not block the UI thread; audio failures show an Arabic error.
