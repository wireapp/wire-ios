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
SWIFTGEN="$REPO_ROOT/scripts/.build/artifacts/scripts/swiftgen/swiftgen.artifactbundle/swiftgen/bin/swiftgen"

if [ ! -z "${CI-}" ]; then
    echo "Skipping SwiftGen in CI environment"
    exit 0
fi

if [[ ! -f "$SWIFTGEN" ]]; then
    echo "❌ Executable is missing, please run the setup script!"
fi

(
    cd "$REPO_ROOT/wire-ios"
    "$SWIFTGEN" "$@"
)
