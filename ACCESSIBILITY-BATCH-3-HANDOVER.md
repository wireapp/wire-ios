# Accessibility batch 04 — composer focus and feedback

Prepared and implemented October 23, 2026. WPB-14710 and WPB-14712 are
implemented in this isolated worktree. Scoped static checks passed; tests, builds,
and interactive simulator/VoiceOver checks have not run. Runtime acceptance is pending.

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
- At the start of implementation, this branch had only the committed handover beyond the release base. No local
  configurations, Ruby edits, credentials, session files, or logs were copied.
  Tool dependencies/build products may therefore be absent here.
- Read this worktree's current `AGENTS.md` and current status before editing.
  Do not import an old AGENTS.md from the estimation branch; previously supplied
  versions were revoked. User workflow preferences below take precedence.
- One combined implementation commit is acceptable; keep ticket changes easy to
  identify for later separate/stacked PRs. Leave this preparation commit intact.
- Do not push, create PRs, modify Jira, start another chat, or alter the earlier
  batches. PR #5437 is already reviewed by someone else; no review requested here.

## Batch 04 revalidation — October 23, 2026

- This chat resumed with both tickets already implemented in commit
  `1b5460f0d35e0ea1896b7fe4c864cc1bd799a873` on the requested branch, with
  a clean worktree. Preserved that combined implementation commit; no additional
  source changes were needed after scoped review.
- Corrected the batch title to **04**. Kept this handover's existing filename
  because it is the requested entry point. The chat is named
  `Accessibility04 WPB-14710, WPB-14712`.
- Reviewed the committed mention insertion/availability feedback, pending-callback
  invalidation, explicit Reply focus handoff, message-action dismissal completion,
  localized strings, and separate restored-draft entry point.
- Re-ran `xcrun swiftc -frontend -parse` on the four changed source files and
  generated strings: passed. Re-ran `plutil -lint` on Base/German accessibility
  strings: passed. Ran `git diff --check` from the recorded release base through
  the implementation commit: passed. These are static checks only.
- Earlier lint results below are historical; lint and SwiftGen were not rerun in
  this resumption. No tests, builds, simulator/VoiceOver checks, Jira writes,
  pushes, PR creation, primary-checkout edits, or other-batch edits were performed.
- Runtime acceptance and the limitations below remain pending, especially speech
  ordering, keyboard/menu animation timing, alternate Reply menu entry points,
  and integration with batch 2's composer label and mention candidate hints.

## Implementation handoff — October 23, 2026

Implemented only WPB-14710 and WPB-14712 on `fix/accessibility-composer-focus`.
The original preparation commit remains intact. The combined implementation commit
uses `fix: improve composer accessibility focus - WPB-14710, WPB-14712`.

### Changes

- **WPB-14710:** the mention button explicitly refreshes matching users after
  inserting `@`, lays out the attached editor, and posts a VoiceOver layout-change
  notification targeting the message field. Queued localized feedback confirms
  that the at sign was inserted and invites typing a name.
- The results controller announces that suggestions are available above the field,
  or that no matching suggestions exist. It announces only transitions between
  empty/nonempty results, rather than every query, cursor or selection update.
  A main-queue turn coalesces synchronous updates without a fixed delay; an update
  generation discards obsolete callbacks. Dismissal invalidates pending callbacks
  and resets announcement state for re-entry. Empty results hide the list without
  resetting that state. Announcements leave VoiceOver focus in the editor and use
  queued speech so they can follow the initiating focus notification.
- **WPB-14712:** Reply from the message action sheet performs its action in the
  dismissal completion, retaining the action controller until completion. The
  explicit input-bar `reply` path switches to text input for VoiceOver, makes the
  attached editor first responder, lays out the window and posts a layout-change
  notification targeting the field. No additional Reply announcement duplicates
  the field's own speech. Quote replacement, cancellation and typed text retain
  their existing code paths. Restored drafts still call `addReplyComposingView`
  directly and do not receive the focus handoff.
- Added three strings in Base English and German `Accessibility.strings` and
  regenerated accessors with `scripts/run-swiftgen.sh config run --config
  swiftgen.yml` from `wire-ios/`. Reused a copy of the existing local SwiftGen
  artifact inside this worktree's ignored `.build`; no setup, download or dependency
  resolution ran. Excluded unrelated account-limit fallback/comment churn emitted
  by generation. No candidate-hint or composer-label changes from batch 2 were copied.

### Checks actually performed

- Read branch/status and traced mention insertion, selection observation, result
  reload/dismissal, action-sheet dismissal, explicit Reply and restored-draft paths.
- SwiftFormat 0.58.3 in `--lint --cache ignore` mode on the four changed source
  files: passed, zero files require formatting.
- SwiftLint 0.61.0 with `lint --strict --quiet --no-cache` on those four files:
  passed. Both lint binaries were read from the existing primary-checkout artifact
  paths, with this worktree as the working directory; primary files were not edited.
- `xcrun swiftc -frontend -parse` on the four source files and generated strings:
  passed. This checks syntax only, not SDK type checking or app integration.
- `plutil -lint` on both changed localization files: passed.
- `git diff --check` and scoped diff review: passed.
- No tests, builds, interactive simulator checks, Accessibility Inspector sessions,
  Jira changes, pushes or PR creation. No primary-checkout or other-batch edits.

### Limitations and next validation

- VoiceOver notification delivery, speech ordering, focus retention through the
  keyboard/menu animations and actual suggestion navigation remain unverified.
  Coalescing cancels callbacks before posting; already queued VoiceOver speech is
  managed by the system and cannot be withdrawn by the update-generation guard.
- Manually validate mention-button entry, typed `@`, filtering through empty and
  nonempty results, selection, dismissal/re-entry, and English/German feedback.
  Verify no repeated feedback for unchanged availability and no focus jump while
  typing; candidate text/selection and hardware-keyboard shortcuts need runtime checks.
- Manually validate Reply through the action sheet and VoiceOver custom action,
  quote replacement, cancellation, existing drafts and restored drafts. Also check
  alternate Reply entry points (collections and link context menus), especially
  their system-menu dismissal timing. Only the message action sheet has an explicit
  dismissal completion in this patch.
- Composer naming still depends on batch 2's WPB-14756; candidate hints remain
  owned by WPB-14707. Neither patch was duplicated. Other locales use the existing
  fallback workflow; only English/German translations were added.
- Tests and interactive checks require Christoph's explicit request. The suggested
  acceptance scenarios below remain pending; static-check success is not evidence
  that VoiceOver runtime behavior has passed.

## Follow-up — October 29, 2026

Christoph reported during manual VoiceOver checks that messages covered by the
mention suggestions overlay were still read. The overlay previously changed only
visual visibility, leaving the underlying accessibility hierarchy exposed.

- Added a visibility callback from the results controller to its conversation
  content owner. While the list is visible, the covered message table, bottom
  reply-preview container and scroll-to-bottom button have
  `accessibilityElementsHidden` enabled. Closing the list or filtering to no
  results restores them. The composer remains accessible as a separate view.
- Routed result reload, show and dismissal through the same visibility update.
  The callback runs only when visibility changes, with a weak owner capture and
  no additional focus notification while typing.
- Pending manual validation: while suggestions are visible, explore by swiping
  and touch; covered messages/quotes/scroll control should not be read, but the
  editor and candidates should remain reachable. After selection, dismissal and
  empty results, verify conversation content becomes reachable again. Repeat
  empty/nonempty filtering and opening/closing with VoiceOver initially off.
- Scoped SwiftFormat lint (0/2 files require formatting), strict SwiftLint,
  Swift frontend syntax parsing on the two changed source files, and
  `git diff --check` passed. The `xcrun` lookup emitted developer-tool filesystem
  event/cache warnings; no Swift parsing errors were reported.
- No tests, builds or interactive simulator checks were run for this follow-up.

## Reply focus follow-up — October 29, 2026

Christoph reported that VoiceOver remained focused on the original message after
Reply. The initial synchronous layout-change request did not achieve the required
runtime behavior. Keyboard/menu timing is a suspected cause, not a confirmed diagnosis.

- Replaced the immediate Reply notification with a pending request tied to the
  current reply preview. Keyboard will/did-change-frame callbacks defer it until
  movement finishes, then a main-queue turn lets the initiating action/callbacks
  return before posting a targeted `screenChanged` notification for the editor.
- If there is no keyboard transition (already open or hardware keyboard), the
  main-queue callback can perform the handoff without waiting for a notification
  that may never occur. No fixed delay or repeated focus retries were introduced.
- The request is consumed once and checks the same reply preview, VoiceOver,
  first-responder status and window attachment. Cancelling/replacing the reply or
  leaving the input-bar screen clears the pending request. Restored drafts still
  bypass this explicit-Reply path. Keyboard callbacks alone cannot trigger focus.
- Runtime verification remains pending: Reply from the message menu and VoiceOver
  custom action with keyboard closed/open; quote replacement with draft text;
  cancelling/leaving before keyboard completion; hardware keyboard and alternate
  Reply entry points. Confirm focus reaches the composer and stays navigable.
- Scoped SwiftFormat lint (0/2 files require formatting), strict SwiftLint,
  Swift frontend syntax parsing on both changed source files, and
  `git diff --check` passed. These do not verify runtime focus behavior.
- No tests, builds or interactive simulator checks were run.

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

Original implementation prompt (historical):

> Work in /Users/christoph/.codex/worktrees/accessibility-composer-focus/wire-ios
> on fix/accessibility-composer-focus. Read ACCESSIBILITY-BATCH-3-HANDOVER.md and
> implement WPB-14710 and WPB-14712. One combined implementation commit is fine.
> Do not run tests or interactive simulator checks unless I ask, modify Jira,
> push, create PRs, or touch my primary checkout/other batches. Update the handover
> with changes, checks and limitations. Continue unless a significant decision
> needs my input.
