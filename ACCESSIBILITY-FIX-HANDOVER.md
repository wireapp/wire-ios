# First accessibility fixes — session handover

Prepared October 22, 2026. This is an implementation handover, not a request to
repeat the backlog estimation. All three fixes are now implemented; see the
implementation and validation record below.

## Task and Git state

- Work in `/Users/christoph/Developer/caldrian/wire-ios`.
- Current branch: `fix/accessibility-labels`, based on
  `github/release/cycle-4.16` at `7bb6a45a1fd6758d610328a815f69e7bbb66976d`.
- Implement the three small tickets below. User's latest preference: **one
  initial combined commit is fine**. This supersedes the earlier request for
  one commit per ticket. User may later split work into separate/stacked PRs;
  keep each ticket's code and string changes easy to identify.
- Do not create PRs, split branches, modify Jira, or start another chat automatically.
  The user subsequently authorized pushing this branch after completion.
- Per the latest request, the initial handover was committed separately as
  `a1424aca7c`, followed by the existing data-model project-file changes as
  `0da43c149d`. The implementation and this updated handover form one combined
  commit after those two preparatory commits.
- Existing unrelated working-tree changes, observed after the user switched
  branches: `.ruby-version`, `Gemfile.lock`,
  `wire-ios-data-model/WireDataModel.xcodeproj/project.pbxproj`,
  `wire-ios/Configuration/Debug.xcconfig`,
  `wire-ios/Configuration/Security-Flags.xcconfig`, and
  `wire-ios/Configuration/session_manager.json`.
  The data-model project-file changes were committed separately as requested.
  Preserve the other five unstaged edits; never stage them with the fixes.
  These files are already tracked; the user’s “stay untracked” instruction is
  treated as keeping their existing modifications uncommitted and unstaged.
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

- Latest user instruction: **do not run tests unless explicitly asked**. Suggest
  useful checks and print commands for Christoph to run. This supersedes earlier
  directions to run tests autonomously. The test attempt recorded below predates
  this instruction; do not rerun it without a new request.

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


## Implementation record — October 22, 2026

Ticket boundaries for a later split into stacked PRs:

- **WPB-14706:** `InputBarButtonsView.swift` derives the ellipsis label centrally
  in `setupAccessibility()` from `currentRow`, including initial configuration.
  Keeps the existing open string and adds `conversation.moreButton.closeDescription`
  in Base/German plus its SwiftGen accessor. `InputBarButtonsViewTests.swift`
  in the unit-test target covers toggle round trips, reset after another action,
  and reset to a single row after a width change. No action or identifier changes.
- **WPB-23323:** `BasicReactionPicker.swift` explicitly labels the Add Emojis
  button with existing `L10n.Localizable.Image.addEmoji` (English “Add an emoji”,
  German “Emoji hinzufügen”). Its target/action still invokes `didTapMoreEmojis()`.
  No new strings or generated changes belong to this ticket.
- **WPB-23346:** `InputBarEditView.swift` explicitly labels Undo, Apply changes,
  and Cancel. Undo reuses `sketch.undoButton.description` (“Undo last step” /
  “Letzten Schritt rückgängig machen”): the actual implementation calls
  `textView.undoManager.undo()`, so the wording fits despite the sketch namespace.
  Cancel had no explicit label or title in this icon-button path; it now reuses
  `general.cancel`. Adds `conversation.applyChangesButton.description` with
  “Apply changes” / “Änderungen übernehmen” and its SwiftGen accessor. Identifiers,
  enabled-state logic, tap delegates, and long-press handling are unchanged.

The only shared files for a future split are Base/German `Accessibility.strings`
(one new key per WPB-14706 and WPB-23346), `Strings+Generated.swift` (one accessor
per key), and this record. SwiftGen ran via `scripts/run-swiftgen.sh config run
--config swiftgen.yml` from `wire-ios/`. Its unrelated account-limit backup-hint
regeneration was excluded from the final diff by restoring that existing block.
Other languages follow the existing Crowdin workflow; the two new keys currently
fall back to English outside German. Reused strings retain existing translations.

### Validation and limitations

- SwiftFormat lint: passed for all three changed production Swift files and the
  new state-transition test file (after formatting that new file).
- SwiftLint: passed for those four files, with no cache and no diagnostics.
- `plutil -lint`: passed for both changed Accessibility string tables.
- Swift parser: passed for all four Swift files and generated string accessors.
- A temporary Foundation/Bundle check loaded all six action labels directly from
  Base/German bundles and verified all 12 expected localized values successfully.
  This checks resource lookup, not VoiceOver speech.
- Focused unit tests were attempted with the command below. `xcodebuild` exited
  65: WireDesign failed to emit its module because `StyleKitIcon` was not found
  in `StyleKitIconSize.swift` and `UIImage+StyleKit.swift`. Tests never executed;
  this is a build blocker in unchanged dependency code, not a passing test result.
  Build log: `/tmp/wire-accessibility-tests.log`.
  Result: `DerivedData/wire-ios-mono/Logs/Test/Test-Wire-iOS-2026.10.22_18-10-49-+0200.xcresult`.

  ```sh
  xcodebuild test -workspace wire-ios-mono.xcworkspace -scheme Wire-iOS \
    -testPlan UnitTests \
    -destination 'platform=iOS Simulator,name=iPhone 17 (Tests),OS=26.5' \
    -derivedDataPath DerivedData/wire-ios-mono \
    -only-testing:'Wire-iOS UnitTests/InputBarButtonsViewTests' \
    -disableAutomaticPackageResolution
  ```
- Interactive simulator, Accessibility Inspector, and VoiceOver testing have not
  run. Coordinate readiness with Christoph before doing that work. Pending manual
  checks: English/German speech for all actions, full emoji picker activation,
  editing enabled/disabled states, Undo and long press, Apply changes and Cancel.
- Installed tools are Xcode 26.6 (17F113) and iOS 26.5 only; the branch requests
  Xcode 26.1.1 / iOS 26.1. The available `iPhone 17 (Tests)` was used for the
  command-line test attempt. No simulator settings or runtime installations changed.


### Commit and working-tree record

- Initial handover: `a1424aca7c`.
- Existing data-model project-file fixes: `0da43c149d`.
- Combined implementation commit includes this updated handover and only the
  ticket-specific production, string, generated-accessor, and regression-test files.
- Final diff whitespace check passed. No PRs created or Jira changes made.
- Original five unrelated modified files remain untouched and unstaged.
- During validation, an additional app-project reference-ordering change appeared
  in `wire-ios/Wire-iOS.xcodeproj/project.pbxproj` and was subsequently found staged.
  It was not part of the initial working-tree diff. Preserve it in its observed
  state and exclude it from the accessibility commit.
- The user authorized pushing the completed branch in a follow-up. Push the
  three task commits to the existing `github/fix/accessibility-labels` upstream;
  no force push. Verify the upstream matches HEAD afterward.
