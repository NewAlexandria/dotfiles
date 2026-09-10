from __future__ import annotations

import json
from pathlib import Path

from rich.console import Console
from rich.table import Table

from xarchive.config import Config
from xarchive.media import iter_tweet_docs
from xarchive.state import TweetIndex

console = Console()


def verify_archive(cfg: Config) -> int:
    """Returns exit code: 0 if healthy, 1 if issues found."""
    archive_dir = cfg.archive_dir
    index = TweetIndex(archive_dir / "metadata" / "index.jsonl")
    tweet_files = iter_tweet_docs(archive_dir)

    indexed_ids = index.tweet_ids
    file_ids = {p.stem for p in tweet_files}

    missing_files = indexed_ids - file_ids
    missing_index = file_ids - indexed_ids

    media_total = 0
    media_ok = 0
    media_missing: list[str] = []

    for path in tweet_files:
        doc = json.loads(path.read_text(encoding="utf-8"))
        for item in doc.get("media") or []:
            media_total += 1
            lp = item.get("local_path")
            if lp and (archive_dir / lp).is_file():
                media_ok += 1
            else:
                media_missing.append(f"{doc['tweet_id']}:{item.get('type')}")

    table = Table(title=f"Archive verification @{cfg.handle}")
    table.add_column("Check")
    table.add_column("Value")
    table.add_row("Tweet JSON files", str(len(tweet_files)))
    table.add_row("Index entries", str(len(indexed_ids)))
    table.add_row("In index but no file", str(len(missing_files)))
    table.add_row("File but not in index", str(len(missing_index)))
    table.add_row("Media items", str(media_total))
    table.add_row("Media on disk", str(media_ok))
    table.add_row("Media missing", str(len(media_missing)))
    console.print(table)

    issues = len(missing_files) + len(missing_index) + len(media_missing)
    if issues:
        console.print("[yellow]Issues detected. Run `xarchive media-retry` for missing media.[/]")
        if missing_index:
            console.print(f"  Or rebuild index for orphan files: {len(missing_index)}")
        return 1

    console.print("[green]Archive looks consistent.[/]")
    return 0
