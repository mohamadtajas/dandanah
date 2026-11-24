// Build the bundled adhkar file from the MIT-licensed Hisn al-Muslim JSON.
// Run from the repository root: node scripts/build-adhkar.mjs

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sourcePath = path.join(root, "data", "hisn-al-muslim.json");
const outputPath = path.join(root, "src", "lib", "data", "adhkar.json");

const source = JSON.parse(fs.readFileSync(sourcePath, "utf8"));
const entries = Object.entries(source);

/** Strip Arabic diacritics, tatweel and extra spaces for stable matching. */
const bare = (text) =>
  text
    .replace(/[\u0640\u064B-\u065F\u0670\u06D6-\u06ED]/g, "")
    .replace(/\s+/g, " ")
    .trim();

function take(bareTitle) {
  const found = entries.find(([title]) => bare(title) === bareTitle);
  if (!found) throw new Error(`missing source category: ${bareTitle}`);
  return found;
}

function normalizeItems(categoryTitle, idPrefix) {
  const category = source[categoryTitle];
  if (!category || !Array.isArray(category.Adhkar)) {
    throw new Error(`missing or empty category: ${categoryTitle}`);
  }
  return category.Adhkar.map((item, index) => {
    const text = String(item.Text ?? "").trim();
    const count = Number(item.Count);
    const reference = String(item.Reference ?? "").trim();
    if (!text) throw new Error(`empty text in ${categoryTitle} #${index + 1}`);
    if (!Number.isInteger(count) || count < 1) {
      throw new Error(`bad count in ${categoryTitle} #${index + 1}`);
    }
    if (!reference) throw new Error(`missing reference in ${categoryTitle} #${index + 1}`);
    return {
      id: `${idPrefix}-${String(index + 1).padStart(2, "0")}`,
      text,
      count,
      reference,
    };
  });
}

function itemCount(category) {
  return category.items.reduce((sum, item) => sum + item.count, 0);
}

const featuredSpecs = [
  {
    id: "morning",
    title: "أذكار الصباح",
    match: "أذكار الصباح",
    streakKey: "morning",
    expected: { items: 24, repeats: 358 },
  },
  {
    id: "evening",
    title: "أذكار المساء",
    match: "أذكار المساء",
    streakKey: "evening",
    expected: { items: 22, repeats: 257 },
  },
  {
    id: "sleep",
    title: "أذكار النوم",
    match: "أذكار النوم",
    expected: { items: 15, repeats: 116 },
  },
  {
    id: "waking",
    title: "أذكار الاستيقاظ",
    match: "أذكار الاستيقاظ من النوم",
    expected: { items: 4, repeats: 4 },
  },
  {
    id: "after-prayer",
    title: "أذكار بعد الصلاة",
    match: "الأذكار بعد السلام من الصلاة",
    expected: { items: 8, repeats: 17 },
  },
];

const usedTitles = new Set();
const featured = featuredSpecs.map((spec) => {
  const [sourceTitle] = take(spec.match);
  usedTitles.add(sourceTitle);
  const items = normalizeItems(sourceTitle, spec.id);
  const actual = { items: items.length, repeats: itemCount({ items }) };
  if (
    spec.expected &&
    (actual.items !== spec.expected.items || actual.repeats !== spec.expected.repeats)
  ) {
    throw new Error(
      `${spec.match}: expected ${spec.expected.items}/${spec.expected.repeats}, got ${actual.items}/${actual.repeats}`,
    );
  }
  const category = {
    id: spec.id,
    title: spec.title,
    featured: true,
    items,
  };
  if (spec.streakKey) category.streakKey = spec.streakKey;
  return category;
});

const miscSources = [
  "دعاء الهم والحزن",
  "دعاء الكرب",
  "الاستغفار والتوبة",
  "دعاء العطاس",
  "الذكر عند الخروج من المنزل",
  "دعاء دخول المسجد",
  "الذكر عند دخول المنزل",
  "دعاء لبس الثوب",
];

const miscItems = [];
for (const match of miscSources) {
  const [sourceTitle] = take(match);
  const items = normalizeItems(sourceTitle, `misc-${String(miscItems.length + 1).padStart(2, "0")}`);
  // Re-number after concatenation so IDs are stable and unique.
  const start = miscItems.length;
  items.forEach((item, index) => {
    miscItems.push({ ...item, id: `misc-${String(start + index + 1).padStart(2, "0")}` });
  });
}
featured.push({
  id: "misc",
  title: "أذكار متنوعة",
  featured: true,
  items: miscItems,
});

let ordinal = 0;
const rest = entries
  .filter(([title]) => !usedTitles.has(title))
  .map(([title, value]) => {
    ordinal += 1;
    const id = `hisn-${String(ordinal).padStart(3, "0")}`;
    return {
      id,
      title,
      featured: false,
      items: normalizeItems(title, id),
    };
  });

const categories = [...featured, ...rest];
const summary = categories
  .filter((category) => category.featured)
  .map((category) => `${category.id}: ${category.items.length}/${itemCount(category)}`)
  .join(", ");

const output = {
  source: {
    title: "حصن المسلم من أذكار الكتاب والسنة",
    author: "د. سعيد بن علي بن وهف القحطاني",
    repository: "https://github.com/asellam/HisnElMuslim",
    commit: "872764ca013116c905f7fc9c3dc972c27cd37d4a",
    license: "MIT",
    generated: "2026-11-26",
  },
  categories,
};

fs.writeFileSync(outputPath, `${JSON.stringify(output, null, 2)}\n`, "utf8");
console.log(`wrote ${path.relative(root, outputPath)}`);
console.log(`categories: ${categories.length}, items: ${categories.reduce((n, c) => n + c.items.length, 0)}`);
console.log(`featured: ${summary}`);
