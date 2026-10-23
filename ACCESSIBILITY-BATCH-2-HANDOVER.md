# Accessibility batch 2 — implementation handover

Prepared October 23, 2026. Implement the three selected tickets below in a fresh
session. No implementation or tests have been performed for this batch yet.

## Branch, scope, and current state

- Repository: `/Users/christoph/Developer/caldrian/wire-ios`.
- Branch: `fix/accessibility-labels-batch-2`.
- Base: local remote-tracking ref `github/release/cycle-4.29`, commit
  `c4b51cae4e1f77b1f491d3efe92b6d68a8b7fa94`. Rebased onto this ref at
  Christoph's request; all future work should use `release/cycle-4.29` unless
  he changes that direction. No fetch or dependency update performed.
  This is independent of the first PR, whose branch was left unchanged.
- First batch is [PR #5437](https://github.com/wireapp/wire-ios/pull/5437), already
  being reviewed by someone else. **Do not review or modify that PR.** It covers
  WPB-14706, WPB-23323, WPB-23346. Those tickets are not part of this batch.
- This branch contains only the preparation handover beyond the release base.
  Implement the three fixes with clear boundaries; one combined implementation
  commit is acceptable, as for the previous batch. Do not push or create PRs
  without a subsequent request. User may split work into separate/stacked PRs later.
- Preserve these unrelated modified files, observed before/after branch creation:
  `.ruby-version`, `Gemfile.lock`, `wire-ios/Configuration/Debug.xcconfig`,
  `wire-ios/Configuration/Security-Flags.xcconfig`,
  `wire-ios/Configuration/session_manager.json`.
- Also preserve untracked `.derived-data-log-0CA5RPJ1`. Do not stage these files
  with the fixes or dump session/configuration/log contents unnecessarily.
  Inspect status at the start to account for newer user changes.
- The five local edits were temporarily stashed for the rebase, then restored;
  their added/removed lines were verified identical to the pre-rebase backup.
  Stash `1d03b58d237ca2b1d411c28cb4f9d8a6f5f5b646`, if still present, is only a
  retained safety copy of already restored edits: do not apply it again.

## 1. WPB-14708 — camera controls have no accessible name (1 point)

[Jira](https://wearezeta.atlassian.net/browse/WPB-14708)

The in-conversation camera switch, enlarge, and shutter buttons need descriptive
alternative text: “Change camera”, “Maximize view”, and “Take photo”.

- File: `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/InputBar/CameraKeyboard/CameraCell.swift`.
- On this release base, `changeCameraButton`, `expandButton`, and
  `takePictureButton` already have icons, targets and identifiers, but no explicit
  labels in their setup. This is a small local labeling fix.
- Reuse suitable localized action strings when available. Verify that each name
  describes the action, not the icon; do not blindly reuse call-camera wording
  if it means something different.
- Preserve identifiers, targets, permission handling, embedded/fullscreen camera
  behavior, and front/back switching. Keep the patch about accessibility labels.
- Suggested manual checks when requested: VoiceOver names in German/English,
  switch camera, expand, and take photo on a camera-capable device.

## 2. WPB-14756 — message input lacks a persistent programmatic label (1 point)

[Jira](https://wearezeta.atlassian.net/browse/WPB-14756)

The message field needs an assistive-technology name that remains available when
the user has entered text. Placeholder text alone is insufficient for that intent.
Tester notes report placeholder speech when empty and typed content when filled;
do not confuse the field's name with its content/value.

- Setup: `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/InputBar/InputBar.swift`.
  `setupViews()` sets the input identifier and placeholder, without an explicit
  stable label. Look for any later assignments before changing it.
- Shared implementation: `wire-ios/Wire-iOS/Sources/UserInterface/Components/TextView/TextView.swift`
  overrides `accessibilityValue`, returning placeholder-related value when empty
  and the superclass value otherwise.
- Likely fix: a localized stable name on the composer text view, keeping actual
  editable text/value available. Prefer a composer-specific change to modifying
  all text views. Do not embed entered message text into the label or erase it
  from accessibilityValue.
- Check normal/empty/filled, editing/reply, and ephemeral-message states. Preserve
  placeholder appearance, typing, identifiers and keyboard behavior.

## 3. WPB-14707 — message and mention hints describe wrong actions (2 points)

[Jira](https://wearezeta.atlassian.net/browse/WPB-14707)

Two contexts: ordinary messages promise “Double-tap to show or hide message
information” when that action is unavailable; mention suggestions promise opening
a conversation even though selection inserts the mention.

- Message file on this base:
  `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/Cells/ConfigurationMessageCell/Content/Text/ConversationTextMessageCell.swift`.
  `setupAccessibility` composes hints from `Conversation.MessageInfo.hint` and
  `Conversation.MessageOptions.hint` on the message container.
- Also inspect `ConversationReplyWithTextCell.swift` in the same directory:
  it is present on cycle-4.29 and composes the same hints.
- Check actual single/double-tap/menu behavior and action routing in
  `ConversationMessageActionController.swift` before deciding which hint to
  remove or replace. Do not advertise an action that does not exist; avoid a
  global string change that makes unrelated message types incorrect.
- Mention list:
  `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Mentions/UserSearchResultsViewController.swift`
  configures a shared `UserCell` and invokes `didSelect(user:)` on selection.
- Shared cell:
  `wire-ios/Wire-iOS/Sources/UserInterface/Components/Views/UserCell.swift`
  supplies `ContactsList.UserCell.hint` for the ordinary contacts context.
  Override with a localized mention-specific hint at the mention-list call site;
  preserve the default for cells that really open conversations.
- Earlier cycle-4.16 handover notes said the separate reply-text cell was absent;
  that detail is obsolete after the cycle-4.29 rebase. Inspect both current paths.
- Check text messages, replies, mention candidates and ordinary contacts, including
  cell reuse. Do not broaden into focus announcements (WPB-14710), keyboard menu
  access (WPB-14714), or inline profile-link actions (WPB-23352).

## Localization, validation, and permissions

- Reuse current strings before adding keys. Main resources:
  `wire-ios/Wire-iOS/Resources/Localization/Base.lproj/Accessibility.strings`,
  `wire-ios/Wire-iOS/Resources/Localization/de.lproj/Accessibility.strings`, and
  corresponding `Localizable.strings` files. Correct Base/German; follow the
  repository's translation workflow for other languages, without invented translations.
- SwiftGen: `wire-ios/swiftgen.yml` →
  `wire-ios/Wire-iOS/Generated/Strings+Generated.swift`. Previous batch used
  `scripts/run-swiftgen.sh config run --config swiftgen.yml` from `wire-ios/`.
  Inspect tool availability/config first. Use the generator, then exclude unrelated
  regeneration churn; do not manually author generated accessors.
- Previous implementation handover records Christoph's preference: **do not run
  tests unless explicitly asked**. Suggest focused commands; do not launch tests
  or interactive simulator/Accessibility Inspector work automatically.
- Static checks/lint can be scoped to changed files. Do not claim VoiceOver
  behavior is verified from parsing, resource checks, or build success alone.
- Nearby existing tests, if the user requests execution:
  `wire-ios/Wire-iOS Tests/CameraKeyboardViewControllerTests.swift`,
  `wire-ios/Wire-iOS Tests/ConversationMessageCell/ConversationTextMessageTests.swift`,
  and `wire-ios/Wire-iOS Tests/UserSearchResultsViewControllerTests.swift`.
- Local test workflow uses `xcodebuild test` with `wire-ios-mono.xcworkspace`,
  not fastlane. Check scheme/test target membership before suggesting selectors.
  Branch `.xcode-version` is **26.1.1**, `fastlane/.env` says **iOS 26.1**.
  Prior handover records only Xcode 26.6 / simulator iOS 26.5 installed; verify
  if relevant rather than installing/changing tools automatically.
- Prior first-batch test attempt failed in unchanged WireDesign code because
  `StyleKitIcon` was missing on its older base; do not assume that failure still
  occurs on cycle-4.29. Do not expand this batch into dependency/build repair
  without assessing the cause and scope. No tests ran in this preparation session.
- **Jira:** read-only except previously authorized Story Points updates; these
  estimates were already saved (1, 1, 2 respectively). Do not change ticket status,
  description, comments, assignee, rank or sprint. No Jira changes needed here.
- No review, push, PR creation or messages to others are requested. Stay on this
  branch and preserve unrelated changes. Use `fix/`, `feat/`, `chore/`, `revert/`
  prefixes; never `codex/`.
- Earlier supplied AGENTS.md instructions were revoked by the user. Do not import
  an old AGENTS.md from the estimation branch as active instructions. This new
  release base contains its own `AGENTS.md`; read current repository guidance
  and honor the user's explicit workflow preferences above.
- Suggested implementation commit:
  `fix: correct camera and composer accessibility - WPB-14708, WPB-14756, WPB-14707`.

## Start / finish checklist

1. Read this file, confirm branch/status, and inspect only relevant current code.
2. Implement the three local fixes and necessary string/accessor updates.
3. Run permitted focused static checks; suggest runtime/test checks for Christoph.
4. Review the diff; stage only ticket-related changes and this handover update.
5. Make the implementation commit and record changes/checks/limitations here.
6. Leave publishing and PR decisions to a later user request.

Full backlog notes remain on `chore/accessibility-estimation` in
`ACCESSIBILITY-ESTIMATION.md`. Read with `git show` only if needed; do not copy
the whole assessment or first batch's implementation onto this branch.

Fresh-session prompt:

> Read ACCESSIBILITY-BATCH-2-HANDOVER.md and implement WPB-14708, WPB-14756,
> and WPB-14707 on the current branch. One combined implementation commit is
> fine. Preserve unrelated changes; don't run tests unless I ask, modify Jira,
> review PR #5437, push, or create PRs. Update the handover with what changed
> and which checks actually ran. Continue unless a significant decision needs me.
