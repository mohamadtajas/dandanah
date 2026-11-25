# Third-party notices

Sakeenah is MIT-licensed. It depends on open-source packages whose licences and
notices are reproduced or referenced here. Full licence texts are shipped inside
each crate or npm package.

## Prayer times — `adhan` 0.2 (Apache-2.0)

```
crateworks
Copyright 2026 Yayasan Pesantren Cipansor and contributors

This product includes software developed by Yayasan Pesantren Cipansor and
contributors (https://github.com/cipansor/crateworks).

The astronomy follows the method in Jean Meeus, "Astronomical Algorithms", as
used by the adhan library by Batoul Apps and contributors
(https://github.com/batoulapps/adhan-js), which is distributed under the MIT
licence. The test fixtures are outputs of that library. This crate is an
independent implementation for Rust and shares no code with it.

Licensed under the Apache License, Version 2.0.
```

## Hijri dates — `hijridate` 0.2 (Apache-2.0)

```
crateworks
Copyright 2026 Yayasan Pesantren Cipansor and contributors

This product includes software developed by Yayasan Pesantren Cipansor and
contributors (https://github.com/cipansor/crateworks).

It also includes the Umm al-Qura month-start table and test fixtures generated
from the hijridate Python package by Mohammed Alshehri
(https://github.com/dralshehri/hijridate), which is distributed under the MIT
licence and reproduces the Umm al-Qura calendar published by the Saudi
authorities.

Licensed under the Apache License, Version 2.0.
```

## Adhkar data — HisnElMuslim (MIT)

The bundled adhkar corpus is the JSON transcription from
<https://github.com/asellam/HisnElMuslim> (commit `872764ca…`). It is MIT
licensed:

```
MIT License

Copyright (c) 2021 Abdellah SELLAM

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

The underlying texts are from *Hisn al-Muslim* by Dr. Sa'id bin Ali bin Wahf
al-Qahtani. The full licence text is also kept at `data/LICENSE.md`.

## Adhan audio - Beautiful adhan (CC0 1.0)

The bundled adhan recording at `src/lib/assets/adhan.ogg` is "Beautiful adhan"
by Adam-synagda, downloaded from Wikimedia Commons
(<https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg>). It is released
under the Creative Commons CC0 1.0 Universal Public Domain Dedication
(<https://creativecommons.org/publicdomain/zero/1.0/>). No changes were made.
The licence record is kept at `data/ADHAN_LICENSE.md`.

## Other direct dependencies

| Package | Licence |
|---|---|
| `tauri`, `tauri-plugin-*` | MIT / Apache-2.0 |
| `souvlaki` | MIT |
| `lofty` | MIT / Apache-2.0 |
| `rusqlite` (bundled SQLite) | MIT; SQLite is public domain |
| `chrono`, `chrono-tz` | MIT / Apache-2.0 |
| `iana-time-zone` | MIT / Apache-2.0 |
| `reqwest`, `tokio` | MIT / Apache-2.0 |
| `serde`, `serde_json` | MIT / Apache-2.0 |
| `anyhow`, `thiserror` | MIT / Apache-2.0 |
| `uuid`, `parking_lot`, `urlencoding`, `encoding_rs` | MIT / Apache-2.0 |
| Svelte, Vite, Tailwind CSS | MIT |
| Tajawal, Amiri Quran fonts | SIL Open Font License 1.1 |

Audio, recitation and anasheed content is never bundled except the adhan
recording added in a later phase, and remains the property of its publishers as
shown in the app's Sources & licences screen.
