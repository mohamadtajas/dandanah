<script lang="ts">
  import { onMount } from "svelte";
  import Sidebar from "$lib/components/Sidebar.svelte";
  import PlayerBar from "$lib/components/PlayerBar.svelte";
  import Toast from "$lib/components/Toast.svelte";
  import Home from "$lib/views/Home.svelte";
  import Quran from "$lib/views/Quran.svelte";
  import Explore from "$lib/views/Explore.svelte";
  import Radio from "$lib/views/Radio.svelte";
  import Search from "$lib/views/Search.svelte";
  import Library from "$lib/views/Library.svelte";
  import Settings from "$lib/views/Settings.svelte";
  import Credits from "$lib/views/Credits.svelte";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import { library } from "$lib/stores/library.svelte.ts";
  import { i18n } from "$lib/i18n/index.svelte.ts";

  onMount(() => {
    void library.load();
    const onKey = (e: KeyboardEvent) => {
      const el = e.target as HTMLElement | null;
      if (el && (el.tagName === "INPUT" || el.tagName === "TEXTAREA" || el.isContentEditable)) {
        return;
      }
      switch (e.code) {
        case "Space":
          e.preventDefault();
          void player.toggle();
          break;
        case "ArrowRight":
          e.preventDefault();
          void player.next();
          break;
        case "ArrowLeft":
          e.preventDefault();
          void player.prev();
          break;
        case "ArrowUp":
          e.preventDefault();
          player.setVolume(player.volume + 0.05);
          break;
        case "ArrowDown":
          e.preventDefault();
          player.setVolume(player.volume - 0.05);
          break;
        case "KeyM":
          player.toggleMute();
          break;
        default:
          break;
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  });
</script>

<svelte:head>
  <title>{i18n.t("app.name")} · {i18n.t("app.tagline")}</title>
</svelte:head>

<div
  class="grid h-screen grid-rows-[minmax(0,1fr)_auto] grid-cols-[248px_minmax(0,1fr)] overflow-hidden bg-ink-950"
  dir={i18n.dir}
>
  <Sidebar />

  <main class="min-w-0 overflow-y-auto">
    <div class="mx-auto w-full max-w-[1180px] px-7 pb-12 pt-7">
      {#if nav.view === "home"}
        <Home />
      {:else if nav.view === "quran"}
        <Quran />
      {:else if nav.view === "explore"}
        <Explore />
      {:else if nav.view === "radio"}
        <Radio />
      {:else if nav.view === "search"}
        <Search />
      {:else if nav.view === "library"}
        <Library />
      {:else if nav.view === "settings"}
        <Settings />
      {:else if nav.view === "credits"}
        <Credits />
      {/if}
    </div>
  </main>

  <div class="col-span-2">
    <PlayerBar />
  </div>

  <Toast />
</div>
