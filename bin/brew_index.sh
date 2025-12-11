#!/usr/bin/env bash
set -euo pipefail

# Output index path (Homebrew repo)
BREW_REPO="$(brew --repository 2>/dev/null || echo "$HOME/.homebrew")"
OUT_JSON="$BREW_REPO/installs_index.json"
TMP_JSON="$(mktemp -d)/hb_index.$$"

# find receipts in Cellar
CELLAR="$(brew --cellar 2>/dev/null || true)"
CASKROOM="$(brew --caskroom 2>/dev/null || true)"

# helper to make ISO8601 from epoch (macOS date)
iso_from_epoch() {
  # $1 epoch seconds
  python3 - "$1" <<PY
import time,sys
print(time.strftime("%Y-%m-%dT%H:%M:%S%z", time.localtime(int(sys.argv[1]))))
PY
}

echo "Scanning Homebrew Cellar: $CELLAR" >&2

# collect records
# We'll emit one JSON object per receipt line (newline-delimited JSON)
: > "$TMP_JSON"

if [ -n "$CELLAR" ] && [ -d "$CELLAR" ]; then
  find "$CELLAR" -type f -name "INSTALL_RECEIPT.json" | while read -r receipt; do
    # derive formula and version from path: .../Cellar/<formula>/<version>/INSTALL_RECEIPT.json
    verdir="$(dirname "$receipt")"
    formula_dir="$(dirname "$verdir")"
    formula="$(basename "$formula_dir")"
    version="$(basename "$verdir")"

    # mtime epoch (portable using python/stat)
    # Use stat -f %m on macOS
    if stat_out="$(stat -f "%m" "$receipt" 2>/dev/null)"; then
      mtime_epoch="$stat_out"
    else
      # fallback to python os.path.getmtime
      mtime_epoch="$(python3 - <<PY
import os,sys
print(int(os.path.getmtime(sys.argv[1])))
PY
"$receipt")"
    fi

    mtime_iso="$(iso_from_epoch "$mtime_epoch")"

    # try some fields from the receipt (not required)
    name_from_receipt="$(jq -r '.formula.name // empty' "$receipt" 2>/dev/null || true)"
    # fall back to directory-derived if empty
    [ -n "$name_from_receipt" ] && formula="$name_from_receipt"

    # emit JSON object (one per line)
    jq -n --arg formula "$formula" \
          --arg version "$version" \
          --arg receipt "$receipt" \
          --arg install_iso "$mtime_iso" \
          --argjson install_epoch "$mtime_epoch" \
          '{formula:$formula,version:$version,install_path:$receipt,install_time:$install_iso,install_epoch:$install_epoch}' \
      >> "$TMP_JSON"
  done
fi

# collect casks too (Caskroom)
if [ -n "$CASKROOM" ] && [ -d "$CASKROOM" ]; then
  find "$CASKROOM" -mindepth 2 -maxdepth 3 -type d | while read -r d; do
    # path layout often: /.../Caskroom/<cask>/<version>/...
    # ensure that a version directory exists by checking for a directory depth
    # we'll look for any metadata file to pick up mtime
    cask="$(basename "$(dirname "$d")")"
    version="$(basename "$d")"
    # pick mtime of the dir (use stat)
    if stat_out="$(stat -f "%m" "$d" 2>/dev/null)"; then
      mtime_epoch="$stat_out"
    else
      mtime_epoch="$(python3 - <<PY
import os,sys
print(int(os.path.getmtime(sys.argv[1])))
PY
"$d")"
    fi
    mtime_iso="$(iso_from_epoch "$mtime_epoch")"

    jq -n --arg formula "$cask" \
          --arg version "$version" \
          --arg receipt "$d" \
          --arg install_iso "$mtime_iso" \
          --argjson install_epoch "$mtime_epoch" \
          '{formula:$formula,version:$version,install_path:$receipt,install_time:$install_iso,install_epoch:$install_epoch,"type":"cask"}' \
      >> "$TMP_JSON"
  done
fi

# Now we have newline-delimited JSON objects in $TMP_JSON.
# Build a single array and compute first-appearance per formula+version.
# For each unique formula+version find the minimum install_epoch and mark records accordingly.

jq -s '
  # input: array of objects
  . as $all
  | ( $all
      | group_by(.formula + "||" + .version)
      | map( { key: (.[0].formula + "||" + .[0].version),
               entries: .,
               first_epoch: (map(.install_epoch) | min) } )
    ) as $groups
  | (
      # produce annotated list
      ($groups | map(.entries) | add) as $records
  )
  | $records
  | map( . + (
      # find the group's min epoch
      ( ($groups[] | select(.key == (.formula + "||" + .version)) | .first_epoch) as $fe
        | { first_installed_epoch: $fe,
            first_installed_time: ( ($fe|tostring) | tonumber | (strftime("%Y-%m-%dT%H:%M:%S%z") ; .) ) } )
    ) )
  | map( . + { first_installed: (.install_epoch == .first_installed_epoch) } )
' "$TMP_JSON" > "$OUT_JSON.tmp" 2>/dev/null || true

# The jq expression above had to create ISO for first_installed_time: fallback, so patch: compute ISO with python for each first_installed_epoch
# We'll load back, replace any null ISO times by computing them in shell per record (simple and portable)
python3 - <<PY
import json,sys,os,time
out="$OUT_JSON.tmp"
final="$OUT_JSON"
with open(out,'r') as f:
    data=json.load(f)
for rec in data:
    fe = rec.get("first_installed_epoch")
    if fe is not None:
        rec["first_installed_epoch"]=int(fe)
        rec["first_installed_time"]=time.strftime("%Y-%m-%dT%H:%M:%S%z", time.localtime(int(fe)))
    # ensure types
    rec["install_epoch"]=int(rec["install_epoch"])
    # ensure booleans are proper
    rec["first_installed"]=bool(rec.get("first_installed", False))
with open(final,'w') as f:
    json.dump(data,f,indent=2,sort_keys=True)
print("Wrote index to", final)
PY

# clean temp
rm -f "$TMP_JSON" "$OUT_JSON.tmp"

echo "Index created: $OUT_JSON"
