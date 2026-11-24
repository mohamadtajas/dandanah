import { api, isTauri } from "$lib/api";
import { convertFileSrc } from "@tauri-apps/api/core";
import type { Track } from "$lib/types";
import { library } from "$lib/stores/library.svelte.ts";

type RepeatMode = "off" | "all" | "one";

const VOLUME_KEY = "dandanah.volume";
const RATE_KEY = "dandanah.rate";

class PlayerStore {
  current = $state<Track | null>(null);
  queue = $state<Track[]>([]);
  index = $state(-1);
  playing = $state(false);
  loading = $state(false);
  position = $state(0);
  duration = $state(0);
  buffered = $state(0);
  volume = $state(0.9);
  muted = $state(false);
  rate = $state(1);
  repeat = $state<RepeatMode>("off");
  shuffle = $state(false);
  error = $state<string | null>(null);
  queueOpen = $state(false);

  /** Optional hook that can take over when a track finishes (hifz loops). */
  onEndedHook: (() => Promise<"stop" | "handled" | false> | "stop" | "handled" | false) | null =
    null;

  private audio: HTMLAudioElement | null = null;

  constructor() {
    if (typeof localStorage !== "undefined") {
      const v = Number(localStorage.getItem(VOLUME_KEY));
      if (Number.isFinite(v) && v >= 0 && v <= 1 && localStorage.getItem(VOLUME_KEY)) {
        this.volume = v;
      }
      const r = Number(localStorage.getItem(RATE_KEY));
      if (Number.isFinite(r) && r > 0) this.rate = r;
    }
  }

  get isLive(): boolean {
    return Boolean(this.current?.live);
  }

  get progress(): number {
    if (this.isLive || !this.duration) return 0;
    return Math.min(1, this.position / this.duration);
  }

  private ensureAudio(): HTMLAudioElement {    if (this.audio) return this.audio;

    const a = new Audio();
    a.preload = "auto";
    a.volume = this.muted ? 0 : this.volume;
    a.preservesPitch = true;

    a.addEventListener("timeupdate", () => {
      this.position = a.currentTime;
    });
    a.addEventListener("durationchange", () => {
      this.duration = Number.isFinite(a.duration) ? a.duration : 0;
    });
    a.addEventListener("progress", () => {
      if (a.buffered.length) {
        this.buffered = a.buffered.end(a.buffered.length - 1);
      }
    });
    a.addEventListener("playing", () => {
      this.playing = true;
      this.loading = false;
      this.error = null;
    });
    a.addEventListener("pause", () => {
      this.playing = false;
    });
    a.addEventListener("waiting", () => {
      this.loading = true;
    });
    a.addEventListener("canplay", () => {
      this.loading = false;
    });
    a.addEventListener("error", () => {
      this.loading = false;
      this.playing = false;
      this.error = "stream-error";
    });
    a.addEventListener("ended", () => this.onEnded());

    this.audio = a;
    return a;
  }

  /** Prefers a downloaded or imported file over the remote stream. */
  private sourceFor(track: Track): string {
    const localPath = track.localPath ?? library.localPathFor(track.id);
    if (localPath && isTauri) return convertFileSrc(localPath);
    return track.streamUrl ?? "";
  }

  async play(track: Track, queue?: Track[]) {
    if (queue && queue.length) {
      this.queue = queue;
      this.index = queue.findIndex((t) => t.id === track.id);
      if (this.index < 0) {
        this.queue = [track, ...queue];
        this.index = 0;
      }
    } else if (!this.queue.some((t) => t.id === track.id)) {
      this.queue = [track];
      this.index = 0;
    } else {
      this.index = this.queue.findIndex((t) => t.id === track.id);
    }

    this.current = track;
    this.position = 0;
    this.duration = 0;
    this.buffered = 0;
    this.error = null;
    this.loading = true;

    const a = this.ensureAudio();
    a.src = this.sourceFor(track);
    a.playbackRate = this.rate;

    try {
      await a.play();
      this.playing = true;
    } catch (e) {
      this.loading = false;
      this.playing = false;
      this.error = e instanceof Error ? e.message : String(e);
    }

    this.updateMediaSession(track);
    api.recordPlay(track).catch(() => {});
  }

  async toggle() {
    if (!this.current) {
      if (this.queue.length) {
        await this.play(this.queue[0]);
      }
      return;
    }
    const a = this.ensureAudio();
    if (a.paused) {
      try {
        await a.play();
        this.playing = true;
        this.setMediaPlaybackState("playing");
      } catch (e) {
        this.error = e instanceof Error ? e.message : String(e);
      }
    } else {
      a.pause();
      this.playing = false;
      this.setMediaPlaybackState("paused");
    }
  }

  async next() {
    if (!this.queue.length) return;
    let target: number;
    if (this.shuffle && this.queue.length > 1) {
      do {
        target = Math.floor(Math.random() * this.queue.length);
      } while (target === this.index);
    } else {
      target = this.index + 1;
      if (target >= this.queue.length) {
        if (this.repeat === "all") target = 0;
        else return;
      }
    }
    await this.play(this.queue[target]);
  }

  async prev() {
    if (!this.queue.length) return;
    const a = this.ensureAudio();
    if (a.currentTime > 4) {
      a.currentTime = 0;
      return;
    }
    let target = this.index - 1;
    if (target < 0) target = this.repeat === "all" ? this.queue.length - 1 : 0;
    await this.play(this.queue[target]);
  }

  seek(seconds: number) {
    if (this.isLive) return;
    const a = this.ensureAudio();
    a.currentTime = Math.max(0, Math.min(seconds, this.duration || 0));
    this.position = a.currentTime;
  }

  seekToFraction(fraction: number) {
    if (!this.duration) return;
    this.seek(fraction * this.duration);
  }

  setVolume(v: number) {
    this.volume = Math.max(0, Math.min(1, v));
    this.muted = this.volume === 0;
    if (this.audio) this.audio.volume = this.volume;
    if (typeof localStorage !== "undefined") {
      localStorage.setItem(VOLUME_KEY, String(this.volume));
    }
  }

  toggleMute() {
    this.muted = !this.muted;
    if (this.audio) this.audio.volume = this.muted ? 0 : this.volume;
  }

  setRate(r: number) {
    this.rate = r;
    if (this.audio) this.audio.playbackRate = r;
    if (typeof localStorage !== "undefined") localStorage.setItem(RATE_KEY, String(r));
  }

  cycleRate() {
    const steps = [0.75, 0.85, 1, 1.15, 1.25, 1.5];
    const i = steps.indexOf(this.rate);
    this.setRate(steps[(i + 1) % steps.length]);
  }

  cycleRepeat() {
    this.repeat = this.repeat === "off" ? "all" : this.repeat === "all" ? "one" : "off";
  }

  stop() {
    const a = this.audio;
    if (a) {
      a.pause();
      a.removeAttribute("src");
      a.load();
    }
    this.current = null;
    this.playing = false;
    this.position = 0;
    this.duration = 0;
  }

  private onEnded: () => Promise<void> = async () => {
    if (this.onEndedHook) {
      const outcome = await this.onEndedHook();
      if (outcome === "stop") {
        this.playing = false;
        this.position = this.duration;
        this.setMediaPlaybackState("paused");
        return;
      }
      if (outcome === "handled") return;
    }
    if (this.repeat === "one") {
      const a = this.ensureAudio();
      a.currentTime = 0;
      await a.play().catch(() => {});
      return;
    }
    await this.next();
  };

  private setMediaPlaybackState(state: MediaSessionPlaybackState) {
    if ("mediaSession" in navigator) {
      try {
        navigator.mediaSession.playbackState = state;
      } catch {
        /* ignore */
      }
    }
  }

  private updateMediaSession(track: Track) {
    if (!("mediaSession" in navigator)) return;
    try {
      navigator.mediaSession.metadata = new MediaMetadata({
        title: track.title,
        artist: track.artist,
        album: track.album ?? "دندنة",
        artwork: track.artworkUrl ? [{ src: track.artworkUrl, sizes: "512x512" }] : [],
      });
      navigator.mediaSession.setActionHandler("play", () => this.toggle());
      navigator.mediaSession.setActionHandler("pause", () => this.toggle());
      navigator.mediaSession.setActionHandler("nexttrack", () => this.next());
      navigator.mediaSession.setActionHandler("previoustrack", () => this.prev());
      navigator.mediaSession.setActionHandler("seekto", (d) => {
        if (typeof d.seekTime === "number") this.seek(d.seekTime);
      });
      navigator.mediaSession.playbackState = "playing";
    } catch {
      /* media session is best-effort */
    }
  }
}

export const player = new PlayerStore();
