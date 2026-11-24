<script lang="ts">
  import type { Track } from "$lib/types";
  import { library } from "$lib/stores/library.svelte.ts";
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import Icon from "./Icon.svelte";

  let {
    track,
    x,
    y,
    onclose,
  }: { track: Track; x: number; y: number; onclose: () => void } = $props();

  let name = $state("");
  let busy = $state(false);

  async function create(event: Event) {
    event.preventDefault();
    if (!name.trim() || busy) return;
    busy = true;
    const playlist = await library.createPlaylist(name);
    if (playlist) await library.addToPlaylist(playlist.id, track);
    busy = false;
    onclose();
  }

  async function add(playlistId: string) {
    if (busy) return;
    busy = true;
    await library.addToPlaylist(playlistId, track);
    busy = false;
    onclose();
  }
</script>

<svelte:window onkeydown={(e) => e.key === "Escape" && onclose()} />

<div class="fixed inset-0 z-40" role="presentation" onclick={onclose}></div>

<div
  class="fade-in fixed z-50 w-[268px] overflow-hidden rounded-xl border border-line bg-ink-900/98 shadow-2xl shadow-black/50 backdrop-blur"
  style="top: {y}px; left: {x}px"
  role="dialog"
  aria-label={i18n.t("library.addToPlaylist")}
>
  <div class="flex items-center justify-between border-b border-line px-3 py-2">
    <span class="text-[11px] font-semibold text-cream">{i18n.t("library.addToPlaylist")}</span>
    <button
      type="button"
      onclick={onclose}
      class="rounded p-1 text-muted transition-colors hover:bg-ink-800 hover:text-cream"
      aria-label={i18n.t("library.cancel")}
    >
      <Icon name="x" size={13} />
    </button>
  </div>

  <form onsubmit={create} class="flex items-center gap-1.5 border-b border-line/60 px-2.5 py-2">
    <input
      bind:value={name}
      placeholder={i18n.t("library.playlistName")}
      class="min-w-0 flex-1 bg-transparent px-1 text-xs text-cream placeholder:text-muted/70 focus:outline-none"
    />
    <button
      type="submit"
      disabled={!name.trim() || busy}
      class="rounded-md bg-gold px-2 py-1 text-[10px] font-semibold text-ink-950 disabled:opacity-40"
    >
      {i18n.t("library.create")}
    </button>
  </form>

  <div class="max-h-56 overflow-y-auto p-1">
    {#if library.playlists.length === 0}
      <p class="px-2 py-3 text-center text-[11px] text-muted">{i18n.t("library.emptyPlaylists")}</p>
    {:else}
      {#each library.playlists as playlist (playlist.id)}
        <button
          type="button"
          onclick={() => add(playlist.id)}
          class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-start transition-colors hover:bg-ink-800"
        >
          <Icon name="list" size={13} class="shrink-0 text-muted" />
          <span class="min-w-0 flex-1 truncate text-xs text-cream">{playlist.name}</span>
          <span class="shrink-0 text-[10px] tabular-nums text-muted">{playlist.trackCount}</span>
        </button>
      {/each}
    {/if}
  </div>
</div>
