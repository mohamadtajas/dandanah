import { api } from "$lib/api";
import type { AdhkarCategory, AdhkarData, AdhkarDay, AdhkarStreak } from "$lib/types";
import { worship } from "$lib/stores/worship.svelte.ts";
import raw from "$lib/data/adhkar.json";

const data = raw as AdhkarData;
export const adhkarCategories = data.categories;
export const featuredAdhkar = data.categories.filter((category) => category.featured);

const key = (categoryId: string, itemId: string) => `${categoryId}::${itemId}`;

class AdhkarStore {
  categories = adhkarCategories;
  featured = featuredAdhkar;
  source = data.source;

  /** Local date as resolved by the backend in the configured timezone. */
  date = $state("");
  day = $state<AdhkarDay | null>(null);
  streak = $state<AdhkarStreak | null>(null);
  /** `category::item` → repetitions still owed. */
  progress = $state<Record<string, number>>({});
  loading = $state(false);
  error = $state<string | null>(null);

  activeCategoryId = $state<string | null>(null);
  activeIndex = $state(0);
  completed = $state(false);

  #queue: Promise<void> = Promise.resolve();
  #timer: ReturnType<typeof setInterval> | null = null;
  #advanceTimer: ReturnType<typeof setTimeout> | null = null;
  #loadGeneration = 0;
  #cleanups: (() => void)[] = [];

  async load() {
    const generation = ++this.#loadGeneration;
    this.loading = true;
    this.error = null;
    this.#clearAdvance();
    try {
      await this.#queue;
      // Passing no date lets the backend resolve "today" from the configured
      // timezone. Its day.date is the only date this store writes to.
      const day = await api.adhkarDay();
      if (generation !== this.#loadGeneration) return;
      const [rows, streak] = await Promise.all([
        api.adhkarProgress(day.date),
        api.adhkarStreak(),
      ]);
      if (generation !== this.#loadGeneration) return;

      this.date = day.date;
      this.day = day;
      this.streak = streak;
      this.progress = Object.fromEntries(
        rows.map((row) => [key(row.categoryId, row.itemId), row.remaining]),
      );
      await this.#reconcile();
      const active = this.activeCategory;
      if (active) {
        this.completed = this.isComplete(active);
        if (!this.completed) this.activeIndex = this.firstIncomplete(active);
      }
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    } finally {
      this.loading = false;
    }
  }

  /** A crash between the last tap and the completion write must not lose the streak. */
  async #reconcile() {
    if (!this.date) return;
    let changed = false;
    for (const category of this.featured) {
      if (!category.streakKey) continue;
      const flag = this.day?.[category.streakKey] ?? false;
      if (!flag && this.isComplete(category)) {
        await api.markAdhkarDone(this.date, category.id);
        changed = true;
      }
    }
    if (changed) {
      this.day = await api.adhkarDay(this.date);
      this.streak = await api.adhkarStreak();
    }
  }

  start() {
    if (this.#timer !== null) return;
    // A local 1s check keeps the midnight rollover tight without polling the
    // database. The initial date still comes from the backend, so this only
    // detects a change after settings are loaded.
    this.#timer = setInterval(() => this.#checkRollover(), 1000);
    if (typeof document !== "undefined") {
      const onVisible = () => {
        if (!document.hidden) this.#checkRollover();
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
    this.#clearAdvance();
    for (const cleanup of this.#cleanups.splice(0)) cleanup();
  }

  #checkRollover() {
    if (!this.date || !worship.settings) return;
    if (worship.localDate() !== this.date) void this.load();
  }

  remainingFor(category: AdhkarCategory, itemId: string): number {
    const item = category.items.find((entry) => entry.id === itemId);
    const stored = this.progress[key(category.id, itemId)];
    return stored === undefined ? (item?.count ?? 0) : stored;
  }

  completedItems(category: AdhkarCategory): number {
    return category.items.filter((item) => this.remainingFor(category, item.id) === 0).length;
  }

  totalRepeats(category: AdhkarCategory): number {
    return category.items.reduce((sum, item) => sum + item.count, 0);
  }

  doneRepeats(category: AdhkarCategory): number {
    return category.items.reduce(
      (sum, item) => sum + Math.max(0, item.count - this.remainingFor(category, item.id)),
      0,
    );
  }

  percent(category: AdhkarCategory): number {
    const total = this.totalRepeats(category);
    return total === 0 ? 0 : Math.round((this.doneRepeats(category) / total) * 100);
  }

  isComplete(category: AdhkarCategory): boolean {
    return category.items.every((item) => this.remainingFor(category, item.id) === 0);
  }

  firstIncomplete(category: AdhkarCategory): number {
    const index = category.items.findIndex(
      (item) => this.remainingFor(category, item.id) > 0,
    );
    return index < 0 ? 0 : index;
  }

  get activeCategory(): AdhkarCategory | null {
    return this.categories.find((category) => category.id === this.activeCategoryId) ?? null;
  }

  get activeItem() {
    const category = this.activeCategory;
    if (!category) return null;
    return category.items[this.activeIndex] ?? null;
  }

  get activeRemaining(): number {
    const category = this.activeCategory;
    const item = this.activeItem;
    return category && item ? this.remainingFor(category, item.id) : 0;
  }

  get todayMorning(): boolean {
    return this.day?.morning ?? false;
  }

  get todayEvening(): boolean {
    return this.day?.evening ?? false;
  }

  openCategory(id: string) {
    const category = this.categories.find((entry) => entry.id === id);
    if (!category) return;
    this.#clearAdvance();
    this.activeCategoryId = id;
    this.completed = this.isComplete(category);
    this.activeIndex = this.completed ? 0 : this.firstIncomplete(category);
  }

  closeReader() {
    this.#clearAdvance();
    this.activeCategoryId = null;
    this.activeIndex = 0;
    this.completed = false;
  }

  next() {
    const category = this.activeCategory;
    if (!category) return;
    this.#clearAdvance();
    this.activeIndex = (this.activeIndex + 1) % category.items.length;
  }

  previous() {
    const category = this.activeCategory;
    if (!category) return;
    this.#clearAdvance();
    this.activeIndex =
      (this.activeIndex - 1 + category.items.length) % category.items.length;
  }

  /** One tap = one repetition. Persists every tap and auto-advances at zero. */
  tap() {
    const category = this.activeCategory;
    const item = this.activeItem;
    if (!category || !item || !this.date || this.completed) return;
    // If the local day just rolled over, never credit the tap to yesterday.
    if (worship.settings && worship.localDate() !== this.date) {
      void this.load();
      return;
    }

    const date = this.date;
    this.#clearAdvance();
    const remaining = this.activeRemaining;
    if (remaining <= 0) {
      this.advanceFrom(category, item.id);
      return;
    }

    const next = remaining - 1;
    this.progress = {
      ...this.progress,
      [key(category.id, item.id)]: next,
    };
    this.#persist(date, category.id, item.id, next);

    if (next === 0) {
      if (this.isComplete(category)) {
        this.completed = true;
        void this.#markComplete(category, date);
      } else {
        // Let the zero register before jumping to the next dhikr. Remember the
        // exact item so manual navigation or a reset cancels the move.
        const index = this.activeIndex;
        this.#advanceTimer = setTimeout(() => {
          this.#advanceTimer = null;
          if (
            this.activeCategoryId === category.id &&
            this.activeIndex === index &&
            this.activeItem?.id === item.id
          ) {
            this.advanceFrom(category, item.id);
          }
        }, 380);
      }
    }
  }

  #clearAdvance() {
    if (this.#advanceTimer !== null) {
      clearTimeout(this.#advanceTimer);
      this.#advanceTimer = null;
    }
  }

  private advanceFrom(category: AdhkarCategory, itemId: string) {
    if (this.completed) return;
    const start = category.items.findIndex((item) => item.id === itemId);
    for (let step = 1; step <= category.items.length; step += 1) {
      const index = (start + step) % category.items.length;
      if (this.remainingFor(category, category.items[index].id) > 0) {
        this.activeIndex = index;
        return;
      }
    }
  }

  /** Serialize writes and always resolve, so one failure cannot wedge the queue. */
  #enqueue(operation: () => Promise<void>) {
    this.#queue = this.#queue
      .then(operation)
      .then(() => {
        this.error = null;
      })
      .catch((error) => {
        this.error = typeof error === "string" ? error : String(error);
      });
  }

  #persist(date: string, categoryId: string, itemId: string, remaining: number) {
    this.#enqueue(async () => {
      await api.setAdhkarRemaining(date, categoryId, itemId, remaining);
    });
  }

  async #markComplete(category: AdhkarCategory, date: string) {
    if (!category.streakKey) return;
    this.#enqueue(async () => {
      this.day = await api.markAdhkarDone(date, category.id);
      this.streak = await api.adhkarStreak();
    });
    await this.#queue;
  }

  resetCategory() {
    const category = this.activeCategory;
    if (!category || !this.date) return;
    const date = this.date;
    this.#clearAdvance();
    const next = { ...this.progress };
    for (const item of category.items) delete next[key(category.id, item.id)];
    this.progress = next;
    this.activeIndex = 0;
    this.completed = false;

    this.#enqueue(async () => {
      this.day = await api.clearAdhkarCategory(date, category.id);
      this.streak = await api.adhkarStreak();
    });
  }
}

export const adhkar = new AdhkarStore();
