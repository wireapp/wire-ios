#!/bin/bash
set -Eeuo pipefail

# Dedicated build directories so cleaning here never touches Xcode's own caches.
# DerivedData is wiped before each run; SourcePackages (downloaded package
# sources and binary artifacts) is kept to avoid re-downloading.
DERIVED_DATA=".measure/DerivedData"
SOURCE_PACKAGES=".measure/SourcePackages"

rm -rf "$DERIVED_DATA"

# Resolve and download all packages up front so the timed build measures
# compilation only, not network fetches.
xcodebuild -resolvePackageDependencies \
  -workspace wire-ios-mono.xcworkspace \
  -scheme Wire-iOS \
  -derivedDataPath "$DERIVED_DATA" \
  -clonedSourcePackagesDirPath "$SOURCE_PACKAGES"

time \
xcodebuild build-for-testing \
  -workspace wire-ios-mono.xcworkspace \
  -scheme Wire-iOS \
  -testPlan AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 (Tests)' \
  -derivedDataPath "$DERIVED_DATA" \
  -clonedSourcePackagesDirPath "$SOURCE_PACKAGES" \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO
