from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from pathlib import Path

if sys.version_info >= (3, 11):
    import tomllib
else:
    import tomli as tomllib


def _expand_path(value: str | Path, base: Path) -> Path:
    path = Path(value).expanduser()
    if not path.is_absolute():
        path = base / path
    return path


@dataclass
class Config:
    target_username: str
    archive_root: Path
    accounts_db: Path
    request_delay_min: float = 3.0
    request_delay_max: float = 8.0
    tweet_limit: int | None = None
    download_media: bool = True
    save_raw_pages: bool = True
    media_max_retries: int = 3
    media_timeout_seconds: int = 120
    yt_dlp_path: str = "yt-dlp"

    @property
    def handle(self) -> str:
        return self.target_username.lstrip("@").lower()

    @property
    def archive_dir(self) -> Path:
        return self.archive_root / self.handle

    @classmethod
    def project_root(cls) -> Path:
        return Path(__file__).resolve().parent.parent

    @classmethod
    def resolve_config_path(cls, path: Path | None = None) -> Path:
        """--config → $XARCHIVE_CONFIG → ~/.config/x-archive/config.toml → <project>/config.toml"""
        if path is not None:
            return Path(path).expanduser()
        env = os.environ.get("XARCHIVE_CONFIG")
        if env:
            return Path(env).expanduser()
        xdg = Path.home() / ".config" / "x-archive" / "config.toml"
        if xdg.is_file():
            return xdg
        return cls.project_root() / "config.toml"

    @classmethod
    def load(cls, path: Path | None = None) -> Config:
        project = cls.project_root()
        config_path = cls.resolve_config_path(path)
        if not config_path.is_file():
            example = project / "config.example.toml"
            xdg = Path.home() / ".config" / "x-archive" / "config.toml"
            raise FileNotFoundError(
                f"Missing {config_path}. Copy {example} to {xdg} "
                f"(or to {project / 'config.toml'}) and set target_username."
            )
        with config_path.open("rb") as f:
            data = tomllib.load(f)

        config_dir = config_path.parent
        archive_root = _expand_path(data.get("archive_root", "archive"), config_dir)
        accounts_db = _expand_path(data.get("accounts_db", "accounts.db"), config_dir)

        tweet_limit = data.get("tweet_limit")
        if tweet_limit is not None:
            tweet_limit = int(tweet_limit)

        return cls(
            target_username=str(data["target_username"]),
            archive_root=archive_root,
            accounts_db=accounts_db,
            request_delay_min=float(data.get("request_delay_min", 3.0)),
            request_delay_max=float(data.get("request_delay_max", 8.0)),
            tweet_limit=tweet_limit,
            download_media=bool(data.get("download_media", True)),
            save_raw_pages=bool(data.get("save_raw_pages", True)),
            media_max_retries=int(data.get("media_max_retries", 3)),
            media_timeout_seconds=int(data.get("media_timeout_seconds", 120)),
            yt_dlp_path=str(data.get("yt_dlp_path", "yt-dlp")),
        )
