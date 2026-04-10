#!/bin/bash
# Scans xcodebuild log files for Objective-C runtime warnings about
# duplicate class implementations across modules.
#
# Usage: check_duplicate_classes.sh <log_dir>
#   log_dir  – directory to search for xcodebuild*.log files (default: .)
#
# Exits with 1 if any duplicates are found, 0 otherwise.

set -euo pipefail

LOG_DIR="${1:-.}"
PATTERN="Class .+ is implemented in both .+ and .+"

DUPLICATES=$(grep -rEo "$PATTERN" "$LOG_DIR" --include='*.log' 2>/dev/null | sort -u || true)

if [ -n "$DUPLICATES" ]; then
    echo "::error::Duplicate class implementations detected in test output!"
    echo ""
    echo "$DUPLICATES"
    echo ""
    echo "Each duplicate must be resolved — it can cause spurious casting failures and mysterious crashes at runtime."
    exit 1
fi

echo "No duplicate class implementations found."
