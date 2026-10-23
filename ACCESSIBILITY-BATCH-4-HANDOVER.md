# Accessibility batch 4 — failed-message error and retry

Prepared October 23, 2026. Preparation only: no fixes, tests, builds, simulator
interaction or dependency setup have run for this batch.

## Worktree and branch

- **Work only in:**
  `/Users/christoph/.codex/worktrees/accessibility-send-failures/wire-ios`.
- Branch: **`fix/accessibility-send-failures`**.
- Base: locally available `github/release/cycle-4.29`, commit
  `c4b51cae4e1f77b1f491d3efe92b6d68a8b7fa94`. No fetch performed.
  Christoph directed new work to `release/cycle-4.29`.
- A separate managed worktree protects ongoing work in the primary checkout and
  in the composer-focus worktree. Do not switch branches or edit files in either
  of those directories for this batch. A fresh chat may open in the primary
  project: explicitly set all command working directories to this worktree.
- This branch has only the committed handover beyond the release base. No user
  configuration/Ruby/session files, logs, dependencies or build products were
  copied. Initial worktree status was clean; check again before editing.
- Read this worktree's `AGENTS.md`; user preferences below take precedence over
  older workflow guidance. Never import old estimation-branch instructions.
- One combined implementation commit for these related findings is acceptable.
  Keep this preparation commit. Do not push or create PRs without a later request.
- Earlier batches remain untouched: PR #5437 is already being reviewed; batch 2
  covers camera/composer labels and action hints, and batch 3 covers mention/reply
  focus. Do not review or change those PRs/branches or copy their patches here.

## Scope: two related findings, one shared investigation

### WPB-14758 — error and Repeat button not announced (2 points)

[Jira](https://wearezeta.atlassian.net/browse/WPB-14758)

The failed-message error text and Repeat/Retry button in a conversation are not
read by the screen reader. Informative text must be discoverable and the retry
action usable. Audit screenshot shows a connection-related send failure below
a message, above the composer.

### WPB-14759 — error/retry not announced and navigation gets stuck (3 points)

[Jira](https://wearezeta.atlassian.net/browse/WPB-14759)

Same reported missing error/Retry output, plus inability to navigate back to the
message-writing area. Tester explicitly asks whether it is the same as #101
(WPB-14758). Both screenshots showed the same failure/retry surface during the
October 22 review. Do not assume every symptom has the same cause.

Keep both tickets listed. Implement shared exposure work once and separately
check the added navigation regression. Do not mark either ticket duplicate or
change Jira workflow fields. Their independent estimates sum to 1.25 likely days;
the staffing assessment provisionally counted about 0.75 day after shared work.
These are static-review judgments, not measured durations or delivery guarantees.

## Source map and observations on cycle-4.29

Paths below relative to this worktree. Inspected code is a starting point, not a
reproduced diagnosis.

1. `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/Cells/Utility/MessageSendFailureView.swift`
   creates a vertical stack containing `titleLabel: WebLinkTextView` and a
   `SecondaryTextButton`. `setTitle` assigns markdown error text. Retry already
   has localized visible text and a tap target; setup assigns `failedToSend.label`
   and `retry.button` identifiers. Its hidden-state observer toggles child visibility.
   Do not assume a titled native button needs a new label as the root fix.
2. `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/Cells/Utility/MessageToolboxView.swift`
   hosts the failure view separately from its ordinary `contentStack`. On
   `.sendFailure`, it hides normal content, reveals the failure view and supplies
   the error string. Some ordinary status content is intentionally grouped for
   accessibility; do not assume all grouping applies to the failure subtree.
   It has a parent tap recognizer, and Retry routes through `resendMessage()` to
   the toolbox delegate. Inspect containment, hit testing and accessibility order.
3. `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/Cells/Utility/MessageToolboxDataSource.swift`
   selects `.sendFailure` when `MessageErrorHelper.errorMessage(message)` returns
   an error. Trace real error variants and state changes, including recovery.
4. `wire-ios/Wire-iOS/Sources/UserInterface/Components/Views/WebLinkTextView.swift`
   is a shared UITextView subclass with `.link` traits, no selected text range,
   `canBecomeFirstResponder = false`, and long-press restrictions. It is also used
   outside message failures, including onboarding/legal text. A global change
   risks unrelated behavior. Check whether actual error content has links before
   replacing it with a label or changing semantics locally.
5. `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/Cells/ConfigurationMessageCell/ConversationMessageCellTableViewAdapter.swift`
   and the surrounding message-cell/container code can affect child accessibility.
   Trace the full failure-view ancestry before setting accessibility flags blindly.
6. `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/ConversationContentViewController+MessageAction.swift`
   handles `.resend` via the user-session enqueue path. Preserve the existing
   message retry logic; this batch is about accessibility, not networking changes.

## Implementation approach and acceptance

- Determine why error text and the native Retry control disappear from usable
  traversal: visibility/grouping, shared text-view semantics, ancestor container,
  or another cause. Avoid an unconditional notification masquerading as a fix.
- Expose informative error text and a clearly named, independently activatable
  retry action in a meaningful order. Preserve links if error text contains them.
- Ensure a screen-reader user can leave the error and reach Compose and other
  conversation controls without touching the screen directly or restarting focus.
- Preserve existing identifiers, localized error and Retry wording, tap routing,
  ordinary status/timestamp behavior and cell reuse. Do not expose stale hidden
  errors or steal reading focus every time a message/layout updates.
- If an announcement is warranted when a failure appears, use localized feedback
  and appropriate timing; it must complement discoverable controls and traversal.
- Do not broaden into general message menus, global text-view redesign, audio
  recording, or composer Reply/Mention focus (already in another batch).
- If the extra trap in WPB-14759 is not explained by the shared failure surface,
  keep its remaining uncertainty explicit rather than claim both tickets fixed.

Suggested manual checks **only when requested/readiness agreed**:

- Failed outgoing text: find/read full error, reach Retry and activate it.
- Navigate backward/forward from the failure to messages and Compose.
- Retry fails again, then succeeds: no stale error or duplicate speech/actions.
- Multiple failures and scrolling/cell reuse; no failure, ordinary status and
  timestamp states remain sensible. Check German/English and relevant error variants.
- Preserve ordinary touch Retry and any links in error content. Do not send test
  messages to real people; coordinate test accounts/destinations with Christoph.

## Validation and workflow constraints

- **Do not run tests unless Christoph explicitly asks.** Suggest focused commands
  instead. Do not start interactive simulator, VoiceOver, Accessibility Inspector,
  or change simulator settings automatically; coordinate readiness first.
- Scoped static checks/lint are acceptable. Parsing or assigning identifiers does
  not prove VoiceOver speech, action activation or navigation. Report exactly
  which checks ran and what remains unverified.
- Existing `wire-ios/Wire-iOS Tests/ConversationMessageCell/MessageToolboxViewTests.swift`
  includes failed-to-send and reason scenarios. They are useful setup references;
  visual snapshots alone will not verify the reported accessibility failures.
  Inspect existing target membership before suggesting focused test commands.
- Branch `.xcode-version` is **26.1.1**; `fastlane/.env` specifies **iOS 26.1**.
  Earlier sessions had Xcode 26.6 / simulator iOS 26.5 installed. Verify when
  needed, without auto-installing tools or running setup/dependency repair.
- If new text is genuinely needed, reuse suitable localization keys first.
  Base/German resources and generated accessors follow `wire-ios/swiftgen.yml`.
  Use the generator script, not hand-written generated accessors; exclude
  unrelated churn and do not invent other-language translations.
- Keep existing GPL headers, identifiers and formatting. Branch prefixes are
  `fix/`, `feat/`, `chore/`, `revert/`, never `codex/`.
- Significant architectural/scope changes need discussion. No subagents requested.
- **No Jira changes** for this implementation task; Story Points already saved
  as 2 and 3. No comments, status/description/assignee/rank edits or messages to others.
- No push/PR creation, prior-PR review, or modification of other worktrees requested.

## Finish record and fresh-session prompt

Update this document with actual implementation choices, shared vs residual
coverage, checks run and limitations. Review/stage only this batch's changes.
Suggested combined implementation commit:
`fix: expose failed message errors and retry accessibly - WPB-14758, WPB-14759`.

Full inventory remains on `chore/accessibility-estimation` in
`ACCESSIBILITY-ESTIMATION.md`; read with `git show` if needed, without copying
the complete assessment onto this branch.

> Work in /Users/christoph/.codex/worktrees/accessibility-send-failures/wire-ios
> on fix/accessibility-send-failures. Read ACCESSIBILITY-BATCH-4-HANDOVER.md and
> implement WPB-14758 and WPB-14759, treating shared work once and checking the
> additional navigation failure separately. One combined implementation commit
> is fine. Don't run tests or interactive simulator checks unless I ask; don't
> modify Jira, push, create PRs, or touch other worktrees/batches. Update the
> handover with changes, checks and limitations. Continue unless a significant
> decision needs my input.
