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

XCRESULT_SEARCH_PATH="${1:-artifacts}"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "ALLURE_REPORT_AVAILABLE=false" >> "${GITHUB_ENV}"
  echo "ALLURE_REPORT_REASON=Report-generation step did not complete." >> "${GITHUB_ENV}"
fi

report_unavailable() {
  echo "::warning::$1"
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "ALLURE_REPORT_REASON=$1" >> "${GITHUB_ENV}"
  fi
}

echo "🔍 Searching for .xcresults under: ${XCRESULT_SEARCH_PATH}"

XCRESULTS=()
while IFS= read -r -d '' xc; do
  XCRESULTS+=("$xc")
done < <(find "${XCRESULT_SEARCH_PATH}" -type d -name "*.xcresult" -print0 2>/dev/null || true)

if [[ "${#XCRESULTS[@]}" -eq 0 ]]; then
  report_unavailable "No xcresult bundles found in the report search directory."
  exit 0
fi

rm -rf allure-reports
mkdir -p allure-reports

XCRESULT="${XCRESULTS[0]}"
if [[ "${#XCRESULTS[@]}" -gt 1 ]]; then
  MERGE_DIR="$(mktemp -d)"
  trap 'rm -rf "$MERGE_DIR"' EXIT
  XCRESULT="$MERGE_DIR/combined.xcresult"
  # Keep the merged bundle outside artifacts so other reporters only see originals.
  if ! xcrun xcresulttool merge --output-path "$XCRESULT" "${XCRESULTS[@]}"; then
    report_unavailable "xcresulttool could not merge the result bundles."
    exit 0
  fi
fi

if ! npx --yes allure awesome "$XCRESULT" --single-file -o allure-reports >/dev/null; then
  report_unavailable "Allure report generation failed. See the report-generation log."
  exit 0
fi

if [[ ! -f allure-reports/index.html ]]; then
  report_unavailable "Allure did not produce allure-reports/index.html."
  exit 0
fi

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "ALLURE_REPORT_AVAILABLE=true" >> "${GITHUB_ENV}"
  echo "ALLURE_REPORT_REASON=" >> "${GITHUB_ENV}"
fi

echo "✅ Allure report generated at ./allure-reports/index.html"
