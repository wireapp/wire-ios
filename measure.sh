#!/bin/bash
set -Eeuo pipefail

time \
xcodebuild build-for-testing \
  -workspace wire-ios-mono.xcworkspace \
  -scheme Wire-iOS \
  -testPlan AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 (Tests)' \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO
