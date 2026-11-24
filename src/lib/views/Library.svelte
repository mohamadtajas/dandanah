<script lang="ts">
  import { onMount } from "svelte";
  import { api } from "$lib/api";
  import type { Track } from "$lib/types";
  import type { Memorization, Surah } from "$lib/types";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { DEFAULT_AYAH_RECITER } from "$lib/constants";
  import TrackRow from "$lib/components/TrackRow.svelte";
  import Icon from "$lib/components/Icon.svelte";
  import type { IconName } from "$lib/components/Icon.svelte";

  type Tab = "recent" | "hifz" | "favorites" | "playlists" | "downloads";

  let tab = $state<Tab>("recent");
  let recent = $state<Track[]>([]);
  let memorisation = $state<Memorization[]>([]);
  let surahs = $state<Surah[]>([]);
  let loading = $state(true);

  const tabs: { id: Tab; label: "library.recent" | "library.hifz" | "library.favorites" | "library.playlists" | "library.downloads"; icon: IconName }[] = [
    { id: "recent", label: "library.recent", icon: "clock" },
    { id: "hifz", label: "library.hifz", icon: "bookmark" },
    { id: "favorites", label: "library.favorites", icon: "heart" },
    { id: "playlists", label: "library.playlists", icon: "list" },
    { id: "downloads", label: "library.downloads", icon: "download" },
  ];

  onMount(async () => {
    const [r, m, s] = await Promise.allSettled([
      api.recent(40),
      api.memorization(),
      api.surahs(),
    ]);
    if (r.status === "fulfilled") recent = r.value;
    if (m.status === "fulfilled") memorisation = m.value;
    if (s.status === "fulfilled") surahs = s.value;
    loading = false;
  });

  const hifzRows = $derived(
    memorisation
      .map((row) => ({
        row,
        surah: surahs.find((s) => s.number === row.surah),
      }))
      .filter((x): x is { row: Memorization; surah: Surah } => Boolean(x.surah)),
  );

  function shortName(name: string) {
    return name.replace(/^سُورَةُ\s*/, "").replace(/^سورة\s*/, "");
  }
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
    {:else if tab === "hifz"}
      {#if hifzRows.length === 0}
        <div class="rounded-2xl border border-line bg-ink-900/50 px-6 py-14 text-center">
          <Icon name="bookmark" size={28} class="mx-auto text-ink-700" />
          <p class="mt-3 text-sm text-muted">{i18n.t("library.noHifz")}</p>
        </div>
      {:else}
        <div class="overflow-hidden rounded-2xl border border-line bg-ink-900/50">
          {#each hifzRows as { row, surah } (row.surah)}
            {@const pct = surah.ayahs > 0 ? Math.round((row.memorized.length / surah.ayahs) * 100) : 0}
            <button
              type="button"
              onclick={() =>
                nav.go("quran", "ayah", DEFAULT_AYAH_RECITER, surah.number)}
              class="group flex w-full items-center gap-3 border-b border-line/50 px-4 py-3 text-start transition-colors last:border-0 hover:bg-ink-800/60"
            >
              <span
                class="grid size-9 shrink-0 place-items-center rounded-lg border border-line text-[11px] tabular-nums text-muted group-hover:border-gold/30 group-hover:text-gold"
              >
                {fmtNumber(surah.number)}
              </span>
              <span class="min-w-0 flex-1">
                <span class="block truncate font-quran text-[1.05rem] leading-snug text-cream group-hover:text-gold">
                  {shortName(surah.name)}
                </span>
                <span class="mt-1 block h-1 w-full max-w-40 overflow-hidden rounded-full bg-ink-800">
                  <span class="block h-full rounded-full bg-teal" style="width: {pct}%"></span>
                </span>
              </span>
              <span class="shrink-0 text-[11px] tabular-nums text-teal">
                {fmtNumber(row.memorized.length)} / {fmtNumber(surah.ayahs)}
              </span>
              <Icon
                name="chevron"
                size={13}
                class="shrink-0 text-muted opacity-0 transition-opacity group-hover:opacity-100"
              />
            </button>
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
