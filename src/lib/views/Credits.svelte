<script lang="ts">
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import Icon from "$lib/components/Icon.svelte";

  const sources = [
    {
      name: "mp3quran.net",
      url: "https://mp3quran.net",
      what: { ar: "تلاوات القرآن الكريم وأكثر من ٢٠٠ قارئ", en: "Quran recitations from 200+ reciters" },
      license: { ar: "متاح مجانًا للاستخدام", en: "Freely available for use" },
    },
    {
      name: "EveryAyah",
      url: "https://everyayah.com",
      what: { ar: "تلاوة آية بآية", en: "Ayah-by-ayah recitation audio" },
      license: { ar: "متاح مجانًا", en: "Freely available" },
    },
    {
      name: "AlQuran Cloud",
      url: "https://alquran.cloud",
      what: { ar: "أسماء السور وعدد الآيات", en: "Surah names and ayah counts" },
      license: { ar: "بيانات مفتوحة", en: "Open data" },
    },
    {
      name: "Hisn al-Muslim (HisnElMuslim)",
      url: "https://github.com/asellam/HisnElMuslim",
      what: {
        ar: "نصوص الأذكار وتكرارها ومصادرها من حصن المسلم",
        en: "Adhkar texts, repeat counts and references from Hisn al-Muslim",
      },
      license: {
        ar: "MIT — نُقلت من النسخة المطبوعة",
        en: "MIT — transcribed from the printed book",
      },
    },
    {
      name: "radio-browser.info",
      url: "https://www.radio-browser.info",
      what: { ar: "دليل محطات الإذاعة المباشرة", en: "Live radio station directory" },
      license: { ar: "بيانات مفتوحة (CC0)", en: "Open data (CC0)" },
    },
    {
      name: "Openverse",
      url: "https://openverse.org",
      what: { ar: "فهرس صوتي بتراخيص مفتوحة (يشمل Jamendo)", en: "Openly licensed audio index (includes Jamendo)" },
      license: { ar: "Creative Commons — حسب كل عمل", en: "Creative Commons — per work" },
    },
    {
      name: "Jamendo",
      url: "https://www.jamendo.com",
      what: { ar: "موسيقى بتراخيص Creative Commons", en: "Creative Commons music" },
      license: { ar: "CC — يتطلب ذكر المصدر", en: "CC — attribution required" },
    },
    {
      name: "Internet Archive",
      url: "https://archive.org",
      what: { ar: "أناشيد وتسجيلات في الملك العام", en: "Anasheed and public-domain recordings" },
      license: { ar: "حسب كل تسجيل", en: "Per-item license" },
    },
  ];
</script>

<div class="fade-in max-w-3xl">
  <button
    type="button"
    onclick={() => nav.go("settings")}
    class="mb-4 flex items-center gap-1.5 text-xs text-muted transition-colors hover:text-gold"
  >
    <Icon name="chevron" size={13} class="rotate-180 rtl:rotate-0" />
    {i18n.t("settings.title")}
  </button>

  <h1 class="text-2xl font-bold text-cream">{i18n.t("credits.title")}</h1>
  <p class="mt-2 text-sm leading-relaxed text-muted">{i18n.t("credits.intro")}</p>

  <div class="mt-6 space-y-3">
    {#each sources as source (source.name)}
      <div class="rounded-2xl border border-line bg-ink-900/60 p-4">
        <div class="flex items-start justify-between gap-4">
          <div class="min-w-0">
            <div class="text-sm font-semibold text-cream">{source.name}</div>
            <div class="mt-0.5 text-xs text-muted">{source.what[i18n.locale]}</div>
          </div>
          <span class="shrink-0 rounded-md border border-line px-2 py-0.5 text-[10px] text-teal">
            {source.license[i18n.locale]}
          </span>
        </div>
        <div class="mt-2 truncate text-[11px] text-muted/70" dir="ltr">{source.url}</div>
      </div>
    {/each}
  </div>
</div>
