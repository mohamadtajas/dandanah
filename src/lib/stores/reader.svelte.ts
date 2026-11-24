import { api } from "$lib/api";
import type { Ayah, Juz, QuranBookmark, ReaderPosition, Surah } from "$lib/types";

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
  daily = $state<Ayah | null>(null);

  translation = $state(readTranslation());
  fontSize = $state(readFont());
  scrollTarget = $state<{ surah: number; ayah: number } | null>(null);

  async loadIndex() {
    this.loadingIndex = true;
    try {
      const [surahs, juzs, bookmarks, position] = await Promise.all([
        api.surahs(),
        api.juzs(),
        api.quranBookmarks(),
        api.readerPosition(),
      ]);
      this.surahs = surahs;
      this.juzs = juzs;
      this.bookmarks = bookmarks;
      this.position = position;
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      this.loadingIndex = false;
    }
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
    this.mode = "surah";
    this.surah = number;
    this.loading = true;
    this.error = null;
    this.scrollTarget = null;
    try {
      this.ayahs = await api.surahText(number, this.translation);
      if (ayah && ayah > 0) {
        this.scrollTarget = { surah: number, ayah };
        void this.savePosition(number, ayah);
      }
    } catch (error) {
      this.ayahs = [];
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      this.loading = false;
    }
  }

  async openJuz(number: number) {
    this.mode = "juz";
    this.juz = number;
    this.loading = true;
    this.error = null;
    this.scrollTarget = null;
    try {
      this.ayahs = await api.juzAyahs(number, this.translation);
    } catch (error) {
      this.ayahs = [];
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      this.loading = false;
    }
  }

  async reload() {
    if (this.mode === "juz") {
      await this.openJuz(this.juz);
    } else {
      await this.openSurah(this.surah);
    }
  }

  async savePosition(surah: number, ayah: number) {
    this.position = { surah, ayah, updatedAt: Date.now() };
    try {
      this.position = await api.saveReaderPosition(surah, ayah);
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    }
  }

  selectAyah(ayah: Ayah) {
    if (ayah.surah) void this.savePosition(ayah.surah, ayah.number);
  }

  async toggleBookmark(surah: number, ayah: number) {
    try {
      if (this.isBookmarked(surah, ayah)) {
        await api.removeQuranBookmark(surah, ayah);
        this.bookmarks = this.bookmarks.filter(
          (entry) => !(entry.surah === surah && entry.ayah === ayah),
        );
      } else {
        const bookmark = await api.addQuranBookmark(surah, ayah);
        this.bookmarks = [bookmark, ...this.bookmarks];
      }
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
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
    await this.reload();
  }

  async loadDaily() {
    if (this.daily) return;
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
