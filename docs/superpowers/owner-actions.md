# Owner actions

Running list of things only the owner can decide or provide. I keep working on
independent tasks while these are open.

## Needed before M5 audio can be finished

- **Confirm mobile use of EveryAyah:** M5 currently streams eight EveryAyah
  reciters, reusing the desktop-approved source and attribution. Confirm that
  mobile distribution is allowed; if not, name the replacement provider.
- **Download/storage budget:** decide whether mobile downloads are in v1 and
  set a cap (for example “warn above 2 GB, never auto-download on cellular”).
- **Anasheed source:** choose the catalogue source and confirm the licence for
  bundled/streamed tracks.
- **Adhan audio:** confirm the desktop CC0 adhan file may be bundled on mobile.
- **Provider keys:** any API key or account needed by a chosen provider.

## Needed before release (M10)

- Android keystore file, alias, and passwords.
- GitHub Actions secrets for signing (`ANDROID_KEYSTORE_BASE64`,
  `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`).
- Play Console app entry and package ownership confirmation.
- Apple Developer team, bundle id confirmation, and a Mac/Xcode signing path.
- Decide the public app name and store description.

## Physical tests only the owner can run

- Large-system-font pass on the phone after M4/M5.
- Airplane-mode reading and audio playback.
- Background audio for 30+ minutes, lock screen and Bluetooth controls (M5).
- Adhan exact-alarm/Doze behaviour on the real device (M6), including a
  reboot-reschedule check and OEM battery settings.
- iOS adhan sound: a 29-second CC0 excerpt (`adhan.caf`, Apple's 30-second
  notification limit) is now bundled; verify it on a real iPhone.
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
