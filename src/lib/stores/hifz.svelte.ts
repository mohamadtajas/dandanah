import { api } from "$lib/api";
import type { Track } from "$lib/types";
import { player } from "$lib/stores/player.svelte.ts";

/** Repetition counts offered in the hifz panel. */
export const PASS_OPTIONS = [1, 3, 5, 7, 10] as const;

/** Reads the surah number out of an EveryAyah provider id (`folder:SSSAAA`). */
export function surahOf(track: Track | null | undefined): number | null {
  if (!track || track.provider !== "everyayah") return null;
  const id = track.providerId;
  const digits = id.slice(id.lastIndexOf(":") + 1);
  if (digits.length !== 6) return null;
  const surah = Number(digits.slice(0, 3));
  return Number.isFinite(surah) && surah > 0 ? surah : null;
}

/** Reads the ayah number out of an EveryAyah provider id (`folder:SSSAAA`). */
export function ayahOf(track: Track | null | undefined): number | null {
  if (!track || track.provider !== "everyayah") return null;
  const id = track.providerId;
  const digits = id.slice(id.lastIndexOf(":") + 1);
  if (digits.length !== 6) return null;
  const ayah = Number(digits.slice(3));
  return Number.isFinite(ayah) && ayah > 0 ? ayah : null;
}

/**
 * Ayah-range repetition for memorisation. It owns the player's `ended` hook
 * while a surah is open, so a range replays without touching the queue.
 */
class HifzStore {
  /** Loop enabled. When off, playback behaves normally. */
  active = $state(false);
  from = $state(1);
  to = $state(1);
  /** How many times the whole range is played before stopping. */
  passes = $state(3);
  /** Completed passes in the current cycle. */
  pass = $state(0);
  surah = $state(0);
  reciterId = $state("");
  memorized = $state<number[]>([]);
  lastAyah = $state(1);
  /** Set when a cycle ends, cleared on the next interaction. */
  justCompleted = $state(false);

  private hooked = false;
  /** Guards async `attach` against a component that unmounts mid-load. */
  private token = 0;

  get count(): number {
    return this.memorized.length;
  }

  get passesLeft(): number {
    return Math.max(0, this.passes - this.pass);
  }

  has(ayah: number): boolean {
    return this.memorized.includes(ayah);
  }

  async attach(surah: number, reciterId: string) {
    const token = ++this.token;
    if (this.surah !== surah || this.reciterId !== reciterId) {
      this.active = false;
      this.pass = 0;
      this.justCompleted = false;
      this.surah = surah;
      this.reciterId = reciterId;
      const [marks, position] = await Promise.all([
        api.memorized(surah).catch(() => [] as number[]),
        api.position(surah, reciterId).catch(() => null),
      ]);
      if (token !== this.token) return;
      this.memorized = marks;
      this.lastAyah = position ?? 1;
      this.from = this.lastAyah;
      this.to = this.lastAyah;
    }
    this.hook();
  }

  detach() {
    this.token += 1;
    if (this.hooked) {
      player.onEndedHook = null;
      this.hooked = false;
    }
  }

  private hook() {
    if (this.hooked) return;
    player.onEndedHook = () => this.handleEnded();
    this.hooked = true;
  }

  setRange(from: number, to: number) {
    const lo = Math.max(1, Math.min(from, to));
    const hi = Math.max(1, Math.max(from, to));
    this.from = lo;
    this.to = hi;
    this.pass = 0;
    this.justCompleted = false;
  }

  setPasses(n: number) {
    this.passes = Math.max(1, Math.min(50, Math.round(n)));
    this.pass = 0;
    this.justCompleted = false;
  }

  toggle() {
    this.active = !this.active;
    this.pass = 0;
    this.justCompleted = false;
  }

  /** Keeps the resume position in step with playback. */
  noteAyah(ayah: number) {
    if (ayah === this.lastAyah) return;
    this.lastAyah = ayah;
    if (this.surah) {
      api.savePosition(this.surah, this.reciterId, ayah).catch(() => {});
    }
  }

  async toggleMemorized(ayah: number) {
    const marks = new Set(this.memorized);
    if (marks.has(ayah)) marks.delete(ayah);
    else marks.add(ayah);
    await this.persist([...marks]);
  }

  async markRange() {
    const marks = new Set(this.memorized);
    for (let n = this.from; n <= this.to; n += 1) marks.add(n);
    await this.persist([...marks]);
  }

  async clearRange() {
    const marks = new Set(this.memorized);
    for (let n = this.from; n <= this.to; n += 1) marks.delete(n);
    await this.persist([...marks]);
  }

  private async persist(marks: number[]) {
    const sorted = [...new Set(marks)].sort((a, b) => a - b);
    this.memorized = sorted;
    if (this.surah) {
      await api.saveMemorized(this.surah, sorted).catch(() => {});
    }
  }

  private async handleEnded(): Promise<"stop" | "handled" | false> {
    if (!this.active) return false;
    if (surahOf(player.current) !== this.surah) return false;
    const ayah = ayahOf(player.current);
    if (ayah === null) return false;
    // Outside the chosen range: normal queue behaviour.
    if (ayah < this.from || ayah > this.to) return false;
    // Mid-range: let the player advance to the next ayah.
    if (ayah < this.to) return false;

    this.pass += 1;
    if (this.pass >= this.passes) {
      this.pass = 0;
      // Disarm: the cycle is done, so the panel offers "Repeat" again.
      this.active = false;
      this.justCompleted = true;
      return "stop";
    }
    await this.playAyah(this.from);
    return "handled";
  }

  async playAyah(ayah: number) {
    const track = player.queue.find((t) => ayahOf(t) === ayah);
    if (track) await player.play(track);
  }
}

export const hifz = new HifzStore();
