<script lang="ts">
  let {
    value,
    max,
    onseek,
    disabled = false,
    class: klass = "",
  }: {
    value: number;
    max: number;
    onseek: (v: number) => void;
    disabled?: boolean;
    class?: string;
  } = $props();

  let bar = $state<HTMLDivElement>();
  let dragging = $state(false);

  const pct = $derived(max > 0 ? Math.min(100, Math.max(0, (value / max) * 100)) : 0);

  function pick(e: PointerEvent) {
    if (!bar || max <= 0) return;
    const r = bar.getBoundingClientRect();
    const rtl = getComputedStyle(bar).direction === "rtl";
    const f = rtl ? (r.right - e.clientX) / r.width : (e.clientX - r.left) / r.width;
    onseek(Math.min(1, Math.max(0, f)) * max);
  }

  function down(e: PointerEvent) {
    if (disabled) return;
    dragging = true;
    bar?.setPointerCapture(e.pointerId);
    pick(e);
  }

  function move(e: PointerEvent) {
    if (dragging) pick(e);
  }

  function up(e: PointerEvent) {
    dragging = false;
    bar?.releasePointerCapture(e.pointerId);
  }
</script>

<div
  bind:this={bar}
  role="slider"
  tabindex={disabled ? -1 : 0}
  aria-valuemin={0}
  aria-valuemax={max}
  aria-valuenow={value}
  onpointerdown={down}
  onpointermove={move}
  onpointerup={up}
  onpointercancel={up}
  onkeydown={(e) => {
    if (disabled) return;
    if (e.key === "ArrowRight") onseek(Math.min(max, value + 5));
    if (e.key === "ArrowLeft") onseek(Math.max(0, value - 5));
  }}
  class="group relative h-2 w-full cursor-pointer touch-none select-none {disabled
    ? 'pointer-events-none opacity-50'
    : ''} {klass}"
>
  <div class="absolute inset-x-0 top-1/2 h-1.5 -translate-y-1/2 overflow-hidden rounded-full bg-ink-700">
    <div class="h-full rounded-full bg-gold/90" style="width:{pct}%"></div>
  </div>
  <div
    class="absolute top-1/2 size-3 -translate-y-1/2 rounded-full bg-gold shadow-[0_0_0_3px_rgba(233,185,92,0.18)] transition-opacity {dragging
      ? 'opacity-100'
      : 'opacity-0 group-hover:opacity-100'}"
    style="inset-inline-start: calc({pct}% - 6px)"
  ></div>
</div>
