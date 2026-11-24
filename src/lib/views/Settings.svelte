<script lang="ts">
  import { onMount } from "svelte";
  import { api, isTauri } from "$lib/api";
  import type { AppInfo } from "$lib/types";
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import { ui } from "$lib/stores/ui.svelte.ts";
  import Icon from "$lib/components/Icon.svelte";

  let info = $state<AppInfo | null>(null);

  type UpdateState = "idle" | "checking" | "available" | "none" | "error";
  let updateState = $state<UpdateState>("idle");
  let updateVersion = $state("");
  let installing = $state(false);
  let pendingUpdate = $state<{ version: string; downloadAndInstall: () => Promise<void> } | null>(
    null,
  );

  const speeds = [0.75, 0.85, 1, 1.15, 1.25, 1.5];

  onMount(async () => {
    try {
      info = await api.appInfo();
    } catch {
      info = null;
    }
  });

  async function checkUpdates() {
    if (!isTauri) {
      ui.notify(i18n.t("settings.updatesDesktop"));
      return;
    }
    updateState = "checking";
    try {
      const { check } = await import("@tauri-apps/plugin-updater");
      const update = await check();
      if (update) {
        pendingUpdate = update;
        updateVersion = update.version;
        updateState = "available";
      } else {
        updateState = "none";
      }
    } catch {
      updateState = "error";
    }
  }

  async function installUpdate() {
    if (!pendingUpdate) return;
    installing = true;
    try {
      await pendingUpdate.downloadAndInstall();
      const { relaunch } = await import("@tauri-apps/plugin-process");
      await relaunch();
    } catch {
      installing = false;
      ui.notify(i18n.t("settings.updateFailed"));
    }
  }
</script>

<div class="fade-in max-w-2xl">
  <header>
    <h1 class="text-2xl font-bold text-cream">{i18n.t("settings.title")}</h1>
  </header>

  <section class="mt-6 rounded-2xl border border-line bg-ink-900/60 p-5">
    <h2 class="text-sm font-semibold text-cream">{i18n.t("settings.language")}</h2>
    <div class="mt-3 flex gap-2">
      <button
        type="button"
        onclick={() => i18n.set("ar")}
        class="rounded-xl border px-4 py-2 text-sm transition-colors
               {i18n.locale === 'ar' ? 'border-gold/50 bg-gold/10 text-gold' : 'border-line text-muted hover:text-cream'}"
      >
        العربية
      </button>
      <button
        type="button"
        onclick={() => i18n.set("en")}
        class="rounded-xl border px-4 py-2 text-sm transition-colors
               {i18n.locale === 'en' ? 'border-gold/50 bg-gold/10 text-gold' : 'border-line text-muted hover:text-cream'}"
      >
        English
      </button>
    </div>
  </section>

  <section class="mt-4 rounded-2xl border border-line bg-ink-900/60 p-5">
    <h2 class="text-sm font-semibold text-cream">{i18n.t("settings.theme")}</h2>
    <div class="mt-3 flex gap-2">
      <button
        type="button"
        onclick={() => ui.setTheme("dark")}
        class="rounded-xl border px-4 py-2 text-sm transition-colors
               {ui.theme === 'dark' ? 'border-gold/50 bg-gold/10 text-gold' : 'border-line text-muted hover:text-cream'}"
      >
        {i18n.t("settings.dark")}
      </button>
      <button
        type="button"
        onclick={() => ui.setTheme("light")}
        class="rounded-xl border px-4 py-2 text-sm transition-colors
               {ui.theme === 'light' ? 'border-gold/50 bg-gold/10 text-gold' : 'border-line text-muted hover:text-cream'}"
      >
        {i18n.t("settings.light")}
      </button>
    </div>
  </section>

  <section class="mt-4 rounded-2xl border border-line bg-ink-900/60 p-5">
    <h2 class="text-sm font-semibold text-cream">{i18n.t("settings.playback")}</h2>

    <div class="mt-4 flex items-center justify-between">
      <span class="text-sm text-muted">{i18n.t("settings.defaultSpeed")}</span>
      <div class="flex flex-wrap gap-1.5">
        {#each speeds as s (s)}
          <button
            type="button"
            onclick={() => player.setRate(s)}
            class="rounded-lg border px-2.5 py-1 text-xs tabular-nums transition-colors
                   {player.rate === s
              ? 'border-gold/50 bg-gold/10 text-gold'
              : 'border-line text-muted hover:text-cream'}"
          >
            {s}×
          </button>
        {/each}
      </div>
    </div>
  </section>

  <section class="mt-4 rounded-2xl border border-line bg-ink-900/60 p-5">
    <h2 class="text-sm font-semibold text-cream">{i18n.t("settings.updates")}</h2>

    <div class="mt-3 flex flex-wrap items-center justify-between gap-3">
      <div class="min-w-0">
        {#if updateState === "checking"}
          <p class="text-sm text-muted">{i18n.t("settings.checking")}</p>
        {:else if updateState === "available"}
          <p class="text-sm text-cream">
            {i18n.t("settings.updateAvailable", { version: updateVersion })}
          </p>
        {:else if updateState === "none"}
          <p class="text-sm text-teal">{i18n.t("settings.upToDate")}</p>
        {:else if updateState === "error"}
          <p class="text-sm text-muted">{i18n.t("settings.updateFailed")}</p>
        {:else}
          <p class="text-sm text-muted">{i18n.t("settings.updateHint")}</p>
        {/if}
      </div>

      {#if updateState === "available"}
        <button
          type="button"
          onclick={installUpdate}
          disabled={installing}
          class="flex items-center gap-2 rounded-xl bg-gold px-3.5 py-2 text-xs font-semibold text-ink-950 disabled:opacity-50"
        >
          <Icon name="download" size={13} />
          {installing ? i18n.t("settings.installing") : i18n.t("settings.installUpdate")}
        </button>
      {:else}
        <button
          type="button"
          onclick={checkUpdates}
          disabled={updateState === "checking"}
          class="flex items-center gap-2 rounded-xl border border-line px-3.5 py-2 text-xs font-medium text-cream transition-colors hover:border-gold/40 hover:text-gold disabled:opacity-50"
        >
          <Icon name="globe" size={13} />
          {i18n.t("settings.checkUpdates")}
        </button>
      {/if}
    </div>
  </section>

  <section class="mt-4 rounded-2xl border border-line bg-ink-900/60 p-5">
    <h2 class="text-sm font-semibold text-cream">{i18n.t("settings.about")}</h2>
    <dl class="mt-3 space-y-2 text-sm">
      <div class="flex justify-between">
        <dt class="text-muted">{i18n.t("settings.version")}</dt>
        <dd class="tabular-nums text-cream">{info?.version ?? "0.1.0"}</dd>
      </div>
      <div class="flex justify-between">
        <dt class="text-muted">{i18n.t("settings.sources")}</dt>
        <dd class="text-cream">{info?.providers.length ?? 3}</dd>
      </div>
    </dl>
    <button
      type="button"
      onclick={() => nav.go("credits")}
      class="mt-4 flex items-center gap-2 rounded-xl border border-line px-3 py-2 text-xs text-muted transition-colors hover:border-gold/40 hover:text-gold"
    >
      <Icon name="info" size={14} />
      {i18n.t("nav.credits")}
    </button>
  </section>
</div>
