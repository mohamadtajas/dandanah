const THEME_KEY = "dandanah.theme";

class UiStore {
  theme = $state<"dark" | "light">("dark");

  constructor() {
    if (typeof localStorage !== "undefined") {
      const saved = localStorage.getItem(THEME_KEY);
      if (saved === "light" || saved === "dark") this.theme = saved;
    }
    if (typeof document !== "undefined") this.apply();
  }

  setTheme(theme: "dark" | "light") {
    this.theme = theme;
    if (typeof localStorage !== "undefined") localStorage.setItem(THEME_KEY, theme);
    this.apply();
  }

  toggleTheme() {
    this.setTheme(this.theme === "dark" ? "light" : "dark");
  }

  private apply() {
    document.documentElement.dataset.theme = this.theme;
    document.documentElement.style.colorScheme = this.theme;
  }
}

export const ui = new UiStore();
