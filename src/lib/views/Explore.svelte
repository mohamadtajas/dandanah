<script lang="ts">
  import { api } from "$lib/api";
  import type { Track } from "$lib/types";
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import TrackRow from "$lib/components/TrackRow.svelte";
  import Icon from "$lib/components/Icon.svelte";

  type Section = "all" | "music" | "anasheed";

  let term = $state("");
  let section = $state<Section>("all");
  let tracks = $state<Track[]>([]);
  let loading = $state(true);
  let failed = $state(false);
  let reload = $state(0);
  let token = 0;

  const sections: { id: Section; label: "explore.all" | "explore.music" | "explore.anasheed" }[] = [
    { id: "all", label: "explore.all" },
    { id: "music", label: "explore.music" },
    { id: "anasheed", label: "explore.anasheed" },
  ];

  $effect(() => {
    const query = term.trim();
    const selected = section;
    reload;
    const ticket = ++token;
    loading = true;

    const handle = setTimeout(async () => {
      try {
        const result = await api.exploreCc(query, selected, 30);
        if (ticket !== token) return;
        tracks = result;
        failed = false;
      } catch {
        if (ticket !== token) return;
        tracks = [];
        failed = true;
      } finally {
        if (ticket === token) loading = false;
      }
    }, query ? 420 : 0);

    return () => clearTimeout(handle);
  });

  function retry() {
    reload += 1;
  }
</script>

<div class="fade-in">
  <header>
    <p class="text-[10px] font-bold uppercase tracking-[0.22em] text-gold/80">
      {i18n.t("explore.sources")}
    </p>
    <h1 class="mt-1 text-2xl font-bold text-cream">{i18n.t("explore.title")}</h1>
    <p class="mt-1 max-w-2xl text-xs leading-relaxed text-muted">{i18n.t("explore.note")}</p>
  </header>

  <div class="mt-5 flex flex-wrap items-center gap-2">
    {#each sections as item (item.id)}
      <button
        type="button"
        onclick={() => (section = item.id)}
        class="rounded-full border px-3 py-1.5 text-[11px] transition-colors
               {section === item.id
          ? 'border-gold/50 bg-gold/12 text-gold'
          : 'border-line text-muted hover:border-gold/30 hover:text-cream'}"
      >
        {i18n.t(item.label)}
      </button>
    {/each}
  </div>

  <label
    class="mt-4 flex max-w-lg items-center gap-2 rounded-xl border border-line bg-ink-850 px-3 py-2 focus-within:border-gold/50"
  >
    <Icon name="search" size={15} class="text-muted" />
    <input
      bind:value={term}
      placeholder={i18n.t("explore.placeholder")}
      class="w-full bg-transparent text-sm text-cream placeholder:text-muted/70 focus:outline-none"
    />
    {#if term}
      <button
        type="button"
        onclick={() => (term = "")}
        class="rounded p-0.5 text-muted hover:text-cream"
        aria-label={i18n.t("common.close")}
      >
        <Icon name="x" size={13} />
      </button>
    {/if}
  </label>

  <div class="mt-6">
    {#if loading}
      <div class="space-y-1">
        {#each Array(7) as _, i (i)}
          <div class="flex animate-pulse items-center gap-3 px-2.5 py-2">
            <div class="size-11 rounded-lg bg-ink-800"></div>
            <div class="h-3 w-56 rounded bg-ink-800"></div>
          </div>
        {/each}
      </div>
      <p class="mt-3 text-center text-[11px] text-muted">{i18n.t("explore.loading")}</p>
    {:else if failed}
      <div class="rounded-2xl border border-line bg-ink-900/50 px-6 py-14 text-center">
        <Icon name="globe" size={28} class="mx-auto text-ink-700" />
        <p class="mt-3 text-sm text-muted">{i18n.t("explore.error")}</p>
        <button
          type="button"
          onclick={retry}
          class="mt-4 rounded-lg border border-line px-3 py-1.5 text-xs text-cream transition-colors hover:border-gold/40 hover:text-gold"
        >
          {i18n.t("common.retry")}
        </button>
      </div>
    {:else if tracks.length === 0}
      <div class="rounded-2xl border border-line bg-ink-900/50 px-6 py-14 text-center">
        <Icon name="sparkle" size={28} class="mx-auto text-ink-700" />
        <p class="mt-3 text-sm text-muted">{i18n.t("explore.empty")}</p>
      </div>
    {:else}
      <div class="overflow-hidden rounded-2xl border border-line bg-ink-900/50 p-1.5">
        {#each tracks as track (track.id)}
          <TrackRow {track} queue={tracks} />
        {/each}
      </div>
    {/if}
  </div>
</div>
