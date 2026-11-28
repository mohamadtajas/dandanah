# Owner actions

Running list of things only the owner can decide or provide. I keep working on
independent tasks while these are open.

## EveryAyah and downloads (decided)

- **EveryAyah:** the site has no explicit licence; recordings stay the
  reciters' copyright. The owner accepts streaming with attribution for this
  personal, unlisted build. If it is ever published, get written permission or
  switch providers.
- **Storage:** downloads are enabled with no cap. "تنزيل كل السور" fetches every
  ayah for the selected reciter, so the app data folder holds a complete local
  copy of the Quran (about 1–2 GB at 128 kbps).
- **Anasheed:** Openverse is the selected source (CC-licensed audio, no key).
  The browse tab is built and plays results with per-track licence labels;
  Internet Archive remains a future fallback.

## Still needed from the owner

- Nothing for publishing: the owner confirmed the app stays personal and will
  not go to Play or the App Store, so signing/store steps are dropped.
- Widgets are dormant by owner choice; no launcher work is needed for now.
- Listen to the three bundled adhan recordings on the phone and pick the
  preferred default, then run the in-app test notification.
- Toggle the adhkar reminders on the phone once and confirm the morning,
  evening and sleep notifications arrive at the expected times.
- Confirm the Islamic radio stations stream on the phone network (the emulator
  played the Kuwait Quran station successfully).

## Physical tests only the owner can run

- Large-system-font pass: done on BKQ-N49 at 2× for the dashboard, adhkar,
  Quran catalog/reader, audio, settings and adhan screens.
- Airplane-mode reading and audio playback (the error banner/retry was verified
  on the emulator; repeat on the phone).
- Background audio for 30+ minutes, lock screen and Bluetooth controls (M5).
- A full-reciter download and a reboot with the downloaded files present.
- Adhan exact-alarm/Doze behaviour on the real device (M6), including a
  reboot-reschedule check and OEM battery settings.
- iOS adhan sounds: three 29-second CAF excerpts (`adhan.caf`, `adhan2.caf`,
  `adhan3.caf`, within Apple's 30-second notification limit) are bundled;
  verify at least the default on a real iPhone.
- Widgets after reboot (M7).
- Battery/background matrix (M9).

## Decisions already taken on the owner's behalf

- v1 stays Arabic-only, offline-first.
- Quran text is never modified; Tanzil attribution stays visible.
- Adhkar completion marks the section and the morning/evening streak.
- Prayer streak counts only days with all five prayers; the dashboard shows
  today’s 1/5 progress separately.
- Device location uses `geolocator` plus a small native IANA timezone channel;
  manual city selection remains the fallback.
- M4 reader uses `scrollable_positioned_list` and saves the first visible ayah.
- Each prayer has its own pre-alert offset (0/5/10/15/20 minutes); the
  per-prayer switch enables or disables both the adhan and its pre-alert.
- iOS keeps the earliest 60 pending notifications (within the platform's 64
  limit) until the next launch/resume refresh.
