<script lang="ts">
  import { onMount } from "svelte";
  import { api } from "$lib/api";
  import type { Track } from "$lib/types";
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import TrackRow from "$lib/components/TrackRow.svelte";
  import Icon from "$lib/components/Icon.svelte";
  import type { IconName } from "$lib/components/Icon.svelte";

  type Tab = "recent" | "favorites" | "playlists" | "downloads";

  let tab = $state<Tab>("recent");
  let recent = $state<Track[]>([]);
  let loading = $state(true);

  const tabs: { id: Tab; label: "library.recent" | "library.favorites" | "library.playlists" | "library.downloads"; icon: IconName }[] = [
    { id: "recent", label: "library.recent", icon: "clock" },
    { id: "favorites", label: "library.favorites", icon: "heart" },
    { id: "playlists", label: "library.playlists", icon: "list" },
    { id: "downloads", label: "library.downloads", icon: "download" },
  ];

  onMount(async () => {
    try {
      recent = await api.recent(40);
    } catch {
      recent = [];
    } finally {
      loading = false;
    }
  });
</script>

<div class="fade-in">
  <header>
    <h1 class="text-2xl font-bold text-cream">{i18n.t("library.title")}</h1>
  </header>

  <div class="mt-5 flex flex-wrap gap-2">
    {#each tabs as t (t.id)}
      <button
        type="button"
        onclick={() => (tab = t.id)}
        class="flex items-center gap-2 rounded-xl border px-3 py-2 text-[12px] transition-colors
               {tab === t.id
          ? 'border-gold/45 bg-gold/10 text-gold'
          : 'border-line text-muted hover:border-gold/25 hover:text-cream'}"
      >
        <Icon name={t.icon} size={14} />
        {i18n.t(t.label)}
      </button>
    {/each}
  </div>

  <div class="mt-6">
    {#if tab === "recent"}
      {#if loading}
        <div class="space-y-1">
          {#each Array(8) as _, i (i)}
            <div class="flex animate-pulse items-center gap-3 px-2.5 py-2">
              <div class="size-11 rounded-lg bg-ink-800"></div>
              <div class="h-3 w-56 rounded bg-ink-800"></div>
            </div>
          {/each}
        </div>
      {:else if recent.length === 0}
        <div class="rounded-2xl border border-line bg-ink-900/50 px-6 py-14 text-center">
          <Icon name="clock" size={28} class="mx-auto text-ink-700" />
          <p class="mt-3 text-sm text-muted">{i18n.t("home.empty")}</p>
        </div>
      {:else}
        <div class="overflow-hidden rounded-2xl border border-line bg-ink-900/50 p-1.5">
          {#each recent as track (track.id)}
            <TrackRow {track} queue={recent} />
          {/each}
        </div>
      {/if}
    {:else}
      <div class="rounded-2xl border border-dashed border-line bg-ink-900/40 px-6 py-16 text-center">
        <Icon name="sparkle" size={26} class="mx-auto text-gold/40" />
        <p class="mt-3 text-sm font-medium text-cream">{i18n.t("library.comingSoon")}</p>
        <p class="mt-1 text-xs text-muted">{i18n.t("library.empty")}</p>
      </div>
    {/if}
  </div>
</div>
