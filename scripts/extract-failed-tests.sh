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

# Finds failed UI Testiny cases from local xcresult bundles, or from the last
# completed Critical Flows run on the same branch via the GH API.

ARTIFACT_PATTERN="${ARTIFACT_PATTERN:-XCResults for *}"
CURRENT_RUN_ID="${GITHUB_RUN_ID:-}"
WORKFLOW_FILE="${WORKFLOW_FILE:-critical_flows.yaml}"

if ! command -v jq >/dev/null 2>&1; then
  echo "[ERROR] jq is not available" >&2
  exit 1
fi

if ! xcrun --find xcresulttool >/dev/null 2>&1; then
  echo "[ERROR] xcresulttool is not available" >&2
  exit 1
fi

extract_failed_cases_from_path() {
  local search_path="$1"
  local tmp_dir ids_file xcresult tests_json
  local xcresults=()

  while IFS= read -r -d '' xcresult; do
    xcresults+=("$xcresult")
  done < <(find "$search_path" -type d -name '*.xcresult' -print0 2>/dev/null || true)

  if [ "${#xcresults[@]}" -eq 0 ]; then
    echo "[ERROR] No .xcresult found under $search_path" >&2
    return 1
  fi

  tmp_dir="$(mktemp -d)"
  ids_file="$tmp_dir/failed-testiny-ids.txt"
  : > "$ids_file"

  for xcresult in "${xcresults[@]}"; do
    tests_json="$tmp_dir/tests-$(basename "$xcresult").json"
    if ! xcrun xcresulttool get test-results tests --path "$xcresult" --compact > "$tests_json" 2>/dev/null; then
      echo "[WARN] Could not read test tree from $xcresult" >&2
      continue
    fi

    if ! jq -r '
      def test_cases:
        [.. | objects | select(.nodeType? == "Test Case")];

      def test_runs:
        [(.children // [])[] | select(.nodeType? == "Repetition" or .nodeType? == "Test Case Run")];

      def normalize_result:
        ((. // "") | ascii_downcase) as $result
        | if $result == "success" or $result == "passed" then "passed"
          elif $result == "failure" or $result == "failed" or $result == "error" then "failed"
          elif $result == "skipped" or $result == "expected failure" then "skipped"
          else $result
          end;

      def final_result:
        . as $test_case
        | (($test_case | test_runs) as $runs | if ($runs | length) > 0 then $runs[-1].result? else $test_case.result? end)
        | normalize_result;

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

      def testiny_test_cases:
        test_cases
        | map(select((testiny_ids | length) > 0))
        | sort_by(testiny_ids | join(","))
        | group_by(testiny_ids | join(","))
        | map(sort_by(test_runs | length) | .[-1]);

      testiny_test_cases
      | map(select(final_result == "failed") | testiny_ids)
      | add // []
      | unique
      | .[]
    ' "$tests_json" >> "$ids_file"; then
      echo "[WARN] Could not parse test tree from $xcresult" >&2
      continue
    fi
  done

  sort -u "$ids_file" | paste -sd, -
  rm -rf "$tmp_dir"
}

extract_failed_cases_from_github_runs() {
  local branch="$1"
  local run_filter run_id tmp_dir failed_cases

  if ! command -v gh >/dev/null 2>&1; then
    echo "[ERROR] gh is not available" >&2
    exit 1
  fi

  if [ -z "${GITHUB_REPOSITORY:-}" ]; then
    echo "[ERROR] GITHUB_REPOSITORY is not set" >&2
    exit 1
  fi

  if [ -n "$CURRENT_RUN_ID" ]; then
    run_filter=".workflow_runs[] | select(.id != ${CURRENT_RUN_ID}) | .id"
  else
    run_filter=".workflow_runs[].id"
  fi

  # Scoped to this workflow only: other workflows (nightly "Run develop tests",
  # manual "Run all tests") also produce an "XCResults for <branch> (...)" artifact
  # on the same branch, and would otherwise get picked up here by mistake.
  run_id="$(gh api \
    --method GET \
    "repos/${GITHUB_REPOSITORY}/actions/workflows/${WORKFLOW_FILE}/runs" \
    -f branch="$branch" \
    -f status=completed \
    -f per_page=5 \
    --jq "$run_filter" | head -n 1)"

  if [ -z "$run_id" ]; then
    echo "[ERROR] No previous completed '$WORKFLOW_FILE' run found for branch '$branch'" >&2
    exit 1
  fi

  echo "[INFO] Looking for failed UI Testiny cases in previous run $run_id" >&2

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  if ! gh run download "$run_id" --pattern "$ARTIFACT_PATTERN" --dir "$tmp_dir" >/dev/null 2>&1; then
    echo "[ERROR] No XCResult artifact found in run $run_id" >&2
    exit 1
  fi

  failed_cases="$(extract_failed_cases_from_path "$tmp_dir" || true)"
  if [ -z "$failed_cases" ]; then
    echo "[ERROR] Previous run $run_id had no failed Testiny cases to rerun" >&2
    exit 1
  fi

  echo "[INFO] Failed Testiny cases from run $run_id: $failed_cases" >&2
  echo "$failed_cases"
}

case "${1:-}" in
  --branch)
    extract_failed_cases_from_github_runs "${2:?Pass branch after --branch}"
    ;;
  *)
    extract_failed_cases_from_path "${1:-artifacts}"
    ;;
esac
