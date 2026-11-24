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
  /** Seconds until the next prayer, derived from an absolute deadline. */
  remaining = $state(0);
  /** A log mutation is in flight; disable the toggles until it settles. */
  pending = $state(false);

  #timer: ReturnType<typeof setInterval> | null = null;
  #deadline = 0;
  #refreshPromise: Promise<void> | null = null;
  #refreshAgain = false;
  #lastSweep = 0;
  #lastDateCheck = 0;
  #cleanups: (() => void)[] = [];

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
      this.#apply(day, logs, streak);
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      this.loading = false;
    }
  }

  #apply(day: PrayerDay, logs: PrayerLog[], streak: PrayerStreak) {
    this.day = day;
    this.logs = logs;
    this.streak = streak;
    this.remaining = day.remainingS;
    // Absolute deadline rather than a decrementing counter: OS sleep and
    // WebView2 throttling must not leave the card showing a past prayer.
    this.#deadline = day.remainingS > 0 ? Date.now() + day.remainingS * 1000 : 0;
  }

  /**
   * Re-read times and the log. If a refresh is already running, queue exactly
   * one more pass so a save that lands mid-refresh is not lost.
   */
  refresh(): Promise<void> {
    if (this.#refreshPromise) {
      this.#refreshAgain = true;
      return this.#refreshPromise;
    }
    this.#refreshPromise = this.#refreshLoop().finally(() => {
      this.#refreshPromise = null;
    });
    return this.#refreshPromise;
  }

  async #refreshLoop() {
    try {
      do {
        this.#refreshAgain = false;
        const [day, logs, streak] = await Promise.all([
          api.prayerDay(),
          api.prayerLogs(),
          api.prayerStreak(),
        ]);
        this.#apply(day, logs, streak);
        this.error = null;
      } while (this.#refreshAgain);
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    }
  }

  start() {
    if (this.#timer !== null) return;
    this.#timer = setInterval(() => this.tick(), 1000);
    if (typeof document !== "undefined") {
      const onVisible = () => {
        if (!document.hidden) void this.refresh();
      };
      document.addEventListener("visibilitychange", onVisible);
      window.addEventListener("focus", onVisible);
      this.#cleanups.push(() => document.removeEventListener("visibilitychange", onVisible));
      this.#cleanups.push(() => window.removeEventListener("focus", onVisible));
    }
  }

  stop() {
    if (this.#timer !== null) {
      clearInterval(this.#timer);
      this.#timer = null;
    }
    for (const cleanup of this.#cleanups.splice(0)) cleanup();
  }

  private tick() {
    const now = Date.now();
    if (this.#deadline > 0) {
      this.remaining = Math.max(0, Math.ceil((this.#deadline - now) / 1000));
      if (this.remaining === 0) {
        // Deadline reached, or the clock jumped while the app was asleep.
        if (now - this.#lastSweep > 5000) {
          this.#lastSweep = now;
          void this.refresh();
        }
        return;
      }
    }

    // Midnight can pass before the next prayer arrives, changing the log's
    // day. Checking twice a minute is cheap and does not poll the disk.
    if (now - this.#lastDateCheck > 30000) {
      this.#lastDateCheck = now;
      if (this.day && this.day.date !== this.localDate()) void this.refresh();
    }
  }

  /** Local calendar date in the configured timezone, `YYYY-MM-DD`. */
  localDate(): string {
    const timezone = this.settings?.timezone ?? "UTC";
    try {
      const parts = new Intl.DateTimeFormat("en-US", {
        timeZone: timezone,
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      }).formatToParts(new Date());
      const value = (type: string) => parts.find((part) => part.type === type)?.value ?? "";
      return `${value("year")}-${value("month")}-${value("day")}`;
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
    if (this.pending) return;
    const today = this.localDate();
    // Resolve the target day at click time, not from a possibly stale render.
    if (this.day && this.day.date !== today) await this.refresh();
    if (this.pending) return;
    const existing = this.logs.find((log) => log.date === today) ?? emptyLog(today);
    const done = (existing as unknown as Record<string, boolean>)[prayer] === true;

    this.pending = true;
    try {
      this.upsert(await api.setPrayerDone(today, prayer, !done));
      this.streak = await api.prayerStreak();
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      this.pending = false;
    }
  }

  async setExcused(excused: boolean) {
    if (this.pending) return;
    const today = this.localDate();
    if (this.day && this.day.date !== today) await this.refresh();
    if (this.pending) return;

    this.pending = true;
    try {
      this.upsert(await api.setPrayerExcused(today, excused));
      this.streak = await api.prayerStreak();
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      this.pending = false;
    }
  }

  async saveSettings(settings: WorshipSettings) {
    this.settings = await api.setWorshipSettings(settings);
    await this.refresh();
    return this.settings;
  }
}

export const worship = new WorshipStore();
