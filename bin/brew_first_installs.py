#!/usr/bin/env python3
"""brew_first_installs.py
Find packages whose first-installed date falls within a range of "days ago".

The range is expressed as two "days ago" values:
  - older end: further in the past (larger number of days ago)
  - newer end: closer to now (smaller number of days ago; 0 = today)

Order of arguments does not matter. The script treats the larger value as the
older end and the smaller as the newer end. E.g. "10 0" and "0 10" both mean
"from 10 days ago through today".

Usage:
    python3 brew_first_installs.py <days_ago> <days_ago> [--json]

Arguments:
    days_ago (two values)  The two ends of the range in days ago. Larger value
                           = older (further in past). Smaller value = newer
                           (closer to now; use 0 for today).
    --json                 Output raw JSON array of matching records.
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path
from datetime import datetime, timezone

# Helper to get ISO8601 string from epoch (used for display)
def iso_from_epoch(epoch: int) -> str:
    dt = datetime.fromtimestamp(epoch, tz=timezone.utc)
    return dt.isoformat()

def load_index(brew_repo: str) -> list:
    index_path = Path(brew_repo) / "installs_index.json"
    if not index_path.is_file():
        print(f"Index file not found at {index_path}", file=sys.stderr)
        sys.exit(2)
    with open(index_path, "r", encoding="utf-8") as f:
        return json.load(f)

def main():
    parser = argparse.ArgumentParser(
        description="Find packages first installed within a date range (given as two 'days ago' values). "
        "Larger days ago = older end (further in past); smaller = newer end (0 = today). Order of args does not matter."
    )
    parser.add_argument(
        "days_ago_a", type=int, metavar="DAYS_AGO",
        help="One end of range (days ago); larger value = older end, smaller = newer end"
    )
    parser.add_argument(
        "days_ago_b", type=int, metavar="DAYS_AGO",
        help="Other end of range (days ago); order does not matter"
    )
    parser.add_argument("--json", action="store_true", help="Output raw JSON array")
    parser.add_argument("--info", action="store_true", help="Show brew info for each match")
    args = parser.parse_args()

    # Determine brew repository location (same logic as brew_index.py)
    brew_repo = os.popen("brew --repository 2>/dev/null").read().strip()
    if not brew_repo:
        brew_repo = os.path.expanduser("~/.homebrew")

    # Convert "days ago" range to epoch boundaries.
    # older_days = further in the past (earlier installs); newer_days = closer to now (0 = today).
    # We include first_installed_epoch when: start_epoch <= epoch <= end_epoch.
    now = int(time.time())
    older_days = max(args.days_ago_a, args.days_ago_b)   # older end of range (further in past)
    newer_days = min(args.days_ago_a, args.days_ago_b)  # newer end of range (closer to now; 0 = today)
    start_epoch = now - older_days * 86400   # oldest time in range (older boundary)
    end_epoch = now - newer_days * 86400     # newest time in range (newer boundary)

    records = load_index(brew_repo)

    # Filter records: first_installed == true and epoch within range (inclusive)
    matches = [
        r for r in records
        if r.get("first_installed")
        and start_epoch <= r.get("first_installed_epoch", 0) <= end_epoch
    ]

    if args.json:
        # Output raw JSON array
        json.dump(matches, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        # Human‑readable table: time, formula, version, install_path
        # Header not required – original script printed rows only.
        for r in matches:
            first_time = r.get("first_installed_time", "unknown")
            formula = r.get("formula", "")
            version = r.get("version", "")
            install_path = r.get("install_path", "")
            status = r.get("status", "installed")

            # Use (Available) label if status is available
            status_str = ""
            if status == "available":
                status_str = "(Available)"

            # Align columns: Time, Formula, Version, Status, Path
            print(f"{first_time:<25}  {formula:<30}  {version:<15}  {status_str:<12} {install_path}")

        if args.info:
            print("\n" + "="*80 + "\n")
            import subprocess
            for r in matches:
                formula = r.get("formula")
                if formula:
                    print(f"--- Info for {formula} ---")
                    # Run brew info, let it stream to stdout/stderr
                    # Use 'brew info <formula>'
                    try:
                        subprocess.run(["brew", "info", formula], check=False)
                    except Exception as e:
                       print(f"Error running info for {formula}: {e}", file=sys.stderr)
                    print("\n")

if __name__ == "__main__":
    main()
