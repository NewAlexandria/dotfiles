from __future__ import annotations

import argparse
import asyncio
import sys
import tomllib
from datetime import date
from pathlib import Path

from rich.console import Console

from xarchive.collector import collect_timeline
from xarchive.config import Config
from xarchive.cookies import (
    cookies_from_browser,
    format_cookie_string,
    import_to_twscrape,
    test_session,
)
from xarchive.gap_search import gap_fill_by_search
from xarchive.media import download_all_media
from xarchive.state import TweetIndex
from xarchive.verify import verify_archive

console = Console()


def _parse_date(s: str) -> date:
    return date.fromisoformat(s)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="xarchive",
        description="Archive an X account timeline and media for local research use.",
    )
    p.add_argument(
        "-c",
        "--config",
        type=Path,
        default=None,
        help="Path to config.toml (default: $XARCHIVE_CONFIG, then ~/.config/x-archive/config.toml, then ./config.toml)",
    )
    sub = p.add_subparsers(dest="command", required=True)

    sub.add_parser("archive", help="Full timeline capture (~3200 tweet API cap) + media")

    sp = sub.add_parser("sync", help="Fetch tweets newer than last archived ID + media")
    sp.add_argument(
        "--no-media",
        action="store_true",
        help="Skip media download after sync",
    )

    sub.add_parser("media", help="Download missing media for all archived tweets")
    sub.add_parser("media-retry", help="Alias for media (retry failed downloads)")
    sub.add_parser("verify", help="Check index/files/media consistency")

    sp = sub.add_parser(
        "import-cookies",
        help="Load auth_token+ct0 from your browser into accounts.db (like yt-dlp)",
    )
    sp.add_argument(
        "username",
        help="Your X username (the logged-in account in the browser)",
    )
    sp.add_argument(
        "--browser",
        default="chrome",
        help="Browser to read cookies from (chrome, firefox, safari, brave, edge)",
    )
    sp.add_argument("--profile", default=None, help="Browser profile name if needed")
    sp.add_argument(
        "--replace",
        action="store_true",
        help="Overwrite existing entry in accounts.db",
    )
    sp.add_argument(
        "--test",
        action="store_true",
        help="After import, call user_by_login to verify the session",
    )
    sp.add_argument(
        "--accounts-db",
        type=Path,
        default=None,
        help="Path to twscrape accounts.db (default: <x-archive>/accounts.db)",
    )
    sp.add_argument(
        "--probe",
        type=str,
        default=None,
        metavar="HANDLE",
        help="With --test: X handle to fetch (default: target_username from config.toml)",
    )

    sp = sub.add_parser(
        "gap-search",
        help="Fill history beyond ~3200 cap via date-chunked search",
    )
    sp.add_argument("--start", type=_parse_date, required=True, help="YYYY-MM-DD")
    sp.add_argument("--end", type=_parse_date, default=None, help="YYYY-MM-DD (default: today)")
    sp.add_argument("--chunk-days", type=int, default=30)
    sp.add_argument("--limit-per-chunk", type=int, default=500)

    return p


async def _run_archive(cfg: Config) -> None:
    await collect_timeline(cfg, mode="archive")
    if cfg.download_media:
        await download_all_media(cfg, only_missing=True)


async def _run_sync(cfg: Config, *, no_media: bool) -> None:
    index = TweetIndex(cfg.archive_dir / "metadata" / "index.jsonl")
    since = index.max_tweet_id()
    if since is None:
        console.print("[yellow]No existing archive; running full archive instead.[/]")
        await _run_archive(cfg)
        return
    console.print(f"Syncing tweets newer than id={since}")
    await collect_timeline(cfg, mode="sync", since_tweet_id=since)
    if cfg.download_media and not no_media:
        await download_all_media(cfg, only_missing=True)


def _project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _resolve_accounts_db(path: Path | None) -> Path:
    root = _project_root()
    db = path or (root / "accounts.db")
    db = Path(db)
    if not db.is_absolute():
        db = root / db
    return db


async def _async_main(args: argparse.Namespace) -> int:
    cmd = args.command

    if cmd == "import-cookies":
        accounts_db = _resolve_accounts_db(args.accounts_db)
        cookies = cookies_from_browser(args.browser, args.profile)
        cookie_string = format_cookie_string(cookies)
        await import_to_twscrape(
            accounts_db,
            args.username,
            cookie_string,
            replace=args.replace,
        )
        if args.test:
            probe = (args.probe or "").lstrip("@").lower()
            if not probe:
                try:
                    cfg_probe = Config.load(args.config)
                    probe = cfg_probe.handle
                except FileNotFoundError:
                    console.print(
                        "[red]--test needs a handle: pass --probe neoconbill or fix config.toml[/]"
                    )
                    return 2
                except tomllib.TOMLDecodeError as exc:
                    console.print(
                        f"[red]config.toml is invalid TOML ({exc}).[/]\n"
                        "Fix the file or pass e.g. [bold]--probe neoconbill[/] with --test."
                    )
                    return 2
            ok = await test_session(accounts_db, probe)
            return 0 if ok else 1
        return 0

    try:
        cfg = Config.load(args.config)
    except FileNotFoundError as exc:
        console.print(f"[red]{exc}[/]")
        return 2
    except tomllib.TOMLDecodeError as exc:
        console.print(
            f"[red]Invalid config.toml ({exc}).[/]\n"
            "TOML has no [bold]null[/]: remove `tweet_limit = null` or set an integer."
        )
        return 2

    if cmd == "archive":
        await _run_archive(cfg)
    elif cmd == "sync":
        await _run_sync(cfg, no_media=args.no_media)
    elif cmd in ("media", "media-retry"):
        await download_all_media(cfg, only_missing=True)
    elif cmd == "verify":
        return verify_archive(cfg)
    elif cmd == "gap-search":
        await gap_fill_by_search(
            cfg,
            start=args.start,
            end=args.end,
            chunk_days=args.chunk_days,
            limit_per_chunk=args.limit_per_chunk,
        )
        if cfg.download_media:
            await download_all_media(cfg, only_missing=True)
    else:
        console.print(f"Unknown command: {cmd}")
        return 2
    return 0


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    try:
        code = asyncio.run(_async_main(args))
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted — checkpoint saved if collection was running.[/]")
        code = 130
    sys.exit(code)


if __name__ == "__main__":
    main()
