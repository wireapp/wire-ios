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

ALLURE_ARTIFACT_NAME="${1:?allure_artifact_name is required}"

OWNER="${GITHUB_REPOSITORY%/*}"
REPO="${GITHUB_REPOSITORY#*/}"
RUN_ID="${GITHUB_RUN_ID}"
SERVER_URL="${GITHUB_SERVER_URL}"

ALLURE_ARTIFACT_URL="${SERVER_URL}/${OWNER}/${REPO}/actions/runs/${RUN_ID}"

echo "🔎 Resolving Allure artifact URL for: ${ALLURE_ARTIFACT_NAME}"

ARTIFACT_ID=$(gh api \
  "/repos/${OWNER}/${REPO}/actions/runs/${RUN_ID}/artifacts?per_page=100" \
  --jq ".artifacts[] | select(.name == \"${ALLURE_ARTIFACT_NAME}\") | .id" \
  | head -n 1 || true)

if [[ -n "${ARTIFACT_ID}" ]]; then
  ALLURE_ARTIFACT_URL="${SERVER_URL}/${OWNER}/${REPO}/actions/runs/${RUN_ID}/artifacts/${ARTIFACT_ID}"
  echo "✅ Allure artifact found (id=${ARTIFACT_ID})"
else
  echo "⚠️ Allure artifact not found: ${ALLURE_ARTIFACT_NAME}" >&2
fi

# Export for subsequent steps
echo "ALLURE_ARTIFACT_NAME=${ALLURE_ARTIFACT_NAME}" >> "$GITHUB_ENV"
echo "ALLURE_ARTIFACT_URL=${ALLURE_ARTIFACT_URL}" >> "$GITHUB_ENV"

