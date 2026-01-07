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

COMMENT_TITLE="${1:?comment_title is required}"
ALLURE_ARTIFACT_NAME="${2:?allure_artifact_name is required}"

OWNER="${GITHUB_REPOSITORY%/*}"
REPO="${GITHUB_REPOSITORY#*/}"

PR_NUMBER="${GITHUB_REF#refs/pull/}"
PR_NUMBER="${PR_NUMBER%/merge}"

ALLURE_URL="${ALLURE_ARTIFACT_URL:-${GITHUB_SERVER_URL}/${OWNER}/${REPO}/actions/runs/${GITHUB_RUN_ID}}"

MARKER_START='<!-- allure-link-start -->'
MARKER_END='<!-- allure-link-end -->'
BLOCK="${MARKER_START}

**Allure report: ** [${ALLURE_ARTIFACT_NAME}](${ALLURE_URL})

${MARKER_END}"

COMMENTS_JSON=$(gh api \
  "/repos/${OWNER}/${REPO}/issues/${PR_NUMBER}/comments?per_page=100")

COMMENT_ID=$(echo "$COMMENTS_JSON" | jq -r \
  --arg title "$COMMENT_TITLE" \
  '.[] | select(.body | contains($title)) | .id' | head -n 1)

if [[ -z "$COMMENT_ID" || "$COMMENT_ID" == "null" ]]; then
  echo "⚠️ Comment with title '${COMMENT_TITLE}' not found; skipping patch"
  exit 0
fi

BODY=$(echo "$COMMENTS_JSON" | jq -r \
  --argjson id "$COMMENT_ID" \
  '.[] | select(.id == $id) | .body')

if [[ "$BODY" == *"$MARKER_START"* && "$BODY" == *"$MARKER_END"* ]]; then
  BODY="$(printf '%s' "$BODY" | sed "/$MARKER_START/,/$MARKER_END/d")"
fi

BODY="${BODY%$'\n'}"$'\n\n'"${BLOCK}"

gh api \
  -X PATCH \
  "/repos/${OWNER}/${REPO}/issues/comments/${COMMENT_ID}" \
  -f body="$BODY"

echo "✅ Allure link patched into PR comment (id=${COMMENT_ID})"

