/**
 * Mirrors the Rust `providers::normalize_arabic` rule set: strips tashkeel,
 * tatweel and Quranic marks, and folds alef/ya/ta-marbuta variants. Kept in
 * sync so client-side filtering matches server-side search.
 */
export function normalizeArabic(input: string): string {
  return input
    .replace(/[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]/g, "")
    .replace(/[\u0622\u0623\u0625\u0671]/g, "\u0627")
    .replace(/[\u0649\u0626]/g, "\u064A")
    .replace(/\u0629/g, "\u0647")
    .replace(/\s+/g, " ")
    .trim()
    .toLowerCase();
}
