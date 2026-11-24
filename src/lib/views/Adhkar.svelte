<script lang="ts">
  import { onMount } from "svelte";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { adhkar } from "$lib/stores/adhkar.svelte.ts";
  import { normalizeArabic } from "$lib/text";
  import AdhkarCards from "$lib/components/AdhkarCards.svelte";
  import Icon from "$lib/components/Icon.svelte";

  let query = $state("");
  let confirmReset = $state(false);

  onMount(() => {
    void adhkar.load();
    adhkar.start();
  });

  // Keep the reader in sync with the hash, so the nav item and browser
  // back/forward close it and deep links open the right category.
  $effect(() => {
    const param = nav.param;
    if (nav.view !== "adhkar") return;
    if (param && param !== adhkar.activeCategoryId) adhkar.openCategory(param);
    if (!param && adhkar.activeCategoryId) adhkar.closeReader();
  });

  function open(id: string) {
    nav.go("adhkar", id);
    adhkar.openCategory(id);
  }

  const active = $derived(adhkar.activeCategory);
  const item = $derived(adhkar.activeItem);
  const remaining = $derived(adhkar.activeRemaining);
  const percent = $derived(active ? adhkar.percent(active) : 0);
  const streak = $derived(adhkar.streak);

  const otherFeatured = $derived(adhkar.featured.filter((category) => !category.streakKey));
  const allCategories = $derived(adhkar.categories.filter((category) => !category.featured));
  const filtered = $derived.by(() => {
    const needle = normalizeArabic(query);
    if (!needle) return allCategories;
    return allCategories.filter((category) => normalizeArabic(category.title).includes(needle));
  });

  const streakLabel = $derived(
    (streak?.current ?? 0) === 1
      ? i18n.t("adhkar.streakOne")
      : i18n.t("adhkar.streakDays", { count: fmtNumber(streak?.current ?? 0) }),
  );

  const iconFor = (id: string) =>
    id === "sleep" ? "moon" : id === "waking" ? "sun" : id === "misc" ? "sparkle" : "book";

  function back() {
    confirmReset = false;
    adhkar.closeReader();
    nav.go("adhkar");
  }

  function reset() {
    adhkar.resetCategory();
    confirmReset = false;
  }
</script>

<div class="fade-in">
  {#if active && item}
    <header class="flex flex-wrap items-center justify-between gap-3">
      <button
        type="button"
        onclick={back}
        class="flex items-center gap-1.5 rounded-xl border border-line px-3 py-2 text-xs text-muted transition-colors hover:border-gold/40 hover:text-gold"
      >
        <Icon name="chevron" size={14} class="rotate-180 rtl:rotate-0" />
        {i18n.t("adhkar.back")}
      </button>
      <h1 class="text-lg font-bold text-cream">{active.title}</h1>
      <div class="flex items-center gap-2">
        {#if confirmReset}
          <button type="button" onclick={reset} class="text-[10px] font-semibold text-gold">
            {i18n.t("adhkar.resetConfirm")}
          </button>
          <button
            type="button"
            onclick={() => (confirmReset = false)}
            class="text-[10px] text-muted hover:text-cream"
          >
            {i18n.t("adhkar.cancel")}
          </button>
        {:else}
          <button
            type="button"
            onclick={() => (confirmReset = true)}
            class="rounded-lg border border-line px-2.5 py-1.5 text-[10px] text-muted transition-colors hover:border-gold/40 hover:text-gold"
          >
            {i18n.t("adhkar.reset")}
          </button>
        {/if}
      </div>
    </header>

    <div class="mt-4 rounded-2xl border border-line bg-ink-900/60 p-4">
      <div class="flex items-center justify-between text-[11px] text-muted">
        <span>
          {i18n.t("adhkar.readerProgress", {
            index: fmtNumber(adhkar.activeIndex + 1),
            count: fmtNumber(active.items.length),
          })}
        </span>
        <span class="tabular-nums">{fmtNumber(percent)}%</span>
      </div>
      <div class="mt-2 h-1.5 overflow-hidden rounded-full bg-ink-800">
        <div
          class="h-full rounded-full transition-[width] duration-300 {adhkar.completed ? 'bg-teal' : 'bg-gold'}"
          style={`width: ${percent}%`}
        ></div>
      </div>
    </div>

    {#if adhkar.completed}
      <div class="mt-4 rounded-3xl border border-teal/30 bg-teal/[0.06] p-8 text-center">
        <span class="mx-auto grid size-14 place-items-center rounded-full bg-teal/15 text-teal">
          <Icon name="check" size={28} />
        </span>
        <h2 class="mt-4 text-xl font-bold text-cream">
          {i18n.t("adhkar.completed", { title: active.title })}
        </h2>
        <p class="mt-1 text-sm text-muted">{i18n.t("adhkar.completedHint")}</p>
        <p class="mt-4 flex items-center justify-center gap-2 text-sm font-semibold text-gold">
          <Icon name="flame" size={15} />
          {streakLabel}
        </p>

        <div class="mt-6 flex flex-wrap justify-center gap-2">
          <button
            type="button"
            onclick={back}
            class="rounded-xl bg-gold px-4 py-2 text-xs font-semibold text-ink-950"
          >
            {i18n.t("adhkar.back")}
          </button>
          {#if confirmReset}
            <button
              type="button"
              onclick={reset}
              class="rounded-xl border border-gold/50 bg-gold/10 px-4 py-2 text-xs font-semibold text-gold"
            >
              {i18n.t("adhkar.resetConfirm")}
            </button>
            <button
              type="button"
              onclick={() => (confirmReset = false)}
              class="rounded-xl border border-line px-4 py-2 text-xs text-muted"
            >
              {i18n.t("adhkar.cancel")}
            </button>
          {:else}
            <button
              type="button"
              onclick={() => (confirmReset = true)}
              class="rounded-xl border border-line px-4 py-2 text-xs text-muted transition-colors hover:border-gold/40 hover:text-gold"
            >
              {i18n.t("adhkar.reset")}
            </button>
          {/if}
        </div>
      </div>
    {:else}
      <button
        type="button"
        onclick={() => adhkar.tap()}
        class="group mt-4 w-full rounded-3xl border border-line bg-ink-900 px-6 py-9 text-center transition-colors hover:border-gold/35 active:scale-[0.995] sm:px-10"
        aria-label={`${i18n.t("adhkar.remaining")} ${remaining}`}
      >
        <p class="mx-auto max-w-3xl font-quran text-[1.45rem] leading-[2.15] text-cream sm:text-[1.6rem]">
          {item.text}
        </p>

        <span class="mx-auto mt-8 flex w-fit flex-col items-center">
          <span
            class="text-4xl font-bold tabular-nums text-gold transition-transform group-active:scale-95"
            aria-live="polite"
          >
            {fmtNumber(remaining)}
          </span>
          <span class="mt-1 text-[11px] text-muted">{i18n.t("adhkar.remaining")}</span>
        </span>
        <span class="mt-4 block text-[10px] text-muted/70">{i18n.t("adhkar.tapHint")}</span>
      </button>

      <div class="mt-3 flex items-start justify-between gap-4 px-1">
        <p class="max-w-xl text-[10px] leading-relaxed text-muted">
          <span class="font-semibold text-muted/80">{i18n.t("adhkar.reference")}:</span>
          {item.reference}
        </p>
        {#if active.streakKey}
          <span class="flex shrink-0 items-center gap-1.5 rounded-full border border-gold/25 bg-gold/5 px-2.5 py-1 text-[10px] text-gold">
            <Icon name="flame" size={11} />
            {streakLabel}
          </span>
        {/if}
      </div>

      <div class="mt-5 flex items-center justify-between gap-3">
        <button
          type="button"
          onclick={() => adhkar.previous()}
          class="flex items-center gap-1.5 rounded-xl border border-line px-3.5 py-2 text-xs text-muted transition-colors hover:border-gold/40 hover:text-gold"
        >
          <Icon name="chevron" size={14} class="rotate-180 rtl:rotate-0" />
          {i18n.t("adhkar.previous")}
        </button>
        <button
          type="button"
          onclick={() => adhkar.next()}
          class="flex items-center gap-1.5 rounded-xl border border-line px-3.5 py-2 text-xs text-muted transition-colors hover:border-gold/40 hover:text-gold"
        >
          {i18n.t("adhkar.next")}
          <Icon name="chevron" size={14} />
        </button>
      </div>
    {/if}
  {:else}
    <header class="flex flex-wrap items-start justify-between gap-4">
      <div>
        <p class="text-[10px] font-bold uppercase tracking-[0.24em] text-gold/80">{i18n.t("app.name")}</p>
        <h1 class="mt-1 text-2xl font-bold text-cream">{i18n.t("adhkar.title")}</h1>
        <p class="mt-1 text-sm text-muted">{i18n.t("adhkar.subtitle")}</p>
      </div>
      <span class="flex items-center gap-2 rounded-full border border-gold/25 bg-gold/5 px-3 py-1.5 text-xs font-semibold text-gold">
        <Icon name="flame" size={14} />
        {i18n.t("adhkar.streak")}: {streakLabel}
      </span>
    </header>

    {#if adhkar.error}
      <div class="mt-4 flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-gold/30 bg-gold/[0.05] px-4 py-3 text-xs text-gold">
        <span>{i18n.t("common.error")}</span>
        <button type="button" onclick={() => adhkar.load()} class="font-semibold underline">
          {i18n.t("common.retry")}
        </button>
      </div>
    {/if}

    <AdhkarCards embedded />

    <div class="mt-3 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
      {#each otherFeatured as category (category.id)}
        {@const done = adhkar.isComplete(category)}
        {@const progress = adhkar.percent(category)}
        <button
          type="button"
          onclick={() => open(category.id)}
          class="group rounded-2xl border border-line bg-ink-900/60 p-4 text-start transition-colors hover:border-gold/35"
        >
          <div class="flex items-center justify-between gap-2">
            <span class="grid size-8 shrink-0 place-items-center rounded-lg bg-gold/10 text-gold">
              <Icon name={iconFor(category.id) as "moon" | "sun" | "sparkle" | "book"} size={14} />
            </span>
            {#if done}
              <Icon name="check" size={14} class="text-teal" />
            {:else}
              <span class="text-[10px] tabular-nums text-muted">{fmtNumber(progress)}%</span>
            {/if}
          </div>
          <p class="mt-2.5 truncate text-sm font-medium text-cream group-hover:text-gold">
            {category.title}
          </p>
          <p class="mt-0.5 text-[10px] text-muted">
            {i18n.t("adhkar.items", { count: fmtNumber(category.items.length) })}
          </p>
          <div class="mt-2 h-1 overflow-hidden rounded-full bg-ink-800">
            <div
              class="h-full rounded-full {done ? 'bg-teal' : 'bg-gold'}"
              style={`width: ${progress}%`}
            ></div>
          </div>
        </button>
      {/each}
    </div>

    <section class="mt-8">
      <div class="flex flex-wrap items-center justify-between gap-2">
        <h2 class="text-sm font-semibold text-cream">{i18n.t("adhkar.all")}</h2>
        <span class="text-[10px] text-muted">{fmtNumber(filtered.length)}</span>
      </div>

      <label class="mt-2.5 flex items-center gap-2 rounded-xl border border-line bg-ink-850 px-3 py-2 focus-within:border-gold/50">
        <Icon name="search" size={15} class="shrink-0 text-muted" />
        <input
          bind:value={query}
          placeholder={i18n.t("adhkar.search")}
          class="w-full bg-transparent text-sm text-cream placeholder:text-muted/70 focus:outline-none"
          aria-label={i18n.t("adhkar.search")}
        />
      </label>

      {#if filtered.length === 0}
        <p class="mt-6 text-center text-sm text-muted">{i18n.t("adhkar.noResults")}</p>
      {:else}
        <div class="mt-3 grid gap-2 sm:grid-cols-2 xl:grid-cols-3">
          {#each filtered as category (category.id)}
            {@const done = adhkar.isComplete(category)}
            <button
              type="button"
              onclick={() => open(category.id)}
              class="flex items-center gap-3 rounded-xl border border-line/70 bg-ink-850/50 px-3 py-2.5 text-start transition-colors hover:border-gold/30 hover:bg-ink-800"
            >
              <span class="min-w-0 flex-1 truncate text-[0.83rem] text-cream">{category.title}</span>
              <span class="shrink-0 text-[10px] tabular-nums text-muted">
                {fmtNumber(category.items.length)}
              </span>
              {#if done}
                <Icon name="check" size={13} class="shrink-0 text-teal" />
              {:else}
                <span class="size-1.5 shrink-0 rounded-full bg-line"></span>
              {/if}
            </button>
          {/each}
        </div>
      {/if}
    </section>

    <footer class="mt-8 flex flex-wrap items-center justify-between gap-2 border-t border-line/60 pt-4 text-[10px] text-muted">
      <span>{i18n.t("adhkar.sourceLine")}</span>
      <a
        href={adhkar.source.repository}
        target="_blank"
        rel="noreferrer"
        class="text-muted underline decoration-line underline-offset-2 hover:text-gold"
      >
        HisnElMuslim (MIT)
      </a>
    </footer>
  {/if}
</div>
