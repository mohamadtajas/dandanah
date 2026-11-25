import { api, isTauri } from "$lib/api";
import adhanUrl from "$lib/assets/adhan.ogg?url";
import { i18n } from "$lib/i18n/index.svelte.ts";
import { ui } from "$lib/stores/ui.svelte.ts";
import type { AdhanSettings, PrayerAlert } from "$lib/types";

type PlayEvent = {
  prayer: string;
  name: string;
  volume: number;
};

function defaults(): AdhanSettings {
  return {
    enabled: true,
    prayers: {
      fajr: { adhan: true, notify: true },
      dhuhr: { adhan: true, notify: true },
      asr: { adhan: true, notify: true },
      maghrib: { adhan: true, notify: true },
      isha: { adhan: true, notify: true },
    },
    preAlertEnabled: false,
    preAlertMinutes: 10,
    volume: 0.8,
  };
}

class AdhanStore {
  settings = $state<AdhanSettings | null>(null);
  playing = $state(false);
  /** Set when the webview refused to start audio without a gesture. */
  blocked = $state(false);
  previewing = $state(false);

  private audio: HTMLAudioElement | null = null;
  private listening = false;
  private loading: Promise<void> | null = null;

  async init() {
    if (this.loading) return this.loading;
    this.loading = (async () => {
      await this.reload();
      if (!isTauri || this.listening) return;
      this.listening = true;
      try {
        const { listen } = await import("@tauri-apps/api/event");
        await listen<PlayEvent>("adhan:play", (event) => {
          this.previewing = false;
          void this.play(event.payload.volume);
        });
      } catch {
        this.listening = false;
      }
    })();
    return this.loading;
  }

  async reload() {
    this.settings = await api.adhanSettings().catch(() => this.settings ?? defaults());
  }

  async save(next: AdhanSettings) {
    const previous = this.settings;
    this.settings = next;
    try {
      this.settings = await api.setAdhanSettings(next);
    } catch {
      this.settings = previous;
      ui.notify(i18n.t("adhan.saveFailed"));
    }
  }

  async setPrayer(key: string, patch: Partial<PrayerAlert>) {
    if (!this.settings) return;
    await this.save({
      ...this.settings,
      prayers: {
        ...this.settings.prayers,
        [key]: { ...this.settings.prayers[key], ...patch },
      },
    });
  }

  /** Plays from a user gesture; also exercises the native toast path. */
  preview() {
    if (this.settings) void this.play(this.settings.volume);
    this.previewing = true;
    void api.testAdhan().catch(() => {});
  }

  async play(volume: number) {
    this.stop();
    this.blocked = false;
    try {
      const audio = new Audio(adhanUrl);
      audio.volume = Math.max(0, Math.min(1, volume));
      audio.onended = () => {
        if (this.audio === audio) {
          this.playing = false;
          this.audio = null;
        }
      };
      this.audio = audio;
      this.playing = true;
      await audio.play();
    } catch {
      this.playing = false;
      this.blocked = true;
      ui.notify(i18n.t("adhan.playBlocked"));
    }
  }

  stop() {
    if (this.audio) {
      this.audio.pause();
      this.audio.src = "";
      this.audio = null;
    }
    this.playing = false;
  }
}

export const adhan = new AdhanStore();
