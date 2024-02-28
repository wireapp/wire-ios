#!/bin/bash
set -Eeuo pipefail

#
# Wire
# Copyright (C) 2024 Wire Swiss GmbH
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

REPO_ROOT=$(git rev-parse --show-toplevel)
XCODEBUILD="xcrun xcodebuild"

# script is work-in-progress, it just runs the sync-engine tests for now

(
    cd "$REPO_ROOT"
    echo "Building WireSyncEngine..."
    xcodebuild build -workspace wire-ios-mono.xcworkspace -scheme WireSyncEngine -destination 'platform=iOS Simulator,OS=17.2,name=iPhone 14'
    echo "Testing WireSyncEngine..."
    xcodebuild test -retry-tests-on-failure -workspace wire-ios-mono.xcworkspace -scheme WireSyncEngine -destination 'platform=iOS Simulator,OS=17.2,name=iPhone 14'
)
