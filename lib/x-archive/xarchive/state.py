from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass
class Checkpoint:
    user_id: str | None = None
    tweets_saved: int = 0
    last_tweet_id: str | None = None
    last_run_at: str | None = None
    completed: bool = False

    @classmethod
    def load(cls, path: Path) -> Checkpoint:
        if not path.is_file():
            return cls()
        return cls(**json.loads(path.read_text(encoding="utf-8")))

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(asdict(self), indent=2), encoding="utf-8")


@dataclass
class ManifestEntry:
    run_id: str
    command: str
    started_at: str
    finished_at: str | None = None
    tweets_new: int = 0
    tweets_skipped: int = 0
    media_ok: int = 0
    media_failed: int = 0
    errors: list[str] = field(default_factory=list)
    extra: dict[str, Any] = field(default_factory=dict)

    def to_jsonl_line(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False)


class RunManifest:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)

    def append(self, entry: ManifestEntry) -> None:
        with self.path.open("a", encoding="utf-8") as f:
            f.write(entry.to_jsonl_line() + "\n")


class TweetIndex:
    """Append-only index of archived tweets for fast scans."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._ids: set[str] | None = None

    def _load_ids(self) -> set[str]:
        if self._ids is not None:
            return self._ids
        ids: set[str] = set()
        if self.path.is_file():
            for line in self.path.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                    tid = row.get("tweet_id")
                    if tid:
                        ids.add(str(tid))
                except json.JSONDecodeError:
                    continue
        self._ids = ids
        return ids

    def has(self, tweet_id: str) -> bool:
        return str(tweet_id) in self._load_ids()

    def append(self, row: dict[str, Any]) -> None:
        tid = str(row["tweet_id"])
        if tid in self._load_ids():
            return
        with self.path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")
        self._ids.add(tid)

    def tweet_ids(self) -> set[str]:
        return set(self._load_ids())

    def max_tweet_id(self) -> int | None:
        ids = self._load_ids()
        if not ids:
            return None
        return max(int(i) for i in ids if i.isdigit())


def tweet_json_path(archive_dir: Path, tweet_id: str, timestamp_iso: str) -> Path:
    year = timestamp_iso[:4] if len(timestamp_iso) >= 4 else "unknown"
    return archive_dir / "tweets" / year / f"{tweet_id}.json"


def ensure_archive_layout(archive_dir: Path) -> None:
    for sub in (
        "tweets",
        "media/images",
        "media/videos",
        "media/gifs",
        "metadata",
        "raw/pages",
    ):
        (archive_dir / sub).mkdir(parents=True, exist_ok=True)
