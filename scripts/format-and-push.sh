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

# Runs the same steps as the Xcode "format & lint Swift code" build phase,
# then commits any resulting changes as "chore: fix format" and pushes them.

REPO_ROOT=$(git rev-parse --show-toplevel)
SCRIPTS_DIR="$REPO_ROOT/scripts"

# --- format & lint (mirrors the Xcode build phase) ---

# Format
"$SCRIPTS_DIR/run-swiftformat.sh" \
    "$REPO_ROOT"

# Lint
"$SCRIPTS_DIR/run-swiftlint.sh" \
    --fix \
    --no-cache \
    --quiet \
    "$REPO_ROOT"
"$SCRIPTS_DIR/run-swiftlint.sh" \
    --strict \
    --no-cache \
    --quiet \
    "$REPO_ROOT"

# --- commit & push ---

if git -C "$REPO_ROOT" diff --quiet; then
    echo "✅ No formatting changes to commit."
    exit 0
fi

echo "📝 Committing formatting changes…"
git -C "$REPO_ROOT" add -u
git -C "$REPO_ROOT" commit -m "chore: fix format"

BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)
echo "🚀 Pushing to origin/$BRANCH…"
git -C "$REPO_ROOT" push origin "$BRANCH"

echo "✅ Done."
