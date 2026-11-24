import { api, isTauri } from "$lib/api";
import { i18n } from "$lib/i18n/index.svelte.ts";
import { ui } from "$lib/stores/ui.svelte.ts";
import type { DownloadRow, DownloadStatus, ImportSummary, Playlist, Track } from "$lib/types";

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
  local = $state<Track[]>([]);
  loading = $state(true);
  /** Opt-in escape hatch for sources that do not publish a licence. */
  allowUnknownLicense = $state(false);

  private listening = false;

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
    const [ids, favs, lists, downloads, local] = await Promise.allSettled([
      api.favoriteIds(),
      api.favorites(),
      api.playlists(),
      api.downloads(),
      api.localTracks(),
    ]);
    if (ids.status === "fulfilled") this.favoriteIds = ids.value;
    if (favs.status === "fulfilled") this.favorites = favs.value;
    if (lists.status === "fulfilled") this.playlists = lists.value;
    if (downloads.status === "fulfilled") this.downloads = downloads.value;
    if (local.status === "fulfilled") this.local = local.value;
    this.loading = false;
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
    const existing = this.downloadFor(track.id);
    if (existing && existing.status !== "error" && existing.status !== "cancelled") return;
    if (!track.streamUrl) {
      ui.notify(i18n.t("library.downloadUnavailable"));
      return;
    }
    // Only download when the licence is known, unless the user opted in.
    const needsLicense =
      (track.kind === "music" || track.kind === "anasheed") && !track.license;
    if (needsLicense && !this.allowUnknownLicense) {
      ui.notify(i18n.t("library.licenseUnknown"));
      return;
    }

    const row: DownloadRow = {
      track,
      status: "queued",
      bytesTotal: 0,
      bytesDone: 0,
      createdAt: Date.now(),
    };
    this.downloads = [row, ...this.downloads.filter((d) => d.track.id !== track.id)];

    try {
      await api.startDownload(track);
      await this.refreshDownloads();
    } catch {
      // A cancelled download is not a failure; the event already updated it.
      await this.refreshDownloads();
      if (this.downloadFor(track.id)?.status !== "cancelled") {
        this.downloads = this.downloads.map((d) =>
          d.track.id === track.id
            ? { ...d, status: "error" as DownloadStatus, error: i18n.t("library.downloadFailed") }
            : d,
        );
        ui.notify(i18n.t("library.downloadFailed"));
      }
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
    try {
      await api.deleteDownload(trackId);
      this.downloads = this.downloads.filter((d) => d.track.id !== trackId);
      // Library tracks carry a localPath snapshot; refetch to drop it.
      await this.refreshLibraryTracks();
    } catch {
      ui.notify(i18n.t("library.saveFailed"));
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
      });
    } catch {
      this.listening = false;
    }
  }
}

export const library = new LibraryStore();
