#!/usr/bin/env python3
"""brew_first_installs.py
Utility to find packages whose first-installed date falls between X and Y days ago.
Usage:
    python3 brew_first_installs.py <X-days-ago> <Y-days-ago> [--json]

Arguments:
    X   Older bound (days ago)
    Y   Newer bound (days ago)
    --json   Output raw JSON array of matching records instead of formatted table.
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
    parser = argparse.ArgumentParser(description="Find packages installed for the first time between X and Y days ago.")
    parser.add_argument("X", type=int, help="Older bound (days ago)")
    parser.add_argument("Y", type=int, help="Newer bound (days ago)")
    parser.add_argument("--json", action="store_true", help="Output raw JSON array")
    parser.add_argument("--info", action="store_true", help="Show brew info for each match")
    args = parser.parse_args()

    # Determine brew repository location (same logic as brew_index.py)
    brew_repo = os.popen("brew --repository 2>/dev/null").read().strip()
    if not brew_repo:
        brew_repo = os.path.expanduser("~/.homebrew")

    # Compute epoch boundaries based on current time
    now = int(time.time())
    start_epoch = now - args.X * 86400  # older bound
    end_epoch = now - args.Y * 86400    # newer bound

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
