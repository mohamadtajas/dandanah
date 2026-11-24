import type { TranslationKey } from "$lib/i18n/dict";
import type { View } from "$lib/types";

export interface NavItem {
  view: View;
  icon: string;
  label: TranslationKey;
}

export const navItems: NavItem[] = [
  { view: "home", icon: "home", label: "nav.home" },
  { view: "quran", icon: "book", label: "nav.quran" },
  { view: "radio", icon: "radio", label: "nav.radio" },
  { view: "library", icon: "music", label: "nav.library" },
];

class NavStore {
  view = $state<View>("home");
  param = $state<string | null>(null);
  query = $state("");

  constructor() {
    if (typeof window !== "undefined") {
      window.addEventListener("hashchange", () => this.readHash());
      this.readHash();
    }
  }

  go(view: View, param?: string | number) {
    const p = param === undefined || param === null ? "" : `/${String(param)}`;
    const next = `#/${view}${p}`;
    if (location.hash === next) {
      this.view = view;
      this.param = param === undefined ? null : String(param);
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
    const [view, param] = raw.split("/");
    const known: View[] = [
      "home",
      "search",
      "quran",
      "radio",
      "library",
      "settings",
      "credits",
    ];
    this.view = (known.includes(view as View) ? view : "home") as View;
    this.param = param ? decodeURIComponent(param) : null;
  }
}

export const nav = new NavStore();
