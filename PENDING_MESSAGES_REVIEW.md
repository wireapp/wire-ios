# Offline pending messages: complexity review (handover)

Date: 2026-10-27
Branch: `feat/pending-message-foundation-WPB-26307` (draft PR #5447)
Related: `PENDING_MESSAGES_PLAN.md` (implementation plan/log). Remove both files before merging to `develop`.

## Question

Does the outbox implementation on this branch need to be this complex?

## Short answer

No, most of it doesn't. The PR adds ~4.4k production lines (plus ~3k tests/plan) across 93 files. Most of
that comes from one early design decision and its consequences, not from the problem itself.

Scope of the review: outbox model, `MessageSender`, `ClientMessageRequestStrategy`, deletion flow, asset
retention, queued editing, schema. UI files and tests were not reviewed in detail.

## Root cause: aiming for "never deliver twice"

The design treats a lost acknowledgement as dangerous and never repeats a possibly-submitted send
automatically. These mechanisms exist only to support that:

- 8-state lifecycle including `uncertain` (`wire-ios-data-model/Source/Model/Message/ZMMessage+Outbox.swift`)
- Frozen, separately EAR-encrypted payload snapshot (`outboxSnapshot`) next to the live message content
- Per-attempt UUID tokens checked in ~15 places to reject late callbacks
- New "request not submitted" marker in `ZMTransportSession.m` / `NSError+ZMTransportSession.h`
- Own error classification in `MessageSender` (`isDefiniteOutboxRejection`, `isRepairableOutboxRejection`)

But receivers already deduplicate: an incoming message whose nonce is already known from the same sender
client updates the existing row instead of creating a new one
(`wire-ios-data-model/Source/Model/Message/ZMOTRMessage+UpdateEvent.swift:227-268`). The existing Retry
already resends with the same nonce. Resending the same content under the same nonce is effectively
harmless. The only real risk is resending *different* content under the same nonce, which only exists
because of in-place editing (below).

## Other complexity drivers

1. **In-place editing of queued messages** (`ZMClientMessage+TextMessageData.swift`). Requires the frozen
   snapshot, the "claim" concept, draft retention on races, and a `.contentUpdate` operation for link
   previews finishing during HTTP. Dropping in-place editing (or allowing it only before the first
   attempt) removes most of this.
2. **A second send path inside `MessageSender`.** `if outboxAttempt != nil` branches in every method, own
   retry loop (`sendOutboxAttempts`), own MLS repair overlapping `handleSendMLSMessageFailure`, own
   conversation reset. Two state models coexist and outbox state is projected back into legacy fields
   (`expire`, `markAsSent`, `delivered = false`, `removeExpirationDate`).
3. **Deferred deletion** (`ConversationMessage+Deletion.swift`, `outboxDeletionScopeRaw`,
   `outboxDeletionMessages`/`outboxDeletionTarget`). Exists because deleting an `uncertain` message is
   ambiguous. With at-least-once: cancel if not yet sent, otherwise send a normal delete (a delete for an
   unknown nonce is harmless on receivers).
4. **Asset retention** (`FileAssetCache.swift`, ~200 lines): durable directory, pin files,
   `RetainedAssetCache` routing, `NSManagedObjectContextDidSave` observer, 24h orphan sweep for a
   hypothetical second process. A separate feature in itself.
5. **Defensive hardening throughout:** `zm_isValidContext` / `isTornDown` checks, teardown hook stored in
   context `userInfo` (`PendingMessageContextTeardown`), `UserClient` session-read changes,
   `IncrementalSyncObserver` rewrite, `ZMUpstreamModifiedObjectSync` change. Individually reasonable, but
   per the plan file many came from repeated self-review passes over hypothetical races, not observed bugs.
6. **Smaller issues:**
   - `Message.outboxPayload` column "for compatibility with intermediate local builds" in the unreleased
     2.145 schema: dead weight.
   - New parameters with default arguments (`reachability: … = nil`, `outboxStrategy: … = nil`,
     `outboxAttempt: … = nil`) – conflicts with the no-default-arguments preference.
   - The plan's PR 1–5 are all in one PR.

## Proposed minimal version

The user-visible problem comes from two places on `develop`:

- Messages expire on a timer (`MessageExpirationTimer`).
- On restart, undelivered messages are expired on purpose: `!isFresh` branch in
  `ClientMessageRequestStrategy.insert(object:isFresh:completion:)`.

A first version behind the `offlinePendingMessages` flag could be:

1. Don't start the expiration timer for user-visible, non-ephemeral messages.
2. In the `!isFresh` case, send instead of expiring.
3. Wait for reachability and sync before attempting a send, so offline time doesn't consume retries.
4. Keep nonce and content stable once the first attempt starts; later edits use the normal edit message.
5. Leave assets, queued editing and deletion edge cases for follow-ups (or skip them, given the possible
   wire-ios retirement).

Plausibly a few hundred lines, extending the existing send path instead of running beside it.

Trade-off: a lost acknowledgement can cause a resend. Given receiver-side nonce dedup this seems
acceptable, but confirm with the protocol owners, especially for MLS.

## Recommendation / next step

Start a fresh, small branch from `develop` and keep this branch as reference, rather than trimming this
one; the pieces here are too interconnected to remove cheaply. Next session: sketch the minimal change
concretely (files: `ClientMessageRequestStrategy.swift`, `MessageExpirationTimer.swift`,
`MessageSender.swift`, `ZMConversation+Message.swift`, `DeveloperFlag.swift`).

Open checks before implementing:

- Whether undelivered messages are currently editable in the UI, and how an edit of a not-yet-sent
  original is ordered relative to it.
- Receiver dedup behaviour on Android/Web and for MLS (only iOS code was checked).
- How the legacy `sendMessage` retry loop behaves while offline (retry budget, `tryAgainLater`).

## Prompt for the next session

```
I'm continuing work on offline pending messages (WPB-26307) for wire-ios.

Context:
- Branch feat/pending-message-foundation-WPB-26307 (draft PR #5447) holds an outbox
  implementation that turned out far too complex (~4.4k production lines).
- Read PENDING_MESSAGES_REVIEW.md on that branch first. It's a handover from a review
  session: why the current design is complex, and a proposed minimal alternative.
- PENDING_MESSAGES_PLAN.md on the same branch is the old implementation log. Use it only
  as background; don't follow its "Resume here" or "Next steps" sections.

Goal for this session:
1. Work through the "Open checks before implementing" in the review file:
   - whether undelivered messages are editable in the UI, and how an edit of a
     not-yet-sent original is ordered relative to it
   - how the legacy MessageSender retry loop behaves while offline
   - what can be confirmed about receiver nonce dedup (iOS code; note what needs
     confirming with Android/Web/MLS owners)
2. Based on that, sketch the minimal change concretely: which files, what changes,
   rough diff size, behind the existing offlinePendingMessages developer flag.
   Extend the existing send path; don't build a parallel one.
3. Don't write code yet. Present the sketch for my review first. Once I approve,
   implement it on a fresh branch from develop (keep the old branch as reference).

Constraints: keep the diff minimal and easy to defend in review. Assets, in-place
editing of queued messages, and deferred-deletion edge cases are out of scope for v1.
```
