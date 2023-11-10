#!/bin/bash

#
# Wire
# Copyright (C) 2018 Wire Swiss GmbH
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

# Get the root directory of the Git repository
REPO_ROOT=$(git rev-parse --show-toplevel)

# Define the source and destination paths for the hooks
HOOKS_SOURCE="$REPO_ROOT/.githooks"
HOOKS_DESTINATION="$REPO_ROOT/.git/hooks"

# Iterate over each file in the .githooks directory
for HOOK_FILE in "$HOOKS_SOURCE"/*; do
    # Get the filename of the hook
    HOOK_NAME=$(basename "$HOOK_FILE")

    # Define the destination path for the hook
    HOOK_DESTINATION="$HOOKS_DESTINATION/$HOOK_NAME"

    # Check if the hook already exists
    if [ -f "$HOOK_DESTINATION" ]; then
        # Check if the existing hook is a symlink
        if [ -L "$HOOK_DESTINATION" ]; then
            # Remove the existing symlink
            rm "$HOOK_DESTINATION"
            echo "Existing $HOOK_NAME hook symlink removed."
        else
            # Rename the existing hook to avoid conflicts
            mv "$HOOK_DESTINATION" "$HOOK_DESTINATION.old"
            echo "Existing $HOOK_NAME hook renamed to $HOOK_NAME.old."
        fi
    fi

    # Create a symlink to the new hook
    ln -svf "$HOOK_FILE" "$HOOK_DESTINATION"
    chmod +x "$HOOK_DESTINATION"

    echo "Installed $HOOK_NAME hook."
done

echo "Git hooks installed successfully."