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

SEARCH_PATH="${1:-artifacts}"

if ! command -v jq >/dev/null 2>&1; then
  echo "[ERROR] jq is not available" >&2
  exit 1
fi

if ! xcrun --find xcresulttool >/dev/null 2>&1; then
  echo "[ERROR] xcresulttool is not available" >&2
  exit 1
fi

XCRESULTS=()
while IFS= read -r -d '' xcresult; do
  XCRESULTS+=("$xcresult")
done < <(find "$SEARCH_PATH" -type d -name '*.xcresult' -print0 2>/dev/null || true)

if [ "${#XCRESULTS[@]}" -eq 0 ]; then
  echo "[ERROR] No .xcresult found under $SEARCH_PATH" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
IDS_FILE="$TMP_DIR/failed-testiny-ids.txt"
: > "$IDS_FILE"

for XCRESULT in "${XCRESULTS[@]}"; do
  TESTS_JSON="$TMP_DIR/tests-$(basename "$XCRESULT").json"
  if ! xcrun xcresulttool get test-results tests --path "$XCRESULT" --compact > "$TESTS_JSON" 2>/dev/null; then
    echo "[WARN] Could not read test tree from $XCRESULT" >&2
    continue
  fi

  jq -r '
    def test_cases:
      [.. | objects | select(.nodeType? == "Test Case")];

    def test_runs:
      [(.children // [])[] | select(.nodeType? == "Repetition" or .nodeType? == "Test Case Run")];

    def final_result:
      ((test_runs | if length > 0 then .[-1].result? else .result? end) // "" | ascii_downcase);

    def testiny_ids_from_text:
      (tostring | gsub("[^A-Za-z0-9_]"; "_")) as $text
      | ($text | (capture("_TC_+(?<chain>.*)$"; "i")? // {}).chain? // "") as $chain
      | if $chain == "" then []
        else
          (
            reduce ($chain | split("_")[]) as $part (
              {active: true, ids: []};
              if .active == false then .
              elif ($part | ascii_downcase) == "tc" then .
              elif ($part | test("^\\d+$")) then .ids += [$part]
              elif $part == "" then .
              else .active = false
              end
            )
            | .ids
            | unique
          )
        end;

    def testiny_ids:
      [(.name? // ""), (.nodeIdentifier? // ""), (.nodeIdentifierURL? // "")]
      | map(testiny_ids_from_text)
      | add
      | unique;

    test_cases
    | map(select(final_result == "failed") | testiny_ids)
    | add // []
    | unique
    | .[]
  ' "$TESTS_JSON" >> "$IDS_FILE"
done

sort -u "$IDS_FILE" | paste -sd, -
