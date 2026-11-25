# Mobile third-party notices

Sakeenah Mobile bundles the following content and depends on the following
packages. Full licence texts for the Quran and adhkar are kept beside the
assets in `assets/data/`; font licences are in `assets/fonts/`.

## Bundled content

| Item | Source | Licence |
|---|---|---|
| Quran text (Uthmani) | Tanzil Project | CC BY 3.0 — `assets/data/QURAN_LICENSE.md` |
| Hisn al-Muslim adhkar | `asellam/HisnElMuslim` | MIT — `assets/data/ADHKAR_LICENSE.md` |
| Tajawal font | Google Fonts | SIL OFL 1.1 — `assets/fonts/OFL-Tajawal.txt` |
| Amiri Quran font | Google Fonts | SIL OFL 1.1 — `assets/fonts/OFL-AmiriQuran.txt` |

The Quran text is bundled verbatim and is never edited by the application.

## Dart and Flutter packages

Versions are pinned by `pubspec.lock`.

| Package | Licence |
|---|---|
| Flutter / Material UI / Cupertino UI | BSD 3-Clause (Flutter Authors) |
| `drift`, `drift_dev` | MIT (Simon Binder) |
| `sqlite3` | MIT (Simon Binder); SQLite itself is public domain |
| `adhan` | MIT (Riajul Islam) |
| `hijri` | BSD 3-Clause (Ahmed Aljoaid) |
| `path_provider`, `path` | BSD 3-Clause (Flutter Authors / Dart team) |
| `intl` | BSD 3-Clause (Dart team) |

The complete dependency graph and transitive licences can be regenerated with
`flutter pub deps` and reviewed against the packages' `LICENSE` files.
