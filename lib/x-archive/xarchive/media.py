from __future__ import annotations

import asyncio
import hashlib
import json
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import httpx
from rich.console import Console
from rich.progress import Progress, TaskID

from xarchive.config import Config
from xarchive.state import ManifestEntry, RunManifest, ensure_archive_layout, utc_now_iso

console = Console()


def _sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def _guess_image_ext(url: str, content_type: str | None) -> str:
    if content_type and "png" in content_type:
        return ".png"
    if content_type and "webp" in content_type:
        return ".webp"
    path = urlparse(url).path
    for ext in (".png", ".webp", ".jpg", ".jpeg"):
        if path.lower().endswith(ext):
            return ext if ext != ".jpeg" else ".jpg"
    return ".jpg"


async def _download_url(
    client: httpx.AsyncClient,
    url: str,
    dest: Path,
    *,
    timeout: float,
    max_retries: int,
) -> tuple[int, str]:
    dest.parent.mkdir(parents=True, exist_ok=True)
    last_err: Exception | None = None
    for attempt in range(max_retries):
        try:
            async with client.stream("GET", url, follow_redirects=True, timeout=timeout) as resp:
                resp.raise_for_status()
                size = 0
                hasher = hashlib.sha256()
                tmp = dest.with_suffix(dest.suffix + ".part")
                with tmp.open("wb") as f:
                    async for chunk in resp.aiter_bytes():
                        f.write(chunk)
                        hasher.update(chunk)
                        size += len(chunk)
                tmp.rename(dest)
                return size, hasher.hexdigest()
        except Exception as exc:
            last_err = exc
            await asyncio.sleep(2**attempt)
    raise RuntimeError(f"Failed to download {url}: {last_err}")


def _download_video_ytdlp(cfg: Config, tweet_url: str, dest: Path) -> tuple[int, str]:
    dest.parent.mkdir(parents=True, exist_ok=True)
    ytdlp = cfg.yt_dlp_path
    if not shutil.which(ytdlp):
        raise RuntimeError(f"{ytdlp} not found on PATH")

    out_tpl = str(dest.with_suffix("")) + ".%(ext)s"
    cmd = [
        ytdlp,
        "--no-playlist",
        "-f",
        "bv*+ba/b",
        "--merge-output-format",
        "mp4",
        "-o",
        out_tpl,
        tweet_url,
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=cfg.media_timeout_seconds)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr or proc.stdout or "yt-dlp failed")

    candidates = list(dest.parent.glob(dest.stem + ".*"))
    mp4 = dest.parent / f"{dest.stem}.mp4"
    if mp4.is_file():
        final = dest if dest.suffix == ".mp4" else dest.with_suffix(".mp4")
        if final != mp4:
            mp4.rename(final)
        size = final.stat().st_size
        return size, _sha256_file(final)

    if candidates:
        picked = max(candidates, key=lambda p: p.stat().st_size)
        if picked != dest:
            picked.rename(dest)
        return dest.stat().st_size, _sha256_file(dest)

    raise RuntimeError(f"No video file produced for {tweet_url}")


def iter_tweet_docs(archive_dir: Path) -> list[Path]:
    root = archive_dir / "tweets"
    if not root.is_dir():
        return []
    return sorted(root.rglob("*.json"))


def _media_dest(cfg: Config, tweet_id: str, item: dict[str, Any]) -> Path:
    idx = item.get("index", 0)
    mtype = item["type"]
    if mtype == "photo":
        return cfg.archive_dir / "media" / "images" / f"{tweet_id}_{idx}.jpg"
    if mtype == "video":
        return cfg.archive_dir / "media" / "videos" / f"{tweet_id}_{idx}.mp4"
    return cfg.archive_dir / "media" / "gifs" / f"{tweet_id}_{idx}.mp4"


async def mirror_tweet_media(
    cfg: Config,
    doc: dict[str, Any],
    client: httpx.AsyncClient,
) -> tuple[int, int]:
    """Update doc in place. Returns (ok_count, fail_count)."""
    ok, fail = 0, 0
    tweet_id = doc["tweet_id"]
    permalink = doc.get("permalink") or f"https://x.com/i/status/{tweet_id}"
    now = datetime.now(timezone.utc).isoformat()

    for item in doc.get("media") or []:
        if item.get("local_path") and item.get("sha256"):
            dest = cfg.archive_dir / item["local_path"]
            if dest.is_file():
                ok += 1
                continue

        dest = _media_dest(cfg, tweet_id, item)
        rel = str(dest.relative_to(cfg.archive_dir))

        try:
            if item["type"] == "photo":
                url = item["url"]
                if not url:
                    fail += 1
                    continue
                size, digest = await _download_url(
                    client,
                    url,
                    dest,
                    timeout=cfg.media_timeout_seconds,
                    max_retries=cfg.media_max_retries,
                )
                ext = _guess_image_ext(url, None)
                if dest.suffix != ext and ext != ".jpg":
                    new_dest = dest.with_suffix(ext)
                    dest.rename(new_dest)
                    dest = new_dest
                    rel = str(dest.relative_to(cfg.archive_dir))
            elif item["type"] == "video":
                loop = asyncio.get_event_loop()
                size, digest = await loop.run_in_executor(
                    None, _download_video_ytdlp, cfg, permalink, dest
                )
            elif item["type"] == "gif":
                url = item.get("url")
                if not url:
                    fail += 1
                    continue
                size, digest = await _download_url(
                    client,
                    url,
                    dest,
                    timeout=cfg.media_timeout_seconds,
                    max_retries=cfg.media_max_retries,
                )
            else:
                fail += 1
                continue

            item["local_path"] = rel
            item["sha256"] = digest
            item["bytes"] = size
            item["downloaded_at"] = now
            ok += 1
        except Exception as exc:
            item["download_error"] = repr(exc)
            fail += 1

    return ok, fail


async def download_all_media(
    cfg: Config,
    *,
    only_missing: bool = True,
    tweet_paths: list[Path] | None = None,
) -> dict[str, int]:
    ensure_archive_layout(cfg.archive_dir)
    paths = tweet_paths or iter_tweet_docs(cfg.archive_dir)
    manifest = RunManifest(cfg.archive_dir / "metadata" / "run_manifest.jsonl")
    entry = ManifestEntry(run_id="media", command="media", started_at=utc_now_iso())

    stats = {"tweets": 0, "media_ok": 0, "media_failed": 0, "skipped_tweets": 0}

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )
    }

    async with httpx.AsyncClient(headers=headers) as client:
        with Progress() as progress:
            task: TaskID = progress.add_task("Media", total=len(paths))
            for path in paths:
                doc = json.loads(path.read_text(encoding="utf-8"))
                if only_missing and all(
                    m.get("local_path") and (cfg.archive_dir / m["local_path"]).is_file()
                    for m in (doc.get("media") or [])
                ):
                    stats["skipped_tweets"] += 1
                    progress.advance(task)
                    continue

                if not doc.get("media"):
                    stats["skipped_tweets"] += 1
                    progress.advance(task)
                    continue

                stats["tweets"] += 1
                ok, fail = await mirror_tweet_media(cfg, doc, client)
                stats["media_ok"] += ok
                stats["media_failed"] += fail
                path.write_text(json.dumps(doc, indent=2, ensure_ascii=False), encoding="utf-8")
                progress.advance(task)

    entry.finished_at = utc_now_iso()
    entry.media_ok = stats["media_ok"]
    entry.media_failed = stats["media_failed"]
    entry.extra = stats
    manifest.append(entry)

    console.print(
        f"[green]Media done[/] tweets={stats['tweets']} ok={stats['media_ok']} "
        f"failed={stats['media_failed']} skipped_tweets={stats['skipped_tweets']}"
    )
    return stats
