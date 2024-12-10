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
CARTHAGE_URL="https://github.com/Carthage/Carthage/releases/download/0.40.0/Carthage.pkg"
CARTHAGE_DIR="$REPO_ROOT/Carthage"
CARTHAGE="$CARTHAGE_DIR/carthage-0.40.0"

if [[ ! -f "$CARTHAGE" ]]; then
    (
        mkdir -pv "$CARTHAGE_DIR"
        cd "$CARTHAGE_DIR"
        curl -LO "$CARTHAGE_URL"
        echo "48431b41db5da40998b84dfb4171f759bb9bb06b88d509818c3ad6b0e874113bb8bdd70eec7a81d0313a6f64127aac4e0f55ffed2379222544f98c945534f64c  Carthage.pkg" | shasum -a 512 -c
        pkgutil --expand-full ./Carthage.pkg ./Carthage_pkg
        mv -v \
            ./Carthage_pkg/CarthageApp.pkg/Payload/usr/local/bin/carthage \
            "$CARTHAGE"
        rm -rvf ./Carthage.pkg ./Carthage_pkg
    )
fi

"$CARTHAGE" "$@"
