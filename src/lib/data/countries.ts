export interface Country {
  code: string;
  ar: string;
  en: string;
}

export const countries: Country[] = [
  { code: "SA", ar: "السعودية", en: "Saudi Arabia" },
  { code: "EG", ar: "مصر", en: "Egypt" },
  { code: "AE", ar: "الإمارات", en: "UAE" },
  { code: "QA", ar: "قطر", en: "Qatar" },
  { code: "KW", ar: "الكويت", en: "Kuwait" },
  { code: "JO", ar: "الأردن", en: "Jordan" },
  { code: "MA", ar: "المغرب", en: "Morocco" },
  { code: "DZ", ar: "الجزائر", en: "Algeria" },
  { code: "TN", ar: "تونس", en: "Tunisia" },
  { code: "LB", ar: "لبنان", en: "Lebanon" },
  { code: "IQ", ar: "العراق", en: "Iraq" },
  { code: "OM", ar: "عُمان", en: "Oman" },
  { code: "BH", ar: "البحرين", en: "Bahrain" },
  { code: "PS", ar: "فلسطين", en: "Palestine" },
  { code: "SD", ar: "السودان", en: "Sudan" },
  { code: "SY", ar: "سوريا", en: "Syria" },
  { code: "LY", ar: "ليبيا", en: "Libya" },
  { code: "YE", ar: "اليمن", en: "Yemen" },
];

export function countryName(code: string, locale: "ar" | "en"): string {
  const c = countries.find((x) => x.code === code);
  return c ? (locale === "ar" ? c.ar : c.en) : code;
}
