// Desktop smoke test. Runs against a *running* Sakeenah window that was started
// with WebView2 remote debugging enabled, e.g.:
//
//   $env:WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS = "--remote-debugging-port=9333"
//   .\src-tauri\target\release\sakeenah.exe
//   node scripts/desktop-smoke.mjs "C:\path\to\audio\folder"
//
// It exercises the real IPC surface: local import, favourites, playlists and a
// network download. Credentials, dialogs and UI clicks are not involved.

import fs from "node:fs";

const folder = process.argv[2];
const port = process.argv[3] ?? "9333";

if (!folder) {
  console.error("usage: node scripts/desktop-smoke.mjs <folder> [debug-port]");
  process.exit(2);
}

const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
const page = targets.find((t) => t.type === "page");
if (!page) {
  console.error("no WebView page found; is the app running with --remote-debugging-port?");
  process.exit(1);
}
console.log("page:", page.url);

const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  ws.addEventListener("open", resolve, { once: true });
  ws.addEventListener("error", reject, { once: true });
});

let nextId = 0;
const pending = new Map();
ws.addEventListener("message", (event) => {
  const message = JSON.parse(event.data);
  if (message.id && pending.has(message.id)) {
    pending.get(message.id)(message);
    pending.delete(message.id);
  }
});

function send(method, params) {
  return new Promise((resolve) => {
    const id = ++nextId;
    pending.set(id, resolve);
    ws.send(JSON.stringify({ id, method, params }));
  });
}

const script = `(async () => {
  const invoke = window.__TAURI_INTERNALS__.invoke;
  const out = {};
  const started = Date.now();

  out.imported = await invoke("import_folder", { paths: [${JSON.stringify(folder)}] });
  out.local = (await invoke("get_local_tracks")).map((t) => ({
    title: t.title,
    artist: t.artist,
    durationS: t.durationS,
    local: Boolean(t.localPath),
  }));

  const reciters = await invoke("get_reciters", { language: "ar" });
  const tracks = await invoke("get_moshaf_tracks", { reciterId: reciters[0].id });
  const target = tracks[0];

  out.playlist = await invoke("create_playlist", { name: "اختبار سطح المكتب" });
  await invoke("add_to_playlist", { playlistId: out.playlist.id, track: target });
  await invoke("add_favorite", { track: target });
  out.lists = await invoke("get_playlists");
  out.favorites = (await invoke("get_favorites")).length;
  out.playlistTracks = (await invoke("get_playlist_tracks", { playlistId: out.playlist.id })).length;

  out.downloadPath = await invoke("start_download", { track: target });
  out.downloads = (await invoke("get_downloads")).map((d) => ({
    title: d.track.title,
    status: d.status,
    bytes: d.bytesDone,
  }));

  // Prove the asset protocol can decode the finished file (and the imported one).
  const probe = async (path) => {
    const src = window.__TAURI_INTERNALS__.convertFileSrc(path);
    const audio = new Audio(src);
    const result = await new Promise((resolve) => {
      audio.addEventListener("loadedmetadata", () =>
        resolve({ ok: true, duration: Math.round(audio.duration * 10) / 10 }),
      );
      audio.addEventListener("error", () => resolve({ ok: false, code: audio.error?.code ?? -1 }));
      setTimeout(() => resolve({ ok: false, code: "timeout" }), 8000);
      audio.load();
    });
    return { src: src.slice(0, 64), ...result };
  };

  out.downloadPlayback = await probe(out.downloadPath);
  const localTrack = (await invoke("get_local_tracks"))[0];
  out.localPlayback = localTrack ? await probe(localTrack.localPath) : { ok: false, code: "none" };

  // Creative Commons catalogue: both providers, plus a real stream probe.
  const probeUrl = async (url) => {
    const audio = new Audio(url);
    return await new Promise((resolve) => {
      audio.addEventListener("loadedmetadata", () =>
        resolve({ ok: true, duration: Math.round(audio.duration * 10) / 10 }),
      );
      audio.addEventListener("error", () => resolve({ ok: false, code: audio.error?.code ?? -1 }));
      setTimeout(() => resolve({ ok: false, code: "timeout" }), 15000);
      audio.load();
    });
  };

  const cc = await invoke("explore_cc", { section: "all", limit: 10 });
  out.cc = {
    count: cc.length,
    providers: [...new Set(cc.map((t) => t.provider))],
    licensed: cc.filter((t) => Boolean(t.license)).length,
    sample: cc.slice(0, 3).map((t) => ({
      title: t.title,
      artist: t.artist,
      license: t.license,
      provider: t.provider,
    })),
  };
  out.ccPlayback = cc[0] ? await probeUrl(cc[0].streamUrl) : { ok: false, code: "none" };

  out.ms = Date.now() - started;
  return out;
})()`;

const result = await send("Runtime.evaluate", {
  expression: script,
  awaitPromise: true,
  returnByValue: true,
});

const value = result.result?.result?.value;
if (!value) {
  console.error("evaluation failed:", JSON.stringify(result, null, 2));
  process.exit(1);
}

console.log(JSON.stringify(value, null, 2));
if (value.downloadPath) {
  console.log(
    "download exists on disk:",
    fs.existsSync(value.downloadPath),
    fs.existsSync(value.downloadPath) ? fs.statSync(value.downloadPath).size : 0,
  );
}
ws.close();
