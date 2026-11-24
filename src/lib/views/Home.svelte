<script lang="ts">
  import { onMount } from "svelte";
  import { api } from "$lib/api";
  import type { Reciter, Track } from "$lib/types";
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import Section from "$lib/components/Section.svelte";
  import ReciterCard from "$lib/components/ReciterCard.svelte";
  import StationCard from "$lib/components/StationCard.svelte";
  import Icon from "$lib/components/Icon.svelte";

  let reciters = $state<Reciter[]>([]);
  let quranRadios = $state<Track[]>([]);
  let stations = $state<Track[]>([]);
  let recent = $state<Track[]>([]);
  let loading = $state(true);
  let failed = $state(false);

  onMount(async () => {
    const [r, qr, st, rc] = await Promise.allSettled([
      api.reciters(),
      api.quranRadios(),
      api.radios(14, "SA"),
      api.recent(12),
    ]);
    if (r.status === "fulfilled") reciters = r.value.slice(0, 14);
    if (qr.status === "fulfilled") quranRadios = qr.value.slice(0, 10);
    if (st.status === "fulfilled") stations = st.value.slice(0, 14);
    if (rc.status === "fulfilled") recent = rc.value;
    failed = [r, qr, st].every((x) => x.status === "rejected");
    loading = false;
  });

  function playStation(track: Track, list: Track[]) {
    player.play(track, list);
  }
</script>

<div class="fade-in">
  <!-- Hero -->
  <section class="relative overflow-hidden rounded-3xl border border-line bg-ink-900 px-7 py-8">
    <div class="pointer-events-none absolute -end-24 -top-28 size-64 rounded-full bg-gold/[0.07] blur-3xl"></div>
    <div class="pointer-events-none absolute -bottom-28 start-10 size-52 rounded-full bg-teal/[0.05] blur-3xl"></div>
    <div class="relative max-w-xl">
      <p class="text-[10px] font-bold uppercase tracking-[0.24em] text-gold/80">
        {i18n.t("app.tagline")}
      </p>
      <h1 class="mt-2 pb-1 font-quran text-[2.1rem] leading-[1.35] text-cream">دندنة</h1>
      <p class="mt-3 text-sm leading-relaxed text-muted">{i18n.t("home.heroLine")}</p>
      <div class="mt-6 flex flex-wrap gap-2.5">
        <button
          type="button"
          onclick={() => nav.go("quran")}
          class="flex items-center gap-2 rounded-xl bg-gold px-4 py-2.5 text-sm font-semibold text-ink-950 transition-transform hover:scale-[1.02] active:scale-95"
        >
          <Icon name="book" size={16} />
          {i18n.t("home.startQuran")}
        </button>
        <button
          type="button"
          onclick={() => nav.go("radio")}
          class="flex items-center gap-2 rounded-xl border border-line bg-ink-850 px-4 py-2.5 text-sm font-medium text-cream transition-colors hover:border-gold/40 hover:text-gold"
        >
          <Icon name="radio" size={16} />
          {i18n.t("home.startRadio")}
        </button>
        <button
          type="button"
          onclick={() => nav.go("explore")}
          class="flex items-center gap-2 rounded-xl border border-line bg-ink-850 px-4 py-2.5 text-sm font-medium text-cream transition-colors hover:border-gold/40 hover:text-gold"
        >
          <Icon name="sparkle" size={16} />
          {i18n.t("home.startExplore")}
        </button>
      </div>
    </div>
  </section>

  {#if failed}
    <div class="mt-10 rounded-2xl border border-line bg-ink-900 px-6 py-10 text-center">
      <Icon name="globe" size={26} class="mx-auto text-muted" />
      <p class="mt-3 text-sm text-muted">{i18n.t("common.offline")}</p>
      <button
        type="button"
        class="mt-4 rounded-lg border border-line px-3 py-1.5 text-xs text-cream hover:border-gold/40"
        onclick={() => location.reload()}>{i18n.t("common.retry")}</button
      >
    </div>
  {:else if loading}
    <div class="mt-10 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
      {#each Array(12) as _, i (i)}
        <div class="animate-pulse">
          <div class="aspect-square rounded-2xl bg-ink-800"></div>
          <div class="mt-2 h-3 w-3/4 rounded bg-ink-800"></div>
          <div class="mt-1.5 h-2.5 w-1/2 rounded bg-ink-800/70"></div>
        </div>
      {/each}
    </div>
  {:else}
    {#if recent.length}
      <Section title={i18n.t("home.continue")}>
        <div class="scroll-row no-scrollbar">
          {#each recent as track (track.id)}
            <StationCard track={track} onplay={() => player.play(track, recent)} />
          {/each}
        </div>
      </Section>
    {/if}

    {#if quranRadios.length}
      <Section
        title={i18n.t("home.quranRadio")}
        action={i18n.t("home.seeAll")}
        onaction={() => nav.go("radio")}
      >
        <div class="grid grid-cols-1 gap-2.5 sm:grid-cols-2 xl:grid-cols-3">
          {#each quranRadios as station (station.id)}
            <button
              type="button"
              onclick={() => playStation(station, quranRadios)}
              class="group flex items-center gap-3 rounded-xl border border-line/70 bg-ink-850/50 px-3 py-2.5 text-start transition-colors hover:border-gold/30 hover:bg-ink-800"
            >
              <span class="grid size-9 shrink-0 place-items-center rounded-lg bg-gold/10 text-gold">
                <Icon name={station.id === player.current?.id ? "pause" : "radio"} size={15} />
              </span>
              <span class="min-w-0 flex-1 truncate text-[0.83rem] font-medium group-hover:text-gold">
                {station.title}
              </span>
              <span class="shrink-0 text-[10px] font-semibold text-teal">{i18n.t("radio.live")}</span>
            </button>
          {/each}
        </div>
      </Section>
    {/if}

    {#if reciters.length}
      <Section
        title={i18n.t("home.reciters")}
        action={i18n.t("home.seeAll")}
        onaction={() => nav.go("quran")}
      >
        <div class="scroll-row no-scrollbar">
          {#each reciters as reciter (reciter.id)}
            <ReciterCard reciter={reciter} onselect={() => nav.go("quran", reciter.id)} />
          {/each}
        </div>
      </Section>
    {/if}

    {#if stations.length}
      <Section
        title={i18n.t("home.stations")}
        action={i18n.t("home.seeAll")}
        onaction={() => nav.go("radio")}
      >
        <div class="scroll-row no-scrollbar">
          {#each stations as station (station.id)}
            <StationCard track={station} onplay={() => playStation(station, stations)} />
          {/each}
        </div>
      </Section>
    {/if}
  {/if}
</div>
