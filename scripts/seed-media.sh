#!/bin/bash
set -Eeuo pipefail

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

VIDEO_PATH="${1:-${REPO_ROOT:-$(pwd)}/wire-ios/WireUITests/TestServicesData/Video/testVideo.mp4}"
SIMULATOR_ID="${IOS_SIM_ID:-booted}"

if [[ ! -f "$VIDEO_PATH" ]]; then
  echo >&2 "[ERROR] Missing test video: $VIDEO_PATH"
  exit 1
fi

echo "[INFO] Seeding simulator Photos with: $VIDEO_PATH"
echo "[INFO] Simulator: $SIMULATOR_ID"

xcrun simctl boot "$SIMULATOR_ID" || true
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl addmedia "$SIMULATOR_ID" "$VIDEO_PATH"

echo "[INFO] Seeded simulator Photos with $VIDEO_PATH"
