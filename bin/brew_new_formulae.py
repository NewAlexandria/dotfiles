#!/usr/bin/env python3
"""brew_new_formulae.py
Query formulae added to Homebrew taps within a date range (days ago).

Uses the same tap git history that powers `brew update`'s "New Formulae".
Run `brew update` first for accurate results.

The range is expressed as two "days ago" values (same as brew_first_installs.py):
  - older end: further in the past (larger number)
  - newer end: closer to now (smaller number; 0 = today)
  Order of arguments does not matter.

Usage:
    python3 brew_new_formulae.py <days_ago> <days_ago> [--json] [--desc]

Example:
    python3 brew_new_formulae.py 0 30   # formulae added in last 30 days
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path


def get_brew_repo() -> str:
    try:
        out = subprocess.check_output(
            ["brew", "--repository"],
            text=True,
            stderr=subprocess.DEVNULL,
        )
        return out.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return os.path.expanduser("~/.homebrew")


def scan_taps_for_new_formulae(
    brew_repo: str,
    since_days: int,
    until_days: int | None,
) -> list[dict]:
    """Scan tap git history for formulae/casks added in the date range."""
    taps_dir = Path(brew_repo) / "Library/Taps"
    if not taps_dir.is_dir():
        return []

    results = []  # list of {formula, date_iso, tap, type}
    seen = set()  # (formula, tap) to avoid duplicates across taps

    for tap in taps_dir.iterdir():
        if not tap.is_dir():
            continue
        for tap_repo in tap.iterdir():
            if not tap_repo.is_dir() or not (tap_repo / ".git").exists():
                continue

            paths_to_scan = []
            for p in ["Formula", "Casks"]:
                if (tap_repo / p).is_dir():
                    paths_to_scan.append((p + "/", p.rstrip("/")))

            for path_spec, kind in paths_to_scan:
                cmd = [
                    "git", "-C", str(tap_repo), "log",
                    "--diff-filter=A", "--name-only", "--format=DT:%aI",
                    f"--since={since_days} days ago",
                ]
                if until_days is not None and until_days > 0:
                    cmd.extend([f"--until={until_days} days ago"])
                cmd.extend(["--", path_spec])

                try:
                    output = subprocess.check_output(
                        cmd, text=True, stderr=subprocess.DEVNULL
                    )
                except subprocess.CalledProcessError:
                    continue

                current_date = None
                tap_name = tap_repo.name
                for line in output.splitlines():
                    line = line.strip()
                    if not line:
                        continue
                    if line.startswith("DT:"):
                        current_date = line[3:]
                    elif current_date:
                        name = Path(line).stem
                        key = (name, tap_name)
                        if key in seen:
                            continue
                        seen.add(key)
                        results.append({
                            "formula": name,
                            "tap_added_time": current_date,
                            "tap": tap_name,
                            "type": kind,
                        })
    return results


def fetch_description(formula: str) -> str:
    """Get one-line description from brew info."""
    try:
        out = subprocess.check_output(
            ["brew", "info", formula],
            text=True,
            stderr=subprocess.DEVNULL,
            timeout=5,
        )
        for line in out.splitlines():
            line = line.strip()
            if line and not line.startswith(formula) and ":" not in line[:20]:
                return line[:80]
        return ""
    except Exception:
        return ""


def main():
    parser = argparse.ArgumentParser(
        description="List formulae added to Homebrew taps within a date range.",
        epilog="Example: 0 30 = last 30 days. Run 'brew update' first for accuracy.",
    )
    parser.add_argument(
        "days_ago_a", type=int, metavar="END1",
        help="One end of range in days ago (0 = today)",
    )
    parser.add_argument(
        "days_ago_b", type=int, metavar="END2",
        help="Other end of range; order does not matter",
    )
    parser.add_argument("--json", action="store_true", help="Output JSON array")
    parser.add_argument("--desc", action="store_true", help="Fetch brew info description (slower)")
    args = parser.parse_args()

    older_days = max(args.days_ago_a, args.days_ago_b)
    newer_days = min(args.days_ago_a, args.days_ago_b)
    until_days = newer_days if newer_days > 0 else None

    brew_repo = get_brew_repo()
    records = scan_taps_for_new_formulae(brew_repo, older_days, until_days)

    # Sort by date (newest first)
    records.sort(key=lambda r: r["tap_added_time"], reverse=True)

    if args.desc:
        for r in records:
            r["description"] = fetch_description(r["formula"])

    if args.json:
        json.dump(records, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        for r in records:
            desc = ""
            if args.desc and r.get("description"):
                desc = f"  {r['description']}"
            print(f"{r['tap_added_time']:<25}  {r['formula']:<30}  {r['tap']}{desc}")


if __name__ == "__main__":
    main()
