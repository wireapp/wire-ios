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

echo "🔍 Searching for .xcresults under: ${XCRESULT_SEARCH_PATH}"

XCRESULTS=()
while IFS= read -r -d '' xc; do
  XCRESULTS+=("$xc")
done < <(find "${XCRESULT_SEARCH_PATH}" -type d -name "*.xcresult" -print0 2>/dev/null || true)

if [[ "${#XCRESULTS[@]}" -eq 0 ]]; then
  echo "⚠️  No .xcresult found under ./${XCRESULT_SEARCH_PATH}. Skipping Allure report generation."
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "ALLURE_REPORT_AVAILABLE=false" >> "${GITHUB_ENV}"
  fi
  exit 0
fi

rm -rf allure-reports
mkdir -p allure-reports

GENERATED_ANY=false

for XCRESULT in "${XCRESULTS[@]}"; do
  # Prefer parent schema name
  SCHEME="$(basename "$(dirname "${XCRESULT}")")"
  if [[ -z "${SCHEME}" ]]; then
    SCHEME="$(basename "${XCRESULT}")"
    SCHEME="${SCHEME%.xcresult}"
  fi

  OUT_DIR="allure-reports/${SCHEME}"

  rm -rf "${OUT_DIR}"
  mkdir -p "${OUT_DIR}"

  echo "🧪 Allure: ${SCHEME}"
  if ! npx --yes allure awesome "${XCRESULT}" --single-file -o "${OUT_DIR}" >/dev/null; then
    echo "⚠️  Allure generation failed for '${SCHEME}' (continuing)"
    continue
  fi

  if [[ -f "${OUT_DIR}/index.html" ]]; then
    GENERATED_ANY=true
  else
    echo "⚠️  Missing ${OUT_DIR}/index.html for '${SCHEME}' (continuing)"
  fi
done

if [[ -n "${GITHUB_ENV:-}" ]]; then
  if [[ "${GENERATED_ANY}" == "true" ]]; then
    echo "ALLURE_REPORT_AVAILABLE=true" >> "${GITHUB_ENV}"
  else
    echo "ALLURE_REPORT_AVAILABLE=false" >> "${GITHUB_ENV}"
  fi
fi

if [[ "${GENERATED_ANY}" == "true" ]]; then
  echo "✅ Allure reports generated under ./allure-reports"
else
  echo "⚠️  No Allure reports were generated."
fi
