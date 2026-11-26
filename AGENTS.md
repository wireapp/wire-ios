# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

Wire iOS is a secure messaging app built as a monorepo (`wire-ios-mono.xcworkspace`). The codebase combines modern Swift Package Manager modules with legacy Carthage/Xcode framework projects. The primary workspace file is `wire-ios-mono.xcworkspace`.

IMPORTANT: You should never look at `wire-ios-build-assets` directory and its content.

## Agent Workflow

- Implement small, clear, low-risk changes directly when requested. Before making broad, high-risk, multi-file, or still-debatable changes, discuss the proposed approach and ask for confirmation.

## Code Review and Pull Request Guidelines

### Review scope and findings

- Establish the actual PR base branch from PR metadata or the user's instructions before reviewing. Do not assume `develop`; release fixes may target a release branch. Ask if the base cannot be determined.
- Gather context with `git log <base>..HEAD`, `git diff --stat <base>...HEAD`, and `git diff --name-only <base>...HEAD`, then read the diff and relevant surrounding code. For an existing PR, review its current head; keep uncommitted local changes separate.
- Check correctness, regressions, security, error handling, and relevant test coverage. For UI changes, also check dynamic type, theme colors, and VoiceOver support against the conventions below.
- Report actionable findings using conventional comments, with a precise code location, the triggering condition, and the impact. Distinguish blocking defects from optional suggestions; avoid speculative findings and unrelated cleanup.
- State what was verified, which tests were run, and any remaining verification gaps. If no actionable findings remain, say so without implying that unrun tests passed.
- A review request alone does not authorize pushing changes, creating a PR, posting review comments, or merging.

### PR title and description

- Verify that the title and description match the committed diff against the actual base. Mention only changes present in that diff.
- Use `type: short description - WPB-XXXXX` for the title, replacing the example ticket with the real Jira identifier. Find it in the branch name, then commit messages; ask if it is missing or ambiguous. Never invent a ticket or leave a placeholder.
- Use `.github/pull_request_template.md`, preserve its Jira markers verbatim, and retain Testing, Checklist, and UI accessibility checklist sections. Remove template prompts and optional paragraphs that do not apply; mark checklist items complete only when verified.
- For bug fixes, use Issue, Cause, and Solution sections: state the broken behavior in one sentence, explain the cause in prose, and describe the solution concisely.
- For features, open with a short active description such as "This PR adds…", followed by a Changes section. Omit Changes for a self-explanatory fix.
- Keep prose direct and free of filler. In Changes, use action verbs such as Added, Updated, and Introduced; refer to class names in backticks instead of file paths, and omit file extensions when naming files. Omit `project.pbxproj` from the narrative Changes list, but still review its diff.
- Write manual testing instructions as imperative steps with expected results. Use bold headers only for prerequisites or non-obvious expected results. Distinguish instructions to run from tests actually completed.

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
- Write scripts (CI, tooling, automation) in Ruby when possible, under `scripts/`, using only the standard library; avoid inline JS/Python in workflows
- Code review uses [conventional comments](https://conventionalcomments.org/)
- Cherry-picked commits are marked with 🍒
- All colors in UI code must come from `WireDesign.ColorTheme` or `WireDesign.BaseColorPalette`
- New UI elements require `accessibilityLabel` for VoiceOver / `accessibilityIdentifier` for UI tests
- UI elements that display text must use the API that supports dynamic type / large fonts
- Push notifications only work with the App Store-signed build (Apple security restriction)


