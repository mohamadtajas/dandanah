<script lang="ts">
  import { onMount } from "svelte";
  import { api } from "$lib/api";
  import type { SearchResults } from "$lib/types";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import { DEFAULT_AYAH_RECITER } from "$lib/constants";
  import Artwork from "$lib/components/Artwork.svelte";
  import TrackRow from "$lib/components/TrackRow.svelte";
  import Icon from "$lib/components/Icon.svelte";
  import Section from "$lib/components/Section.svelte";

  let term = $state(nav.query);
  let results = $state<SearchResults>({ reciters: [], surahs: [], tracks: [] });
  let loading = $state(false);
  let filter = $state<"all" | "quran" | "radio">("all");
  let inputEl = $state<HTMLInputElement>();

  onMount(() => inputEl?.focus());

  $effect(() => {
    const q = term.trim();
    const f = filter;
    if (!q) {
      results = { reciters: [], surahs: [], tracks: [] };
      loading = false;
      return;
    }
    loading = true;
    const handle = setTimeout(async () => {
      try {
        const kinds = f === "all" ? undefined : [f];
        results = await api.search(q, kinds);
      } catch {
        results = { reciters: [], surahs: [], tracks: [] };
      } finally {
        loading = false;
      }
    }, 320);
    return () => clearTimeout(handle);
  });

  $effect(() => {
    if (nav.query) term = nav.query;
  });

  const hasResults = $derived(
    results.reciters.length > 0 || results.surahs.length > 0 || results.tracks.length > 0,
  );

  function shortName(name: string) {
    return name.replace(/^سُورَةُ\s*/, "").replace(/^سورة\s*/, "");
  }
</script>

<div class="fade-in">
  <header>
    <h1 class="text-2xl font-bold text-cream">{i18n.t("search.title")}</h1>
  </header>

  <label
    class="mt-4 flex items-center gap-3 rounded-2xl border border-line bg-ink-900 px-4 py-3 focus-within:border-gold/50"
  >
    <Icon name="search" size={18} class="shrink-0 text-muted" />
    <input
      bind:this={inputEl}
      bind:value={term}
      placeholder={i18n.t("search.placeholder")}
      class="w-full bg-transparent text-base text-cream placeholder:text-muted/70 focus:outline-none"
    />
    {#if term}
      <button
        type="button"
        onclick={() => (term = "")}
        class="rounded-lg p-1 text-muted hover:bg-ink-800 hover:text-cream"
        aria-label={i18n.t("common.close")}
      >
        <Icon name="x" size={15} />
      </button>
    {/if}
  </label>

  <div class="mt-3 flex gap-2">
    {#each [["all", "search.filterAll"], ["quran", "search.filterQuran"], ["radio", "search.filterRadio"]] as [value, key] (value)}
      <button
        type="button"
        onclick={() => (filter = value as "all" | "quran" | "radio")}
        class="rounded-full border px-3 py-1 text-[11px] transition-colors
               {filter === value
          ? 'border-gold/50 bg-gold/12 text-gold'
          : 'border-line text-muted hover:border-gold/30 hover:text-cream'}"
      >
        {i18n.t(key as "search.filterAll")}
      </button>
    {/each}
  </div>

  {#if !term.trim()}
    <div class="mt-16 text-center">
      <Icon name="search" size={34} class="mx-auto text-ink-700" />
      <p class="mt-3 text-sm text-muted">{i18n.t("search.hint")}</p>
    </div>
  {:else if loading}
    <div class="mt-8 space-y-1">
      {#each Array(6) as _, i (i)}
        <div class="flex animate-pulse items-center gap-3 px-2.5 py-2">
          <div class="size-11 rounded-lg bg-ink-800"></div>
          <div class="h-3 w-52 rounded bg-ink-800"></div>
        </div>
      {/each}
    </div>
  {:else if !hasResults}
    <div class="mt-16 text-center">
      <Icon name="search" size={34} class="mx-auto text-ink-700" />
      <p class="mt-3 text-sm text-muted">{i18n.t("search.empty")}</p>
    </div>
  {:else}
    {#if results.surahs.length}
      <Section title={i18n.t("search.surahs")}>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-4">
          {#each results.surahs as surah (surah.number)}
            <button
              type="button"
              onclick={() =>
                nav.go("quran", "ayah", DEFAULT_AYAH_RECITER, surah.number)}
              class="group flex items-center gap-3 rounded-xl border border-line/70 bg-ink-850/50 p-2.5 text-start transition-colors hover:border-gold/30 hover:bg-ink-800"
            >
              <span
                class="grid size-11 shrink-0 place-items-center rounded-xl border border-line font-quran text-sm tabular-nums text-gold/80 group-hover:border-gold/40"
              >
                {fmtNumber(surah.number)}
              </span>
              <div class="min-w-0 flex-1">
                <div class="truncate font-quran text-base text-cream group-hover:text-gold">
                  {shortName(surah.name)}
                </div>
                <div class="truncate text-[11px] text-muted">
                  {surah.englishName} · {fmtNumber(surah.ayahs)} {i18n.t("quran.ayahs")}
                </div>
              </div>
            </button>
          {/each}
        </div>
      </Section>
    {/if}

    {#if results.reciters.length}
      <Section title={i18n.t("search.reciters")}>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-4">
          {#each results.reciters as reciter (reciter.id)}
            <button
              type="button"
              onclick={() => nav.go("quran", reciter.id)}
              class="group flex items-center gap-3 rounded-xl border border-line/70 bg-ink-850/50 p-2.5 text-start transition-colors hover:border-gold/30 hover:bg-ink-800"
            >
              <Artwork
                seed={reciter.name}
                kind="quran"
                initials
                class="size-11 shrink-0"
                rounded="rounded-xl"
              />
              <div class="min-w-0 flex-1">
                <div class="truncate font-quran text-base text-cream group-hover:text-gold">
                  {reciter.name}
                </div>
                <div class="truncate text-[11px] text-muted">{reciter.moshafs[0]?.name ?? ""}</div>
              </div>
            </button>
          {/each}
        </div>
      </Section>
    {/if}

    {#if results.tracks.length}
      <Section title={i18n.t("search.tracks")}>
        <div class="overflow-hidden rounded-2xl border border-line bg-ink-900/50 p-1.5">
          {#each results.tracks as track (track.id)}
            <TrackRow {track} queue={results.tracks} />
          {/each}
        </div>
      </Section>
    {/if}
  {/if}
</div>
