# Accessibility batch 3 — composer focus and feedback

Prepared October 23, 2026. This is preparation for a fresh implementation session.
No fixes, tests, builds, dependency setup, or simulator interaction have run for
this batch. Implement only the two tickets below.

## Worktree and branch — important

- **Use this isolated checkout:**
  `/Users/christoph/.codex/worktrees/accessibility-composer-focus/wire-ios`.
- Branch: **`fix/accessibility-composer-focus`**.
- Base: `github/release/cycle-4.29` at
  `c4b51cae4e1f77b1f491d3efe92b6d68a8b7fa94` (locally available ref; no fetch).
  Christoph explicitly directed all new work to `release/cycle-4.29`.
- This managed worktree was created so preparation/implementation does not switch
  or change the primary checkout while Christoph works on the first batches.
  The primary directory `/Users/christoph/Developer/caldrian/wire-ios` was on
  `fix/accessibility-labels-batch-2` when preparation started. **Do not switch
  branches or edit files there for this batch.** Set command working directories
  to this isolated checkout, even if a new chat opens in the primary project.
- This branch has only the committed handover beyond the release base. No local
  configurations, Ruby edits, credentials, session files, or logs were copied.
  Tool dependencies/build products may therefore be absent here.
- Read this worktree's current `AGENTS.md` and current status before editing.
  Do not import an old AGENTS.md from the estimation branch; previously supplied
  versions were revoked. User workflow preferences below take precedence.
- One combined implementation commit is acceptable; keep ticket changes easy to
  identify for later separate/stacked PRs. Leave this preparation commit intact.
- Do not push, create PRs, modify Jira, start another chat, or alter the earlier
  batches. PR #5437 is already reviewed by someone else; no review requested here.

## Why two tickets

Both concern intentional handoff to the composer and VoiceOver feedback. They
share controller/lifecycle investigation but have distinct triggers and acceptance
checks. This is a focused batch of **5 estimated points**, roughly **1.25 likely
developer-days**, not a promise of runtime behavior or a points-to-days conversion.
It is deliberately smaller than the estimation batches because focus timing is
more uncertain than static label assignment.

## WPB-14710 — mentioning gives no screen-reader feedback (3 points)

[Jira](https://wearezeta.atlassian.net/browse/WPB-14710)

Audit finding: after activating @ / Mention someone, a screen-reader user does
not learn that @ was inserted, focus moved to the message field, and a mention
suggestion became available. Expected: the transition and suggestions are
discoverable without losing the ability to edit or select a candidate.

Starting points, relative to this worktree:

- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/InputBar/ConversationInputBarViewController+Mentions.swift`.
  `mentionButtonTapped` makes the text view first responder, calls
  `MentionsHandler.startMentioning`, and creates the mention handler.
- `triggerMentionsIfNeeded` derives the current search and assigns
  `mentionsView?.users`; selection observation may fire repeatedly while editing.
  `insertMention(for:)` replaces text, plays haptics and dismisses suggestions.
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Mentions/UserSearchResultsViewController.swift`.
  Handles results, selection, popup layout and dismissal. Existing identifiers:
  `mentions.list.container`, `mentions.list.collection`, and candidate identifiers.
  Inspect update/presentation timing and visual ordering before choosing targets.
- `ConversationInputBarViewController.swift` in the nested
  `Conversation/InputBar/ConversationInputBarViewController/` directory holds
  the optional mention handler/view; find the complete presentation lifecycle.

Static review found no explicit VoiceOver handoff in the initiating method.
That is an investigation lead, not proof of the current runtime failure.
First-responder/keyboard focus is not the same as VoiceOver focus.

Implementation direction:

- Make the intentional mention transition clear, with localized feedback for
  suggestions when actual results become available. Reuse established patterns.
- Avoid repeated announcements on every selection/text update, stale suggestions,
  focus jumping out of the editor while typing, and fixed arbitrary delays.
- Keep edit position, typed @, filtering, candidate selection, and hardware-keyboard
  shortcuts intact. Handle no matches and dismissal/re-entry cleanly.
- Batch 2's WPB-14707 corrects candidate hints. It is separate from this transition
  work and may still be under review; do not copy or reimplement that patch here.

Suggested manual acceptance checks when explicitly requested: enter mentions via
button, filter, select, dismiss and re-enter; empty/nonempty results; German and
English feedback; no duplicate announcements; selection and editing still work.

## WPB-14712 — Reply leaves VoiceOver focus on original message (2 points)

[Jira](https://wearezeta.atlassian.net/browse/WPB-14712)

Audit recommendation: choosing Reply should move screen-reader focus to Compose
and inform the user, rather than leave focus at the selected message.

Starting points:

- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/ConversationViewController+ConversationContentViewControllerDelegate.swift`.
  `didTriggerReplyingTo` builds `ReplyComposingView` and invokes the input-bar controller.
- `wire-ios/Wire-iOS/Sources/UserInterface/Conversation/InputBar/ConversationInputBarViewController+Reply.swift`.
  `reply(to:composingView:)` replaces the old quote, then calls
  `addReplyComposingView`; the latter sets quote/view/delegate. No explicit
  VoiceOver handoff was found in this path during static inspection.
- Trace actual menu dismissal, composer presentation, layout and first-responder
  handling before placing a notification. The target must exist and be visible.

Implementation direction:

- Handoff after an explicit Reply action, once the composer can receive focus.
  Use meaningful localized feedback if needed without repeating information
  VoiceOver already reads. Avoid a global focus jump on every layout/view update.
- Preserve typed draft, quote replacement, cancellation, message actions and
  restored drafts; background restoration should not steal current reading focus.
- Batch 2's WPB-14756 adds a stable composer label. Do not duplicate that label
  patch here; note any validation dependency on its eventual merge.
- Share a small helper with the mention fix only if the actual timing and
  semantics fit both. Do not introduce a broad focus abstraction speculatively.

Suggested manual acceptance checks when requested: Reply from the message menu,
replace a quote, cancel, reply with a draft, and restore a draft; check focus and
editing behavior with VoiceOver as well as ordinary use.

## Validation, localization, and scope rules

- **Do not run tests unless Christoph explicitly asks.** Suggest focused commands
  instead. Do not start interactive simulator/Accessibility Inspector work or
  change simulator settings automatically; coordinate readiness first.
- Scoped static checks/lint are acceptable. Do not claim VoiceOver behavior is
  verified by parsing/building or by merely posting an accessibility notification.
- This release requests Xcode **26.1.1**, iOS **26.1** (`.xcode-version`,
  `fastlane/.env`). Earlier sessions had Xcode 26.6 / simulator iOS 26.5 installed;
  verify tool availability only when needed. No installation/setup was done here.
- No broad dependency/build repair, architecture change or unrelated cleanup.
  Discuss a significant scope/design decision before pursuing it. No subagents requested.
- Use existing localized strings where suitable; new user-facing text belongs
  in Base/German resources and the existing translation workflow. Do not invent
  translations for other languages or expose raw technical state to users.
- Relevant tables: `wire-ios/Wire-iOS/Resources/Localization/Base.lproj/Accessibility.strings`
  and `de.lproj/Accessibility.strings`; inspect Localizable tables as needed.
- SwiftGen config: `wire-ios/swiftgen.yml`; output:
  `wire-ios/Wire-iOS/Generated/Strings+Generated.swift`. Use the repository script
  rather than hand-author generated accessors. Inspect tool availability first;
  exclude unrelated generator churn.
- Keep existing GPL headers, 2026 year, formatting and identifiers. Use repo
  branch prefixes `fix/`, `feat/`, `chore/`, `revert/`, never `codex/`.
- These two tickets already have 3 and 2 Story Points from estimation. No Jira
  writes are needed; implementation progress belongs in this handover until
  Christoph requests otherwise.

## Finish and handoff

1. Implement only these two fixes in this worktree.
2. Run permitted scoped static checks; report checks actually run and limitations.
3. Update this document with implementation choices and pending manual validation.
4. Review/stage only relevant changes. Suggested combined implementation commit:
   `fix: improve composer accessibility focus - WPB-14710, WPB-14712`.
5. Do not push/create PRs or touch the primary checkout without a later request.

The original inventory is on `chore/accessibility-estimation` in
`ACCESSIBILITY-ESTIMATION.md`; read via `git show` if more background is needed.

Fresh-session prompt:

> Work in /Users/christoph/.codex/worktrees/accessibility-composer-focus/wire-ios
> on fix/accessibility-composer-focus. Read ACCESSIBILITY-BATCH-3-HANDOVER.md and
> implement WPB-14710 and WPB-14712. One combined implementation commit is fine.
> Do not run tests or interactive simulator checks unless I ask, modify Jira,
> push, create PRs, or touch my primary checkout/other batches. Update the handover
> with changes, checks and limitations. Continue unless a significant decision
> needs my input.
