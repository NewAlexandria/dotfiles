#!/usr/bin/env python3
import argparse
import concurrent.futures
import json
import os
import re
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

class Enricher:
    def __init__(self):
        self.taps = {}
        self.installed_info = {}
        self._load_taps()
        self._load_installed_info()

    def _load_taps(self):
        # Default mappings for standard taps (since they might not be locally tapped in Brew 4.0)
        self.taps = {
            "homebrew/core": "Homebrew/homebrew-core",
            "homebrew/cask": "Homebrew/homebrew-cask",
            "homebrew/cask-fonts": "Homebrew/homebrew-cask-fonts",
            "homebrew/cask-versions": "Homebrew/homebrew-cask-versions"
        }

        out = run_cmd("brew tap-info --json")
        if not out:
            return
        try:
            data = json.loads(out)
            for tap in data:
                remote = tap.get("remote")
                name = tap.get("name")
                if remote and "github.com" in remote:
                    parts = remote.rstrip(".git").split("/")
                    if len(parts) >= 2:
                        repo_path = f"{parts[-2]}/{parts[-1]}"
                        self.taps[name] = repo_path
        except Exception as e:
            print(f"Warning: Failed to load tap info: {e}", file=sys.stderr)

    def _load_installed_info(self):
        # We need this to get the source path (ruby_source_file)
        # brew info --json=v2 --installed
        out = run_cmd("brew info --json=v2 --installed")
        if not out:
            return
        try:
            data = json.loads(out)
            # Combine formulae and casks
            items = data.get("formulae", []) + data.get("casks", [])
            for item in items:
                try:
                    # Formulae have 'name' and 'full_name'
                    # Casks have 'token' and 'full_token'
                    keys = []
                    if "token" in item: keys.append(item["token"])
                    if "full_token" in item: keys.append(item["full_token"])
                    if "name" in item: keys.append(item["name"])
                    if "full_name" in item: keys.append(item["full_name"])

                    # Filter None and empty strings
                    keys = [k for k in keys if k and isinstance(k, str)]

                    for k in keys:
                        self.installed_info[k] = item
                        # also map aliases if any
                        aliases = item.get("aliases", [])
                        if isinstance(aliases, list):
                            for alias in aliases:
                                if alias and isinstance(alias, str):
                                    self.installed_info[alias] = item
                except Exception:
                    continue

        except Exception as e:
             print(f"Warning: Failed to load installed info: {e}", file=sys.stderr)

    def get_repo_and_path(self, formula_name):
        # Try to find installed info
        info = self.installed_info.get(formula_name)
        if not info:
             return None, None

        tap_name = info.get("tap")
        repo = self.taps.get(tap_name)

        path = info.get("ruby_source_path")

        if repo and path:
            return repo, path
        return None, None

    def fetch_oldest_commit_date(self, formula_name):
        repo, path = self.get_repo_and_path(formula_name)
        if not repo or not path:
            return None

        # Use gh api to fetch
        # Endpoint: /repos/{repo}/commits?path={path}&per_page=1
        endpoint = f"/repos/{repo}/commits?path={path}&per_page=1"

        try:
            # 1. Get First Page to check headers
            # gh api -i endpoint
            cmd = ["gh", "api", "-i", endpoint]
            output = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
            parts = output.split("\n\n", 1)
            headers = parts[0]

            # Parse Link header
            last_page = 1
            for line in headers.splitlines():
                if line.lower().startswith("link:"):
                    # <url>; rel="next", <url>; rel="last"
                    matches = re.findall(r'<([^>]+)>;\s*rel="([^"]+)"', line)
                    for url, rel in matches:
                        if rel == "last":
                            m = re.search(r'[?&]page=(\d+)', url)
                            if m:
                                last_page = int(m.group(1))

            # 2. Fetch Last Page
            if last_page > 1:
                endpoint_last = f"{endpoint}&page={last_page}"
                out_json = subprocess.check_output(["gh", "api", endpoint_last], text=True, stderr=subprocess.DEVNULL)
                data = json.loads(out_json)
            else:
                # Body is parts[1] if parts length > 1 else ...
                # Easier to just re-fetch body or parse parts[1]
                body = parts[1] if len(parts) > 1 else "[]"
                data = json.loads(body)

            if isinstance(data, list) and len(data) > 0:
                commit = data[-1]
                return commit['commit']['committer']['date']

        except Exception as e:
            print(f"Debug: fetch failed for {repo}/{path}: {e}", file=sys.stderr)
            return None

        return None

def main():
    parser = argparse.ArgumentParser(description="Index Homebrew installs.")
    parser.add_argument("--enrich", action="store_true", help="Enrich with history from GitHub")
    parser.add_argument("--available", action="store_true", help="Index available (non-installed) packages from last year")
    args = parser.parse_args()

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
                version_dir = receipt.parent
                formula_dir = version_dir.parent

                formula = formula_dir.name
                version = version_dir.name

                mtime_epoch = int(receipt.stat().st_mtime)
                mtime_iso = get_iso_time(mtime_epoch)

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
        try:
            for cask_dir in caskroom_path.iterdir():
                if not cask_dir.is_dir():
                    continue
                for version_dir in cask_dir.iterdir():
                    if not version_dir.is_dir():
                        continue

                    if version_dir.name == ".metadata":
                        continue

                    cask = cask_dir.name
                    version = version_dir.name

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
    groups = {}
    for r in records:
        key = f"{r['formula']}||{r['version']}"
        if key not in groups:
            groups[key] = []
        groups[key].append(r)

    final_records = []

    for key, group in groups.items():
        min_epoch = min(item['install_epoch'] for item in group)
        min_iso = get_iso_time(min_epoch)

        for item in group:
            item['first_installed_epoch'] = min_epoch
            item['first_installed_time'] = min_iso
            item['first_installed'] = (item['install_epoch'] == min_epoch)
            final_records.append(item)

    # 5. Optional Enrichment
    if args.enrich:
        print("Enriching with GitHub history (this may take a while)...", file=sys.stderr)
        enricher = Enricher()
        print(f"Loaded {len(enricher.taps)} taps and {len(enricher.installed_info)} installed info records", file=sys.stderr)

        unique_formulas = set(r['formula'] for r in final_records)
        print(f"Processing {len(unique_formulas)} unique formulas for enrichment", file=sys.stderr)

        history_map = {}

        # Run concurrently
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            future_to_formula = {executor.submit(enricher.fetch_oldest_commit_date, f): f for f in unique_formulas}
            for future in concurrent.futures.as_completed(future_to_formula):
                form = future_to_formula[future]
                try:
                    date = future.result()
                    if date:
                        history_map[form] = date
                        print(f"Found history for {form}: {date}", file=sys.stderr)
                    else:
                        print(f"No history found for {form}", file=sys.stderr)
                except Exception as e:
                    print(f"Error fetching history for {form}: {e}", file=sys.stderr)

        print(f"Enrichment complete. Found history for {len(history_map)} formulas.", file=sys.stderr)

        # Apply to records
        for r in final_records:
            if r['formula'] in history_map:
                r['repo_first_commit_date'] = history_map[r['formula']]

    # 6. Available Packages (News Feed)
    if args.available and brew_repo:
        print("Scanning for available packages added in the last year...", file=sys.stderr)
        # Scan Taps
        taps_dir = Path(brew_repo) / "Library/Taps"
        available_map = {} # formula -> date_iso

        if taps_dir.is_dir():
            for tap in taps_dir.iterdir(): # e.g. homebrew/homebrew-core
               if not tap.is_dir(): continue
               for tap_repo in tap.iterdir():
                   if not tap_repo.is_dir() or not (tap_repo / ".git").exists():
                       continue

                   # Build paths to scan (check if they exist)
                   paths_to_scan = []
                   for p in ["Formula", "Casks"]:
                       if (tap_repo / p).is_dir():
                           paths_to_scan.append(p + "/")

                   if not paths_to_scan:
                       continue

                   # Run git log
                   # git log --diff-filter=A --name-only ... -- paths
                   cmd = [
                       "git", "-C", str(tap_repo), "log",
                       "--diff-filter=A", "--name-only", "--format=DT:%aI",
                       "--since=1 year ago", "--"
                   ] + paths_to_scan

                   try:
                        # We need to capture output and parse
                        # Output format:
                        # DT:2024-01-01T...
                        # Formula/foo.rb
                        # ...
                        output = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
                        current_date = None
                        for line in output.splitlines():
                            line = line.strip()
                            if not line: continue
                            if line.startswith("DT:"):
                                current_date = line[3:]
                            elif current_date:
                                # It's a file path
                                # Formula/foo.rb -> foo
                                name = Path(line).stem
                                # Prefer oldest date if we see it multiple times (unlikely with A filter but possible if renamed/deleted/added)
                                # Actually diff-filter=A means Added.
                                # If we see it, it is an addition.
                                # Use the most recent addition? Or oldest?
                                # News feed usually wants "New", so "Recently Added".
                                # If added multiple times (deleted/added), usually we want the latest addition for "News" or oldest for "History"?
                                # User said: "packages that were recently added... never-before been part of ... system"
                                # Let's stick to the log order (reverse chronological usually default).
                                # So first occurrence in log is most recent.
                                # But we want to show it.
                                # Let's store the date.
                                if name not in available_map:
                                    available_map[name] = current_date

                   except subprocess.CalledProcessError:
                       print(f"Warning: Failed to scan tap {tap_repo.name}", file=sys.stderr)

        print(f"Found {len(available_map)} recently added packages.", file=sys.stderr)

        # Merge into final_records
        # Use set of installed names to avoid duplicates
        installed_names = set(r['formula'] for r in final_records)

        for name, date_iso in available_map.items():
            if name in installed_names:
                # Already installed.
                # We could potentially update repo_first_commit_date if missing, but 'enrich' does that better with full history.
                # 'available' scan is limited to 1 year.
                continue

            # Add new record
            # We need an epoch for filtering in brew_first_installs.py
            try:
                # date_iso is ISO 8601
                # python 3.7+ fromisoformat handle it?
                # git log %aI is strict ISO 8601
                dt = datetime.fromisoformat(date_iso)
                epoch = int(dt.timestamp())

                final_records.append({
                    "formula": name,
                    "version": "N/A",
                    "install_path": "",
                    "install_time": date_iso,
                    "install_epoch": epoch,
                    "first_installed": True, # So it passes the filter "first_installed == true"
                    "first_installed_epoch": epoch,
                    "first_installed_time": date_iso,
                    "repo_first_commit_date": date_iso,
                    "status": "available"
                })
            except ValueError:
                pass


    # 7. Output
    out_json = os.path.join(brew_repo, "installs_index.json")
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
