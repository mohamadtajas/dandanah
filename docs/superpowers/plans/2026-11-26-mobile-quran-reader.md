# Mobile Quran Reader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Mushaf placeholder with an offline Quran catalog and continuous reader with bookmarks, resume, font sizing and a daily ayah.

**Architecture:** Keep Quran text read-only in `QuranRepository`; add a separate `QuranReaderRepository` for user state (`reader_state`, `bookmarks`, font size). `QuranPage` becomes a four-tab catalog (surahs, juz, bookmarks, resume). `QuranReaderPage` renders surah or juz text with `ScrollablePositionedList`, saving the first visible ayah as the resume position.

**Tech Stack:** Flutter 3.50 / Dart 3.14, Drift, `scrollable_positioned_list`, Amiri Quran font.

**Spec:** `docs/plans/sakeenah-plan.md` (M4) and `docs/plans/plan-tracker.md`.

## Global Constraints

- Quran text must be displayed verbatim; never normalise or reorder ayahs.
- All reading works offline; no network calls.
- Arabic-only UI; add every string to `app_ar.arb` and `app_en.arb`.
- Bookmarks persist across restart and survive content refresh.
- Font size persists and is clamped 20–44.
- Existing tests and CI must stay green.

## Review Focus

- Al-Fatiha (bismillah is ayah 1) and At-Tawba (no bismillah) render correctly.
- A bookmark toggled twice leaves no duplicate and removes cleanly.
- Resume opens the saved ayah, not ayah 1.
- A long surah (Al-Baqarah) scrolls without building all 286 rows at once.
- Juz reader crosses surah boundaries with headers in the right order.

---

### Task 1: Reader state repository and daily ayah

**Files:**
- Create: `lib/data/models/quran_reader.dart`
- Create: `lib/data/repositories/quran_reader_repository.dart`
- Create: `lib/data/worship/daily_ayah.dart`
- Modify: `lib/data/repositories/quran_repository.dart`
- Modify: `lib/data/app_services.dart`
- Test: `test/quran_reader_repository_test.dart`
- Test: `test/daily_ayah_test.dart`

**Interfaces:**
- Produces:
  - `class ReaderPosition { int surah; int ayah; DateTime updatedAt; }`
  - `class QuranBookmark { int surah; int ayah; DateTime createdAt; }`
  - `abstract interface class QuranReaderRepository` with `position`, `savePosition`, `bookmarks`, `isBookmarked`, `toggleBookmark`, `removeBookmark`, `fontSize`, `saveFontSize`.
  - `int dailyAyahOrdinal(String dateKey)`.
  - `QuranRepository.ayahByOrdinal(int ordinal)` returning `Ayah?`.
  - `AppServices.quranReader`.

- [ ] **Step 1: Write failing tests**

`test/quran_reader_repository_test.dart` (in-memory DB): position starts null; save then read; second save updates one row; toggle bookmark adds then removes; bookmarks list has one row after double toggle; font size defaults 28, clamps 20 and 44, persists in `SettingsStore` key `quran.fontSize`.

`test/daily_ayah_test.dart`: ordinal is stable, between 1 and 6236, changes across dates; `ayahByOrdinal(1)` returns Al-Fatiha 1.

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/quran_reader_repository_test.dart test/daily_ayah_test.dart`
Expected: FAIL because classes/methods do not exist.

- [ ] **Step 3: Implement models, repository and daily helper**

`savePosition` uses `ReaderStateCompanion.insert(id: const Value(1), surah: surah, ayah: ayah, updatedAt: DateTime.now())` with `insertOnConflictUpdate`. `toggleBookmark` runs in a transaction and checks `(surah, ayah)` before insert/delete. `fontSize` uses `SettingsStore.readInt` with default 28; `saveFontSize` clamps 20..44 and writes `'$size'`. `ayahByOrdinal` uses `...limit(1, offset: ordinal - 1)` ordered by surah, ayah. `dailyAyahOrdinal` sums code units of the date key and returns `(sum * 37) % 6236 + 1`.

- [ ] **Step 4: Run tests to verify pass**

Run: `flutter test test/quran_reader_repository_test.dart test/daily_ayah_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/data mobile/test/quran_reader_repository_test.dart mobile/test/daily_ayah_test.dart
git commit -m "feat(mobile): persist Quran reader state and bookmarks"
```

---

### Task 2: Four-tab Quran catalog

**Files:**
- Replace: `lib/features/quran/quran_page.dart`
- Create: `lib/features/quran/quran_reader_page.dart` (navigation target only; full reader in Task 3)
- Test: `test/quran_page_test.dart`
- Modify: `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`

**Interfaces:**
- Consumes: `QuranRepository`, `QuranReaderRepository`, `dailyAyahOrdinal`.
- Produces: `QuranPage` with tabs `السور`, `الأجزاء`, `العلامات`, `المتابعة`.

- [ ] **Step 1: Write failing widget test**

Pump `QuranPage` inside the existing test harness. Assert four tab labels and `البقرة`; enter `الكهف` in the search field and assert only Al-Kahf remains; tap `الأجزاء` and assert `الجزء 30`; tap `العلامات` and assert the empty state; tap `المتابعة` and assert the empty resume state plus `آية اليوم`.

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/quran_page_test.dart`
Expected: FAIL because the placeholder has no tabs.

- [ ] **Step 3: Implement the catalog**

Use `DefaultTabController` with four tabs. Surah list rows show number, name, English name, ayah count and Makkah/Madinah chip. Search normalises Arabic with `normalizeArabic`. Juz rows show number and start `surah:ayah`. Bookmarks and resume load from `AppServices.current.quranReader`; reload after returning from the reader. Daily ayah uses `dailyAyahOrdinal(localDateKey(DateTime.now()))` and `ayahByOrdinal`.

Tapping a surah or juz pushes `QuranReaderPage`. Bookmarks/resume open the reader at the saved ayah.

- [ ] **Step 4: Run test to verify pass**

Run: `flutter test test/quran_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/quran mobile/lib/l10n mobile/test/quran_page_test.dart
git commit -m "feat(mobile): add Quran catalog tabs"
```

---

### Task 3: Continuous reader

**Files:**
- Replace: `lib/features/quran/quran_reader_page.dart`
- Test: `test/quran_reader_page_test.dart`
- Modify: `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb`

**Interfaces:**
- Consumes: `QuranRepository`, `QuranReaderRepository`.
- Produces:
  - `QuranReaderPage.surah({required int surah, int? initialAyah})`
  - `QuranReaderPage.juz({required int juz, int? initialAyah})`

- [ ] **Step 1: Write failing widget tests**

- Surah reader: pump `QuranReaderPage.surah(surah: 1)`; assert the first ayah text is visible.
- Font: tap the increase icon; assert the ayah `Text` style fontSize grows by 2 and `quranReader.fontSize()` returns the new value.
- Bookmark: tap the bookmark icon on an ayah; assert `bookmarks()` contains it; tap again and assert removal.
- Resume: tap an ayah; assert `position()` matches that surah/ayah.
- Juz: pump `QuranReaderPage.juz(juz: 30)`; assert An-Nas text is visible.

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/quran_reader_page_test.dart`
Expected: FAIL because the reader page is a stub.

- [ ] **Step 3: Implement the reader**

Load surah/juz data and build `List<ReaderEntry>` where an entry is a surah header or an ayah. Use `ScrollablePositionedList.builder` with `initialScrollIndex` for `initialAyah`. Use `ItemPositionsListener` plus a 500 ms debounce to save the first visible ayah; flush on dispose. Render each ayah with `SakeenahTheme.quran(..., size: _fontSize)`, an ayah-number badge, a sajda label when `ayah.sajda`, and a bookmark `IconButton`. AppBar actions decrease/increase font size by 2 (clamped 20..44) and persist. Show the surah bismillah between the header and ayah 1 when `surah.bismillah != null`.

- [ ] **Step 4: Run tests to verify pass**

Run: `flutter test test/quran_reader_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/quran mobile/lib/l10n mobile/test/quran_reader_page_test.dart
git commit -m "feat(mobile): add continuous Quran reader"
```

---

### Task 4: Verification and documentation

- [ ] **Step 1: Full checks**

```bash
cd mobile
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Expected: analyzer clean, all tests pass, APK builds.

- [ ] **Step 2: Emulator/phone check**

Open Mushaf, search `الكهف`, open it, scroll, change font size, bookmark an ayah, return, open Bookmarks, reopen the bookmark, force-stop, reopen, verify resume. Turn on airplane mode and repeat.

- [ ] **Step 3: Screenshot and README**

Refresh `docs/screenshots/mobile/01-mushaf.png` and add `10-quran-reader.png`; update the README feature list and screenshot table.

- [ ] **Step 4: Push and CI**

```bash
git push origin master
```

Expected: Android and iOS CI jobs pass.
