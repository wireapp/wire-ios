#!/bin/bash
set -Eeuo pipefail

#
# Wire
# Copyright (C) 2018 Wire Swiss GmbH
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
SWIFTLINT="$SCRIPTS_DIR/.build/artifacts/scripts/SwiftLintBinary/SwiftLintBinary.artifactbundle/swiftlint-0.53.0-macos/bin/swiftlint"

if [ -z "${CI-}" ]; then
    xcrun --sdk macosx swift package --sdk macos --package-path "$SCRIPTS_DIR" resolve
    "$SWIFTLINT" --config "$REPO_ROOT/.swiftlint.yml"
else
    echo "Skipping SwiftLint in CI environment"
fi
