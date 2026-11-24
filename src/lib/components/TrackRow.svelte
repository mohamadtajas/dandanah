<script lang="ts">
  import type { Track } from "$lib/types";
  import { player } from "$lib/stores/player.svelte.ts";
  import { fmtTime, i18n } from "$lib/i18n/index.svelte.ts";
  import Artwork from "./Artwork.svelte";
  import Icon from "./Icon.svelte";

  let {
    track,
    queue,
    index,
  }: { track: Track; queue?: Track[]; index?: number } = $props();

  const active = $derived(player.current?.id === track.id);
</script>

<button
  type="button"
  onclick={() => player.play(track, queue)}
  class="group flex w-full items-center gap-3 rounded-xl px-2.5 py-2 text-start transition-colors
         {active ? 'bg-gold/10' : 'hover:bg-ink-800/70'}"
>
  <div class="relative shrink-0">
    <Artwork
      url={track.artworkUrl}
      seed={track.title}
      kind={track.kind}
      class="size-11"
      rounded="rounded-lg"
    />
    <div
      class="absolute inset-0 grid place-items-center rounded-lg bg-ink-950/70 opacity-0 transition-opacity group-hover:opacity-100
             {active ? 'opacity-100' : ''}"
    >
      {#if active && player.playing}
        <div class="eq">
          <i></i><i></i><i></i><i></i>
        </div>
      {:else}
        <Icon name="play" size={16} class="text-gold" />
      {/if}
    </div>
  </div>

  <div class="min-w-0 flex-1">
    <div class="truncate text-[0.95rem] font-medium {active ? 'text-gold' : 'text-cream'}">
      {track.title}
    </div>
    <div class="flex items-center gap-1.5 text-xs text-muted">
      <span class="truncate">{track.artist}</span>
      {#if track.live}
        <span class="flex shrink-0 items-center gap-1 rounded-md border border-teal/30 bg-teal/10 px-1.5 py-px text-[9px] font-semibold tracking-wide text-teal">
          <span class="size-1 animate-pulse rounded-full bg-teal"></span>
          {i18n.t("radio.live")}
        </span>
      {:else if track.subtitle}
        <span class="truncate text-muted/60">· {track.subtitle}</span>
      {/if}
    </div>
  </div>

  {#if !track.live && track.durationS}
    <span class="shrink-0 text-xs tabular-nums text-muted">
      {fmtTime(track.durationS)}
    </span>
  {/if}
</button>
