# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

Wire iOS is a secure messaging app built as a monorepo (`wire-ios-mono.xcworkspace`). The codebase combines modern Swift Package Manager modules with legacy Carthage/Xcode framework projects. The primary workspace file is `wire-ios-mono.xcworkspace`.

## Prerequisites & Setup

- **Xcode**: version specified in `.xcode-version`
- **Carthage**: 0.39.1+
- **Ruby**: version in `.ruby-version`, managed via `rbenv`
- **Git LFS**: required for binary files

Initial setup:
```sh
./setup.sh
```

To update or rebuild dependencies, just re-run the `setup.sh` script when needed.

## Build

Open `wire-ios-mono.xcworkspace` in Xcode and select the `Wire-iOS` scheme.

## Testing

All the commands for testing are used via fastlane. This is what the CI executes. See `fastlane/README.md` for the common commands.

Note that the simulator model and OS version can be read in `fastlane/.env`

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
UITests require a special env, that is filled by 1password command. See `wire-ios/WireUITests/README` for more information
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

- **Commits and PR titles** must reference a JIRA issue: `fix: description - WPB-XXXXX` - see [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- Code review uses [conventional comments](https://conventionalcomments.org/)
- Cherry-picked commits are marked with 🍒
- All colors in UI code must come from `WireDesign.ColorTheme` or `WireDesign.BaseColorPalette`
- Push notifications only work with the App Store-signed build (Apple security restriction)

## Accessibility

Every new screen or UI element must pass the following checklist before merging:

### Identifiers and labels
- Set `accessibilityIdentifier` on every new element — **never remove existing ones** (QA automation depends on them)
- Set `accessibilityLabel` for VoiceOver on every interactive or informative element
- Set `accessibilityHint` to describe the result of an action (e.g. "Double tap to open profile"); omit it when the label already makes the outcome obvious
- Set `accessibilityValue` for elements with dynamic state (e.g. a text field's current content)
- VoiceOver reads in order: **label → value → trait → hint**
- Put all VoiceOver strings in `Accessibility.strings`, not `Localizable.strings`

### Traits
- Assign the correct trait to every custom element (all native elements already have traits): `.button`, `.header`, `.staticText`, `.link`, `.selected`, etc.
- Combine traits when needed (e.g. `.button` + `.selected` for a selected toggleable button)

### Hiding elements
- Hide purely decorative elements with `accessibilityHidden(true)` / `isAccessibilityElement = false`
- When a container element expresses the full meaning, hide its children and set the label/trait/hint on the container (use `.accessibilityElement(children: .ignore)` in SwiftUI)

### Navigation bar
- All navigation bar buttons must have alternative text
- Back buttons must describe the destination (e.g. "Go back to Settings", not just "Back") in the accessibilityLabel (no button's title visible)

### Dynamic content
- When content changes dynamically (list updates, search results, state transitions), post a UIAccessibility notification:
  - `.layoutChanged` — an element appeared or disappeared
  - `.screenChanged` — the major portion of the screen changed
  - `.announcement` — a brief status message (e.g. "Loading…")

### Dynamic type
- UI elements that display text must use the API that supports dynamic type / large fonts
- Test with the largest accessibility font size (Settings → Accessibility → Larger Text)