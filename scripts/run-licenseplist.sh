#!/bin/bash
set -Eeuo pipefail

# Wire
# Copyright (C) 2023 Wire Swiss GmbH
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

REPO_ROOT=$(git rev-parse --show-toplevel)
DIRECTORY="$REPO_ROOT/scripts"
LICENSEPLIST="$DIRECTORY/.build/artifacts/scripts/LicensePlist/LicensePlistBinary.artifactbundle/license-plist-3.25.1-macos/bin/license-plist"
PACKAGES_DIR="$REPO_ROOT/DerivedData/CachedSwiftPackages"
DOWNLOADS_DIR="$REPO_ROOT/DerivedData/LicensePlist-tmp"


# Resolve Executable

if [[ ! -f "$LICENSEPLIST" ]]; then

echo ""
echo "ℹ️  Resolve Executable"

xcrun --sdk macosx swift package --package-path "$DIRECTORY" resolve

fi


# Resolve Dependencies

echo ""
echo "ℹ️  Resolve Dependencies"

( cd $REPO_ROOT && xcodebuild -resolvePackageDependencies -clonedSourcePackagesDirPath "$PACKAGES_DIR" )


# Copy Dependencies

echo ""
echo "ℹ️  Copy Dependencies"

rm -rf "$DOWNLOADS_DIR"

cp -R "$PACKAGES_DIR" "$DOWNLOADS_DIR"

cp -Rf "$REPO_ROOT"/Carthage/Checkouts/* "$DOWNLOADS_DIR/checkouts"


# Generate Licenses

echo ""
echo "ℹ️  Generate Licenses"

"$LICENSEPLIST" --sandbox-mode --package-sources-path "$DOWNLOADS_DIR" "$@"
