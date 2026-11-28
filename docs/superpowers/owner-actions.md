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
- Confirm the other radio stations on the phone network (the Kuwait Quran
  station streamed successfully on BKQ-N49).

## Physical test results (2026-11-28, BKQ-N49)

- Adhan test notification delivered through `adhan_3_v2` with Android
  `USAGE_ALARM`; it stayed audible even though the notification stream was
  muted. The immediate test notification and snackbar both appeared.
- Exact scheduled test ("اختبار بعد دقيقتين") fired at 10:45:18 with the screen
  off, within a few seconds of the requested time, and used the alarm stream.
- Health card reported notifications and exact alarms allowed, battery
  unrestricted, 298 prayer notifications scheduled.
- Quran playback continued in the background and reached ayah 6 after 30 s;
  the whole-surah player showed 0:49 total and seeked correctly to ayah 7.
- Kuwait Quran radio streamed on the phone network, continued with the screen
  off and in the background, and showed lock-screen media controls.
- The morning adhkar reminder increased the scheduled count by 29 (one per
  remaining day), then was turned back off.
- 2x text pass: audio mode dropdown, list and settings rendered without
  overflow; font scale restored to 1.0.
- A pre-existing system alarm rang at 10:30 and paused radio once; after
  dismissing it, the radio background test passed. The alarm was snoozed and
  then dismissed; no app alarm was involved.

## Physical tests only the owner can run

- Large-system-font pass: done on BKQ-N49 at 2× for the dashboard, adhkar,
  Quran catalog/reader, audio, settings and adhan screens.
- Airplane-mode reading and audio playback (the error banner/retry was verified
  on the emulator; repeat on the phone).
- Background audio for 30+ minutes, lock screen and Bluetooth controls (M5).
- A full-reciter download and a reboot with the downloaded files present.
- Adhan exact-alarm/Doze behaviour: exact scheduled test passed with the screen
  off on BKQ-N49; still run the reboot-reschedule check and review OEM battery
  settings.
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
