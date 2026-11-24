<script lang="ts">
  import { ui } from "$lib/stores/ui.svelte.ts";
</script>

{#if ui.toast}
  <div
    class="pointer-events-none fixed bottom-[104px] left-1/2 z-50 -translate-x-1/2"
    role="status"
    aria-live="polite"
  >
    <div
      class="fade-in max-w-[420px] rounded-xl border border-line bg-ink-850/98 px-4 py-2.5 text-center text-xs text-cream shadow-xl shadow-black/40 backdrop-blur"
    >
      {ui.toast}
    </div>
  </div>
{/if}
