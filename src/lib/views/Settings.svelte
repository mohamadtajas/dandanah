<script lang="ts">
  import { onMount } from "svelte";
  import { api, isTauri } from "$lib/api";
  import type { AppInfo, HotkeyMap, PrayerMethod, WorshipSettings } from "$lib/types";
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import type { TranslationKey } from "$lib/i18n/dict";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import { library } from "$lib/stores/library.svelte.ts";
  import { worship } from "$lib/stores/worship.svelte.ts";
  import { ui } from "$lib/stores/ui.svelte.ts";
  import { cities, nearestCity, timezones } from "$lib/data/cities";
  import Icon from "$lib/components/Icon.svelte";

  let info = $state<AppInfo | null>(null);

  const PRAYER_METHODS: PrayerMethod[] = [
    "ummAlQura",
    "muslimWorldLeague",
    "egyptian",
    "karachi",
    "dubai",
    "moonsightingCommittee",
    "northAmerica",
    "kuwait",
    "qatar",
    "singapore",
    "tehran",
    "turkey",
  ];

  const DEFAULT_PRAYER: WorshipSettings = {
    latitude: 21.4225,
    longitude: 39.8262,
    timezone: "Asia/Riyadh",
    method: "ummAlQura",
    madhab: "shafi",
    hijriAdjustment: 0,
    configured: false,
  };

  let prayer = $state<WorshipSettings>({ ...DEFAULT_PRAYER });
  let savingPrayer = $state(false);
  const matchedCity = $derived(nearestCity(prayer.latitude, prayer.longitude));

  type UpdateState = "idle" | "checking" | "available" | "none" | "error";
  let updateState = $state<UpdateState>("idle");
  let updateVersion = $state("");
  let installing = $state(false);
  let pendingUpdate = $state<{ version: string; downloadAndInstall: () => Promise<void> } | null>(
    null,
  );

  const speeds = [0.75, 0.85, 1, 1.15, 1.25, 1.5];

  const DEFAULT_HOTKEYS: HotkeyMap = {
    toggle: "Ctrl+Alt+Space",
    next: "Ctrl+Alt+ArrowRight",
    previous: "Ctrl+Alt+ArrowLeft",
  };

  const hotkeyRows: {
    id: keyof HotkeyMap;
    label: "settings.hotkeyToggle" | "settings.hotkeyNext" | "settings.hotkeyPrevious";
  }[] = [
    { id: "toggle", label: "settings.hotkeyToggle" },
    { id: "next", label: "settings.hotkeyNext" },
    { id: "previous", label: "settings.hotkeyPrevious" },
  ];

  let hotkeys = $state<HotkeyMap>({ ...DEFAULT_HOTKEYS });
  let hotkeyDraft = $state<HotkeyMap>({ ...DEFAULT_HOTKEYS });
  let recording = $state<keyof HotkeyMap | null>(null);
  let savingHotkeys = $state(false);

  onMount(async () => {
    const [infoResult, hotkeyResult, prayerResult] = await Promise.allSettled([
      api.appInfo(),
      api.getHotkeys(),
      api.worshipSettings(),
    ]);
    info = infoResult.status === "fulfilled" ? infoResult.value : null;
    if (hotkeyResult.status === "fulfilled") {
      hotkeys = hotkeyResult.value;
      hotkeyDraft = { ...hotkeyResult.value };
    }
    if (prayerResult.status === "fulfilled") {
      prayer = { ...prayerResult.value };
    }
  });

  function chooseCity(id: string) {
    const city = cities.find((item) => item.id === id);
    if (!city) return;
    prayer = {
      ...prayer,
      latitude: city.latitude,
      longitude: city.longitude,
      timezone: city.timezone,
    };
  }

  async function savePrayer() {
    savingPrayer = true;
    try {
      prayer = { ...(await worship.saveSettings(prayer)) };
      ui.notify(i18n.t("settings.prayerSaved"));
    } catch (error) {
      const detail = typeof error === "string" ? error : "";
      ui.notify(`${i18n.t("settings.prayerFailed")} ${detail}`.trim());
    } finally {
      savingPrayer = false;
    }
  }

  function prettyAccelerator(accelerator: string) {
    if (!accelerator) return i18n.t("settings.hotkeyDisabled");
    return accelerator
      .replace("ArrowRight", "→")
      .replace("ArrowLeft", "←")
      .replace("ArrowUp", "↑")
      .replace("ArrowDown", "↓")
      .replace(/\bKey([A-Z])\b/g, "$1")
      .replace(/\bDigit(\d)\b/g, "$1");
  }

  function startRecording(action: keyof HotkeyMap) {
    if (!isTauri) {
      ui.notify(i18n.t("settings.hotkeyDesktop"));
      return;
    }
    recording = action;
  }

  function onHotkeyKey(event: KeyboardEvent) {
    if (!recording) return;
    event.preventDefault();
    event.stopPropagation();

    if (event.key === "Escape") {
      recording = null;
      return;
    }
    if (event.key === "Backspace" || event.key === "Delete") {
      hotkeyDraft = { ...hotkeyDraft, [recording]: "" };
      recording = null;
      return;
    }
    if (["Control", "Alt", "Shift", "Meta", "CapsLock"].includes(event.key)) return;

    const mods: string[] = [];
    if (event.ctrlKey) mods.push("Ctrl");
    if (event.altKey) mods.push("Alt");
    if (event.shiftKey) mods.push("Shift");
    if (event.metaKey) mods.push("Super");
    if (mods.length === 0) {
      ui.notify(i18n.t("settings.hotkeyNeedModifier"));
      return;
    }

    hotkeyDraft = { ...hotkeyDraft, [recording]: [...mods, event.code].join("+") };
    recording = null;
  }

  async function saveHotkeys() {
    if (!isTauri) {
      ui.notify(i18n.t("settings.hotkeyDesktop"));
      return;
    }
    savingHotkeys = true;
    try {
      hotkeys = await api.setHotkeys(hotkeyDraft);
      hotkeyDraft = { ...hotkeys };
      ui.notify(i18n.t("settings.hotkeySaved"));
    } catch (error) {
      const detail = typeof error === "string" ? error : "";
      ui.notify(`${i18n.t("settings.hotkeyFailed")} ${detail}`.trim());
    } finally {
      savingHotkeys = false;
    }
  }

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

<svelte:window onkeydowncapture={onHotkeyKey} />

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
    <div class="flex flex-wrap items-center justify-between gap-2">
      <h2 class="flex items-center gap-2 text-sm font-semibold text-cream">
        <Icon name="compass" size={15} class="text-gold" />
        {i18n.t("settings.prayer")}
      </h2>
      <span
        class="rounded-full border px-2.5 py-1 text-[10px] font-medium
               {prayer.configured
          ? 'border-teal/40 bg-teal/10 text-teal'
          : 'border-gold/30 bg-gold/5 text-gold'}"
      >
        {prayer.configured ? i18n.t("settings.locationSet") : i18n.t("settings.locationUnset")}
      </span>
    </div>
    <p class="mt-1 text-xs leading-relaxed text-muted">{i18n.t("settings.prayerHint")}</p>

    <div class="mt-4 grid gap-3 sm:grid-cols-2">
      <label class="block">
        <span class="text-[11px] text-muted">{i18n.t("settings.city")}</span>
        <select
          value={matchedCity?.id ?? ""}
          onchange={(event) => chooseCity(event.currentTarget.value)}
          class="mt-1 w-full rounded-xl border border-line bg-ink-850 px-3 py-2 text-sm text-cream focus:border-gold/50 focus:outline-none"
        >
          <option value="">{i18n.t("settings.customLocation")}</option>
          {#each cities as city (city.id)}
            <option value={city.id}>
              {i18n.locale === "ar" ? `${city.name} — ${city.country}` : `${city.nameEn} — ${city.country}`}
            </option>
          {/each}
        </select>
      </label>

      <label class="block">
        <span class="text-[11px] text-muted">{i18n.t("settings.timezone")}</span>
        <select
          bind:value={prayer.timezone}
          class="mt-1 w-full rounded-xl border border-line bg-ink-850 px-3 py-2 text-sm text-cream focus:border-gold/50 focus:outline-none"
        >
          {#if !timezones.includes(prayer.timezone)}
            <option value={prayer.timezone}>{prayer.timezone}</option>
          {/if}
          {#each timezones as zone (zone)}
            <option value={zone}>{zone}</option>
          {/each}
        </select>
      </label>

      <label class="block">
        <span class="text-[11px] text-muted">{i18n.t("settings.latitude")}</span>
        <input
          type="number"
          step="0.0001"
          min="-90"
          max="90"
          bind:value={prayer.latitude}
          class="mt-1 w-full rounded-xl border border-line bg-ink-850 px-3 py-2 text-sm tabular-nums text-cream focus:border-gold/50 focus:outline-none"
        />
      </label>

      <label class="block">
        <span class="text-[11px] text-muted">{i18n.t("settings.longitude")}</span>
        <input
          type="number"
          step="0.0001"
          min="-180"
          max="180"
          bind:value={prayer.longitude}
          class="mt-1 w-full rounded-xl border border-line bg-ink-850 px-3 py-2 text-sm tabular-nums text-cream focus:border-gold/50 focus:outline-none"
        />
      </label>

      <label class="block">
        <span class="text-[11px] text-muted">{i18n.t("settings.method")}</span>
        <select
          value={prayer.method}
          onchange={(event) =>
            (prayer = { ...prayer, method: event.currentTarget.value as PrayerMethod })}
          class="mt-1 w-full rounded-xl border border-line bg-ink-850 px-3 py-2 text-sm text-cream focus:border-gold/50 focus:outline-none"
        >
          {#each PRAYER_METHODS as method (method)}
            <option value={method}>{i18n.t(`method.${method}` as TranslationKey)}</option>
          {/each}
        </select>
      </label>

      <label class="block">
        <span class="text-[11px] text-muted">{i18n.t("settings.madhab")}</span>
        <select
          value={prayer.madhab}
          onchange={(event) =>
            (prayer = {
              ...prayer,
              madhab: event.currentTarget.value === "hanafi" ? "hanafi" : "shafi",
            })}
          class="mt-1 w-full rounded-xl border border-line bg-ink-850 px-3 py-2 text-sm text-cream focus:border-gold/50 focus:outline-none"
        >
          <option value="shafi">{i18n.t("settings.shafi")}</option>
          <option value="hanafi">{i18n.t("settings.hanafi")}</option>
        </select>
      </label>

      <label class="block sm:col-span-2">
        <span class="text-[11px] text-muted">{i18n.t("settings.hijriAdjustment")}</span>
        <div class="mt-1 flex items-center gap-3">
          <input
            type="number"
            min="-3"
            max="3"
            step="1"
            bind:value={prayer.hijriAdjustment}
            class="w-24 rounded-xl border border-line bg-ink-850 px-3 py-2 text-sm tabular-nums text-cream focus:border-gold/50 focus:outline-none"
          />
          <span class="text-[11px] leading-relaxed text-muted">{i18n.t("settings.hijriHint")}</span>
        </div>
      </label>
    </div>

    <div class="mt-4 flex flex-wrap items-center gap-3">
      <button
        type="button"
        onclick={savePrayer}
        disabled={savingPrayer}
        class="flex items-center gap-2 rounded-xl bg-gold px-3.5 py-2 text-xs font-semibold text-ink-950 transition-transform hover:scale-[1.02] active:scale-95 disabled:opacity-50"
      >
        <Icon name="check" size={13} />
        {i18n.t("settings.savePrayer")}
      </button>
      <span class="text-[10px] text-muted">
        {matchedCity ? (i18n.locale === "ar" ? matchedCity.name : matchedCity.nameEn) : ""}
      </span>
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
    <h2 class="text-sm font-semibold text-cream">{i18n.t("settings.downloads")}</h2>
    <div class="mt-4 flex items-start justify-between gap-4">
      <div class="min-w-0">
        <div class="text-sm text-cream">{i18n.t("settings.allowUnknownLicense")}</div>
        <p class="mt-1 text-xs leading-relaxed text-muted">
          {i18n.t("settings.allowUnknownLicenseHint")}
        </p>
      </div>
      <button
        type="button"
        role="switch"
        aria-checked={library.allowUnknownLicense}
        aria-label={i18n.t("settings.allowUnknownLicense")}
        onclick={() => library.setAllowUnknownLicense(!library.allowUnknownLicense)}
        class="relative mt-0.5 h-6 w-11 shrink-0 rounded-full border transition-colors
               {library.allowUnknownLicense
          ? 'border-gold/60 bg-gold/80'
          : 'border-line bg-ink-800'}"
      >
        <span
          class="absolute top-[3px] size-[18px] rounded-full bg-cream shadow transition-all
                 {library.allowUnknownLicense ? 'start-[22px]' : 'start-[3px]'}"
        ></span>
      </button>
    </div>
  </section>

  <section class="mt-4 rounded-2xl border border-line bg-ink-900/60 p-5">
    <div class="flex items-center justify-between gap-3">
      <h2 class="text-sm font-semibold text-cream">{i18n.t("settings.hotkeys")}</h2>
      <button
        type="button"
        onclick={() => (hotkeyDraft = { ...DEFAULT_HOTKEYS })}
        class="rounded-lg border border-line px-2.5 py-1 text-[10px] text-muted transition-colors hover:border-gold/40 hover:text-gold"
      >
        {i18n.t("settings.hotkeyReset")}
      </button>
    </div>
    <p class="mt-1 text-xs leading-relaxed text-muted">{i18n.t("settings.hotkeysHint")}</p>

    <div class="mt-4 space-y-2">
      {#each hotkeyRows as row (row.id)}
        <div class="flex items-center justify-between gap-3 rounded-xl border border-line/70 bg-ink-850/60 px-3 py-2">
          <span class="text-sm text-cream">{i18n.t(row.label)}</span>
          <div class="flex items-center gap-2">
            <kbd
              class="min-w-28 rounded-md border px-2 py-1 text-center text-[11px] tabular-nums
                     {recording === row.id
                ? 'border-gold/60 text-gold'
                : hotkeyDraft[row.id]
                  ? 'border-line text-muted'
                  : 'border-line/60 text-muted/50'}"
            >
              {recording === row.id
                ? i18n.t("settings.hotkeyRecording")
                : prettyAccelerator(hotkeyDraft[row.id])}
            </kbd>
            <button
              type="button"
              onclick={() => startRecording(row.id)}
              class="rounded-lg border px-2.5 py-1 text-[10px] transition-colors
                     {recording === row.id
                ? 'border-gold/50 bg-gold/10 text-gold'
                : 'border-line text-muted hover:border-gold/40 hover:text-gold'}"
            >
              {i18n.t("settings.hotkeyChange")}
            </button>
          </div>
        </div>
      {/each}
    </div>

    <div class="mt-4 flex flex-wrap items-center gap-3">
      <button
        type="button"
        onclick={saveHotkeys}
        disabled={savingHotkeys}
        class="flex items-center gap-2 rounded-xl bg-gold px-3.5 py-2 text-xs font-semibold text-ink-950 transition-transform hover:scale-[1.02] active:scale-95 disabled:opacity-50"
      >
        <Icon name="check" size={13} />
        {i18n.t("settings.hotkeySave")}
      </button>
      <span class="text-[10px] text-muted">{i18n.t("settings.hotkeyClearHint")}</span>
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
        <dd class="tabular-nums text-cream">{info?.version ?? "0.2.0"}</dd>
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
