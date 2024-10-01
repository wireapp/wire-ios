#!/bin/bash
set -Eeuo pipefail

#
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
# along with this program. If not, see <http://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------


#
# USAGE:
# This scripts checks that the necessary tools are installed on the local machine
# and sets up the project so that it can be built with Xcode
#

function die { ( >&2 echo "$*"); exit 1; }

# CHECK PREREQUISITES

## Xcode
hash xcodebuild 2>/dev/null || die "Can't find Xcode, please install from the App Store"
local_xcode_version=`xcodebuild -version | sed -n "s/Xcode //p"`
LOCAL_XCODE_VERSION=( ${local_xcode_version//./ } )

repository_xcode_version=`cat .xcode-version`
REPOSITORY_XCODE_VERSION=( ${repository_xcode_version//./ } )


[[ ${LOCAL_XCODE_VERSION[0]} -gt ${REPOSITORY_XCODE_VERSION[0]} ||
( ${LOCAL_XCODE_VERSION[0]} -eq ${REPOSITORY_XCODE_VERSION[0]} && ${LOCAL_XCODE_VERSION[1]} -ge ${REPOSITORY_XCODE_VERSION[1]} ) ]] ||
die "Xcode version for the repository should be at least ${repository_xcode_version}. The current local version is ${local_xcode_version}. If you have multiple versions of Xcode installed, please run: sudo xcode-select --switch /Applications/Xcode_${repository_xcode_version}.app"

# SETUP

REPO_ROOT=$(git rev-parse --show-toplevel)
PACKAGES_DIR="$REPO_ROOT/DerivedData/CachedSwiftPackages"

if [[ -n "${CI-}" ]]; then
    echo "Running on CI, skipping git lfs install"
elif command -v git-lfs > /dev/null 2>&1; then
    echo "ℹ️  Running git lfs install..."
    git lfs install
else
    die "git-lfs is not installed."
fi
echo ""

# Workaround for carthage "The file couldn’t be saved." error
rm -rf ${TMPDIR}/TemporaryItems/*carthage*

echo "ℹ️  Carthage bootstrap. This might take a while..."
if [[ -n "${CI-}" ]]; then
    echo "Skipping Carthage bootstrap from setup.sh script since CI is defined"
else
    "$REPO_ROOT/scripts/carthage.sh" bootstrap --cache-builds --platform ios --use-xcframeworks
fi
echo ""

echo "ℹ️  Resolve Swift Packages for Scripts..."
#( cd $REPO_ROOT && xcodebuild -resolvePackageDependencies -clonedSourcePackagesDirPath "$PACKAGES_DIR" )
xcrun --sdk macosx swift package --package-path scripts resolve
xcrun --sdk macosx swift package --package-path SourceryPlugin resolve
echo ""

echo "ℹ️  Installing ImageMagick..."
if [[ -n "${CI-}" ]]; then
    # CI
    which identify || brew install ImageMagick
else
    # Local Machine
    echo "Skipping ImageMagick install because not running on CI"
fi
echo ""

echo "ℹ️  Installing AWS CLI..."
if [[ -n "${CI-}" ]]; then
    # CI
    which aws || (curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg" && sudo installer -pkg AWSCLIV2.pkg -target /)
else
    # Local Machine
    echo "Skipping AWS CLI install because not running on CI"
fi
echo ""

echo "ℹ️  Fetching submodules..."
    git submodule update --init --recursive || true
    git submodule sync --recursive || true
echo ""

echo "ℹ️  Installing bundler and Ruby dependencies..."
if [[ -n "${CI-}" ]]; then
    # CI
    echo "Skipping install since CI is defined"
else
    # Local machine
    which bundle || gem install bundler
    bundle check || bundle install
fi
echo ""

echo "ℹ️  Overriding configuration if specified..."
scripts/override-configuration_if_needed.sh "$@"
echo ""

echo "ℹ️  Generate Licenses"
if [[ -n "${CI-}" ]]; then
    # CI
    scripts/generate-licenses.sh
else
    # Local Machine
    # Skipped on local machines, because updating sdks, libraries etc. causes
    # Git changes when running this script, that can be easily forgotten.
    # We decided that the CI should always generate the latest licenses include it in delivered builds.
    echo "Skipping as CI is not is defined"
fi
echo ""

(
    cd "$REPO_ROOT/wire-ios"

    echo "ℹ️  [CodeGen] Update StyleKit Icons..."
    swift run --package-path ./Scripts/updateStylekit
    echo ""
)

echo "✅  Wire project was set up, you can now open wire-ios-mono.xcworkspace"

