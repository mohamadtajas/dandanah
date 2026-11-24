// Build the bundled Uthmani Quran from the verbatim Tanzil XML downloads.
// Run from the repository root: node scripts/build-quran.mjs
//
// The Arabic text is never edited. This script only reshapes the XML into JSON
// and attaches the juz/page numbers from Tanzil's metadata.

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const textPath = path.join(root, "data", "quran-uthmani.xml");
const metaPath = path.join(root, "data", "quran-metadata.xml");
const outputPath = path.join(root, "src-tauri", "data", "quran.json");

const textXml = fs.readFileSync(textPath, "utf8");
const metaXml = fs.readFileSync(metaPath, "utf8");
const sha256 = (value) => crypto.createHash("sha256").update(value).digest("hex");

const decode = (value) =>
  value
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, "&");

function attrsOf(source) {
  return Object.fromEntries(
    [...source.matchAll(/([\w:-]+)="([^"]*)"/g)].map((match) => [match[1], decode(match[2])]),
  );
}

// --- Metadata: surah counts, juz and page starts -------------------------
const metaSurahs = new Map();
for (const match of metaXml.matchAll(/<sura\s+([^>]*?)\/>/g)) {
  const attrs = attrsOf(match[1]);
  metaSurahs.set(Number(attrs.index), {
    ayahs: Number(attrs.ayas),
    revelation: attrs.type === "Medinan" ? "madinah" : "makkah",
    englishName: attrs.tname,
    meaning: attrs.ename,
  });
}

const juzStarts = [];
for (const match of metaXml.matchAll(/<juz\s+([^>]*?)\/>/g)) {
  const attrs = attrsOf(match[1]);
  juzStarts.push({ number: Number(attrs.index), surah: Number(attrs.sura), ayah: Number(attrs.aya) });
}
const pageStarts = [];
for (const match of metaXml.matchAll(/<page\s+([^>]*?)\/>/g)) {
  const attrs = attrsOf(match[1]);
  pageStarts.push({ number: Number(attrs.index), surah: Number(attrs.sura), ayah: Number(attrs.aya) });
}

const sajdaAt = new Set();
for (const match of metaXml.matchAll(/<sajda\s+([^>]*?)\/>/g)) {
  const attrs = attrsOf(match[1]);
  sajdaAt.add(`${Number(attrs.sura)}:${Number(attrs.aya)}`);
}

if (metaSurahs.size !== 114) throw new Error(`metadata has ${metaSurahs.size} surahs`);
if (juzStarts.length !== 30) throw new Error(`metadata has ${juzStarts.length} juz`);
if (pageStarts.length !== 604) throw new Error(`metadata has ${pageStarts.length} pages`);
if (sajdaAt.size !== 15) throw new Error(`metadata has ${sajdaAt.size} sajdas`);

// --- Text: verbatim ayahs, basmala kept as Tanzil supplies it -------------
const surahs = [];
const ayahs = [];
const surahRe = /<sura index="(\d+)" name="([^"]*)">([\s\S]*?)<\/sura>/g;
for (const match of textXml.matchAll(surahRe)) {
  const number = Number(match[1]);
  const name = decode(match[2]);
  const body = match[3];
  const meta = metaSurahs.get(number);
  if (!meta) throw new Error(`no metadata for surah ${number}`);

  let count = 0;
  let bismillah = null;
  for (const ayaMatch of body.matchAll(
    /<aya index="(\d+)" text="([^"]*)"(?: bismillah="([^"]*)")?\s*\/>/g,
  )) {
    const ayah = Number(ayaMatch[1]);
    const text = decode(ayaMatch[2]);
    const surahBismillah = ayaMatch[3] ? decode(ayaMatch[3]) : null;
    if (!text) throw new Error(`empty text ${number}:${ayah}`);
    if (surahBismillah) bismillah = surahBismillah;
    const row = { surah: number, ayah, text };
    if (surahBismillah) row.bismillah = surahBismillah;
    if (sajdaAt.has(`${number}:${ayah}`)) row.sajda = true;
    ayahs.push(row);
    count += 1;
  }

  if (count !== meta.ayahs) {
    throw new Error(`surah ${number}: ${count} ayahs, metadata says ${meta.ayahs}`);
  }
  surahs.push({
    number,
    name,
    englishName: meta.englishName,
    meaning: meta.meaning,
    ayahs: count,
    revelation: meta.revelation,
    bismillah,
  });
}

if (surahs.length !== 114) throw new Error(`text has ${surahs.length} surahs`);
if (ayahs.length !== 6236) throw new Error(`text has ${ayahs.length} ayahs`);

for (let i = 1; i < ayahs.length; i += 1) {
  const previous = ayahs[i - 1];
  const current = ayahs[i];
  if (
    current.surah < previous.surah ||
    (current.surah === previous.surah && current.ayah <= previous.ayah)
  ) {
    throw new Error(`ayah order broke at ${current.surah}:${current.ayah}`);
  }
}

// --- Attach juz and page numbers ----------------------------------------
const juzAt = new Map(juzStarts.map((juz) => [`${juz.surah}:${juz.ayah}`, juz.number]));
const pageAt = new Map(pageStarts.map((page) => [`${page.surah}:${page.ayah}`, page.number]));
let juz = 0;
let page = 0;
let juzSeen = 0;
let pageSeen = 0;
const juzCounts = new Map();

for (const ayah of ayahs) {
  const key = `${ayah.surah}:${ayah.ayah}`;
  if (juzAt.has(key)) {
    juz = juzAt.get(key);
    juzSeen += 1;
  }
  if (pageAt.has(key)) {
    page = pageAt.get(key);
    pageSeen += 1;
  }
  if (!juz) throw new Error(`ayah before the first juz: ${key}`);
  if (!page) throw new Error(`ayah before the first page: ${key}`);
  ayah.juz = juz;
  ayah.page = page;
  juzCounts.set(juz, (juzCounts.get(juz) || 0) + 1);
}

if (juzSeen !== juzStarts.length) throw new Error(`matched ${juzSeen} juz starts`);
if (pageSeen !== pageStarts.length) throw new Error(`matched ${pageSeen} page starts`);

const juzs = juzStarts.map((entry) => ({
  ...entry,
  ayahs: juzCounts.get(entry.number) || 0,
}));

const notice = `# PLEASE DO NOT REMOVE OR CHANGE THIS COPYRIGHT BLOCK
#====================================================================
#
#  Tanzil Quran Text (Uthmani, Version 1.1)
#  Copyright (C) 2007-2026 Tanzil Project
#  License: Creative Commons Attribution 3.0
#
#  This copy of the Quran text is carefully produced, highly
#  verified and continuously monitored by a group of specialists
#  at Tanzil Project.
#
#  TERMS OF USE:
#
#  - Permission is granted to copy and distribute verbatim copies
#    of this text, but CHANGING IT IS NOT ALLOWED.
#
#  - This Quran text can be used in any website or application,
#    provided that its source (Tanzil Project) is clearly indicated,
#    and a link is made to tanzil.net to enable users to keep
#    track of changes.
#
#  - This copyright notice shall be included in all verbatim copies
#    of the text, and shall be reproduced appropriately in all files
#    derived from or containing substantial portion of this text.
#
#  Please check updates at: http://tanzil.net/updates/
#
#====================================================================`;

const output = {
  source: {
    title: "Tanzil Quran Text (Uthmani)",
    version: "1.1",
    copyright: "Copyright (C) 2007-2026 Tanzil Project",
    license: "Creative Commons Attribution 3.0",
    licenseUrl: "https://tanzil.net/docs/tanzil_license",
    sourceUrl: "https://tanzil.net",
    downloaded: "2026-11-26",
    textSha256: sha256(textXml),
    metadataSha256: sha256(metaXml),
    notice,
  },
  surahs,
  juzs,
  pages: pageStarts,
  ayahs,
};

fs.writeFileSync(outputPath, `${JSON.stringify(output)}\n`, "utf8");
console.log(`wrote ${path.relative(root, outputPath)}`);
console.log(
  `${surahs.length} surahs, ${ayahs.length} ayahs, ${juzs.length} juz, ${pageStarts.length} pages`,
);
console.log(`last ayah: ${ayahs.at(-1).surah}:${ayahs.at(-1).ayah}`);
