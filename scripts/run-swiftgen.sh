#!/bin/bash
set -Eeuo pipefail

#
# Wire
# Copyright (C) 2023 Wire Swiss GmbH
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
SCRIPTS_DIR="$REPO_ROOT/scripts"
SWIFTGEN="$SCRIPTS_DIR/.build/artifacts/scripts/swiftgen/swiftgen.artifactbundle/swiftgen/bin/swiftgen"
SWIFTGEN_CONFIG_MAIN="$REPO_ROOT/wire-ios/swiftgen.yml" # path to main config
SWIFTGEN_CONFIG_SHARE_EXT="$REPO_ROOT/wire-ios/swiftgenShareExtension.yml" # path to share extension config

if [ ! -z "${CI-}" ]; then
    echo "Skipping SwiftGen in CI environment"
    exit 0
fi

if [[ ! -f "$SWIFTGEN" ]]; then
    xcrun --sdk macosx swift package --package-path "$SCRIPTS_DIR" resolve
fi

# Run SwiftGen for main app
(
    cd "$REPO_ROOT/wire-ios"
    if [[ -f "$SWIFTGEN_CONFIG_MAIN" ]]; then
        "$SWIFTGEN" config run --config "$SWIFTGEN_CONFIG_MAIN"
    else
        echo "SwiftGen config not found for main app: $SWIFTGEN_CONFIG_MAIN"
        exit 1
    fi
)

# Run SwiftGen for share extension
(
    cd "$REPO_ROOT/wire-ios"
    if [[ -f "$SWIFTGEN_CONFIG_SHARE_EXT" ]]; then
        "$SWIFTGEN" config run --config "$SWIFTGEN_CONFIG_SHARE_EXT"
    else
        echo "SwiftGen config not found for share extension: $SWIFTGEN_CONFIG_SHARE_EXT"
        exit 1
    fi
)

