<script lang="ts">
  import { onDestroy, onMount } from "svelte";
  import { api } from "$lib/api";
  import type { Ayah, AyahReciter, Surah, Track } from "$lib/types";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import { ayahOf, hifz, surahOf, PASS_OPTIONS } from "$lib/stores/hifz.svelte.ts";
  import Icon from "$lib/components/Icon.svelte";

  let { reciter, surah }: { reciter: AyahReciter; surah: Surah } = $props();

  let tracks = $state<Track[]>([]);
  let ayahs = $state<Ayah[]>([]);
  let translations = $state<Ayah[] | null>(null);
  let loading = $state(true);
  let textError = $state(false);
  let showTranslation = $state(false);
  let translationFailed = $state(false);
  let container = $state<HTMLElement>();

  const currentAyah = $derived(
    surahOf(player.current) === surah.number ? ayahOf(player.current) : null,
  );
  const memorisedPct = $derived(
    surah.ayahs > 0 ? Math.round((hifz.count / surah.ayahs) * 100) : 0,
  );

  onMount(async () => {
    void hifz.attach(surah.number, reciter.id);
    loading = true;
    const [trackRes, textRes] = await Promise.allSettled([
      api.ayahTracks(surah.number, reciter.id),
      api.surahText(surah.number),
    ]);
    if (trackRes.status === "fulfilled") tracks = trackRes.value;
    if (textRes.status === "fulfilled") ayahs = textRes.value;
    else textError = true;
    loading = false;

    // Restore the reader to where they stopped.
    requestAnimationFrame(() => {
      const n = hifz.lastAyah;
      container?.querySelector<HTMLElement>(`[data-ayah="${n}"]`)?.scrollIntoView({
        block: "center",
      });
    });
  });

  onDestroy(() => hifz.detach());

  $effect(() => {
    const n = currentAyah;
    if (!n) return;
    hifz.noteAyah(n);
    container
      ?.querySelector<HTMLElement>(`[data-ayah="${n}"]`)
      ?.scrollIntoView({ block: "center", behavior: "smooth" });
  });

  function shortName(name: string) {
    return name.replace(/^سُورَةُ\s*/, "").replace(/^سورة\s*/, "");
  }

  async function playAyah(n: number) {
    const track = tracks[n - 1];
    if (track) await player.play(track, tracks);
  }

  async function startLoop() {
    hifz.active = true;
    hifz.setRange(hifz.from, hifz.to);
    const track = tracks[hifz.from - 1];
    if (track) await player.play(track, tracks);
  }

  async function toggleTranslation() {
    showTranslation = !showTranslation;
    if (!showTranslation || translations) return;
    // Arabic is local; the translation is fetched separately so an offline
    // toggle never blocks the text.
    const list = await api.surahTranslation(surah.number).catch(() => [] as string[]);
    translationFailed = list.length === 0;
    translations = ayahs.map((ayah, index) => ({
      ...ayah,
      translation: list[index] || undefined,
    }));
  }
</script>

<div class="fade-in">
  <button
    type="button"
    onclick={() => nav.go("quran", "ayah", reciter.id)}
    class="mb-5 flex items-center gap-1.5 text-xs text-muted transition-colors hover:text-gold"
  >
    <Icon name="chevron" size={13} class="rotate-180 rtl:rotate-0" />
    {i18n.t("quran.surahs")} · {reciter.name}
  </button>

  <header class="flex flex-wrap items-end gap-4">
    <div class="min-w-0 flex-1">
      <p class="text-[10px] font-bold uppercase tracking-[0.22em] text-gold/80">
        {i18n.t("quran.byAyah")}
      </p>
      <h1 class="mt-1 pb-1 font-quran text-3xl leading-[1.5] text-cream">
        {surah.name}
      </h1>
      <p class="mt-1 text-xs text-muted">
        {reciter.name} · {fmtNumber(surah.ayahs)} {i18n.t("quran.ayahs")}
        {#if hifz.lastAyah > 1}
          <span class="text-muted/60">
            · {i18n.t("quran.continue")} {fmtNumber(hifz.lastAyah)}
          </span>
        {/if}
      </p>
    </div>

    <button
      type="button"
      onclick={() =>
        player.play(tracks[Math.max(0, hifz.lastAyah - 1)] ?? tracks[0], tracks)}
      disabled={!tracks.length}
      class="flex items-center gap-2 rounded-xl bg-gold px-4 py-2.5 text-sm font-semibold text-ink-950 transition-transform hover:scale-[1.02] active:scale-95 disabled:opacity-50"
    >
      <Icon name="play" size={14} />
      {i18n.t("player.play")}
    </button>
  </header>

  <!-- Memorisation panel -->
  <section class="mt-5 rounded-2xl border border-line bg-ink-900/60 p-4">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div class="flex items-center gap-2">
        <Icon name="bookmark" size={15} class="text-gold/80" />
        <h2 class="text-sm font-semibold text-cream">{i18n.t("quran.hifz")}</h2>
      </div>
      <div class="flex items-center gap-2 text-[11px] text-muted">
        <span>{i18n.t("quran.progress")}</span>
        <span class="tabular-nums text-cream">
          {fmtNumber(hifz.count)} / {fmtNumber(surah.ayahs)}
        </span>
        <span class="h-1.5 w-24 overflow-hidden rounded-full bg-ink-800">
          <span
            class="block h-full rounded-full bg-gold transition-[width] duration-300"
            style="width: {memorisedPct}%"
          ></span>
        </span>
      </div>
    </div>

    <div class="mt-4 flex flex-wrap items-end gap-2.5">
      <label class="flex flex-col gap-1 text-[10px] uppercase tracking-wide text-muted">
        {i18n.t("quran.from")}
        <select
          value={hifz.from}
          onchange={(e) => hifz.setRange(Number(e.currentTarget.value), hifz.to)}
          class="min-w-16 rounded-lg border border-line bg-ink-850 px-2 py-1.5 text-sm tabular-nums text-cream focus:border-gold/50 focus:outline-none"
        >
          {#each ayahs as a (a.number)}
            <option value={a.number}>{fmtNumber(a.number)}</option>
          {/each}
        </select>
      </label>

      <label class="flex flex-col gap-1 text-[10px] uppercase tracking-wide text-muted">
        {i18n.t("quran.to")}
        <select
          value={hifz.to}
          onchange={(e) => hifz.setRange(hifz.from, Number(e.currentTarget.value))}
          class="min-w-16 rounded-lg border border-line bg-ink-850 px-2 py-1.5 text-sm tabular-nums text-cream focus:border-gold/50 focus:outline-none"
        >
          {#each ayahs as a (a.number)}
            <option value={a.number}>{fmtNumber(a.number)}</option>
          {/each}
        </select>
      </label>

      <label class="flex flex-col gap-1 text-[10px] uppercase tracking-wide text-muted">
        {i18n.t("quran.times")}
        <select
          value={hifz.passes}
          onchange={(e) => hifz.setPasses(Number(e.currentTarget.value))}
          class="min-w-16 rounded-lg border border-line bg-ink-850 px-2 py-1.5 text-sm tabular-nums text-cream focus:border-gold/50 focus:outline-none"
        >
          {#each PASS_OPTIONS as n (n)}
            <option value={n}>{fmtNumber(n)}</option>
          {/each}
        </select>
      </label>

      {#if hifz.active}
        <button
          type="button"
          onclick={() => (hifz.active = false)}
          class="flex items-center gap-1.5 rounded-lg border border-gold/50 bg-gold/12 px-3 py-2 text-xs font-semibold text-gold"
        >
          <Icon name="pause" size={12} />
          {i18n.t("quran.stopLoop")}
          {#if hifz.passesLeft > 0 && hifz.passes > 1}
            <span class="tabular-nums text-gold/70">
              · {fmtNumber(hifz.passesLeft)} {i18n.t("quran.pass")}
            </span>
          {/if}
        </button>
      {:else}
        <button
          type="button"
          onclick={startLoop}
          disabled={!tracks.length}
          class="flex items-center gap-1.5 rounded-lg border border-line px-3 py-2 text-xs font-semibold text-cream transition-colors hover:border-gold/40 hover:text-gold disabled:opacity-50"
        >
          <Icon name="repeat" size={12} />
          {i18n.t("quran.startLoop")}
        </button>
      {/if}

      <div class="ms-auto flex items-center gap-2">
        <button
          type="button"
          onclick={() => hifz.markRange()}
          class="rounded-lg border border-teal/40 bg-teal/10 px-3 py-2 text-xs font-semibold text-teal transition-colors hover:bg-teal/15"
        >
          {i18n.t("quran.markRange")}
        </button>
        <button
          type="button"
          onclick={() => hifz.clearRange()}
          class="rounded-lg border border-line px-2.5 py-2 text-xs text-muted transition-colors hover:border-line hover:text-cream"
        >
          {i18n.t("quran.clearRange")}
        </button>
      </div>
    </div>

    {#if hifz.justCompleted}
      <p class="mt-3 flex items-center gap-1.5 rounded-lg bg-teal/8 px-3 py-2 text-[11px] text-teal">
        <Icon name="check" size={12} />
        {i18n.t("quran.loopDone")}
      </p>
    {/if}
  </section>

  <!-- Text -->
  <div class="mt-5 flex items-center justify-between">
    <p class="text-[11px] text-muted">
      {shortName(surah.name)} · {surah.englishName}
    </p>
    <button
      type="button"
      onclick={toggleTranslation}
      class="flex items-center gap-1.5 rounded-lg border px-2.5 py-1 text-[11px] transition-colors
             {showTranslation
        ? 'border-gold/40 bg-gold/10 text-gold'
        : 'border-line text-muted hover:text-cream'}"
    >
      {i18n.t("quran.translation")}
    </button>
  </div>

  {#if showTranslation && translationFailed}
    <p class="mt-2 text-[11px] text-muted">{i18n.t("reader.translationUnavailable")}</p>
  {/if}

  {#if loading}
    <div class="mt-4 space-y-3">
      {#each Array(6) as _, i (i)}
        <div class="h-20 animate-pulse rounded-xl bg-ink-900"></div>
      {/each}
    </div>
  {:else if textError}
    <p class="mt-6 text-sm text-muted">{i18n.t("quran.textError")}</p>
  {:else}
    <div
      bind:this={container}
      class="no-scrollbar mt-3 max-h-[54vh] space-y-1.5 overflow-y-auto rounded-2xl border border-line bg-ink-900/40 p-2"
    >
      {#each ayahs as ayah (ayah.number)}
        {@const active = currentAyah === ayah.number}
        {@const memorised = hifz.has(ayah.number)}
        <div
          data-ayah={ayah.number}
          class="group flex w-full items-start gap-2 rounded-xl px-3 py-3 transition-colors
                 {active ? 'bg-gold/10 ring-1 ring-gold/30' : 'hover:bg-ink-800/70'}"
        >
          <button
            type="button"
            onclick={() => playAyah(ayah.number)}
            aria-label={i18n.t("quran.playAyah")}
            class="flex min-w-0 flex-1 gap-3 rounded-lg text-start focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gold/70"
          >
            <span
              class="grid size-8 shrink-0 place-items-center rounded-lg border text-[10px] tabular-nums transition-colors
                     {active
                ? 'border-gold/50 bg-gold/15 text-gold'
                : 'border-line text-muted group-hover:border-gold/30 group-hover:text-gold'}"
            >
              {#if active && player.playing}
                <span class="eq"><i></i><i></i><i></i><i></i></span>
              {:else}
                {fmtNumber(ayah.number)}
              {/if}
            </span>

            <span class="min-w-0 flex-1">
              <span
                class="block font-quran text-[1.35rem] leading-[2.1] {active
                  ? 'text-cream'
                  : 'text-cream/85'}"
              >
                {ayah.text}
              </span>
              {#if showTranslation && translations?.[ayah.number - 1]?.translation}
                <span class="mt-1 block text-[12px] leading-relaxed text-muted" dir="ltr" style="text-align: start">
                  {translations[ayah.number - 1].translation}
                </span>
              {/if}
              {#if ayah.sajda}
                <span class="mt-1 inline-block rounded border border-teal/30 px-1.5 py-px text-[9px] text-teal">
                  {i18n.t("quran.sajda")}
                </span>
              {/if}
            </span>
          </button>

          <button
            type="button"
            onclick={() => hifz.toggleMemorized(ayah.number)}
            aria-label={i18n.t("quran.memorized")}
            class="mt-1 shrink-0 rounded-full p-1 transition-colors
                   {memorised ? 'text-teal' : 'text-muted/40 hover:text-muted'}"
          >
            <Icon name={memorised ? "check" : "bookmark"} size={11} />
          </button>
        </div>
      {/each}
    </div>
  {/if}
</div>
