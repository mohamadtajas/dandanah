import { dictionaries, type Locale, type TranslationKey } from "./dict";

const STORAGE_KEY = "dandanah.locale";

class I18nStore {
  locale = $state<Locale>("ar");
  dir = $derived<"rtl" | "ltr">(this.locale === "ar" ? "rtl" : "ltr");
  isRtl = $derived(this.locale === "ar");

  constructor() {
    const saved = (typeof localStorage !== "undefined" && localStorage.getItem(STORAGE_KEY)) as
      | Locale
      | null;
    if (saved === "ar" || saved === "en") this.locale = saved;
    if (typeof document !== "undefined") this.applyDocument();
  }

  t = (key: TranslationKey, vars?: Record<string, string | number>): string => {
    let text: string = dictionaries[this.locale][key] ?? key;
    if (vars) {
      for (const [k, v] of Object.entries(vars)) {
        text = text.replaceAll(`{${k}}`, String(v));
      }
    }
    return text;
  };

  set(locale: Locale) {
    this.locale = locale;
    if (typeof localStorage !== "undefined") localStorage.setItem(STORAGE_KEY, locale);
    this.applyDocument();
  }

  toggle() {
    this.set(this.locale === "ar" ? "en" : "ar");
  }

  private applyDocument() {
    document.documentElement.lang = this.locale;
    document.documentElement.dir = this.dir;
  }
}

export const i18n = new I18nStore();

/** Locale-aware number formatting (Arabic-Indic digits for `ar`). */
export function fmtNumber(n: number, locale: Locale = i18n.locale): string {
  return new Intl.NumberFormat(locale === "ar" ? "ar-EG" : "en-US").format(n);
}

export function fmtTime(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds < 0) return "0:00";
  const total = Math.floor(seconds);
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  const pad = (x: number) => String(x).padStart(2, "0");
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`;
}
