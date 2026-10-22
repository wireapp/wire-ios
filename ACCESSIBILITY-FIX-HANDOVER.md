# First accessibility fixes — session handover

Prepared October 22, 2026. This is an implementation handover, not a request to
repeat the backlog estimation. No fixes have been implemented yet.

## Task and Git state

- Work in `/Users/christoph/Developer/caldrian/wire-ios`.
- Current branch: `fix/accessibility-labels`, based on
  `github/release/cycle-4.16` at `7bb6a45a1fd6758d610328a815f69e7bbb66976d`.
- Implement the three small tickets below. User's latest preference: **one
  initial combined commit is fine**. This supersedes the earlier request for
  one commit per ticket. User may later split work into separate/stacked PRs;
  keep each ticket's code and string changes easy to identify.
- Do not create PRs, push, split branches, or start another chat automatically.
  The user intends to start the fresh session themselves.
- This handover is deliberately uncommitted so it can accompany the initial
  combined fix commit. No new implementation files have been edited.
- Existing unrelated working-tree changes, observed after the user switched
  branches: `.ruby-version`, `Gemfile.lock`,
  `wire-ios-data-model/WireDataModel.xcodeproj/project.pbxproj`,
  `wire-ios/Configuration/Debug.xcconfig`,
  `wire-ios/Configuration/Security-Flags.xcconfig`, and
  `wire-ios/Configuration/session_manager.json`.
  Preserve all six. Inspect current status first; never stage them with the fixes.
  Do not dump configuration/session contents unnecessarily.

## Selected tickets (all currently estimated at 1 point)

### 1. WPB-14706 — messaging-options toggle has a static accessible name

[Jira](https://wearezeta.atlassian.net/browse/WPB-14706)

The composer's ellipsis button always announces “Open more messaging options”,
including when activating it returns from the extra row. The name should describe
the action available in the current state, including “Close more messaging options”.

- Source: `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/InputBar/InputBarButtonsView.swift`.
- `configureViews()` sets `expandRowButton.accessibilityLabel` once using
  `L10n.Accessibility.Conversation.MoreButton.description`.
- `showRow(_:animated:)` updates `currentRow` and calls `setupAccessibility()`.
  `ellipsisButtonPressed()` toggles between rows. Other action/layout paths also
  call `showRow(0, ...)` or `setupAccessibility()`.
- Likely fix: derive the localized label centrally from row state so initial
  layout, direct toggles, automatic reset and width/layout changes stay consistent.
  Keep the existing accessibility identifier and action behavior.
- Verify first row → extra row → first row, plus automatic reset after another
  action. Avoid fixing only the ellipsis tap handler.

### 2. WPB-23323 — Add Emojis label only available in English

[Jira](https://wearezeta.atlassian.net/browse/WPB-23323)

Remaining scope is the Add Emojis button's localized accessible name. Ticket
explicitly says the second part of original audit finding #75 is already resolved.

- Source: `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/MessageActions/BasicReactionPicker.swift`.
- The UIButton using `UIImage(resource: .addEmojis)` calls `didTapMoreEmojis()`
  without an explicit accessibility label in its construction.
- Likely fix: supply a localized action label, including German
  “Emoji hinzufügen”. Reuse suitable localized wording if available.
- Verify the label in German and English and that activation still opens the
  full picker. Do not expand into keyboard menu access (WPB-14714) or redesign
  reaction controls.

### 3. WPB-23346 — editing Undo / Apply changes labels

[Jira](https://wearezeta.atlassian.net/browse/WPB-23346)

When editing a message, Undo needs alternative text, and the confirmation button
must describe “Apply changes”.

- Source: `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/InputBar/InputBarEditView.swift`.
- `configureViews()` configures undo/confirm/cancel icons and identifiers without
  explicit labels. Likely add localized action labels, reusing strings where suitable.
- Preserve identifiers, enabled/disabled behavior, undo and its long-press action.
  Check Cancel's existing effective name; add a label if needed for consistency.
- Verify Undo and Apply changes are announced correctly in editing states.

## Localization and checks

- Inspect and reuse existing strings before adding keys. Relevant files:
  `wire-ios/Wire-iOS/Resources/Localization/Base.lproj/Accessibility.strings` and
  `wire-ios/Wire-iOS/Resources/Localization/de.lproj/Accessibility.strings`.
- Existing `conversation.moreButton.description` is the open action in Base and
  German. `sketch.undoButton.description` exists, but confirm whether that wording
  fits message editing before reusing an unrelated namespace.
- SwiftGen config: `wire-ios/swiftgen.yml`; generated accessors:
  `wire-ios/Wire-iOS/Generated/Strings+Generated.swift`.
  Use `scripts/run-swiftgen.sh` with the appropriate config after adding keys;
  inspect this branch's script invocation and artifact availability first.
  Include generated changes attributable to these tickets. Do not hand-edit
  generated accessors or commit unrelated generator churn.
- Keep Base and German correct. Follow existing localization workflow for other
  languages; do not invent translations or perform mass string rewrites.
- Existing nearby tests: `wire-ios/Wire-iOS Tests/InputBar/InputBarEditViewTests.swift`
  and `wire-ios/Wire-iOS Tests/ConversationMessageCell/BasicReactionPickerSnapshotTests.swift`.
  Use focused checks appropriate to semantic-only changes; avoid broad snapshot
  regeneration or tests that merely repeat the assigned labels.
- Read `.xcode-version` and `fastlane/.env` on this branch: at handover they
  specify **Xcode 26.1.1** and **iOS 26.1**. Previous estimation was on a newer
  develop checkout; do not copy its 26.6/26.5 assumptions.
- Local tests use `xcodebuild test` directly with
  `wire-ios-mono.xcworkspace`; no local fastlane tests. Use module schemes with
  the `All` suffix where applicable and simulator `iPhone 17 (Tests)` with the
  configured OS. Inspect actual app scheme/test-plan membership for focused tests.
- Simulator/Accessibility Inspector work was deferred; Christoph can prepare a
  simulator when needed. Do not start interactive app/VoiceOver testing without
  coordinating readiness. Report clearly which checks actually ran; static
  inspection and build success do not prove VoiceOver behavior.

## Repository rules and permissions

- Root `AGENTS.md` is absent from this release base. Repository guidance saved
  during estimation can be read with
  `git show chore/accessibility-estimation:AGENTS.md`.
  Follow any applicable instructions found in the current checkout as well.
- Branch prefixes: `feat/`, `fix/`, `revert/`, `chore/`; **never `codex/`**.
- Swift files retain the GPL v3 header, year 2026; 4-space indentation and
  120-column formatting. Run relevant lint/format checks without changing
  unrelated files. TODOs need a JIRA reference.
- Small, clear fixes are authorized. Discuss broad, high-risk or debatable
  changes before implementing them. No subagents requested.
- **Jira stays read-only except Story Points**, already authorized in the prior
  session. These three already have 1 point each, saved and verified. No Jira
  status/description/comment/assignee/rank changes are authorized for this task.
- Do not send messages to others. No PR creation or publishing requested yet.
- Suggested combined implementation commit:
  `fix: correct composer accessibility labels - WPB-14706, WPB-23323, WPB-23346`.
  Stage only the ticket-specific changes and this handover if desired.

## Prior context and next steps

The full assessment lives on `chore/accessibility-estimation` in
`ACCESSIBILITY-ESTIMATION.md` (30 findings, 79 points, provisional staffing
recommendation). It is intentionally not copied wholesale onto this fix branch.
Read it via `git show` only if more context is needed.

1. Confirm branch/status and read this handover plus repository guidance.
2. Implement these three local label fixes, keeping ownership of shared strings clear.
3. Run focused checks; report any build, tooling, localization or runtime blockers.
4. Review the staged diff for unrelated changes, then make the combined commit.
5. Update this document with what changed, checks run, limitations and commit status.

Fresh-session prompt:

> Read ACCESSIBILITY-FIX-HANDOVER.md and implement its three selected tickets on
> the current fix/accessibility-labels branch. One combined commit is fine for
> now; preserve my unrelated changes and don't create PRs or modify Jira fields.
