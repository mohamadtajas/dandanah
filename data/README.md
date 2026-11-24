# Hisn al-Muslim source

- **Book:** حصن المسلم من أذكار الكتاب والسنة — د. سعيد بن علي بن وهف القحطاني.
- **JSON:** <https://github.com/asellam/HisnElMuslim> at commit
  `872764ca013116c905f7fc9c3dc972c27cd37d4a` (`main`, 2026-11-26).
- **Licence:** MIT (the repository's `LICENSE.md`). The transcription was made
  from the printed copy and cross-checked against an online copy with
  Levenshtein distance, per the repository's README.
- **Scope:** 133 categories, 302 adhkar, each with its repeat count (`Count`)
  and source reference (`Reference`). Audio URLs from the source are not used.

The bundled file `src/lib/data/adhkar.json` is generated from
`data/hisn-al-muslim.json`:

```bash
node scripts/build-adhkar.mjs
```

The generator removes audio links, adds stable IDs, and marks the six featured
categories (morning, evening, sleep, waking, after prayer, misc). The app shows
the full book under "كل الأذكار"; the featured categories drive the dashboard
and the adhkar streak.
