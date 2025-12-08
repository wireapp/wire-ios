#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID="${1:-com.wearezeta.zclient.alpha}"
GROUP_ID="${2:-group.com.wearezeta.zclient.alpha}"
OUT_ZIP="${3:-app-group-${GROUP_ID}.zip}"

APPINFO="$(xcrun simctl appinfo booted "$BUNDLE_ID")"

GROUP_URL="$(
python3 - <<'PY' "$APPINFO" "$GROUP_ID"
import re, sys
text = sys.argv[1]
group_id = sys.argv[2]

# Match: "group.id" = "file:///path/to/container/";
pattern = r'"%s"\s*=\s*"([^"]+)"' % re.escape(group_id)
m = re.search(pattern, text)
if not m:
    print("", end="")
    sys.exit(2)

print(m.group(1), end="")
PY
)"

if [[ -z "$GROUP_URL" ]]; then
  echo "Could not find GroupContainers value for: $GROUP_ID" >&2
  exit 2
fi

# Convert file URL -> filesystem path, strip trailing slash
GROUP_PATH="${GROUP_URL#file://}"
GROUP_PATH="${GROUP_PATH%/}"

if [[ ! -d "$GROUP_PATH" ]]; then
  echo "Resolved group path is not a directory: $GROUP_PATH" >&2
  exit 3
fi

echo "Group container:"
echo "  $GROUP_ID -> $GROUP_PATH"

# Zip (keeps parent folder)
rm -f "$OUT_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$GROUP_PATH" "$OUT_ZIP"

echo "Created zip:"
echo "  $(pwd)/$OUT_ZIP"
