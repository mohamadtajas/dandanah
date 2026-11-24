import { api } from "$lib/api";
import type { PrayerDay, PrayerLog, PrayerStreak, WorshipSettings } from "$lib/types";

export const PRAYER_KEYS = ["fajr", "dhuhr", "asr", "maghrib", "isha"] as const;

export function emptyLog(date: string): PrayerLog {
  return {
    date,
    fajr: false,
    dhuhr: false,
    asr: false,
    maghrib: false,
    isha: false,
    excused: false,
  };
}

export function logCount(log: PrayerLog | undefined): number {
  if (!log) return 0;
  return PRAYER_KEYS.filter((key) => log[key]).length;
}

export function logComplete(log: PrayerLog | undefined): boolean {
  return logCount(log) === PRAYER_KEYS.length;
}

class WorshipStore {
  settings = $state<WorshipSettings | null>(null);
  day = $state<PrayerDay | null>(null);
  logs = $state<PrayerLog[]>([]);
  streak = $state<PrayerStreak | null>(null);
  loading = $state(false);
  error = $state<string | null>(null);
  /** Seconds until the next prayer, counted down locally. */
  remaining = $state(0);

  #timer: ReturnType<typeof setInterval> | null = null;
  #refreshing = false;
  #lastSweep = 0;

  async load() {
    this.loading = true;
    this.error = null;
    try {
      const [settings, day, logs, streak] = await Promise.all([
        api.worshipSettings(),
        api.prayerDay(),
        api.prayerLogs(),
        api.prayerStreak(),
      ]);
      this.settings = settings;
      this.day = day;
      this.logs = logs;
      this.streak = streak;
      this.remaining = day.remainingS;
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      this.loading = false;
    }
  }

  /** Re-read times and the log without showing the first-load skeleton. */
  async refresh() {
    if (this.#refreshing) return;
    this.#refreshing = true;
    try {
      const [day, logs, streak] = await Promise.all([
        api.prayerDay(),
        api.prayerLogs(),
        api.prayerStreak(),
      ]);
      this.day = day;
      this.logs = logs;
      this.streak = streak;
      this.remaining = day.remainingS;
      this.error = null;
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      this.#refreshing = false;
    }
  }

  start() {
    if (this.#timer !== null) return;
    this.#timer = setInterval(() => this.tick(), 1000);
  }

  stop() {
    if (this.#timer === null) return;
    clearInterval(this.#timer);
    this.#timer = null;
  }

  private tick() {
    if (this.remaining > 0) {
      this.remaining -= 1;
      // Midnight can pass before the next prayer arrives, changing the log's
      // day. Check twice a minute without a network or disk round-trip.
      if (this.remaining % 30 === 0 && this.day && this.day.date !== this.localDate()) {
        void this.refresh();
      }
      return;
    }
    // Countdown finished or the day rolled over. Sweep at most every 5s so a
    // failed refresh cannot spin.
    const now = Date.now();
    if (this.day && now - this.#lastSweep > 5000) {
      this.#lastSweep = now;
      void this.refresh();
    }
  }

  /** Local calendar date in the configured timezone, `YYYY-MM-DD`. */
  localDate(): string {
    const timezone = this.settings?.timezone ?? "UTC";
    try {
      return new Intl.DateTimeFormat("en-CA", {
        timeZone: timezone,
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      }).format(new Date());
    } catch {
      return new Date().toISOString().slice(0, 10);
    }
  }

  get todayLog(): PrayerLog {
    const date = this.day?.date ?? this.localDate();
    return this.logs.find((log) => log.date === date) ?? emptyLog(date);
  }

  get nextLabelKey(): "prayer.fajr" | "prayer.dhuhr" | "prayer.asr" | "prayer.maghrib" | "prayer.isha" {
    switch (this.day?.next?.key) {
      case "dhuhr":
        return "prayer.dhuhr";
      case "asr":
        return "prayer.asr";
      case "maghrib":
        return "prayer.maghrib";
      case "isha":
        return "prayer.isha";
      default:
        return "prayer.fajr";
    }
  }

  private upsert(log: PrayerLog) {
    const index = this.logs.findIndex((item) => item.date === log.date);
    if (index >= 0) {
      this.logs[index] = log;
    } else {
      this.logs = [...this.logs, log].sort((a, b) => a.date.localeCompare(b.date));
    }
  }

  async togglePrayer(prayer: string) {
    const log = this.todayLog;
    const done = (log as unknown as Record<string, boolean>)[prayer] === true;
    try {
      this.upsert(await api.setPrayerDone(log.date, prayer, !done));
      this.streak = await api.prayerStreak();
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    }
  }

  async setExcused(excused: boolean) {
    const date = this.todayLog.date;
    try {
      this.upsert(await api.setPrayerExcused(date, excused));
      this.streak = await api.prayerStreak();
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    }
  }

  async saveSettings(settings: WorshipSettings) {
    this.settings = await api.setWorshipSettings(settings);
    await this.refresh();
    return this.settings;
  }
}

export const worship = new WorshipStore();
