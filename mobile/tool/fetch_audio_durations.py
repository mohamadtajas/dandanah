"""Build the bundled per-ayah duration index for EveryAyah recitations.

EveryAyah MP3s are constant-bitrate, so duration ~= size_bytes * 8 / bitrate.
The app ships this index for instant whole-surah totals; unknown entries fall
back to a live HEAD request.

Usage: python tool/fetch_audio_durations.py [reciter ...]
"""

from __future__ import annotations

import json
import os
import sys
import threading
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QURAN = ROOT / "assets" / "data" / "quran.json"
OUT = ROOT / "assets" / "data" / "audio_durations.json"

RECITERS = {
    "Alafasy_128kbps": 128,
    "Husary_128kbps": 128,
    "Minshawy_Murattal_128kbps": 128,
    "Abdul_Basit_Murattal_192kbps": 192,
    "Abdurrahmaan_As-Sudais_192kbps": 192,
    "Saood_ash-Shuraym_128kbps": 128,
    "MaherAlMuaiqly128kbps": 128,
    "Ghamadi_40kbps": 40,
}
BASE = "https://everyayah.com/data"
WORKERS = 10
RETRIES = 4

lock = threading.Lock()


def load_ayah_counts() -> dict[int, int]:
    data = json.loads(QURAN.read_text(encoding="utf-8"))
    return {int(s["number"]): int(s["ayahs"]) if isinstance(s["ayahs"], int) else len(s["ayahs"]) for s in data["surahs"]}


def load_index() -> dict:
    if OUT.exists():
        try:
            return json.loads(OUT.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}


def save_index(index: dict) -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    tmp = OUT.with_suffix(".tmp")
    tmp.write_text(json.dumps(index, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    tmp.replace(OUT)


def head_size(url: str) -> int | None:
    for attempt in range(RETRIES):
        try:
            req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "Sakeenah-duration-builder/0.1"})
            with urllib.request.urlopen(req, timeout=20) as response:
                length = response.headers.get("Content-Length")
                if length:
                    return int(length)
                return None
        except Exception:
            time.sleep(1.5 * (attempt + 1))
    return None


def build_reciter(reciter: str, bitrate: int, counts: dict[int, int], index: dict) -> None:
    existing = index.setdefault(reciter, {})
    for surah, ayah_count in counts.items():
        key = str(surah)
        if key in existing and len(existing[key]) == ayah_count:
            continue
        durations: list[int | None] = [None] * ayah_count
        jobs = {}
        with ThreadPoolExecutor(max_workers=WORKERS) as pool:
            for ayah in range(1, ayah_count + 1):
                if existing.get(key) and ayah <= len(existing[key]) and existing[key][ayah - 1]:
                    durations[ayah - 1] = existing[key][ayah - 1]
                    continue
                url = f"{BASE}/{reciter}/{surah:03d}{ayah:03d}.mp3"
                jobs[pool.submit(head_size, url)] = (ayah, url)
            for future in as_completed(jobs):
                ayah, url = jobs[future]
                size = future.result()
                if size:
                    durations[ayah - 1] = int(round(size * 8 / bitrate))
        if all(d is not None for d in durations):
            existing[key] = durations
            with lock:
                save_index(index)
            print(f"{reciter} {surah:03d} ok ({ayah_count})", flush=True)
        else:
            missing = sum(1 for d in durations if d is None)
            print(f"{reciter} {surah:03d} incomplete ({missing} missing)", flush=True)


def main() -> None:
    counts = load_ayah_counts()
    index = load_index()
    requested = sys.argv[1:] or list(RECITERS)
    for reciter in requested:
        bitrate = RECITERS.get(reciter)
        if not bitrate:
            print(f"unknown reciter {reciter}", flush=True)
            continue
        print(f"start {reciter}", flush=True)
        build_reciter(reciter, bitrate, counts, index)
        print(f"done {reciter}", flush=True)


if __name__ == "__main__":
    main()
