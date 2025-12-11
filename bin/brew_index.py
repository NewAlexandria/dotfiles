#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    except subprocess.CalledProcessError:
        return None

def get_iso_time(epoch):
    # Determine timezone offset
    if time.localtime(epoch).tm_isdst and time.daylight:
        tz_offset = -time.altzone
    else:
        tz_offset = -time.timezone

    tz_hours = tz_offset // 3600
    tz_minutes = (tz_offset % 3600) // 60

    # Python 3.6+ f-string formatting for timezone
    tz_str = f"{tz_hours:+03d}{tz_minutes:02d}"

    # Format time
    dt = datetime.fromtimestamp(epoch)
    return dt.strftime("%Y-%m-%dT%H:%M:%S") + tz_str

def main():
    # 1. Determine Paths
    brew_repo = run_cmd("brew --repository") or os.path.expanduser("~/.homebrew")
    cellar = run_cmd("brew --cellar")
    caskroom = run_cmd("brew --caskroom")

    print(f"Scanning Homebrew Cellar: {cellar}", file=sys.stderr)

    records = []

    # 2. Scan Cellar
    if cellar and os.path.isdir(cellar):
        cellar_path = Path(cellar)
        for receipt in cellar_path.rglob("INSTALL_RECEIPT.json"):
            try:
                # Structure: .../Cellar/<formula>/<version>/INSTALL_RECEIPT.json
                # receipt.parent = version dir
                # receipt.parent.parent = formula dir
                version_dir = receipt.parent
                formula_dir = version_dir.parent

                formula = formula_dir.name
                version = version_dir.name

                # Get mtime
                mtime_epoch = int(receipt.stat().st_mtime)
                mtime_iso = get_iso_time(mtime_epoch)

                # Try to get meaningful name from receipt if possible (optional)
                try:
                    with open(receipt, 'r') as f:
                        data = json.load(f)
                        if 'formula' in data and 'name' in data['formula']:
                            formula = data['formula']['name']
                except Exception:
                    pass

                records.append({
                    "formula": formula,
                    "version": version,
                    "install_path": str(receipt),
                    "install_time": mtime_iso,
                    "install_epoch": mtime_epoch
                })
            except Exception as e:
                print(f"Error processing {receipt}: {e}", file=sys.stderr)

    # 3. Scan Caskroom
    if caskroom and os.path.isdir(caskroom):
        caskroom_path = Path(caskroom)
        # Scan depth equivalent to mindepth 2, maxdepth 3
        # Caskroom/<cask>/<version>
        try:
            for cask_dir in caskroom_path.iterdir():
                if not cask_dir.is_dir():
                    continue
                for version_dir in cask_dir.iterdir():
                    if not version_dir.is_dir():
                        continue

                    cask = cask_dir.name
                    version = version_dir.name

                    # Get mtime of the version directory
                    mtime_epoch = int(version_dir.stat().st_mtime)
                    mtime_iso = get_iso_time(mtime_epoch)

                    records.append({
                        "formula": cask,
                        "version": version,
                        "install_path": str(version_dir),
                        "install_time": mtime_iso,
                        "install_epoch": mtime_epoch,
                        "type": "cask"
                    })
        except Exception as e:
            print(f"Error processing Casks in {caskroom}: {e}", file=sys.stderr)

    # 4. Process Data (Grouping and First Installed)
    # Group by key = formula + "||" + version
    groups = {}
    for r in records:
        key = f"{r['formula']}||{r['version']}"
        if key not in groups:
            groups[key] = []
        groups[key].append(r)

    final_records = []

    for key, group in groups.items():
        # Find min epoch in this group
        min_epoch = min(item['install_epoch'] for item in group)
        min_iso = get_iso_time(min_epoch)

        for item in group:
            item['first_installed_epoch'] = min_epoch
            item['first_installed_time'] = min_iso
            item['first_installed'] = (item['install_epoch'] == min_epoch)
            final_records.append(item)

    # 5. Output
    out_json = os.path.join(brew_repo, "installs_index.json")

    # Sort for consistency (optional but good for diffing)
    # Sorting by formula then version then epoch
    final_records.sort(key=lambda x: (x['formula'], x['version'], x['install_epoch']))

    try:
        with open(out_json, 'w') as f:
            json.dump(final_records, f, indent=2, sort_keys=True)
        print(f"Index created: {out_json}")
    except Exception as e:
        print(f"Error writing output to {out_json}: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
