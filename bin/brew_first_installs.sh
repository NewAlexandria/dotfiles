#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  cat <<USAGE
Usage: $0 <X-days-ago> <Y-days-ago> [--json]
Find packages whose first-installed date is between X and Y days ago.
X = number of days ago (older). Y = number of days ago (newer).
Example: $0 30 7      -> between 30 days ago and 7 days ago (inclusive)
Add --json to output raw JSON objects (array).
USAGE
  exit 1
fi

X="$1"   # older bound (days ago)
Y="$2"   # newer bound (days ago)
OUT_JSON="$(brew --repository 2>/dev/null || echo "$HOME/.homebrew")/installs_index.json"

if [ ! -f "$OUT_JSON" ]; then
  echo "Index file not found at $OUT_JSON"
  echo "Run the indexer script first."
  exit 2
fi

# compute epoch bounds (start = now - X*86400, end = now - Y*86400)
start_epoch=$(python3 - <<PY
import time,sys
X=int(sys.argv[1])
print(int(time.time()) - X*86400)
PY
"$X")
end_epoch=$(python3 - <<PY
import time,sys
Y=int(sys.argv[1])
print(int(time.time()) - Y*86400)
PY
"$Y")

# choose output mode
JSON_OUT=false
if [ "${3:-}" = "--json" ]; then
  JSON_OUT=true
fi

if $JSON_OUT ; then
  jq --argjson start "$start_epoch" --argjson end "$end_epoch" \
    '[ .[] | select(.first_installed == true and (.first_installed_epoch >= $start and .first_installed_epoch <= $end)) ]' \
    "$OUT_JSON"
else
  jq -r --argjson start "$start_epoch" --argjson end "$end_epoch" \
    '.[] | select(.first_installed == true and (.first_installed_epoch >= $start and .first_installed_epoch <= $end)) | 
      [ (.first_installed_time // "unknown"), .formula, .version, .install_path ] | @tsv' \
    "$OUT_JSON" | \
  awk -F"\t" '{ printf "%-25s  %-30s  %s\n", $1, $2, $3 }'
fi

