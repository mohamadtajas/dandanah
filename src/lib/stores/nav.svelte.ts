import type { TranslationKey } from "$lib/i18n/dict";
import type { View } from "$lib/types";

export interface NavItem {
  view: View;
  icon: string;
  label: TranslationKey;
}

export const navItems: NavItem[] = [
  { view: "home", icon: "home", label: "nav.home" },
  { view: "worship", icon: "compass", label: "nav.worship" },
  { view: "quran", icon: "book", label: "nav.quran" },
  { view: "explore", icon: "sparkle", label: "nav.explore" },
  { view: "radio", icon: "radio", label: "nav.radio" },
  { view: "library", icon: "music", label: "nav.library" },
];

class NavStore {
  view = $state<View>("home");
  /** All path segments after the view, e.g. `#/quran/ayah/Husary_128kbps/2`. */
  params = $state<string[]>([]);
  query = $state("");

  /** First segment — kept for views that only need one argument. */
  get param(): string | null {
    return this.params[0] ?? null;
  }

  constructor() {
    if (typeof window !== "undefined") {
      window.addEventListener("hashchange", () => this.readHash());
      this.readHash();
    }
  }

  go(view: View, param?: string | number, ...rest: (string | number)[]) {
    const segments = [param, ...rest]
      .filter((p) => p !== undefined && p !== null && p !== "")
      .map((p) => encodeURIComponent(String(p)));
    const next = `#/${view}${segments.length ? "/" + segments.join("/") : ""}`;
    if (location.hash === next) {
      this.view = view;
      this.params = segments.map((s) => decodeURIComponent(s));
    } else {
      location.hash = next;
    }
  }

  search(term: string) {
    this.query = term;
    this.go("search");
  }

  private readHash() {
    const raw = location.hash.replace(/^#\/?/, "");
    const [view, ...params] = raw.split("/");
    const known: View[] = [
      "home",
      "worship",
      "search",
      "quran",
      "explore",
      "radio",
      "library",
      "settings",
      "credits",
    ];
    this.view = (known.includes(view as View) ? view : "home") as View;
    this.params = params.filter(Boolean).map((p) => decodeURIComponent(p));
  }
}

export const nav = new NavStore();
