<script lang="ts">
  import type { TrackKind } from "$lib/types";

  let {
    url,
    seed = "",
    kind = "music",
    class: klass = "",
    rounded = "rounded-xl",
    initials = false,
  }: {
    url?: string;
    seed?: string;
    kind?: TrackKind;
    class?: string;
    rounded?: string;
    initials?: boolean;
  } = $props();

  let failed = $state(false);

  const hue = $derived(hash(seed || "dandanah"));
  const second = $derived((hue + 62) % 360);

  function hash(s: string): number {
    let h = 0;
    for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 360;
    return h;
  }

  const gradient = $derived(
    kind === "quran"
      ? `linear-gradient(140deg, hsl(${hue} 32% 22%), hsl(${second} 28% 12%))`
      : kind === "radio"
        ? `linear-gradient(140deg, hsl(${hue} 40% 24%), hsl(${second} 34% 13%))`
        : `linear-gradient(140deg, hsl(${hue} 36% 26%), hsl(${second} 30% 14%))`,
  );
</script>

<div
  class="relative overflow-hidden [container-type:inline-size] {rounded} {klass}"
  style="background: {gradient}"
  aria-hidden="true"
>
  {#if url && !failed}
    <img
      src={url}
      alt=""
      loading="lazy"
      class="h-full w-full object-cover"
      onerror={() => (failed = true)}
    />
  {:else if initials}
    <div class="grid h-full w-full place-items-center">
      <span class="font-quran text-[30cqw] leading-none text-gold-soft/85">
        {seed.slice(0, 1)}
      </span>
    </div>
  {:else}
    <div class="grid h-full w-full place-items-center">
      <svg viewBox="0 0 48 48" class="h-[42%] w-[42%] text-gold/35" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round">
        <path d="M6 24h3l3-9 4 18 4-14 3 9h3" />
        <path d="M30 24h3l4-12 4 20" opacity="0.55" />
      </svg>
    </div>
  {/if}
</div>
