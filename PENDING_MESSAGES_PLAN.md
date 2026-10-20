# Offline pending messages: implementation plan

Last updated: 2026-10-20

Jira issue: [WPB-26307](https://wearezeta.atlassian.net/browse/WPB-26307)

Plan branch: `chore/pending-messages-plan-WPB-26307`

This is the working checklist for investigation, design, implementation, and rollout.
Check an item only when its result has been verified. Record relevant PRs and test
results here as work progresses. Implementation details below are proposals until
the design decisions are approved.

## Goal

Users can press Send while offline. The message is saved locally in a pending state
and sent automatically after connectivity returns and synchronization permits it.
Editing a never-sent queued text message changes its original content without an
edited marker. Edits to previously sent messages retain normal edit semantics.

## Progress and decisions

- [x] Locate and read the supplied RFC efficiently (all 13 pages extracted).
- [x] Trace local creation and sending of regular messages.
- [x] Trace preprocessing, upload, and sending of asset messages.
- [x] Inspect text editing, eligibility checks, and the edited marker.
- [x] Inspect timeout handling and recovery of messages from a previous app run.
- [x] Identify the existing local developer flag infrastructure.
- [x] Propose PR boundaries and a rollout approach.
- [x] Confirm branch naming: use repository prefixes such as `feat/`, `chore/`, and
      `fix/`. Use `feat/` for feature work.
- [x] Agree to keep this plan committed during feature work, carry it to later
      branches/PRs as needed, and remove it before merging into `develop`.
- [ ] Approve the design, implementation sequence, and local flag approach.
- [x] Record the Jira issue key before creating commits or PRs: `WPB-26307`.
- [ ] Run and record the manual baseline scenarios below before finalizing the design.
- [ ] Implement the feature incrementally.
- [ ] Complete validation and rollout review.

The investigation above is based on source inspection, supplemented by the
user-reported manual baseline results below. No automated tests have been run
for this feature yet.

## Reference and scope

The supplied document is `PAD-2026-05-28 RFC Pending Connection-201026-085514.pdf`.
It primarily specifies pending users and conversation memberships. It mentions
offline messages as context but does not define this outbox or its editing rules.
Use the requested offline-message behavior as the requirement for this work.

Proposed scope:

- Queue user-authored text, location, knock, multipart, and asset messages in
  conversations where sending is otherwise allowed.
- Support images, files, audio, and video through the asset pipeline.
- Preserve existing edit eligibility by message type: add queued text editing;
  do not introduce editing for standalone assets or locations.
- Preserve existing restrictions for self-deleting messages and security checks.
- Keep pending-user onboarding and pending-membership APIs outside this work.
- Do not automatically apply the outbox policy to receipts, reactions, typing
  notifications, or other hidden protocol traffic.
- Do not automatically revive messages that already failed under legacy behavior.

## Current behavior

| Area | Findings from source inspection |
| --- | --- |
| Regular messages | Text, location, knock, and multipart messages are created locally as `ZMClientMessage`. `ClientMessageRequestStrategy` picks up eligible unsent messages. |
| Asset messages | `ZMAssetClientMessage` stores local bytes, preprocesses and encrypts assets, uploads them, then sends the message containing the uploaded asset reference. |
| Delivery state | `.pending` generally represents `delivered == false` while the message is not expired. It includes more than messages waiting for connectivity. |
| UI | Pending messages currently display a sending state. Ordinary text editing is offered only for sent, delivered, or read messages. |
| Synchronization | `MessageSender` waits for synchronization and message dependencies. The synchronization observer is not a reliable connectivity gate. |
| Expiration | Network-attempt expiration is assigned in the sender. Its default interval is 60 seconds; this is not necessarily measured from pressing Send. Send errors can expire messages. |
| Restart | Both regular and asset message strategies explicitly expire messages recovered from a previous app run (`isFresh == false`). |
| Normal edits | `editText` creates a `MessageEdit`, replaces the nonce, sets `updatedTimestamp`, and sets `delivered = false`. The timestamp drives the edited marker. |
| Asset storage | Original and encrypted bytes live in a file cache. A persisted message row alone does not guarantee long-term attachment availability. |

### Source map

- [Message creation](wire-ios-data-model/Source/Model/Conversation/ZMConversation+Message.swift)
- [Delivery state](wire-ios-data-model/Source/Model/Message/ZMOTRMessage.m)
- [Regular message strategy](wire-ios-request-strategy/Sources/Request%20Strategies/Client%20Message/ClientMessageRequestStrategy.swift)
- [Message sender](wire-ios-request-strategy/Sources/Message%20Sending/MessageSender.swift)
- [Synchronization observer](wire-ios-sync-engine/Source/Synchronization/IncrementalSyncObserver.swift)
- [Inserted object tracking](wire-ios-request-strategy/Sources/Object%20Syncs/Helpers/InsertedObjectSync.swift)
- [Expiration timer](wire-ios-request-strategy/Sources/Helpers/MessageExpirationTimer.swift)
- [Asset preprocessing](wire-ios-request-strategy/Sources/Request%20Strategies/Assets/Helpers/AssetsPreprocessor.swift)
- [Asset upload](wire-ios-request-strategy/Sources/Request%20Strategies/Assets/AssetV3UploadRequestStrategy.swift)
- [Asset message sending](wire-ios-request-strategy/Sources/Request%20Strategies/Assets/AssetClientMessageRequestStrategy.swift)
- [Asset storage](wire-ios-data-model/Source/Model/Message/FileAssetCache.swift)
- [Text editing](wire-ios-data-model/Source/Model/Message/ZMClientMessage+TextMessageData.swift)
- [Model edit eligibility](wire-ios-data-model/Source/Model/Message/ConversationMessage+Deletion.swift)
- [UI edit eligibility](wire-ios/Wire-iOS/Sources/Helpers/syncengine/ZMMessage+Actions.swift)
- [Message status and edited label](wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/Cells/Utility/MessageToolboxDataSource.swift)
- [Local developer flags](wire-ios-utilities/Source/DeveloperFlag.swift)

## Manual baseline: current behavior before implementation

Purpose: observe existing behavior and use the findings to refine the design.
These scenarios are investigative, not assertions that the proposed feature
already works. Completed runs and remaining observations are recorded below;
reported results have not been independently reproduced by the agent.

### Setup and observations

- [ ] Record the tested build/commit, device and OS, conversation type, message
      protocol (MLS/Proteus), and synchronization implementation if known.
- [ ] Use an existing conversation that can successfully send online, with a
      second client/account remaining online to observe actual receipt.
- [ ] Start with self-deleting messages off and no outstanding verification or
      legal-hold prompts, to isolate connection behavior.
- [ ] Prepare a local image and a small local file while online so fetching the
      attachment from cloud storage is not part of the test.
- [ ] Disable the sender's actual connectivity. On a physical device, use Airplane
      Mode and ensure Wi-Fi is also off. Keep the receiving client online.
- [ ] Do not use `simulateDriveOffline` as a messaging network switch: its scope
      is Wire Drive. On a simulator, document how connectivity was disabled and
      keep the receiver on an independent connection.
- [ ] Record status immediately, around 15 seconds, and around 90 seconds after
      submission. A failure can happen earlier; 60 seconds is not a guaranteed
      countdown from pressing Send.
- [x] Record whether automatic recovery occurs before trying manual Retry for
      the reported text scenarios; see B2-B4 below.

For each run, record the exact steps, status text/icon, available message actions,
whether the message survives relaunch, receiver content/count/order, and timestamps
of offline submission, reconnection, receipt, or failure. When using Xcode, retain
the relevant messaging/asset logs alongside the observations.

### Scenarios

Use fresh, distinguishable message content for each scenario. Start with B1-B3.
Reset connectivity and let the app finish synchronizing between independent runs.

- [x] **B1: Online control and normal edit.** Send text online, verify receipt,
      edit it, and verify the receiver sees the new text and the edited marker.
- [x] **B2: Send text after going offline.** First finish synchronization online.
      Disable connectivity, submit text, inspect its status and long-press actions,
      and check whether Edit is offered. Observe for about 90 seconds. Reconnect
      without tapping Retry and record whether it sends automatically. If it does
      not, record whether manual Retry succeeds.
- [ ] **B2 follow-up: Timing.** Repeat with fresh messages and brief versus
      prolonged disconnections; record actual timings and available Edit actions.
- [x] **B3: Edit already-sent text while offline.** Send and confirm receipt online,
      disconnect, edit that message, then reconnect. Observe local changes, the
      edited marker, status transitions, and the receiver's final content.
- [x] **B4: Relaunch with unsent text.** Disconnect after an online sync, submit
      fresh text, then terminate and relaunch while still offline. Record its
      state before and after reconnecting, without manually retrying first.
- [ ] **B5: Submit after launching offline.** Start with an existing synced account
      and conversation. Terminate the app, disable connectivity, launch offline,
      and submit fresh text. Compare with B2, including reconnect behavior.
- [ ] **B6: Location and knock.** Repeat offline submission and reconnection with
      each type. If the location flow cannot produce content offline, record that
      separately from failure to send an already-created message.
- [ ] **B7: Image and file.** Separately submit the prepared local image and file
      while offline. Observe preview/progress, status, available actions, and
      reconnect behavior. Repeat each with a relaunch before reconnecting. Add
      audio/video afterward if available; do not assume every asset behaves alike.
- [x] **B7 partial observation: Editing.** The user reports that asset messages
      do not appear editable. This matches the existing standalone-asset edit
      restriction; specific asset types and delivery states were not recorded.
- [x] **B7 partial observation: Video reconnect.** Repeating offline submission
      with a video, the user reports that it appeared to send after Wi-Fi was
      enabled again. Treat this as a tentative automatic-recovery observation;
      receiver playback and whether Retry was used have not been explicitly
      confirmed. No restart result was reported for this video.
- [ ] **B8: Ordering and interruption.** Submit distinguishable text, an asset,
      and another text while offline, then reconnect and record receipt order.
      Separately interrupt a larger asset upload and observe recovery. Use logs
      to distinguish upload completion from delivery of the asset-reference
      message; the progress indicator alone cannot prove both stages succeeded.

Source-based expectations to check: pending text currently has no Edit action;
normal sent-message edits create an edited marker; unsent messages recovered by
the strategies after restart are expired as stale. Runtime timing and recovery
must be observed rather than inferred from these expectations.

### Results and design follow-up

| Scenario | Test configuration/date | Observed result | Evidence/follow-up |
| --- | --- | --- | --- |
| B1 | User report, 2026-10-20; build/device/protocol not recorded | Online sending and normal editing worked. | User confirmed scenario 1 worked. |
| B2 | User report, 2026-10-20; build/device/protocol not recorded | Offline submission was not sent; Retry was visible. Manual Retry sent the message successfully. | Exact timing, short-offline variant, and Edit availability were not reported. |
| B3 | User report, 2026-10-20; build/device/protocol not recorded | Offline edit was not sent; Retry was visible. Manual Retry successfully changed the message. | Edited-marker appearance during/after the failed edit was not separately reported. |
| B4 | User report, 2026-10-20; build/device/protocol not recorded | After relaunch, the message was not sent automatically. Retry was visible and worked once connected. | Confirms the restart case requires manual recovery in this run. |
| B5 | Not run | Not recorded | |
| B6 | Not run | Not recorded | |
| B7 | Partial user reports, 2026-10-20; build/device/protocol not recorded | Assets appear not editable. A video appeared to send when Wi-Fi was enabled again. | Confirm receiver playback and whether any manual Retry was used. Image/file comparisons, offline duration, upload stage, and restart outcomes remain pending. User's scenario 5 refers to assets (B7 here), not B5. |
| B8 | Not run | Not recorded | |

- [ ] Compare observations with the source-based findings and investigate gaps.
- [ ] Confirm the video reconnect result on the receiver and compare with text;
      identify which asset stage waited offline before changing its recovery path.
- [ ] Repeat relevant cases for MLS and Proteus, and each synchronization
      implementation available in the test environment.
- [ ] Refine the design and automated regression cases using the observed results.

The first four user-reported scenarios cover online control, offline text
submission, an offline edit of already-sent text, and relaunch with unsent text.
Manual Retry recovers the reported text failures; the desired automatic recovery
is the missing behavior. Keep retrying an edit separate from retrying a new
message when designing recovery. Asset editing appears unavailable, consistent
with source inspection. A video tentatively recovered on Wi-Fi reconnection,
unlike the reported text cases; asset restart recovery remains unverified. These
observations do not establish timeout causes or uncertain-delivery semantics.

A source-based explanation to verify is that asset upload uses
`.allowsRequestsWhileOnline`, with the asset-reference message eligible for
sending only after upload. File creation also sets `shouldExpire = false`, unlike
text and image creation. These differences can explain why a video can wait for
reconnection without following the text failure path. They do not prove which
stage this particular video reached or that every asset automatically recovers.

Asset tests concern queuing, upload, cancellation, and delivery recovery. They do
not require introducing editing for standalone assets. Editing text in a multipart
message is a separate case from replacing or editing its asset content.

## Proposed design

### Persisted outbox lifecycle

- [ ] Define explicit, persisted outbox metadata alongside the existing delivery
      state. Choose the exact model fields and migration during PR 1.
- [ ] Distinguish waiting locally, an active send attempt, an uncertain delivery
      outcome, successful sending, and terminal failure.
- [ ] Distinguish never-sent content from an edit of previously sent content;
      `delivered == false` alone cannot establish that distinction.
- [ ] Persist queued intent before reporting successful local submission.
- [ ] Keep waiting time separate from network-attempt expiration.
- [ ] Resume eligible messages on reconnect and after app restart.
- [ ] Recheck synchronization, membership, protocol readiness, verification, and
      legal-hold requirements before sending.
- [ ] Coordinate send ownership and payload snapshots on the managed object
      context so editing cannot race with transport handoff.
- [ ] Classify temporary connectivity failures separately from permanent errors.
- [ ] Retry without a busy loop or duplicate concurrent send attempts.
- [ ] Verify how to reconcile uncertain delivery after a lost acknowledgement;
      do not assume that retrying an arbitrary changed payload is safe.

### Editing

- [ ] Update never-sent queued text in place while preserving the original nonce.
- [ ] Keep the outgoing payload as original text or multipart content, without a
      `MessageEdit` wrapper or an edited timestamp.
- [ ] Preserve mentions, quotes, multipart attachments, and applicable metadata.
- [ ] Reset or invalidate obsolete link previews and attachment detection results.
- [ ] Preserve normal edit semantics for messages that were previously sent.
- [ ] Define behavior when connectivity returns while the editor is open.
- [ ] Define behavior when an edit is confirmed after a send attempt has claimed
      or transmitted an earlier payload.
- [ ] Ensure queued deletion and empty-edit behavior cannot later send removed
      content or create unnecessary remote delete operations.

### Assets

- [ ] Resume separately from preprocessing, asset upload, and message sending.
- [ ] Reuse recorded asset references after successful upload.
- [ ] Retain required bytes for the lifetime of a queued asset, accounting for
      cache eviction, cleanup, app restart, and account lifecycle.
- [ ] Reconcile outstanding background uploads after restart.
- [ ] Handle cancellation and missing local bytes explicitly.
- [ ] Prevent cancellation or deletion from being undone by late callbacks.

### Rollout

Recommendation: use small PRs targeting `develop`, with a single default-off local
developer flag. Each PR uses a short-lived branch with the appropriate repository
prefix. A long-lived feature branch is not currently proposed.

- [ ] Approve the default-off flag approach and choose its name.
- [ ] Preserve legacy behavior while the feature is disabled.
- [ ] Use explicit enrollment so existing failed or legacy messages are not
      silently adopted into the outbox.
- [ ] Define flag changes for already-enrolled messages: disabling the flag must
      not discard accepted messages or leave them without a recovery path.
- [ ] Keep migrations safe even when the flag is disabled; a behavior flag does
      not hide schema changes.
- [ ] Decide whether toggling the flag requires restarting the session/app.
- [ ] Enable broadly only after end-to-end validation and rollout review.

## PR checklist

### PR 1: Outbox foundation

- [ ] Confirm the design decisions listed below.
- [ ] Add persisted metadata and migration with safe legacy defaults.
- [ ] Add the default-off local flag and define enrollment rules.
- [ ] Add lifecycle and migration tests.
- [ ] Keep actual message enrollment disabled in this foundation PR.
- [ ] Validate that existing sending behavior is unchanged.
- [ ] Record PR URL and validation results.

### PR 2: Regular-message queuing and recovery

- [ ] Enroll supported regular messages behind the flag.
- [ ] Add connectivity gating alongside existing synchronization checks.
- [ ] Wake the queue after reconnect and synchronization.
- [ ] Recover enrolled messages after restart without expiring them as stale.
- [ ] Separate waiting, attempt expiration, retry, and terminal failure.
- [ ] Verify message ordering and avoid duplicate send ownership.
- [ ] Add focused tests for text, location, knock, and multipart messages.
- [ ] Record PR URL and validation results.

### PR 3: Queued text editing and presentation

- [ ] Allow eligible queued text messages to enter the existing editor.
- [ ] Implement in-place updates without the edited marker.
- [ ] Cover repeated edits, mentions, quotes, multipart text, and link previews.
- [ ] Resolve editor/reconnection and editor/send-claim races.
- [ ] Preserve normal sent-message editing and its marker.
- [ ] Implement the agreed pending status presentation with accessibility support.
- [ ] Cover queued deletion and empty-edit behavior.
- [ ] Add model, UI eligibility, and relevant presentation tests.
- [ ] Record PR URL and validation results.

### PR 4: Asset queuing and recovery

- [ ] Preserve any confirmed automatic reconnect behavior already provided by the
      asset pipeline; target observed gaps rather than replacing it wholesale.
- [ ] Enroll supported asset messages behind the flag.
- [ ] Implement required byte retention and cleanup.
- [ ] Recover preprocessing and interrupted uploads.
- [ ] Resume asset-reference sending after an upload already succeeded.
- [ ] Handle background upload recovery, cancellation, and missing bytes.
- [ ] Cover image, file, audio, and video cases.
- [ ] Record PR URL and validation results.

### PR 5, if needed: Integration and rollout preparation

- [ ] Complete cross-layer verification and fix integration gaps.
- [ ] Confirm rollout and flag-disable behavior.
- [ ] Review failure diagnostics without exposing message content.
- [ ] Decide whether to enable the feature and later remove the temporary flag.
- [ ] Record PR URL and validation results, or explain why a separate PR is unnecessary.

## Decisions to settle before the relevant implementation

- [x] Jira issue key: `WPB-26307`.
- [ ] Design approval and PR sequence.
- [ ] Flag name, enrollment rules, and toggle/restart behavior.
- [ ] Exact persisted lifecycle and reconciliation strategy for uncertain delivery.
- [ ] Editor behavior when reconnection or transmission occurs during editing.
- [ ] Ordering policy: whether a large pending asset blocks later text messages.
- [ ] Pending status wording and visual treatment.
- [ ] Retention policy for queued messages and attachment bytes.
- [ ] Treatment of self-deleting messages while queued, preserving existing
      editing restrictions and the agreed start of their destruction timer.
- [ ] Scope for share-extension submissions and recovery when the main app resumes.

## Acceptance and validation checklist

- [ ] Sending offline immediately creates a visible local pending message.
- [ ] Waiting offline beyond the normal attempt timeout does not fail the message.
- [ ] Reconnection sends queued messages without further user interaction.
- [ ] Relaunching offline preserves enrolled messages; reconnecting later sends them.
- [ ] Repeated offline edits deliver the final content without an edited marker.
- [ ] Offline edits to previously sent messages retain the edited marker.
- [ ] Quotes, mentions, multipart attachments, and link previews remain consistent.
- [ ] Reconnection during editing cannot silently lose the user's changes.
- [ ] A lost acknowledgement does not cause unsafe content replacement or duplicate
      visible messages; verify protocol-specific behavior.
- [ ] Assets recover before upload, during upload, and after upload but before the
      asset-reference message succeeds.
- [ ] Queued asset bytes survive the supported restart and cleanup scenarios.
- [ ] Deleted or cancelled messages are not subsequently sent.
- [ ] Missing attachment data produces a recoverable or actionable failure.
- [ ] Membership removal, verification changes, legal hold, and permanent server
      errors retain the required protections and user feedback.
- [ ] Verify Proteus and MLS, with both synchronization implementations.
- [ ] Verify self-deleting messages and account/session lifecycle behavior.
- [ ] Verify the flag-off path and disabling the flag with queued messages present.
- [ ] Run focused unit/integration tests using the repository's test workflow.
- [ ] Run relevant UI/snapshot tests; new UI test methods include Testiny TC IDs.
- [ ] Run required formatting and lint checks for changed code.
- [ ] Perform manual simulator/device reconnect and restart checks.

## Execution notes

- No feature code has been changed yet.
- The existing `.ruby-version` modification and temporary RFC belong to the user
  and must remain untouched by this work.
- Update this checklist in each implementation PR with completed items, actual
  design decisions, test evidence, and any justified changes to the sequence.

## Plan handoff and cleanup

- [x] Commit this plan separately from feature code using the feature's Jira key
      on `chore/pending-messages-plan-WPB-26307`.
- [ ] Update and commit checklist progress at meaningful handoff points.
- [ ] Before removing the plan from a PR branch, preserve its latest committed
      version for the next branch if implementation work remains.
- [ ] Carry the plan forward by restoring the file from its latest plan commit or
      cherry-picking a plan-only commit; keep completed items and test evidence.
- [ ] Remove the plan from each PR's final changes before merging into `develop`.
- [ ] Verify the final PR diff contains no `PENDING_MESSAGES_PLAN.md` file.

The plan is a temporary collaboration artifact. Its presence on a working branch
does not mean the feature design or rollout has been approved. The supplied PDF
and unrelated local changes must not be included in plan commits.
