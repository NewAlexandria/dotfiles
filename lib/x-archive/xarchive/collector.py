from __future__ import annotations

import asyncio
import json
import random
import uuid
from contextlib import aclosing
from pathlib import Path
from typing import Any

from rich.console import Console
from twscrape import API
from twscrape.models import Tweet, User

from xarchive.config import Config
from xarchive.normalize import normalize_tweet, profile_from_user
from xarchive.state import (
    Checkpoint,
    ManifestEntry,
    RunManifest,
    TweetIndex,
    ensure_archive_layout,
    tweet_json_path,
    utc_now_iso,
)

console = Console()


class RateLimitPause(Exception):
    """Signal to backoff and retry."""

    pass


def _is_rate_or_auth_error(exc: BaseException) -> bool:
    msg = str(exc).lower()
    return any(
        token in msg
        for token in ("rate", "429", "403", "limit", "no account", "unauthorized", "suspend")
    )


async def _sleep_jitter(cfg: Config) -> None:
    delay = random.uniform(cfg.request_delay_min, cfg.request_delay_max)
    await asyncio.sleep(delay)


async def resolve_target_user(api: API, username: str) -> User:
    user = await api.user_by_login(username.lstrip("@"))
    if user is None:
        raise ValueError(f"User not found: @{username}")
    return user


def _save_profile(archive_dir: Path, user: User) -> None:
    path = archive_dir / "metadata" / "profile.json"
    path.write_text(
        json.dumps(profile_from_user(user), indent=2, ensure_ascii=False),
        encoding="utf-8",
    )


def _write_tweet(
    archive_dir: Path,
    doc: dict[str, Any],
    index: TweetIndex,
    *,
    skip_existing: bool,
) -> bool:
    """Returns True if newly written, False if skipped."""
    tweet_id = doc["tweet_id"]
    path = tweet_json_path(archive_dir, tweet_id, doc["timestamp"])
    if skip_existing and path.is_file():
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, indent=2, ensure_ascii=False), encoding="utf-8")
    index.append(
        {
            "tweet_id": tweet_id,
            "timestamp": doc["timestamp"],
            "path": str(path.relative_to(archive_dir)),
            "permalink": doc.get("permalink"),
        }
    )
    return True


async def collect_timeline(
    cfg: Config,
    *,
    mode: str = "archive",
    since_tweet_id: int | None = None,
) -> dict[str, int]:
    """
    mode=archive: full timeline until exhaustion (~3200 cap)
    mode=sync: stop when reaching tweets older than since_tweet_id
    """
    ensure_archive_layout(cfg.archive_dir)
    api = API(str(cfg.accounts_db))
    user = await resolve_target_user(api, cfg.target_username)
    _save_profile(cfg.archive_dir, user)

    user_id = int(user.id)
    checkpoint_path = cfg.archive_dir / "metadata" / "checkpoint.json"
    checkpoint = Checkpoint.load(checkpoint_path)
    checkpoint.user_id = user.id_str or str(user.id)
    index = TweetIndex(cfg.archive_dir / "metadata" / "index.jsonl")
    manifest = RunManifest(cfg.archive_dir / "metadata" / "run_manifest.jsonl")

    run_id = uuid.uuid4().hex[:12]
    entry = ManifestEntry(
        run_id=run_id,
        command=mode,
        started_at=utc_now_iso(),
        extra={"user_id": str(user_id), "username": cfg.handle},
    )

    stats = {"new": 0, "skipped": 0, "pages": 0}
    limit = cfg.tweet_limit
    collected = 0
    page_idx = 0

    console.print(f"[bold]Collecting[/] @{cfg.handle} (user_id={user_id}) mode={mode}")

    try:
        async with aclosing(api.user_tweets(user_id, limit=limit or 999999)) as gen:
            async for tweet in gen:
                tid = int(tweet.id)
                if since_tweet_id is not None and tid <= since_tweet_id:
                    console.print(f"Reached sync boundary tweet_id={since_tweet_id}")
                    break

                raw_path = None
                if cfg.save_raw_pages:
                    raw_path = f"raw/pages/page_{page_idx:05d}_{tweet.id_str}.json"
                    raw_file = cfg.archive_dir / raw_path
                    raw_file.parent.mkdir(parents=True, exist_ok=True)
                    raw_file.write_text(tweet.json(), encoding="utf-8")

                doc = normalize_tweet(tweet, raw_path=raw_path)
                is_new = _write_tweet(cfg.archive_dir, doc, index, skip_existing=True)
                if is_new:
                    stats["new"] += 1
                    checkpoint.last_tweet_id = doc["tweet_id"]
                    checkpoint.tweets_saved += 1
                else:
                    stats["skipped"] += 1

                collected += 1
                if collected % 50 == 0:
                    checkpoint.save(checkpoint_path)
                    console.print(
                        f"  … {collected} processed ({stats['new']} new, {stats['skipped']} skipped)"
                    )

                await _sleep_jitter(cfg)

        checkpoint.completed = mode == "archive"
        checkpoint.last_run_at = utc_now_iso()
        checkpoint.save(checkpoint_path)

    except Exception as exc:
        entry.errors.append(repr(exc))
        checkpoint.save(checkpoint_path)
        if _is_rate_or_auth_error(exc):
            console.print(f"[yellow]Rate/auth issue — checkpoint saved. Retry later.[/] {exc}")
        raise
    finally:
        entry.finished_at = utc_now_iso()
        entry.tweets_new = stats["new"]
        entry.tweets_skipped = stats["skipped"]
        entry.extra["pages"] = stats["pages"]
        manifest.append(entry)

    console.print(
        f"[green]Done[/] new={stats['new']} skipped={stats['skipped']} total_processed={collected}"
    )
    return stats


async def collect_search_chunk(
    cfg: Config,
    query: str,
    *,
    limit: int = 500,
) -> dict[str, int]:
    """Gap-fill via search API (date-chunked queries)."""
    ensure_archive_layout(cfg.archive_dir)
    api = API(str(cfg.accounts_db))
    index = TweetIndex(cfg.archive_dir / "metadata" / "index.jsonl")
    stats = {"new": 0, "skipped": 0}

    console.print(f"[bold]Search[/] {query!r} limit={limit}")
    async with aclosing(api.search(query, limit=limit)) as gen:
        async for tweet in gen:
            doc = normalize_tweet(tweet, source="twscrape_search")
            if _write_tweet(cfg.archive_dir, doc, index, skip_existing=True):
                stats["new"] += 1
            else:
                stats["skipped"] += 1
            await _sleep_jitter(cfg)

    return stats
