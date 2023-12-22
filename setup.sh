#!/bin/bash
set -Eeuo pipefail

#
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
local_xcode_version=`xcodebuild -version | head -n 1 | sed "s/Xcode //"`
LOCAL_XCODE_VERSION=( ${local_xcode_version//./ } )

repository_xcode_version=`cat .xcode-version`
REPOSITORY_XCODE_VERSION=( ${repository_xcode_version//./ } )


[[ ${LOCAL_XCODE_VERSION[0]} -gt ${REPOSITORY_XCODE_VERSION[0]} ||
( ${LOCAL_XCODE_VERSION[0]} -eq ${REPOSITORY_XCODE_VERSION[0]} && ${LOCAL_XCODE_VERSION[1]} -ge ${REPOSITORY_XCODE_VERSION[1]} ) ]] ||
die "Xcode version for the repository should be at least ${repository_xcode_version}. The current local version is ${local_xcode_version}. If you have multiple versions of Xcode installed, please run: sudo xcode-select --switch /Applications/Xcode_${repository_xcode_version}.app"

# SETUP

REPO_ROOT=$(git rev-parse --show-toplevel)

# Workaround for carthage "The file couldn’t be saved." error
rm -rf ${TMPDIR}/TemporaryItems/*carthage*

echo "ℹ️  Carthage bootstrap. This might take a while..."
if [[ -n "${CI-}" ]]; then
    echo "Skipping Carthage bootstrap from setup.sh script since CI is defined"
else 
    "$REPO_ROOT/scripts/carthage.sh" bootstrap --cache-builds --platform ios --use-xcframeworks
fi
echo ""

echo "ℹ️  Installing ImageMagick..."
if [[ -z "${CI-}" ]]; then # skip cache bootstrap for CI
    echo "Skipping ImageMagick install because not running on CI"
else
    which identify || brew install ImageMagick
fi 
echo ""

echo "ℹ️  Installing AWS CLI..."
if [[ -z "${CI-}" ]]; then # skip cache bootstrap for CI
    echo "Skipping AWS CLI install because not running on CI"
else
    which aws || (curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg" && sudo installer -pkg AWSCLIV2.pkg -target /)
fi 
echo ""

echo "ℹ️  Fetching submodules..."
    git submodule update --init --recursive || true
    git submodule sync --recursive || true
echo ""

echo "ℹ️  Installing bundler and Ruby dependencies..."
which bundle || gem install bundler
bundle check || bundle install
echo ""

echo "ℹ️  Overriding configuration if specified..."
scripts/override-configuration_if_needed.sh "$@"
echo "" 

echo "ℹ️  Doing additional postprocessing..."
scripts/postprocess.sh
echo ""

echo "ℹ️ Install Git hook"
scripts/githooks-install.sh
echo ""

(
    cd "$REPO_ROOT/wire-ios"

    echo "ℹ️  [CodeGen] Update StyleKit Icons..."
    swift run --package-path ./Scripts/updateStylekit
    echo ""

    echo "ℹ️ Update Licenses File..."
    swift run --package-path ./Scripts/updateLicenses
    echo ""
)

echo "✅  Wire project was set up, you can now open wire-ios-mono.xcworkspace"
