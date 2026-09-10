from __future__ import annotations

import asyncio
from datetime import date, timedelta

from rich.console import Console

from xarchive.collector import collect_search_chunk
from xarchive.config import Config

console = Console()

# twscrape user_tweets returns at most ~3200 tweets. Use search chunks for older history.


def build_date_chunks(
    start: date,
    end: date,
    *,
    chunk_days: int = 30,
) -> list[tuple[date, date]]:
    """Inclusive start, exclusive end windows for since/until search operators."""
    chunks: list[tuple[date, date]] = []
    cur = start
    while cur < end:
        nxt = min(cur + timedelta(days=chunk_days), end)
        chunks.append((cur, nxt))
        cur = nxt
    return chunks


def search_query(handle: str, since: date, until: date) -> str:
    """X advanced search: from:user since:YYYY-MM-DD until:YYYY-MM-DD"""
    return f"from:{handle.lstrip('@')} since:{since.isoformat()} until:{until.isoformat()}"


async def gap_fill_by_search(
    cfg: Config,
    *,
    start: date,
    end: date | None = None,
    chunk_days: int = 30,
    limit_per_chunk: int = 500,
) -> dict[str, int]:
    """
    Stub implementation for accounts with >~3200 tweets.

    Runs twscrape search in date windows and merges into the same archive layout.
    Adjust start/end to bracket missing history after a timeline archive run.
    """
    end = end or date.today()
    handle = cfg.handle
    totals = {"new": 0, "skipped": 0, "chunks": 0}

    chunks = build_date_chunks(start, end, chunk_days=chunk_days)
    console.print(
        f"[bold]Gap search[/] @{handle}: {len(chunks)} chunks "
        f"({start} → {end}, {chunk_days}d each)"
    )

    for since, until in chunks:
        q = search_query(handle, since, until)
        console.print(f"  Chunk {since} .. {until}: {q}")
        stats = await collect_search_chunk(cfg, q, limit=limit_per_chunk)
        totals["new"] += stats["new"]
        totals["skipped"] += stats["skipped"]
        totals["chunks"] += 1

    console.print(
        f"[green]Gap search done[/] new={totals['new']} skipped={totals['skipped']} "
        f"chunks={totals['chunks']}"
    )
    return totals
