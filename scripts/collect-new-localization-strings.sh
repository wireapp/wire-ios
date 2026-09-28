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

# Finds localization keys added between BASE_SHA and HEAD_SHA and writes
# `has_new_strings` / `new_keys` / `message` to GITHUB_OUTPUT.
#
# Required env: BASE_SHA, HEAD_SHA, PR_TITLE, PR_AUTHOR, PR_URL, GITHUB_OUTPUT.

: "${BASE_SHA:?BASE_SHA is required}"
: "${HEAD_SHA:?HEAD_SHA is required}"
: "${PR_TITLE:?PR_TITLE is required}"
: "${PR_AUTHOR:?PR_AUTHOR is required}"
: "${PR_URL:?PR_URL is required}"

# Localization values come from the PR itself, so a value that happens to
# contain a line matching a fixed heredoc delimiter (e.g. "EOF") could
# truncate or corrupt the output. Use a random delimiter instead.
DELIM="EOF_$(uuidgen)"

NEW_KEYS=""

# .strings files: report keys whose name doesn't exist in the base file yet
# (a value-only edit of an existing key also shows up as a "+" diff line, so
# we compare key sets rather than diff output).
CHANGED_STRINGS=$(git diff --name-only "$BASE_SHA" "$HEAD_SHA" \
  | grep -E '(en|Base)\.lproj/.*\.strings$' \
  | grep -v 'vendor/' \
  | grep -v 'Carthage/') || true

if [ -n "$CHANGED_STRINGS" ]; then
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    BASE_KEYS=$(git show "$BASE_SHA:$file" 2>/dev/null \
      | grep -oE '^"[^"]+" *=' \
      | sed -E 's/^"([^"]*)".*/\1/') || true
    HEAD_LINES=$(git show "$HEAD_SHA:$file" 2>/dev/null \
      | grep -E '^"[^"]+" *= *"') || true
    [ -z "$HEAD_LINES" ] && continue

    while IFS= read -r line; do
      [ -z "$line" ] && continue
      key=$(echo "$line" | sed -E 's/^"([^"]*)".*/\1/')
      if ! printf '%s\n' "$BASE_KEYS" | grep -qxF "$key"; then
        value=$(echo "$line" | sed -E 's/^"[^"]*" *= *"(.*)";.*/\1/')
        ENTRY="\`$key\` = \"$value\""
        if [ -n "$NEW_KEYS" ]; then
          NEW_KEYS="$NEW_KEYS"$'\n'"$ENTRY"
        else
          NEW_KEYS="$ENTRY"
        fi
      fi
    done <<< "$HEAD_LINES"
  done <<< "$CHANGED_STRINGS"
fi

# Compare base and head key sets.
CHANGED_XCSTRINGS=$(git diff --name-only "$BASE_SHA" "$HEAD_SHA" \
  | grep '\.xcstrings$' \
  | grep -v 'vendor/' \
  | grep -v 'Carthage/') || true

if [ -n "$CHANGED_XCSTRINGS" ]; then
  for file in $CHANGED_XCSTRINGS; do
    BASE_STRING_KEYS=$(git show "$BASE_SHA:$file" 2>/dev/null | jq -r '.strings | keys[]' 2>/dev/null) || true
    HEAD_STRING_KEYS=$(git show "$HEAD_SHA:$file" 2>/dev/null | jq -r '.strings | keys[]' 2>/dev/null) || true
    [ -z "$HEAD_STRING_KEYS" ] && continue

    NEW_IN_FILE=$(comm -13 \
      <(printf '%s\n' "$BASE_STRING_KEYS" | sort) \
      <(printf '%s\n' "$HEAD_STRING_KEYS" | sort)) || true

    while IFS= read -r key; do
      [ -z "$key" ] && continue
      EN_VALUE=$(jq -r --arg k "$key" \
        '.strings[$k].localizations.en.stringUnit.value // "(no English value)"' "$file")
      ENTRY="\`$key\` = \"$EN_VALUE\""
      if [ -n "$NEW_KEYS" ]; then
        NEW_KEYS="$NEW_KEYS"$'\n'"$ENTRY"
      else
        NEW_KEYS="$ENTRY"
      fi
    done <<< "$NEW_IN_FILE"
  done
fi

if [ -n "$NEW_KEYS" ]; then
  echo "has_new_strings=true" >> "$GITHUB_OUTPUT"
  {
    echo "new_keys<<$DELIM"
    echo "$NEW_KEYS"
    echo "$DELIM"
  } >> "$GITHUB_OUTPUT"

  TICKET=$(echo "$PR_TITLE" | grep -oiE 'WPB-[0-9]+' | tr 'a-z' 'A-Z' | head -1 || true)
  if [ -n "$TICKET" ]; then
    TICKET_LINE="**Jira ticket:** [$TICKET](https://wearezeta.atlassian.net/browse/$TICKET)"
  else
    TICKET_LINE="**Jira ticket:** none found in PR title"
  fi

  BULLET_LIST=$(echo "$NEW_KEYS" | sed 's/^/- /')
  MESSAGE=$(printf 'New localization strings added\n\n%s\n\n%s\n**Author:** %s\n**PR:** %s' \
    "$BULLET_LIST" "$TICKET_LINE" "$PR_AUTHOR" "$PR_URL")
  {
    echo "message<<$DELIM"
    echo "$MESSAGE"
    echo "$DELIM"
  } >> "$GITHUB_OUTPUT"
else
  echo "has_new_strings=false" >> "$GITHUB_OUTPUT"
fi
