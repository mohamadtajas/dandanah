import { api } from "$lib/api";
import type {
  Ayah,
  Juz,
  JuzTranslation,
  QuranBookmark,
  ReaderPosition,
  Surah,
} from "$lib/types";

const FONT_KEY = "sakeenah.reader.font";
const TRANSLATION_KEY = "sakeenah.reader.translation";

function readFont(): number {
  if (typeof localStorage === "undefined") return 30;
  const value = Number(localStorage.getItem(FONT_KEY));
  return Number.isFinite(value) && value >= 20 && value <= 48 ? value : 30;
}

function readTranslation(): boolean {
  if (typeof localStorage === "undefined") return false;
  return localStorage.getItem(TRANSLATION_KEY) === "1";
}

class ReaderStore {
  surahs = $state<Surah[]>([]);
  juzs = $state<Juz[]>([]);
  bookmarks = $state<QuranBookmark[]>([]);
  position = $state<ReaderPosition | null>(null);

  ayahs = $state<Ayah[]>([]);
  mode = $state<"surah" | "juz">("surah");
  surah = $state(1);
  juz = $state(1);
  loading = $state(false);
  loadingIndex = $state(false);
  error = $state<string | null>(null);
  indexError = $state<string | null>(null);
  daily = $state<Ayah | null>(null);

  translation = $state(readTranslation());
  translationLoading = $state(false);
  translationFailed = $state(false);
  fontSize = $state(readFont());
  scrollTarget = $state<{ surah: number; ayah: number } | null>(null);

  #requestId = 0;
  #bookmarkPending = new Set<string>();

  async loadIndex() {
    this.loadingIndex = true;
    this.indexError = null;
    const [surahs, juzs, bookmarks, position] = await Promise.allSettled([
      api.surahs(),
      api.juzs(),
      api.quranBookmarks(),
      api.readerPosition(),
    ]);
    if (surahs.status === "fulfilled") this.surahs = surahs.value;
    if (juzs.status === "fulfilled") this.juzs = juzs.value;
    if (bookmarks.status === "fulfilled") this.bookmarks = bookmarks.value;
    if (position.status === "fulfilled") this.position = position.value;

    const failed = [bookmarks, position].some((result) => result.status === "rejected");
    if (failed) this.indexError = "reader.indexError";
    if (surahs.status === "rejected" && juzs.status === "rejected") {
      this.indexError = "reader.error";
    }
    this.loadingIndex = false;
  }

  get surahMeta(): Surah | null {
    return this.surahs.find((entry) => entry.number === this.surah) ?? null;
  }

  get juzMeta(): Juz | null {
    return this.juzs.find((entry) => entry.number === this.juz) ?? null;
  }

  isBookmarked(surah: number, ayah: number): boolean {
    return this.bookmarks.some((entry) => entry.surah === surah && entry.ayah === ayah);
  }

  async openSurah(number: number, ayah?: number) {
    const requestId = ++this.#requestId;
    this.mode = "surah";
    this.surah = number;
    this.loading = true;
    this.error = null;
    this.scrollTarget = null;
    this.translationFailed = false;
    this.translationLoading = false;
    try {
      const ayahs = await api.surahText(number);
      if (requestId !== this.#requestId) return;
      this.ayahs = ayahs;
      if (ayah && ayah > 0) {
        this.scrollTarget = { surah: number, ayah };
        void this.savePosition(number, ayah, "surah", this.juz);
      }
    } catch (error) {
      if (requestId !== this.#requestId) return;
      this.ayahs = [];
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      if (requestId === this.#requestId) this.loading = false;
    }
    if (this.translation && requestId === this.#requestId) {
      void this.#translateCurrent(requestId);
    }
  }

  async openJuz(number: number, target?: { surah: number; ayah: number }) {
    const requestId = ++this.#requestId;
    this.mode = "juz";
    this.juz = number;
    this.loading = true;
    this.error = null;
    this.scrollTarget = target ?? null;
    this.translationFailed = false;
    this.translationLoading = false;
    try {
      const ayahs = await api.juzAyahs(number);
      if (requestId !== this.#requestId) return;
      this.ayahs = ayahs;
      if (target) void this.savePosition(target.surah, target.ayah, "juz", number);
    } catch (error) {
      if (requestId !== this.#requestId) return;
      this.ayahs = [];
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      if (requestId === this.#requestId) this.loading = false;
    }
    if (this.translation && requestId === this.#requestId) {
      void this.#translateCurrent(requestId);
    }
  }

  async #translateCurrent(requestId: number) {
    this.translationLoading = true;
    this.translationFailed = false;
    try {
      if (this.mode === "juz") {
        const entries = await api.juzTranslation(this.juz);
        if (requestId !== this.#requestId) return;
        const bySurah = new Map(entries.map((entry) => [entry.surah, entry.translations]));
        this.ayahs = this.ayahs.map((ayah) => {
          const list = ayah.surah ? bySurah.get(ayah.surah) : undefined;
          return { ...ayah, translation: list?.[ayah.number - 1] || undefined };
        });
        this.translationFailed = entries.length === 0;
      } else {
        const list = await api.surahTranslation(this.surah);
        if (requestId !== this.#requestId) return;
        this.ayahs = this.ayahs.map((ayah) => ({
          ...ayah,
          translation: list[ayah.number - 1] || undefined,
        }));
        this.translationFailed = list.length === 0;
      }
    } catch {
      if (requestId === this.#requestId) this.translationFailed = true;
    } finally {
      if (requestId === this.#requestId) this.translationLoading = false;
    }
  }

  async reload() {
    if (this.mode === "juz") {
      await this.openJuz(this.juz);
    } else {
      await this.openSurah(this.surah);
    }
  }

  async savePosition(
    surah: number,
    ayah: number,
    mode: "surah" | "juz" = this.mode,
    juz: number = this.juz,
  ) {
    this.position = { mode, juz, surah, ayah, updatedAt: Date.now() };
    try {
      this.position = await api.saveReaderPosition(mode, juz, surah, ayah);
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    }
  }

  selectAyah(ayah: Ayah) {
    if (ayah.surah) void this.savePosition(ayah.surah, ayah.number);
  }

  async toggleBookmark(surah: number, ayah: number) {
    const key = `${surah}:${ayah}`;
    if (this.#bookmarkPending.has(key)) return;
    this.#bookmarkPending.add(key);
    try {
      if (this.isBookmarked(surah, ayah)) {
        await api.removeQuranBookmark(surah, ayah);
        this.bookmarks = this.bookmarks.filter(
          (entry) => !(entry.surah === surah && entry.ayah === ayah),
        );
      } else {
        const bookmark = await api.addQuranBookmark(surah, ayah);
        this.bookmarks = [
          bookmark,
          ...this.bookmarks.filter(
            (entry) => !(entry.surah === surah && entry.ayah === ayah),
          ),
        ];
      }
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      this.#bookmarkPending.delete(key);
    }
  }

  setFontSize(size: number) {
    this.fontSize = Math.max(20, Math.min(48, Math.round(size)));
    if (typeof localStorage !== "undefined") {
      localStorage.setItem(FONT_KEY, String(this.fontSize));
    }
  }

  async setTranslation(enabled: boolean) {
    this.translation = enabled;
    if (typeof localStorage !== "undefined") {
      localStorage.setItem(TRANSLATION_KEY, enabled ? "1" : "0");
    }
    if (!enabled) {
      this.translationLoading = false;
      this.translationFailed = false;
      this.ayahs = this.ayahs.map((ayah) => ({ ...ayah, translation: undefined }));
      return;
    }
    await this.#translateCurrent(this.#requestId);
  }

  async loadDaily() {
    try {
      this.daily = await api.dailyAyah();
    } catch {
      // The daily card is decorative; the reader remains usable.
    }
  }

  clearScrollTarget() {
    this.scrollTarget = null;
  }
}

export const reader = new ReaderStore();
