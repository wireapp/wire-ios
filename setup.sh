#!/bin/bash
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

set -e

function die { ( >&2 echo "$*"); exit 1; }

# CHECK PREREQUISITES
hash carthage 2>/dev/null || die "Can't find Carthage, please install from https://github.com/Carthage/Carthage"
hash xcodebuild 2>/dev/null || die "Can't find Xcode, please install from the App Store"

version=`carthage version | tail -n 1`
CARTHAGE_VERSION=( ${version//./ } )
version=`xcodebuild -version | head -n 1 | sed "s/Xcode //"`
XCODE_VERSION=( ${version//./ } )

[[ ${CARTHAGE_VERSION[0]} -gt 0 || ${CARTHAGE_VERSION[1]} -ge 38 ]] || die "Carthage should be at least version 0.38"
[[ ${XCODE_VERSION[0]} -gt 14 || ( ${XCODE_VERSION[0]} -eq 14 && ${XCODE_VERSION[1]} -ge 2 ) ]] || die "Xcode version should be at least 14.2. The current version is ${XCODE_VERSION}. If you have multiple versions of Xcode installed, please run: sudo xcode-select --switch /Applications/Xcode_14.2.app/Contents/Developer"

# SETUP

# Workaround for carthage "The file couldn’t be saved." error
rm -rf ${TMPDIR}/TemporaryItems/*carthage*

echo "ℹ️  Carthage bootstrap. This might take a while..."
if [[ -n "${CIRRUS_BUILD_ID}" ]]; then
    echo "Skipping Carthage bootstrap from setup.sh script since CI or CIRRUS_BUILD_ID is defined"
else 
    carthage bootstrap --cache-builds --platform ios --use-xcframeworks
fi
echo ""

echo "ℹ️  Installing ImageMagick..."
if [[ -z "${CIRRUS_BUILD_ID}" ]]; then # skip cache bootstrap for CI
    echo "Skipping ImageMagick install because not running on Cirrus-CI"
else
    which identify || brew install ImageMagick
fi 
echo ""

echo "ℹ️  Installing AWS CLI..."
if [[ -z "${CIRRUS_BUILD_ID}" ]]; then # skip cache bootstrap for CI
    echo "Skipping AWS CLI install because not running on Cirrus-CI"
else
    which aws || curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg" && sudo installer -pkg AWSCLIV2.pkg -target /
fi 
echo ""

echo "ℹ️  Installing bundler and Ruby dependencies..."
which bundle || gem install bundler
bundle check || bundle install
echo ""

echo "ℹ️  Downloading additional assets..."
scripts/download-assets.sh "$@"
echo "" 

echo "ℹ️  Doing additional postprocessing..."
scripts/postprocess.sh
echo ""

cd wire-ios

echo "ℹ️  [CodeGen] Update StyleKit Icons..."
swift run --package-path Scripts/updateStylekit
echo ""

echo "ℹ️ Update Licenses File..."
swift run --package-path Scripts/updateLicenses
echo ""

cd ..

echo "✅  Wire project was set up, you can now open wire-ios-mono.xcworkspace"
