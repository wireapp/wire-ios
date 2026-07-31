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

write_empty_outputs() {
  {
    echo "passed=0"
    echo "failed=0"
    echo "skipped=0"
    echo "total=0"
    echo "failed_details=None"
    echo "report_message="
  } >> "$GITHUB_OUTPUT"
}

if ! command -v jq >/dev/null 2>&1; then
  echo "[WARN] jq is not available on the runner"
  write_empty_outputs
  exit 0
fi

if ! xcrun --find xcresulttool >/dev/null 2>&1; then
  echo "[WARN] xcresulttool is not available on the runner"
  write_empty_outputs
  exit 0
fi

XCRESULTS=()
while IFS= read -r -d '' xcresult; do
  XCRESULTS+=("$xcresult")
done < <(find "$XCRESULT_SEARCH_PATH" -type d -name '*.xcresult' -print0 2>/dev/null || true)

if [ "${#XCRESULTS[@]}" -eq 0 ]; then
  write_empty_outputs
  exit 0
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
SUMMARY_FILE="$TMP_DIR/summaries.jsonl"
: > "$SUMMARY_FILE"

for XCRESULT in "${XCRESULTS[@]}"; do
  TESTS_JSON="$TMP_DIR/tests-$(basename "$XCRESULT").json"
  # Prefer the detailed test tree because it gives us stable per-test failure details.
  # If this subcommand is unavailable or fails for an older xcresult format, fall back
  # to the summary endpoint below instead of treating the whole bundle as unreadable.
  if xcrun xcresulttool get test-results tests --path "$XCRESULT" --compact > "$TESTS_JSON" 2>/dev/null; then
    jq -c '
      def normalize:
        tostring | gsub("[[:space:]]+"; " ") | .[0:240];

      def test_cases:
        [.. | objects | select(.nodeType? == "Test Case")];

      def failed_test_cases:
        test_cases | map(select((.result? // "" | ascii_downcase) == "failed"));

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

      def failure_message:
        ((.children // [])
          | map(select(.nodeType? == "Failure Message") | .name?)
          | map(select(. != null and . != ""))
          | first) // "No failure message available";

      def test_title:
        (.name? // "") as $testName
        | (.nodeIdentifier? // "") as $identifier
        | (.nodeIdentifierURL? // "") as $identifierURL
        | (
            if ($identifierURL | test("/[^/]+/[^/]+/[^/]+$")) then
              ($identifierURL | capture("/(?<target>[^/]+)/(?<class>[^/]+)/[^/]+$") | [.target, .class])
            elif ($identifier | test("/")) then
              ($identifier | split("/") | .[0:-1])
            else
              []
            end
          ) as $parents
        | (
            if $testName != "" then $testName
            elif ($identifier | test("/")) then ($identifier | split("/") | last)
            elif $identifier != "" then $identifier
            else "Unknown test"
            end
          ) as $test
        | ($parents + [$test] | map(select(. != null and . != "")) | join(" > "));

      {
        total: (test_cases | length),
        passed: (test_cases | map(select((.result? // "" | ascii_downcase) == "passed")) | length),
        failed: (failed_test_cases | length),
        skipped: (test_cases | map(select((.result? // "" | ascii_downcase) | test("skipped|expected"))) | length),
        testiny_passed_ids: (test_cases | map(select((.result? // "" | ascii_downcase) == "passed") | testiny_ids) | add // [] | unique),
        testiny_failed_ids: (failed_test_cases | map(testiny_ids) | add // [] | unique),
        testiny_skipped_ids: (test_cases | map(select((.result? // "" | ascii_downcase) | test("skipped|expected")) | testiny_ids) | add // [] | unique),
        failed_details: (
          failed_test_cases
          | map("  ❌ " + test_title + ": " + (failure_message | normalize))
          | unique
        )
      }
    ' "$TESTS_JSON" >> "$SUMMARY_FILE" || echo "[WARN] Could not parse test tree from $XCRESULT"
    continue
  fi

  RESULT_JSON="$TMP_DIR/result-$(basename "$XCRESULT").json"
  if ! xcrun xcresulttool get test-results summary --path "$XCRESULT" --compact > "$RESULT_JSON" 2>/dev/null; then
    echo "[WARN] Could not read test results from $XCRESULT"
    continue
  fi

  jq -c '
    def normalize:
      tostring | gsub("[[:space:]]+"; " ") | .[0:240];

    def failure_title:
      ([.targetName?, .testName?] | map(select(. != null and . != "")) | join(" > ")) as $title
      | if $title == "" then "Unknown test" else $title end;

    def failures:
      if (.testFailures == null) then
        []
      elif (.testFailures | type) == "array" then
        .testFailures
      elif (.testFailures | type) == "object" then
        if ((.testFailures | has("testName")) or (.testFailures | has("targetName")) or (.testFailures | has("failureText"))) then
          [.testFailures]
        else
          [.testFailures | .. | objects | select(has("testName") or has("targetName") or has("failureText"))]
        end
      else
        []
      end;

    {
      total: (.totalTestCount // 0),
      passed: (.passedTests // 0),
      failed: (.failedTests // 0),
      skipped: ((.skippedTests // 0) + (.expectedFailures // 0)),
      testiny_passed_ids: [],
      testiny_failed_ids: [],
      testiny_skipped_ids: [],
      failed_details: (
        failures
        | map("  ❌ " + failure_title + ": " + ((.failureText? // "No failure message available") | normalize))
        | unique
      )
    }
  ' "$RESULT_JSON" >> "$SUMMARY_FILE" || echo "[WARN] Could not parse test summary from $XCRESULT"
done

if [ ! -s "$SUMMARY_FILE" ]; then
  write_empty_outputs
  exit 0
fi

SUMMARY="$(jq -s -c '
  (map(.testiny_failed_ids // []) | add // [] | unique) as $testiny_failed
  | (map(.testiny_passed_ids // []) | add // [] | unique) as $testiny_passed
  | (map(.testiny_skipped_ids // []) | add // [] | unique) as $testiny_skipped
  | ($testiny_passed - $testiny_failed) as $testiny_passed_only
  | ($testiny_skipped - $testiny_failed - $testiny_passed) as $testiny_skipped_only
  | {
    total: (map(.total) | add // 0),
    passed: (map(.passed) | add // 0),
    failed: (map(.failed) | add // 0),
    skipped: (map(.skipped) | add // 0),
    testiny_total: (($testiny_failed + $testiny_passed_only + $testiny_skipped_only) | length),
    testiny_passed: ($testiny_passed_only | length),
    testiny_failed: ($testiny_failed | length),
    testiny_skipped: ($testiny_skipped_only | length),
    failed_details: ([.[].failed_details[]] | unique | .[:20])
  }
' "$SUMMARY_FILE")"

TOTAL="$(jq -r '.total' <<< "$SUMMARY")"
PASSED="$(jq -r '.passed' <<< "$SUMMARY")"
FAILED="$(jq -r '.failed' <<< "$SUMMARY")"
SKIPPED="$(jq -r '.skipped' <<< "$SUMMARY")"
TESTINY_TOTAL="$(jq -r '.testiny_total' <<< "$SUMMARY")"
TESTINY_PASSED="$(jq -r '.testiny_passed' <<< "$SUMMARY")"
TESTINY_FAILED="$(jq -r '.testiny_failed' <<< "$SUMMARY")"
TESTINY_SKIPPED="$(jq -r '.testiny_skipped' <<< "$SUMMARY")"
FAILED_DETAILS="$(jq -r '.failed_details | if length == 0 then "None" else join("\n") end' <<< "$SUMMARY")"

REPORT_MESSAGE="--------------------------------------
**XCTest Methods:** total ${TOTAL} | passed ${PASSED} | failed ${FAILED} | skipped ${SKIPPED}
--------------------------------------"

if [ "$TESTINY_TOTAL" -gt 0 ]; then
  REPORT_MESSAGE="${REPORT_MESSAGE}

**Total Testiny Test Cases:** ${TESTINY_TOTAL}
✅ **Passed:** ${TESTINY_PASSED}
❌ **Failed:** ${TESTINY_FAILED}
⏭️ **Skipped:** ${TESTINY_SKIPPED}
--------------------------------------"
fi

if [ "$FAILED" -gt 0 ] && [ "$FAILED_DETAILS" != "None" ]; then
  REPORT_MESSAGE="${REPORT_MESSAGE}

❌ **Failed Tests:**
${FAILED_DETAILS}"
fi

echo "passed=$PASSED" >> "$GITHUB_OUTPUT"
echo "failed=$FAILED" >> "$GITHUB_OUTPUT"
echo "skipped=$SKIPPED" >> "$GITHUB_OUTPUT"
echo "total=$TOTAL" >> "$GITHUB_OUTPUT"
{
  echo "failed_details<<__TEST_FAILED_DETAILS__"
  echo "$FAILED_DETAILS"
  echo "__TEST_FAILED_DETAILS__"
  echo "report_message<<__TEST_REPORT_MESSAGE__"
  echo "$REPORT_MESSAGE"
  echo "__TEST_REPORT_MESSAGE__"
} >> "$GITHUB_OUTPUT"
