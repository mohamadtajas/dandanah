<script lang="ts">
  import type { PrayerDay, PrayerLog } from "$lib/types";
  import type { TranslationKey } from "$lib/i18n/dict";
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import Icon from "./Icon.svelte";

  let {
    day,
    log,
    disabled = false,
    ontoggle,
  }: {
    day: PrayerDay;
    log: PrayerLog;
    disabled?: boolean;
    ontoggle: (prayer: string) => void;
  } = $props();

  const friday = $derived(new Date(day.date + "T12:00:00").getDay() === 5);
  const label = (key: string) =>
    key === "dhuhr" && friday ? i18n.t("prayer.jumuah") : i18n.t(`prayer.${key}` as TranslationKey);
  const isDone = (key: string) =>
    key === "sunrise" ? false : log[key as "fajr" | "dhuhr" | "asr" | "maghrib" | "isha"];
  const nextKey = $derived(
    day.next && day.next.iso.startsWith(day.date) ? day.next.key : null,
  );
</script>

<div class="divide-y divide-line/60">
  {#each day.times as row (row.key)}
    {@const obligatory = row.key !== "sunrise"}
    {@const done = isDone(row.key)}
    <div
      class="flex items-center gap-3 py-2.5
             {row.key === nextKey ? 'rounded-xl bg-gold/[0.04] px-2' : ''}"
    >
      <span class="w-14 shrink-0 text-[13px] font-semibold tabular-nums {row.passed ? 'text-muted' : 'text-cream'}">
        {row.time}
      </span>

      <span class="flex min-w-0 flex-1 items-center gap-2">
        <span class="text-sm {done ? 'text-teal' : 'text-cream'}">{label(row.key)}</span>
        {#if row.key === nextKey}
          <span class="rounded-full bg-gold/10 px-1.5 py-0.5 text-[9px] font-semibold text-gold">
            {i18n.t("prayer.next")}
          </span>
        {/if}
      </span>

      {#if obligatory}
        <button
          type="button"
          disabled={disabled}
          aria-pressed={done}
          aria-label={label(row.key)}
          onclick={() => ontoggle(row.key)}
          class="grid size-8 shrink-0 place-items-center rounded-full border transition-colors
                 {done
            ? 'border-teal/50 bg-teal/15 text-teal'
            : 'border-line text-muted/40 hover:border-gold/40 hover:text-gold'} disabled:opacity-50"
        >
          <Icon name="check" size={15} />
        </button>
      {:else}
        <span class="w-8 shrink-0 text-center text-[10px] text-muted/50">—</span>
      {/if}
    </div>
  {/each}
</div>
