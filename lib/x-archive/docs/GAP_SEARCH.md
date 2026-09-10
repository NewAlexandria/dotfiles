# Gap search strategy

## The ~3,200 tweet ceiling

`twscrape` `user_tweets` (used by `xarchive archive`) can return at most roughly **3,200** posts per account. If the target has more history, the oldest tweets will not appear in a timeline-only archive.

## Recommended fill: date-chunked search

Use X advanced search operators via `xarchive gap-search`:

```
from:<handle> since:YYYY-MM-DD until:YYYY-MM-DD
```

Example:

```bash
poetry run xarchive gap-search --start 2016-01-01 --end 2024-01-01 --chunk-days 30 --limit-per-chunk 500
```

- **start / end**: bracket the missing era (exclusive `until` per chunk).
- **chunk-days**: smaller chunks if search results hit per-query limits.
- **limit-per-chunk**: twscrape search pagination cap per window.

Merged tweets land in the same `archive/<handle>/` tree; dedupe is by `tweet_id` (idempotent writes).

## Detecting gaps

1. Compare `metadata/profile.json` `statuses_count` to tweet file count.
2. Run `xarchive verify` after gap-search.
3. Inspect `metadata/run_manifest.jsonl` for errors.

## Other options (manual)

| Approach | When |
|----------|------|
| X data export ZIP | Subject provides their archive; zero scrape risk |
| Playwright timeline scroll | twscrape broken or search incomplete; high maintenance |
| Multiple search dimensions | `from:handle filter:media`, keyword slices for dense accounts |

## After gap fill

```bash
poetry run xarchive media-retry
poetry run xarchive verify
```
