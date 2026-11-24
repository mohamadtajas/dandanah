<script lang="ts">
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { navItems } from "$lib/stores/nav.svelte.ts";
  import type { View } from "$lib/types";
  import Icon, { type IconName } from "./Icon.svelte";

  let query = $state("");

  function submit(e: Event) {
    e.preventDefault();
    if (query.trim()) {
      nav.search(query.trim());
    }
  }
</script>

<aside class="flex h-full flex-col border-e border-line bg-ink-900/80">
  <div class="flex items-center gap-3 px-5 pt-6 pb-6">
    <img src="/logo.png" alt="" class="size-11 shrink-0 rounded-2xl ring-1 ring-gold/25" />
    <div class="min-w-0">
      <div class="leading-none text-lg font-bold">{i18n.t("app.name")}</div>
      <div class="mt-1 text-[10px] font-medium tracking-[0.18em] text-muted">SAKEENAH</div>
    </div>
  </div>

  <form onsubmit={submit} class="px-4 pb-4 {nav.view === 'search' ? 'hidden' : ''}">
    <label class="flex items-center gap-2 rounded-xl border border-line bg-ink-850 px-3 py-2 focus-within:border-gold/50">
      <Icon name="search" size={16} class="shrink-0 text-muted" />
      <input
        bind:value={query}
        placeholder={i18n.t("search.placeholder")}
        class="w-full bg-transparent text-sm text-cream placeholder:text-muted/70 focus:outline-none"
        aria-label={i18n.t("nav.search")}
      />
    </label>
  </form>

  <nav class="flex flex-col gap-1 px-3">
    {#each navItems as item (item.view)}
      {@const active = nav.view === item.view}
      <button
        type="button"
        onclick={() => nav.go(item.view as View)}
        class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm transition-colors
               {active
          ? 'bg-gold/12 font-semibold text-gold'
          : 'text-muted hover:bg-ink-800/80 hover:text-cream'}"
      >
        <Icon name={item.icon as IconName} size={18} />
        <span>{i18n.t(item.label)}</span>
      </button>
    {/each}
  </nav>

  <div class="mt-auto px-4 pb-5">
    <div class="mb-3 h-px bg-line/70"></div>
    <div class="flex items-center justify-between text-[11px] text-muted">
      <button
        type="button"
        onclick={() => i18n.toggle()}
        class="flex items-center gap-1.5 rounded-lg px-2 py-1.5 transition-colors hover:bg-ink-800 hover:text-cream"
      >
        <Icon name="globe" size={14} />
        {i18n.locale === "ar" ? "English" : "العربية"}
      </button>
      <button
        type="button"
        onclick={() => nav.go("settings")}
        class="rounded-lg p-1.5 transition-colors hover:bg-ink-800 hover:text-cream"
        aria-label={i18n.t("nav.settings")}
      >
        <Icon name="settings" size={16} />
      </button>
    </div>
  </div>
</aside>
