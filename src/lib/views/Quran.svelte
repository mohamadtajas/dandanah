<script lang="ts">
  import { onMount } from "svelte";
  import { api } from "$lib/api";
  import type { Reciter, Surah, Track } from "$lib/types";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import Artwork from "$lib/components/Artwork.svelte";
  import Icon from "$lib/components/Icon.svelte";

  let reciters = $state<Reciter[]>([]);
  let surahs = $state<Surah[]>([]);
  let tracks = $state<Track[]>([]);
  let loading = $state(true);
  let loadingTracks = $state(false);
  let filter = $state("");
  let selectedId = $state<number | null>(null);
  let moshafId = $state<number | null>(null);
  let booted = $state(false);

  const surahMap = $derived(new Map(surahs.map((s) => [s.number, s])));
  const selected = $derived(reciters.find((r) => r.id === selectedId) ?? null);
  const moshaf = $derived(
    selected?.moshafs.find((m) => m.id === moshafId) ?? selected?.moshafs[0] ?? null,
  );

  const visibleReciters = $derived(
    filter.trim()
      ? reciters.filter((r) => r.name.includes(filter.trim()) || r.letter === filter.trim())
      : reciters,
  );

  const rows = $derived(
    tracks
      .map((track, i) => {
        const number = moshaf?.surahs[i];
        const surah = number ? surahMap.get(number) : undefined;
        return surah ? { track, surah } : null;
      })
      .filter((x): x is { track: Track; surah: Surah } => x !== null),
  );

  onMount(async () => {
    const [r, s] = await Promise.allSettled([api.reciters(), api.surahs()]);
    if (r.status === "fulfilled") reciters = r.value;
    if (s.status === "fulfilled") surahs = s.value;
    loading = false;
    booted = true;
    if (nav.param) await openReciter(Number(nav.param));
  });

  $effect(() => {
    if (!booted) return;
    const p = nav.param;
    if (!p) {
      selectedId = null;
      tracks = [];
      return;
    }
    const id = Number(p);
    if (!Number.isNaN(id) && id !== selectedId) void openReciter(id);
  });

  async function openReciter(id: number) {
    const reciter = reciters.find((r) => r.id === id);
    if (!reciter) return;
    selectedId = id;
    moshafId = reciter.moshafs[0]?.id ?? null;
    await loadTracks();
  }

  async function loadTracks() {
    if (selectedId === null) return;
    loadingTracks = true;
    try {
      tracks = await api.moshafTracks(selectedId, moshafId ?? undefined);
    } catch {
      tracks = [];
    } finally {
      loadingTracks = false;
    }
  }

  async function chooseMoshaf(id: number) {
    if (id === moshafId) return;
    moshafId = id;
    await loadTracks();
  }

  function shortName(name: string) {
    return name.replace(/^سُورَةُ\s*/, "").replace(/^سورة\s*/, "");
  }

  function play(track: Track) {
    player.play(track, tracks);
  }

  function playAll() {
    if (tracks.length) player.play(tracks[0], tracks);
  }
</script>

<div class="fade-in">
  {#if selected}
    <!-- Reciter header -->
    <button
      type="button"
      onclick={() => nav.go("quran")}
      class="mb-5 flex items-center gap-1.5 text-xs text-muted transition-colors hover:text-gold"
    >
      <Icon name="chevron" size={13} class="rotate-180 rtl:rotate-0" />
      {i18n.t("quran.backToReciters")}
    </button>

    <header class="flex flex-wrap items-center gap-5">
      <Artwork
        seed={selected.name}
        kind="quran"
        initials
        class="size-24 shrink-0 shadow-xl shadow-black/30"
        rounded="rounded-3xl"
      />
      <div class="min-w-0 flex-1">
        <p class="text-[10px] font-bold uppercase tracking-[0.22em] text-gold/80">
          {i18n.t("quran.title")}
        </p>
        <h1 class="mt-1 truncate pb-1 font-quran text-3xl leading-[1.5] text-cream">{selected.name}</h1>
        <p class="mt-1 text-xs text-muted">
          {moshaf?.name} · {fmtNumber(moshaf?.surahTotal ?? 0)} {i18n.t("quran.surah")}
        </p>
      </div>
      <button
        type="button"
        onclick={playAll}
        class="flex items-center gap-2 rounded-xl bg-gold px-4 py-2.5 text-sm font-semibold text-ink-950 transition-transform hover:scale-[1.02] active:scale-95"
      >
        <Icon name="play" size={14} />
        {i18n.t("quran.playAll")}
      </button>
    </header>

    {#if selected.moshafs.length > 1}
      <div class="mt-5 flex flex-wrap gap-2">
        {#each selected.moshafs as m (m.id)}
          <button
            type="button"
            onclick={() => chooseMoshaf(m.id)}
            class="rounded-full border px-3 py-1.5 text-[11px] transition-colors
                   {m.id === moshaf?.id
              ? 'border-gold/50 bg-gold/12 text-gold'
              : 'border-line text-muted hover:border-gold/30 hover:text-cream'}"
          >
            {m.name}
          </button>
        {/each}
      </div>
    {/if}

    <div class="mt-6 overflow-hidden rounded-2xl border border-line bg-ink-900/60">
      {#if loadingTracks}
        <div class="divide-y divide-line/60">
          {#each Array(10) as _, i (i)}
            <div class="flex animate-pulse items-center gap-3 px-4 py-3">
              <div class="size-9 rounded-lg bg-ink-800"></div>
              <div class="h-3 w-40 rounded bg-ink-800"></div>
            </div>
          {/each}
        </div>
      {:else}
        {#each rows as row, i (row.surah.number)}
          {@const active = player.current?.id === row.track.id}
          <button
            type="button"
            onclick={() => play(row.track)}
            class="group flex w-full items-center gap-3 border-b border-line/50 px-4 py-2.5 text-start transition-colors last:border-0
                   {active ? 'bg-gold/8' : 'hover:bg-ink-800/60'}"
          >
            <span
              class="grid size-9 shrink-0 place-items-center rounded-lg border text-[11px] tabular-nums transition-colors
                     {active
                ? 'border-gold/40 bg-gold/10 text-gold'
                : 'border-line text-muted group-hover:border-gold/30 group-hover:text-gold'}"
            >
              {#if active && player.playing}
                <div class="eq"><i></i><i></i><i></i><i></i></div>
              {:else}
                {fmtNumber(row.surah.number)}
              {/if}
            </span>
            <span class="min-w-0 flex-1">
              <span class="block truncate font-quran text-[1.05rem] leading-snug {active ? 'text-gold' : 'text-cream'}">
                {shortName(row.surah.name)}
              </span>
              <span class="block truncate text-[11px] text-muted">
                {row.surah.englishName} · {fmtNumber(row.surah.ayahs)} {i18n.t("quran.ayahs")}
              </span>
            </span>
            <span
              class="hidden shrink-0 rounded-md border border-line px-1.5 py-0.5 text-[10px] text-muted sm:block"
            >
              {i18n.t(row.surah.revelation === "makkah" ? "quran.makkah" : "quran.madinah")}
            </span>
            <Icon
              name="play"
              size={13}
              class="shrink-0 text-muted opacity-0 transition-opacity group-hover:opacity-100"
            />
          </button>
        {/each}
      {/if}
    </div>
  {:else}
    <header>
      <p class="text-[10px] font-bold uppercase tracking-[0.22em] text-gold/80">
        {i18n.t("quran.chooseReciter")}
      </p>
      <h1 class="mt-1 text-2xl font-bold text-cream">{i18n.t("quran.title")}</h1>
      <p class="mt-1 text-xs text-muted">{i18n.t("quran.subtitle")}</p>
      <label class="mt-5 flex max-w-sm items-center gap-2 rounded-xl border border-line bg-ink-850 px-3 py-2 focus-within:border-gold/50">
        <Icon name="search" size={15} class="text-muted" />
        <input
          bind:value={filter}
          placeholder={i18n.t("quran.searchReciter")}
          class="w-full bg-transparent text-sm text-cream placeholder:text-muted/70 focus:outline-none"
        />
      </label>
    </header>

    {#if loading}
      <div class="mt-7 grid grid-cols-2 gap-4 sm:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8">
        {#each Array(16) as _, i (i)}
          <div class="animate-pulse">
            <div class="aspect-square rounded-2xl bg-ink-800"></div>
            <div class="mt-2 h-3 w-3/4 rounded bg-ink-800"></div>
          </div>
        {/each}
      </div>
    {:else if visibleReciters.length === 0}
      <p class="mt-10 text-sm text-muted">{i18n.t("search.empty")}</p>
    {:else}
      <div class="mt-7 grid grid-cols-2 gap-x-4 gap-y-6 sm:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8">
        {#each visibleReciters as reciter (reciter.id)}
          <button
            type="button"
            onclick={() => nav.go("quran", reciter.id)}
            class="group text-start"
          >
            <div class="relative">
              <Artwork
                seed={reciter.name}
                kind="quran"
                initials
                class="aspect-square w-full transition-transform duration-200 group-hover:-translate-y-0.5"
                rounded="rounded-2xl"
              />
              <div
                class="absolute inset-0 grid place-items-center rounded-2xl bg-ink-950/45 opacity-0 transition-opacity group-hover:opacity-100"
              >
                <span class="grid size-9 place-items-center rounded-full bg-gold text-ink-950">
                  <Icon name="play" size={13} />
                </span>
              </div>
            </div>
            <div class="mt-2 truncate text-[0.83rem] font-medium text-cream group-hover:text-gold">
              {reciter.name}
            </div>
            <div class="truncate text-[11px] text-muted">{reciter.moshafs[0]?.name ?? ""}</div>
          </button>
        {/each}
      </div>
    {/if}
  {/if}
</div>
