import { api, isTauri } from "$lib/api";
import adhanUrl from "$lib/assets/adhan.ogg?url";
import { i18n } from "$lib/i18n/index.svelte.ts";
import { player } from "$lib/stores/player.svelte.ts";
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
  /** Set when the bundled recording failed to load or decode. */
  error = $state<string | null>(null);

  private audio: HTMLAudioElement | null = null;
  private wasPlaying = false;
  private listening = false;
  private loading: Promise<void> | null = null;
  private saveToken = 0;

  async init() {
    if (this.loading) return this.loading;
    this.loading = (async () => {
      await this.reload();
      if (!isTauri || this.listening) return;
      this.listening = true;
      try {
        const { listen } = await import("@tauri-apps/api/event");
        await listen<PlayEvent>("adhan:play", (event) => {
          void this.play(event.payload.volume);
        });
        await listen("adhan:stop", () => this.stop());
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
    const token = ++this.saveToken;
    this.settings = next;
    try {
      const saved = await api.setAdhanSettings(next);
      // Rapid toggles can resolve out of order; only the newest response wins.
      if (token === this.saveToken) this.settings = saved;
    } catch {
      if (token === this.saveToken) {
        this.settings = previous;
        ui.notify(i18n.t("adhan.saveFailed"));
      }
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
    void api.testAdhan().catch(() => {});
  }

  setVolume(volume: number) {
    if (this.audio) {
      this.audio.volume = Math.max(0, Math.min(1, volume));
    }
  }

  async play(volume: number) {
    // Replacing a playing adhan keeps the original music-pause decision.
    if (this.audio) this.stopInternal(false);
    if (!this.wasPlaying) {
      this.wasPlaying = player.playing;
      if (this.wasPlaying) void player.toggle();
    }

    this.blocked = false;
    this.error = null;
    const audio = new Audio(adhanUrl);
    audio.volume = Math.max(0, Math.min(1, volume));

    const finish = (failed: boolean) => {
      if (this.audio !== audio) return;
      this.audio = null;
      this.playing = false;
      audio.onended = null;
      audio.onerror = null;
      audio.pause();
      audio.removeAttribute("src");
      audio.load();
      if (failed) {
        this.error = i18n.t("adhan.playFailed");
        ui.notify(this.error);
      }
      this.resumeMusic();
    };

    audio.onended = () => finish(false);
    audio.onerror = () => finish(true);
    this.audio = audio;
    this.playing = true;

    try {
      await audio.play();
    } catch {
      if (this.audio === audio) {
        this.blocked = true;
        finish(true);
      }
    }
  }

  stop() {
    this.stopInternal(true);
  }

  private stopInternal(resumeMusic: boolean) {
    const audio = this.audio;
    if (!audio) return;
    this.audio = null;
    this.playing = false;
    audio.onended = null;
    audio.onerror = null;
    audio.pause();
    audio.removeAttribute("src");
    audio.load();
    if (resumeMusic) this.resumeMusic();
  }

  private resumeMusic() {
    if (!this.wasPlaying) return;
    this.wasPlaying = false;
    if (!player.playing) void player.toggle();
  }
}

export const adhan = new AdhanStore();
