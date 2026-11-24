# Tanzil Quran Text — licence and terms

The bundled Uthmani text and its surah/juz/page metadata come from the Tanzil
Project:

- **Text:** Tanzil Quran Text (Uthmani, Version 1.1), downloaded 2026-11-26.
- **Metadata:** Tanzil Quran Metadata (Version 1.0).
- **Copyright:** Copyright (C) 2007–2026 Tanzil Project.
- **Licence:** Creative Commons Attribution 3.0.
- **Source:** <https://tanzil.net> · <https://tanzil.net/docs/tanzil_license>

## Terms of use (from the supplied text)

```
# PLEASE DO NOT REMOVE OR CHANGE THIS COPYRIGHT BLOCK
#====================================================================
#
#  Tanzil Quran Text (Uthmani, Version 1.1)
#  Copyright (C) 2007-2026 Tanzil Project
#  License: Creative Commons Attribution 3.0
#
#  This copy of the Quran text is carefully produced, highly
#  verified and continuously monitored by a group of specialists
#  at Tanzil Project.
#
#  TERMS OF USE:
#
#  - Permission is granted to copy and distribute verbatim copies
#    of this text, but CHANGING IT IS NOT ALLOWED.
#
#  - This Quran text can be used in any website or application,
#    provided that its source (Tanzil Project) is clearly indicated,
#    and a link is made to tanzil.net to enable users to keep
#    track of changes.
#
#  - This copyright notice shall be included in all verbatim copies
#    of the text, and shall be reproduced appropriately in all files
#    derived from or containing substantial portion of this text.
#
#  Please check updates at: http://tanzil.net/updates/
#
#====================================================================
```

Sakeenah keeps the text verbatim. `scripts/build-quran.mjs` only reshapes the
XML into JSON (surah/ayah keys, juz and page numbers, and the basmala that
Tanzil already separates); it never edits the Arabic text. The full copyright
block is also embedded in the generated `src-tauri/data/quran.json` and shown in
the app's Sources screen.

No page images, translations or recitations are bundled here. The English
translation is fetched at runtime from AlQuran Cloud (Sahih International).
