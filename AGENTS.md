# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

Wire iOS is a secure messaging app built as a monorepo (`wire-ios-mono.xcworkspace`). The codebase combines modern Swift Package Manager modules with legacy Carthage/Xcode framework projects. The primary workspace file is `wire-ios-mono.xcworkspace`.

## Prerequisites & Setup

- **Xcode**: version specified in `.xcode-version` (currently 26.1.1)
- **Carthage**: 0.39.1+
- **Ruby**: version in `Gemfile` (3.4.7), managed via rbenv
- **Git LFS**: required for binary files

Initial setup:
```sh
./setup.sh
```

To rebuild Carthage dependencies:
```sh
carthage bootstrap --platform ios --use-xcframeworks
```

## Build

Open `wire-ios-mono.xcworkspace` in Xcode and select the `Wire-iOS` scheme.

## Testing

Run security tests from the command line:
```sh
xcodebuild test \
  -workspace wire-ios-mono.xcworkspace \
  -scheme Wire-iOS \
  -testPlan SecurityTests \
  -destination 'platform=iOS Simulator,name=iPhone 14,OS=26.0.1'
```

Available test plans in `wire-ios/Tests/TestPlans/`:
- `AllTests.xctestplan` — all tests
- `UnitTests.xctestplan` — unit tests only
- `UITests.xctestplan` — UI tests only
- `SecurityTests.xctestplan` — security-specific tests
- `GermanLocaleTests.xctestplan` — German locale tests

The same `-testPlan` flag applies to the `WireSyncEngine` and `WireDataModel` schemes.

UI test methods **must** include a Testiny TC ID suffix, e.g. `testLogin_TC_1234`.

## Linting & Formatting

Both tools are distributed as SPM binary targets in `scripts/Package.swift`.

```sh
./scripts/run-swiftlint.sh    # lint
./scripts/run-swiftformat.sh  # format
```

Key rules enforced:
- **SwiftLint**: TODOs must reference a JIRA ticket — `// TODO: [WPB-123] description`
- **SwiftFormat**: max line width 120 chars, 4-space indent, imports sorted (`testable-last`)
- Every Swift file must begin with the GPL v3 license header (year 2026)

## Architecture

The app is layered. Data flows upward:

```
UI Layer          WireUI (SwiftUI) — WireDesign, WireConversationListUI, WireMainNavigationUI, etc.
                      ↑
Domain Layer      WireDomain — business logic, use cases, entity models
                      ↑
Sync Engine       wire-ios-sync-engine — network sync, push notifications, client-side logic
                      ↑
Data/Model        wire-ios-data-model (Core Data) + WireData (modern SPM layer)
                      ↑
Transport/Network wire-ios-transport + wire-ios-request-strategy + WireNetwork
```

Supporting modules (all SPM packages unless noted):
- **WireAuthentication** — login flows, SSO
- **WireCalling** — VoIP via AVS (open-source audio/video signaling)
- **WireCoreCrypto** — Proteus/MLS end-to-end encryption
- **WireMessaging** — messaging logic
- **WireBackup** — import/export
- **WireAnalytics** — analytics
- **WireLogging** — structured logging
- **WireFoundation** — shared utilities and test helpers
- **WireDebug** — debug-only tooling

Legacy Xcode projects (in their own subdirectories): `wire-ios-sync-engine/`, `wire-ios-data-model/`, `wire-ios-request-strategy/`, `wire-ios-transport/`, `wire-ios-system/`, `wire-ios-utilities/`, `wire-ios-testing/`, `wire-ios-images/`, `wire-ios-share-engine/`, `wire-ios-link-preview/`, `wire-ios-ziphy/`, `wire-ios-canvas/`.

Code generation: Sourcery generates mocks (`AutoMockable`), SwiftGen generates string/asset accessors. Run via `scripts/run-sourcery.sh` and `scripts/run-swiftgen.sh`.

## Conventions

- **Commits and PR titles** must reference a JIRA issue: `fix: description - WPB-XXXXX`
- Cherry-picked commits are marked with 🍒
- All colors in UI code must come from `WireDesign.ColorTheme` or `WireDesign.BaseColorPalette`
- New UI elements require `accessibilityLabel` / `accessibilityIdentifier` strings for VoiceOver
- UI elements that display text must use the API that supports dynamic type / large fonts
- Push notifications only work with the App Store-signed build (Apple security restriction)
- The open-source AVS library differs from the App Store version (proprietary call quality improvements)
