/// Mirrors the desktop `normalizeArabic` rule set: strips tashkeel, tatweel and
/// Quranic marks, folds alef/ya/ta-marbuta variants and collapses whitespace.
///
/// Used for adhkar search so a query typed without vocalisation still matches
/// the fully vocalised bundled titles and bodies.
String normalizeArabic(String input) {
  return input
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '')
      .replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671]'), '\u0627')
      .replaceAll(RegExp(r'[\u0649\u0626]'), '\u064A')
      .replaceAll('\u0629', '\u0647')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
}
