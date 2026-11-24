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
