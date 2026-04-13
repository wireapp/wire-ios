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

# Scans *.log files recursively for Objective-C runtime warnings about duplicate
# symbol implementations across modules (classes, protocols, categories, etc.).
#
# Usage: check_duplicate_classes.sh <log_dir>
#   log_dir  – directory to search for recursively *.log files (default: .)
#
# Exits with 1 if any duplicates are found, 0 otherwise.

set -euo pipefail

LOG_DIR="${1:-.}"
PATTERN="is implemented in both .+ and .+"

DUPLICATES=$(grep -rE "$PATTERN" "$LOG_DIR" --include='*.log' 2>/dev/null | sort -u || true)

if [ -n "$DUPLICATES" ]; then
    echo "::warning::Duplicate symbol implementations detected in test output!"
    echo ""
    echo "$DUPLICATES"
    echo ""
    echo "Each duplicate must be resolved — it can cause spurious casting failures and mysterious crashes at runtime."

    # Write to GitHub Actions job summary if available
    if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
        {
            echo "## Duplicate Symbol Implementations"
            echo ""
            echo "The following symbols are implemented in multiple modules:"
            echo ""
            echo '```'
            echo "$DUPLICATES"
            echo '```'
            echo ""
            echo "Each duplicate must be resolved — it can cause spurious casting failures and mysterious crashes at runtime."
        } >> "$GITHUB_STEP_SUMMARY"
    fi

    exit 1
fi

echo "No duplicate symbol implementations found."
