import { api, isTauri } from "$lib/api";
import { i18n } from "$lib/i18n/index.svelte.ts";
import { ui } from "$lib/stores/ui.svelte.ts";
import type {
  DeleteSummary,
  DownloadRow,
  DownloadStatus,
  ImportSummary,
  Playlist,
  StorageTotals,
  Track,
} from "$lib/types";

const ALLOW_UNKNOWN_LICENSE_KEY = "sakeenah.allowUnknownLicense";

type ProgressEvent = {
  trackId: string;
  status: DownloadStatus;
  received: number;
  total: number;
  path?: string;
  error?: string;
};

/**
 * Favorites, playlists, downloads and imported files. Kept in one store so the
 * sidebar, track rows and library tabs all see the same state.
 */
class LibraryStore {
  favoriteIds = $state<string[]>([]);
  favorites = $state<Track[]>([]);
  playlists = $state<Playlist[]>([]);
  downloads = $state<DownloadRow[]>([]);
  storage = $state<StorageTotals | null>(null);
  local = $state<Track[]>([]);
  loading = $state(true);
  /** Opt-in escape hatch for sources that do not publish a licence. */
  allowUnknownLicense = $state(false);

  private listening = false;
  private pollTimer: ReturnType<typeof setInterval> | null = null;
  private storageTimer: ReturnType<typeof setTimeout> | null = null;

  constructor() {
    if (typeof localStorage !== "undefined") {
      this.allowUnknownLicense = localStorage.getItem(ALLOW_UNKNOWN_LICENSE_KEY) === "1";
    }
  }

  setAllowUnknownLicense(value: boolean) {
    this.allowUnknownLicense = value;
    if (typeof localStorage !== "undefined") {
      localStorage.setItem(ALLOW_UNKNOWN_LICENSE_KEY, value ? "1" : "0");
    }
  }

  async load() {
    this.loading = true;
    const [ids, favs, lists, downloads, local, storage] = await Promise.allSettled([
      api.favoriteIds(),
      api.favorites(),
      api.playlists(),
      api.downloads(),
      api.localTracks(),
      api.storageTotals(),
    ]);
    if (ids.status === "fulfilled") this.favoriteIds = ids.value;
    if (favs.status === "fulfilled") this.favorites = favs.value;
    if (lists.status === "fulfilled") this.playlists = lists.value;
    if (downloads.status === "fulfilled") this.downloads = downloads.value;
    if (local.status === "fulfilled") this.local = local.value;
    if (storage.status === "fulfilled") this.storage = storage.value;
    this.loading = false;
    this.ensurePolling();
    void this.listen();
  }

  isFavorite(trackId: string): boolean {
    return this.favoriteIds.includes(trackId);
  }

  downloadFor(trackId: string): DownloadRow | undefined {
    return this.downloads.find((d) => d.track.id === trackId);
  }

  /** Path on disk for a completed download, used to play offline. */
  localPathFor(trackId: string): string | null {
    return this.downloads.find((d) => d.track.id === trackId && d.status === "done")?.filePath ?? null;
  }

  async toggleFavorite(track: Track) {
    const active = this.isFavorite(track.id);
    // Optimistic: the UI should react on the same frame as the click.
    this.favoriteIds = active
      ? this.favoriteIds.filter((id) => id !== track.id)
      : [...this.favoriteIds, track.id];
    this.favorites = active
      ? this.favorites.filter((t) => t.id !== track.id)
      : [track, ...this.favorites];

    try {
      if (active) await api.removeFavorite(track.id);
      else await api.addFavorite(track);
    } catch {
      // Roll back if the write failed.
      this.favoriteIds = active
        ? [...this.favoriteIds, track.id]
        : this.favoriteIds.filter((id) => id !== track.id);
      this.favorites = active
        ? [track, ...this.favorites]
        : this.favorites.filter((t) => t.id !== track.id);
      ui.notify(i18n.t("library.saveFailed"));
    }
  }

  async createPlaylist(name: string): Promise<Playlist | null> {
    const trimmed = name.trim();
    if (!trimmed) return null;
    try {
      const playlist = await api.createPlaylist(trimmed);
      this.playlists = [playlist, ...this.playlists];
      return playlist;
    } catch {
      ui.notify(i18n.t("library.saveFailed"));
      return null;
    }
  }

  async renamePlaylist(playlistId: string, name: string) {
    const trimmed = name.trim();
    if (!trimmed) return;
    try {
      await api.renamePlaylist(playlistId, trimmed);
      this.playlists = this.playlists.map((p) =>
        p.id === playlistId ? { ...p, name: trimmed } : p,
      );
    } catch {
      ui.notify(i18n.t("library.saveFailed"));
    }
  }

  async deletePlaylist(playlistId: string) {
    try {
      await api.deletePlaylist(playlistId);
      this.playlists = this.playlists.filter((p) => p.id !== playlistId);
    } catch {
      ui.notify(i18n.t("library.saveFailed"));
    }
  }

  async addToPlaylist(playlistId: string, track: Track) {
    const playlist = this.playlists.find((p) => p.id === playlistId);
    if (!playlist) return;
    try {
      await api.addToPlaylist(playlistId, track);
      // Recount rather than assuming: the track may already be in the list.
      this.playlists = await api.playlists().catch(() => this.playlists);
      ui.notify(i18n.t("library.addedTo", { name: playlist.name }));
    } catch {
      ui.notify(i18n.t("library.saveFailed"));
    }
  }

  async removeFromPlaylist(playlistId: string, trackId: string) {
    try {
      await api.removeFromPlaylist(playlistId, trackId);
      this.playlists = await api.playlists().catch(() => this.playlists);
    } catch {
      ui.notify(i18n.t("library.saveFailed"));
    }
  }

  async startDownload(track: Track) {
    return this.startDownloads([track]);
  }

  /**
   * Enqueues a batch. Arabic/Quran tracks come from providers that grant
   * download rights, while anasheed/music still need a known licence.
   */
  async startDownloads(tracks: Track[]): Promise<number> {
    const allowed = tracks.filter((track) => {
      const existing = this.downloadFor(track.id);
      if (
        existing &&
        (existing.status === "queued" ||
          existing.status === "downloading" ||
          existing.status === "done")
      ) {
        return false;
      }
      if (!track.streamUrl) return false;
      const needsLicense =
        (track.kind === "music" || track.kind === "anasheed") && !track.license;
      return !needsLicense || this.allowUnknownLicense;
    });

    if (allowed.length === 0) {
      const licenseBlocked = tracks.some(
        (track) =>
          (track.kind === "music" || track.kind === "anasheed") &&
          !track.license &&
          !this.allowUnknownLicense,
      );
      if (licenseBlocked) {
        ui.notify(i18n.t("library.licenseUnknown"));
      } else if (
        !tracks.every((track) => {
          const existing = this.downloadFor(track.id);
          return (
            existing &&
            (existing.status === "queued" ||
              existing.status === "downloading" ||
              existing.status === "done")
          );
        })
      ) {
        ui.notify(i18n.t("library.downloadUnavailable"));
      }
      return 0;
    }

    const stamp = Date.now();
    const ids = new Set(allowed.map((track) => track.id));
    const optimistic: DownloadRow[] = allowed.map((track, index) => ({
      track,
      status: "queued",
      bytesTotal: 0,
      bytesDone: 0,
      createdAt: stamp + index,
    }));
    this.downloads = [...optimistic, ...this.downloads.filter((row) => !ids.has(row.track.id))];

    try {
      const accepted = await api.startDownloads(allowed);
      await Promise.all([this.refreshDownloads(), this.refreshStorage()]);
      if (accepted > 0) {
        ui.notify(i18n.t("library.downloadQueued", { count: accepted }));
      }
      this.ensurePolling();
      return accepted;
    } catch {
      await this.refreshDownloads();
      const stillQueued = this.downloads.filter(
        (row) => ids.has(row.track.id) && row.status !== "error" && row.status !== "cancelled",
      );
      if (stillQueued.length === 0) {
        ui.notify(i18n.t("library.downloadFailed"));
      }
      return 0;
    }
  }

  async cancelDownload(trackId: string) {
    try {
      const accepted = await api.cancelDownload(trackId);
      if (!accepted) {
        // The download finished before the request landed; resync the row.
        await this.refreshDownloads();
        return;
      }
      // Reflect the intent immediately; the Rust event confirms it.
      this.downloads = this.downloads.map((d) =>
        d.track.id === trackId && (d.status === "queued" || d.status === "downloading")
          ? { ...d, status: "cancelled" as DownloadStatus, error: undefined }
          : d,
      );
      ui.notify(i18n.t("library.downloadCancelled"));
    } catch {
      ui.notify(i18n.t("library.saveFailed"));
    }
  }

  async removeDownload(trackId: string) {
    return this.removeDownloads([trackId]);
  }

  /**
   * Deletes files and rows for the selection. The backend removes disk files
   * first and keeps a row when its file could not be deleted, so the list and
   * the disk stay in agreement.
   */
  async removeDownloads(trackIds: string[]): Promise<DeleteSummary | null> {
    if (trackIds.length === 0) return null;
    const selected = new Set(trackIds);
    try {
      const summary = await api.deleteDownloads(trackIds);
      const failedIds = new Set(summary.failed.map((entry) => entry.split(": ")[0]));
      this.downloads = this.downloads.filter(
        (row) => !selected.has(row.track.id) || failedIds.has(row.track.id),
      );
      await this.refreshLibraryTracks();
      await this.refreshStorage();
      if (summary.failed.length > 0) {
        ui.notify(i18n.t("library.deleteFailed", { count: summary.failed.length }));
      } else {
        ui.notify(i18n.t("library.deleteDone", { count: summary.deleted }));
      }
      return summary;
    } catch {
      ui.notify(i18n.t("library.saveFailed"));
      return null;
    }
  }

  async importFolders(): Promise<ImportSummary | null> {
    if (!isTauri) {
      ui.notify(i18n.t("library.importDesktopOnly"));
      return null;
    }
    const { open } = await import("@tauri-apps/plugin-dialog");
    const picked = await open({ directory: true, multiple: true, title: i18n.t("library.importTitle") });
    if (!picked) return null;
    const paths = Array.isArray(picked) ? picked : [picked];

    try {
      const summary = await api.importFolder(paths);
      this.local = await api.localTracks();
      ui.notify(
        i18n.t("library.importDone", { count: summary.imported }) +
          (summary.truncated ? ` — ${i18n.t("library.importTruncated")}` : ""),
      );
      return summary;
    } catch {
      ui.notify(i18n.t("library.importFailed"));
      return null;
    }
  }

  async forgetLocalTrack(trackId: string) {
    try {
      await api.forgetLocalTrack(trackId);
      this.local = this.local.filter((t) => t.id !== trackId);
    } catch {
      ui.notify(i18n.t("library.saveFailed"));
    }
  }

  async refreshDownloads() {
    this.downloads = await api.downloads().catch(() => this.downloads);
  }

  async refreshStorage() {
    this.storage = await api.storageTotals().catch(() => this.storage);
  }

  private scheduleStorageRefresh() {
    if (this.storageTimer) return;
    this.storageTimer = setTimeout(() => {
      this.storageTimer = null;
      void this.refreshStorage();
    }, 500);
  }

  /**
   * Progress events are the primary signal, but a poll while jobs are active
   * keeps the list and byte totals correct if an event is missed (and keeps
   * the browser mock moving without Tauri events).
   */
  private ensurePolling() {
    if (this.pollTimer) return;
    const busy = () =>
      this.downloads.some(
        (row) => row.status === "queued" || row.status === "downloading",
      );
    if (!busy()) return;
    this.pollTimer = setInterval(() => {
      if (!busy()) {
        if (this.pollTimer) clearInterval(this.pollTimer);
        this.pollTimer = null;
        void this.refreshStorage();
        void this.refreshLibraryTracks();
        return;
      }
      void this.refreshDownloads();
      void this.refreshStorage();
    }, 1200);
  }

  private async refreshLibraryTracks() {
    const [favs, local] = await Promise.allSettled([api.favorites(), api.localTracks()]);
    if (favs.status === "fulfilled") this.favorites = favs.value;
    if (local.status === "fulfilled") this.local = local.value;
  }

  /** Subscribe once to the Rust downloader's progress events. */
  private async listen() {
    if (this.listening || !isTauri) return;
    this.listening = true;
    try {
      const { listen } = await import("@tauri-apps/api/event");
      await listen<ProgressEvent>("download:progress", (event) => {
        const p = event.payload;
        const index = this.downloads.findIndex((d) => d.track.id === p.trackId);
        if (index < 0) return;
        this.downloads = this.downloads.map((row, i) =>
          i === index
            ? {
                ...row,
                status: p.status,
                bytesDone: p.received || row.bytesDone,
                bytesTotal: p.total || row.bytesTotal,
                filePath: p.path ?? row.filePath,
                error: p.error,
              }
            : row,
        );
        if (p.status === "done" || p.status === "error" || p.status === "cancelled") {
          this.scheduleStorageRefresh();
        }
      });
    } catch {
      this.listening = false;
    }
  }
}

export const library = new LibraryStore();
