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

# Runs the same format & lint steps as the Xcode "format & lint Swift code"
# build phase. Optionally commits the resulting changes as "chore: fix format"
# and pushes them.
#
# By default only the Swift files you changed (vs HEAD, plus new untracked
# files) are processed — this is dramatically faster than sweeping the whole
# repo and is safe because these tools only run locally.
#
# Options:
#   --all     full-repo sweep (exact Xcode build-phase parity) instead of just
#             the changed files
#   --push    after formatting, commit the changes as "chore: fix format" and
#             push to the current branch's remote
#
# Usage:
#   format.sh                 format/lint changed files only (no commit)
#   format.sh --push          format/lint changed files, then commit & push
#   format.sh --all           full-repo sweep (used by the Xcode target)
#   format.sh --all --push    full-repo sweep, then commit & push

REPO_ROOT=$(git rev-parse --show-toplevel)
SCRIPTS_DIR="$REPO_ROOT/scripts"

ALL=false
PUSH=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --all) ALL=true; shift ;;
        --push) PUSH=true; shift ;;
        *) echo "❌ Unknown option: $1" >&2; exit 1 ;;
    esac
done

# --- collect targets ---

TARGETS=()
if $ALL; then
    TARGETS=("$REPO_ROOT")
else
    while IFS= read -r f; do
        [[ -n "$f" ]] && TARGETS+=("$REPO_ROOT/$f")
    done < <(
        {
            # tracked files changed vs HEAD (staged + unstaged), excluding deletions
            git -C "$REPO_ROOT" diff --name-only --diff-filter=d HEAD -- '*.swift'
            # new files not yet tracked
            git -C "$REPO_ROOT" ls-files --others --exclude-standard -- '*.swift'
        } | sort -u
    )

    if [[ ${#TARGETS[@]} -eq 0 ]]; then
        echo "✅ No changed Swift files. (Use --all for a full-repo sweep.)"
        exit 0
    fi
    echo "🔍 Formatting ${#TARGETS[@]} changed Swift file(s)."
fi

# --- format & lint (mirrors the Xcode build phase) ---

# Format
"$SCRIPTS_DIR/run-swiftformat.sh" \
    "${TARGETS[@]}"

# Lint
"$SCRIPTS_DIR/run-swiftlint.sh" \
    --fix \
    --no-cache \
    --quiet \
    "${TARGETS[@]}"
"$SCRIPTS_DIR/run-swiftlint.sh" \
    --strict \
    --no-cache \
    --quiet \
    "${TARGETS[@]}"

# --- commit & push (only with --push) ---

if ! $PUSH; then
    echo "✅ Format & lint complete."
    exit 0
fi

if git -C "$REPO_ROOT" diff --quiet; then
    echo "✅ No formatting changes to commit."
    exit 0
fi

echo "📝 Committing formatting changes…"
git -C "$REPO_ROOT" add -u
git -C "$REPO_ROOT" commit -m "chore: fix format"

BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)
echo "🚀 Pushing to origin/${BRANCH}…"
git -C "$REPO_ROOT" push origin "$BRANCH"

echo "✅ Done."
