# x-archive

Personal research archiver for a single X (Twitter) account: timeline JSON, local media, and resumable incremental sync. Uses [twscrape](https://github.com/vladkens/twscrape) with your logged-in session (free; no official API tier).

This copy lives in **dotfiles** at `~/.dotfiles/lib/x-archive`. The `xarchive` wrapper on `PATH` (`~/.dotfiles/bin/xarchive`) runs it. **Archive data, `accounts.db`, and `config.toml` stay outside this repo** — default example paths point at `~/src/scrapers/x-archive/`.

## Prerequisites

- Python 3.11+
- [Poetry](https://python-poetry.org/)
- [ffmpeg](https://ffmpeg.org/) and [yt-dlp](https://github.com/yt-dlp/yt-dlp) on `PATH` (videos)
- An X account you control (for session cookies)

## Setup

```bash
cd ~/.dotfiles/lib/x-archive
poetry install
mkdir -p ~/.config/x-archive
cp config.example.toml ~/.config/x-archive/config.toml
# Edit config.toml: set target_username (and archive_root / accounts_db if needed)
```

Config search order: `--config` → `$XARCHIVE_CONFIG` → `~/.config/x-archive/config.toml` → `lib/x-archive/config.toml`.

After a new shell (or `source ~/.zshrc`), `xarchive` is on `PATH` via `functions_shell.sh`.

### Authentication (same cookies as yt-dlp)

X does not give you API keys for free. **twscrape** reuses the same session cookies your browser uses for GraphQL requests: principally `auth_token` and `ct0`. That is the same material yt-dlp reads with `--cookies-from-browser chrome`.

**Recommended — import from browser:**

```bash
# Log into x.com in Chrome (or firefox/safari/brave), then:
xarchive import-cookies invis_insight --browser chrome --replace --test --probe neoconbill
```

`--test` calls `user_by_login` on `--probe` (or on `target_username` from `config.toml` if you omit `--probe`). `import-cookies` does not require a valid `config.toml` unless you use `--test` without `--probe`.

**Config note:** TOML has no `null`. Do not use `tweet_limit = null`; omit `tweet_limit` for unlimited, or set an integer cap.

**Manual copy (DevTools):**

```bash
cd ~/.dotfiles/lib/x-archive
poetry run twscrape add_cookie newalexandria "auth_token=PASTE; ct0=PASTE"
```

x.com → DevTools (F12) → Application → Cookies → `https://x.com` → copy values (not the word “…").

**`twscrape accounts` and `logged_in`:** With cookie-based setup, `logged_in` may show `0` even when auth works — twscrape only sets that flag after a full password login stores headers. Check **`active=1`** and run `--test` instead.

If you see `403 Session expired or banned`, cookies are wrong, expired, or placeholders — re-import from a fresh browser session.

## Commands

```bash
xarchive archive      # Full timeline (~3200 tweet cap) + media
xarchive sync         # New tweets since last run + media
xarchive media        # Download missing media only
xarchive media-retry  # Same as media
xarchive verify       # Consistency check
xarchive gap-search --start 2018-01-01   # Older history via search chunks
```

### Gap search (> ~3200 tweets)

See [docs/GAP_SEARCH.md](docs/GAP_SEARCH.md) for details.

`user_tweets` stops at roughly 3,200 posts. For older history:

```bash
xarchive gap-search --start 2015-01-01 --end 2020-01-01 --chunk-days 30
```

Then run `verify` and `media-retry` as needed.

## Output layout

```
archive/<handle>/
├── tweets/YYYY/<tweet_id>.json
├── media/images|videos|gifs/
├── metadata/
│   ├── profile.json
│   ├── index.jsonl
│   ├── checkpoint.json
│   └── run_manifest.jsonl
└── raw/pages/          # optional GraphQL tweet JSON
```

## Throttling

Defaults in `config.toml`: 3–8s jitter between timeline items. Slow is intentional to reduce account risk. Expect **hours to days** for a full archive.

## Optional Playwright session export

```bash
cd ~/.dotfiles/lib/x-archive
poetry install --with dev
poetry run playwright install chromium
poetry run python -m xarchive.playwright_export
```

Primary auth path remains `twscrape add_cookie`.

## Ethics

For **personal research** only: do not republish or resell the archive. Keep attribution (`permalink` in each JSON). Respect X Terms of Service and rate limits.
