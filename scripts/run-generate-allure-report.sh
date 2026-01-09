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

echo "🔍 Searching for .xcresult under: ${XCRESULT_SEARCH_PATH}"

XCRESULT="$(find "${XCRESULT_SEARCH_PATH}" -type d -name "*.xcresult" | head -n 1 || true)"

if [[ -z "${XCRESULT}" ]]; then
  echo "⚠️  No .xcresult found under ./${XCRESULT_SEARCH_PATH}. Skipping Allure report generation."
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "ALLURE_REPORT_AVAILABLE=false" >> "${GITHUB_ENV}"
  fi
  exit 0
fi

echo "✅ Using xcresult: ${XCRESULT}"

echo "🧪 Generating Allure report…"
npx --yes allure awesome "${XCRESULT}" --single-file -o allure-report

if [[ ! -f "allure-report/index.html" ]]; then
  echo "❌ Allure report not generated (missing allure-report/index.html)" >&2
  exit 1
fi

FILE_SIZE="$(du -h allure-report/index.html | cut -f1)"
echo "✅ Allure report generated successfully (${FILE_SIZE})"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "ALLURE_REPORT_AVAILABLE=true" >> "${GITHUB_ENV}"
fi
