<script lang="ts">
  import { fmtNumber, fmtTime, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { worship } from "$lib/stores/worship.svelte.ts";
  import type { TranslationKey } from "$lib/i18n/dict";
  import Icon from "./Icon.svelte";

  let { showLink = true }: { showLink?: boolean } = $props();

  const day = $derived(worship.day);
  const next = $derived(day?.next ?? null);
  const hijri = $derived(day?.hijri ?? null);
  const streak = $derived(worship.streak);
  const excused = $derived(worship.todayLog.excused);

  const label = (key: string) => i18n.t(`prayer.${key}` as TranslationKey);
  const prayerTimes = $derived((day?.times ?? []).filter((time) => time.key !== "sunrise"));
  // After Isha `next` is tomorrow's Fajr; it must not highlight today's row.
  const nextIsToday = $derived(!!day && !!next && next.iso.startsWith(day.date));
</script>

<section
  class="relative mt-6 overflow-hidden rounded-3xl border border-line bg-ink-900 shadow-[0_24px_60px_-40px_rgba(0,0,0,0.9)]"
>
  <div class="pointer-events-none absolute -end-16 -top-20 size-56 rounded-full bg-gold/[0.08] blur-3xl"></div>
  <div class="pointer-events-none absolute -bottom-24 start-1/3 size-52 rounded-full bg-teal/[0.06] blur-3xl"></div>

  {#if day && next}
    <div class="relative flex flex-col gap-7 px-6 py-6 lg:flex-row lg:items-center lg:justify-between">
      <div class="min-w-0">
        <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] font-medium text-gold/90">
          <span class="flex items-center gap-1.5"><Icon name="moon" size={13} />{hijri?.formatted ?? ""}</span>
          <span class="text-muted/60">·</span>
          <span class="text-muted">{i18n.t("prayer.calculated")}</span>
        </div>

        <div class="mt-3 flex flex-wrap items-baseline gap-x-3 gap-y-1">
          <span class="text-sm text-muted">{i18n.t("prayer.next")}</span>
          <h2 class="font-quran text-[1.7rem] leading-tight text-cream">
            {next.key === "dhuhr" && new Date(day.date + "T12:00:00").getDay() === 5
              ? i18n.t("prayer.jumuah")
              : label(next.key)}
          </h2>
          <span class="text-[1.7rem] font-bold tabular-nums text-gold">{next.time}</span>
        </div>

        <p class="mt-1.5 text-sm text-muted">
          <span class="tabular-nums text-cream">{fmtTime(worship.remaining)}</span>
          <span class="mx-1.5">·</span>
          {i18n.t("prayer.left")}
          {#if day.timezone}<span class="mx-1.5">·</span><span class="text-xs">{day.timezone}</span>{/if}
        </p>
      </div>

      <div class="flex flex-wrap items-stretch gap-1.5">
        {#each prayerTimes as time (time.key)}
          {@const active = nextIsToday && time.key === next.key}
          {@const done = worship.todayLog[time.key as "fajr" | "dhuhr" | "asr" | "maghrib" | "isha"]}
          <div
            class="flex min-w-[4.3rem] flex-col items-center rounded-xl border px-2.5 py-2 transition-colors
                   {active
              ? 'border-gold/50 bg-gold/10'
              : done
                ? 'border-teal/30 bg-teal/5'
                : 'border-line/70 bg-ink-850/60'}"
          >
            <span class="text-[10px] font-medium {active ? 'text-gold' : 'text-muted'}">{label(time.key)}</span>
            <span class="mt-0.5 text-[13px] font-semibold tabular-nums {time.passed ? 'text-muted' : 'text-cream'}">
              {time.time}
            </span>
            <span class="mt-1 h-1 w-1 rounded-full {done ? 'bg-teal' : active ? 'bg-gold' : 'bg-line'}"></span>
          </div>
        {/each}
      </div>
    </div>

    <div class="relative flex flex-wrap items-center justify-between gap-3 border-t border-line/70 px-6 py-3">
      <div class="flex flex-wrap items-center gap-2 text-[11px]">
        <span class="flex items-center gap-1.5 rounded-full border border-gold/25 bg-gold/5 px-2.5 py-1 font-semibold text-gold">
          <Icon name="flame" size={12} />
          {streak?.current === 1
            ? i18n.t("prayer.streakOne")
            : i18n.t("prayer.streakDays", { count: fmtNumber(streak?.current ?? 0) })}
        </span>
        {#if excused}
          <span class="rounded-full border border-teal/30 bg-teal/5 px-2.5 py-1 text-teal">{i18n.t("prayer.excused")}</span>
        {:else}
          <span class="rounded-full border border-line/70 px-2.5 py-1 text-muted">
            {i18n.t("prayer.todayCount", { count: fmtNumber(streak?.todayCount ?? 0) })}
          </span>
        {/if}
      </div>

      {#if showLink}
        <button
          type="button"
          onclick={() => nav.go("worship")}
          class="flex items-center gap-1.5 rounded-lg border border-line px-2.5 py-1.5 text-[11px] text-muted transition-colors hover:border-gold/40 hover:text-gold"
        >
          <Icon name="compass" size={13} />
          {i18n.t("prayer.viewAll")}
        </button>
      {/if}
    </div>
  {:else}
    <div class="flex h-[9.5rem] animate-pulse items-center justify-center px-6">
      <p class="text-sm text-muted">{i18n.t(worship.error ? "prayer.error" : "prayer.loading")}</p>
    </div>
  {/if}
</section>
