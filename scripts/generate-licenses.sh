#!/bin/bash
set -Eeuo pipefail

# Wire
# Copyright (C) 2024 Wire Swiss GmbH
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

# Technical Details
# 
# The tool `LicensePlist` has two modes that differ in essence:
# 
# 1. No Sandbox Mode / Online
# This mode requests all Swift Packages from the remote URLs, which seems convenient at first.
# However, it quickly reaches the GitHub API limit and suggests providing a GitHub token.
# Nevertheless, during development, I ran into API limits again because the project fetches 25+ licenses in parallel.
#
# 2. Sandbox Mode / Offline
# This mode allows you to work offline by providing a source path.
# Unfortunately, it seems to look only for Swift Packages and can no longer find the Carthage licenses.
# Therefore, the implemented workaround is to merge the SPM and Carthage folders into one temporary folder and generate licenses from it.
# Additionally, SPM binaries are not supported, so you need to download the LICENSE file manually and add it to the configuration.

REPO_ROOT=$(git rev-parse --show-toplevel)
LICENSEPLIST="$REPO_ROOT/scripts/.build/artifacts/scripts/LicensePlist/LicensePlistBinary.artifactbundle/license-plist-3.25.1-macos/bin/license-plist"
PACKAGES_DIR="$REPO_ROOT/DerivedData/CachedSwiftPackages"
TMP_DIR="$REPO_ROOT/DerivedData/Generate-Licenses"

# Cleanup old artifacts
rm -rf "$TMP_DIR"

# Resolve Dependencies
echo ""
echo "ℹ️  Resolve Dependencies"
#( cd $REPO_ROOT && xcodebuild -resolvePackageDependencies -clonedSourcePackagesDirPath "$PACKAGES_DIR" )


# Copy Dependencies
echo ""
echo "ℹ️  Copy Dependencies"

### Swift Packages
cp -R "$PACKAGES_DIR" "$TMP_DIR"

### Carthage
cp -Rf "$REPO_ROOT"/Carthage/Checkouts/* "$TMP_DIR/checkouts"


# Generate Licenses
echo ""
echo "ℹ️  Generate Licenses"
"$LICENSEPLIST" --package-sources-path "$TMP_DIR" --config-path ".license_plist.yml"
