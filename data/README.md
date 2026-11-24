# Hisn al-Muslim source

- **Book:** حصن المسلم من أذكار الكتاب والسنة — د. سعيد بن علي بن وهف القحطاني.
- **JSON:** <https://github.com/asellam/HisnElMuslim> at commit
  `872764ca013116c905f7fc9c3dc972c27cd37d4a` (`main`, 2026-11-26).
- **Licence:** MIT, Copyright (c) 2021 Abdellah SELLAM. The full text is in
  [`LICENSE.md`](./LICENSE.md) and is reproduced in the app's Sources screen.
  The transcription was made from the printed copy and cross-checked against an
  online copy with Levenshtein distance, per the repository's README.
- **Scope:** 133 source chapters, 302 adhkar, each with its repeat count
  (`Count`) and source reference (`Reference`). Audio URLs from the source are
  not used.

## Bundled shape

The generated `src/lib/data/adhkar.json` has **126 sections / 302 items**:

- 6 featured sections: morning (24/358 repeats), evening (22/257), sleep
  (15/116), waking (4/4), after prayer (8/17), and a curated `misc` section
  (19/19) that folds eight source chapters (worry, distress, repentance, sneezing,
  leaving/entering home, entering the mosque, clothing).
- 120 further source chapters, shown under "كل الأذكار".
- The five featured source chapters and the eight misc source chapters are not
  repeated in the "all" list, so every dhikr has one counter.

The app shows the featured cards first and the remaining 120 chapters in a
searchable index; search covers all 126 titles and all 302 dhikr texts.

```bash
node scripts/build-adhkar.mjs
```

The generator removes audio links, adds stable IDs, asserts the 126/302 shape,
and pins the featured repeat counts.

---

# Quran source

- **Text:** Tanzil Quran Text (Uthmani, Version 1.1), downloaded 2026-11-26.
- **Metadata:** Tanzil Quran Metadata (Version 1.0).
- **Licence:** Creative Commons Attribution 3.0, Copyright (C) 2007-2026 Tanzil
  Project. The full notice and terms are in
  [`QURAN_LICENSE.md`](./QURAN_LICENSE.md) and are embedded in the generated
  `src-tauri/data/quran.json`.
- **Source:** <https://tanzil.net> · <https://tanzil.net/docs/tanzil_license>

## Files and generation

- `quran-uthmani.xml` — the verbatim Uthmani text download (basmala is a
  separate attribute on the first ayah, exactly as Tanzil supplies it).
- `quran-metadata.xml` — surah counts, juz starts and page starts.
- `scripts/build-quran.mjs` — reshapes the XML into
  `src-tauri/data/quran.json`; it never edits the Arabic text.
- `src-tauri/data/quran.json` — 114 surahs, 6236 ayahs, 30 juz, 604 pages,
  112 separate basmalas and 15 sajda flags. Embedded in the binary at compile
  time; parsing happens once at first use.

```bash
node scripts/build-quran.mjs
```

The reader (`src-tauri/src/quran.rs`) slices this file by surah and juz; the
Sahih International translation is fetched at runtime and cached, so the Arabic
text remains fully offline.
