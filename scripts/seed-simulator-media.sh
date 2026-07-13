#!/bin/bash
set -euo pipefail

#
# Wire
# Copyright (C) 2026 Wire Swiss GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
VIDEO_PATH="$REPO_ROOT/wire-ios/WireUITests/TestServicesData/Video/testVideo.mp4"
FILE_PATH="$REPO_ROOT/wire-ios/WireUITests/TestServicesData/File/testFile.pdf"

if [ -z "${IOS_SIM_ID:-}" ]; then
  echo "::warning::IOS_SIM_ID is not set. Skipping simulator media seeding."
  exit 0
fi

for FIXTURE_PATH in "$VIDEO_PATH" "$FILE_PATH"; do
  if [[ ! -f "$FIXTURE_PATH" ]]; then
    echo "::error::Missing simulator media fixture: $FIXTURE_PATH" >&2
    exit 1
  fi
done

echo "Booting simulator $IOS_SIM_ID"
xcrun simctl boot "$IOS_SIM_ID" || true
BOOTED_SIMULATORS=$(xcrun simctl list devices booted)
if ! echo "$BOOTED_SIMULATORS" | grep -q "$IOS_SIM_ID"; then
  echo "::warning::Simulator $IOS_SIM_ID is not booted yet. Skipping simulator media seeding."
  exit 0
fi

echo "Seeding simulator media"
if xcrun simctl addmedia "$IOS_SIM_ID" "$VIDEO_PATH"; then
  echo "Simulator media seeded successfully"
else
  echo "::error::Failed to seed simulator media with $VIDEO_PATH" >&2
  exit 1
fi

echo "Seeding Files app fixtures"
if ! FILES_CONTAINER="$(xcrun simctl get_app_container "$IOS_SIM_ID" com.apple.DocumentsApp data 2>/dev/null)"; then
  echo "::error::Unable to locate Files app container for simulator $IOS_SIM_ID" >&2
  exit 1
fi

DEVICE_DATA_DIR="$(cd "$FILES_CONTAINER/../../../.." && pwd)"
APP_GROUP_ROOT="$DEVICE_DATA_DIR/Containers/Shared/AppGroup"
LOCAL_STORAGE_DIR=""

for METADATA_PATH in "$APP_GROUP_ROOT"/*/.com.apple.mobile_container_manager.metadata.plist; do
  GROUP_IDENTIFIER="$(plutil -extract MCMMetadataIdentifier raw -o - "$METADATA_PATH" 2>/dev/null || true)"
  if [[ "$GROUP_IDENTIFIER" == "group.com.apple.FileProvider.LocalStorage" ]]; then
    LOCAL_STORAGE_DIR="$(dirname "$METADATA_PATH")/File Provider Storage"
    break
  fi
done

if [[ -z "$LOCAL_STORAGE_DIR" ]]; then
  echo "::error::Unable to locate Files local storage app group for simulator $IOS_SIM_ID" >&2
  exit 1
fi

mkdir -p "$LOCAL_STORAGE_DIR"

if cp "$FILE_PATH" "$VIDEO_PATH" "$LOCAL_STORAGE_DIR/"; then
  echo "Files app fixtures seeded successfully"
else
  echo "::error::Failed to copy $FILE_PATH and $VIDEO_PATH into $LOCAL_STORAGE_DIR" >&2
  exit 1
fi
