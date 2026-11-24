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
  #cleanups: (() => void)[] = [];

  async load() {
    this.loading = true;
    this.error = null;
    try {
      const date = worship.localDate();
      const [rows, day, streak] = await Promise.all([
        api.adhkarProgress(date),
        api.adhkarDay(date),
        api.adhkarStreak(),
      ]);
      this.date = date;
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
    this.#timer = setInterval(() => this.tick(), 60000);
    if (typeof document !== "undefined") {
      const onVisible = () => {
        if (!document.hidden && this.date !== worship.localDate()) void this.load();
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
    this.activeCategoryId = id;
    this.completed = this.isComplete(category);
    this.activeIndex = this.completed ? 0 : this.firstIncomplete(category);
  }

  closeReader() {
    this.activeCategoryId = null;
    this.activeIndex = 0;
    this.completed = false;
  }

  next() {
    const category = this.activeCategory;
    if (!category) return;
    this.activeIndex = (this.activeIndex + 1) % category.items.length;
  }

  previous() {
    const category = this.activeCategory;
    if (!category) return;
    this.activeIndex =
      (this.activeIndex - 1 + category.items.length) % category.items.length;
  }

  /** One tap = one repetition. Persists every tap and auto-advances at zero. */
  tap() {
    const category = this.activeCategory;
    const item = this.activeItem;
    if (!category || !item || this.completed) return;

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
    this.#persist(category.id, item.id, next);

    if (next === 0) {
      if (this.isComplete(category)) {
        this.completed = true;
        void this.#markComplete(category);
      } else {
        // Let the zero register before jumping to the next dhikr.
        setTimeout(() => {
          if (this.activeCategoryId === category.id) this.advanceFrom(category, item.id);
        }, 380);
      }
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

  #persist(categoryId: string, itemId: string, remaining: number) {
    this.#queue = this.#queue
      .then(() =>
        api.setAdhkarRemaining(this.date, categoryId, itemId, remaining).then(() => undefined),
      )
      .catch((error) => {
        this.error = typeof error === "string" ? error : String(error);
      });
  }

  async #markComplete(category: AdhkarCategory) {
    if (!category.streakKey) return;
    try {
      this.#queue = this.#queue.then(async () => {
        this.day = await api.markAdhkarDone(this.date, category.id);
        this.streak = await api.adhkarStreak();
      });
      await this.#queue;
    } catch (error) {
      this.error = typeof error === "string" ? error : String(error);
    }
  }

  resetCategory() {
    const category = this.activeCategory;
    if (!category) return;
    const next = { ...this.progress };
    for (const item of category.items) delete next[key(category.id, item.id)];
    this.progress = next;
    this.activeIndex = 0;
    this.completed = false;

    this.#queue = this.#queue.then(async () => {
      this.day = await api.clearAdhkarCategory(this.date, category.id);
      this.streak = await api.adhkarStreak();
    });
  }
}

export const adhkar = new AdhkarStore();
