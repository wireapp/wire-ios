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

if [[ ! -f "$VIDEO_PATH" ]]; then
  echo "::warning::Missing test video: $VIDEO_PATH. Skipping simulator media seeding."
  exit 0
fi

if [ -z "${IOS_SIM_ID:-}" ]; then
  echo "::warning::IOS_SIM_ID is not set. Skipping simulator media seeding."
  exit 0
fi

BOOTED_SIMULATORS=$(xcrun simctl list devices booted)
if echo "$BOOTED_SIMULATORS" | grep -q "$IOS_SIM_ID"; then
  echo "Simulator $IOS_SIM_ID is already booted"
else
  echo "Booting simulator $IOS_SIM_ID"
  xcrun simctl boot "$IOS_SIM_ID" || true
  if ! xcrun simctl bootstatus "$IOS_SIM_ID" -b >/dev/null 2>&1; then
    echo "::warning::Simulator $IOS_SIM_ID did not finish booting."
  fi
fi

BOOTED_SIMULATORS=$(xcrun simctl list devices booted)
if ! echo "$BOOTED_SIMULATORS" | grep -q "$IOS_SIM_ID"; then
  echo "::warning::Simulator $IOS_SIM_ID is not booted yet. Skipping simulator media seeding."
  exit 0
fi

echo "Seeding simulator media"
if xcrun simctl addmedia "$IOS_SIM_ID" "$VIDEO_PATH"; then
  echo "Simulator media seeded successfully"
else
  echo "::warning::Failed to seed simulator media with $VIDEO_PATH"
  exit 1
fi
