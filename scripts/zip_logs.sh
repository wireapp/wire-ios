#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID="${1:-com.wearezeta.zclient.alpha}"
GROUP_ID="${2:-group.com.wearezeta.zclient.alpha}"
OUT_ZIP="${3:-app-group.zip}"
DEVICE_ID="${4:-booted}"

echo "BUNDLE_ID=$BUNDLE_ID"
echo "GROUP_ID=$GROUP_ID"
echo "OUT_ZIP=$OUT_ZIP"
echo "DEVICE_ID=$DEVICE_ID"

echo "Checking app is installed..."
if ! xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" data >/dev/null 2>&1; then
  echo "ERROR: App not installed (or wrong device). Try:" >&2
  echo "  xcrun simctl list devices booted" >&2
  echo "  xcrun simctl install <UDID|booted> <path-to-app>" >&2
  exit 10
fi

echo "Reading appinfo..."
if ! APPINFO="$(xcrun simctl appinfo "$DEVICE_ID" "$BUNDLE_ID" 2>&1)"; then
  echo "ERROR: simctl appinfo failed:" >&2
  echo "$APPINFO" >&2
  exit 11
fi

# Extract URL for the group id
GROUP_URL="$(
python3 - "$APPINFO" "$GROUP_ID" <<'PY'
import re, sys
text = sys.argv[1]
group_id = sys.argv[2]
pattern = r'"%s"\s*=\s*"([^"]+)"' % re.escape(group_id)
m = re.search(pattern, text)
print(m.group(1) if m else "", end="")
PY
)"

if [[ -z "$GROUP_URL" ]]; then
  echo "ERROR: Could not find GroupContainers value for: $GROUP_ID" >&2
  echo "appinfo output was:" >&2
  echo "$APPINFO" >&2
  exit 12
fi

# file:///... -> /...
GROUP_PATH="${GROUP_URL#file://}"
GROUP_PATH="${GROUP_PATH%/}"

echo "Resolved group path: $GROUP_PATH"

if [[ ! -d "$GROUP_PATH" ]]; then
  echo "ERROR: Resolved group path is not a directory: $GROUP_PATH" >&2
  exit 13
fi

echo "Zipping..."
rm -f "$OUT_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$GROUP_PATH" "$OUT_ZIP"

echo "Created zip: $(pwd)/$OUT_ZIP"