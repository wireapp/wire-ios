# Offline pending messages: implementation plan

Last updated: 2026-10-21

Jira issue: [WPB-26307](https://wearezeta.atlassian.net/browse/WPB-26307)

Original plan branch (older snapshot): `chore/pending-messages-plan-WPB-26307`

Investigation staging branch (latest plan and isolated prerequisite fix):
`fix/preserve-bootstrap-trackers-WPB-26307`

Local testing preference: use `xcodebuild` directly. The user confirmed this on
2026-10-21; repository CI can continue using Fastlane.

Latest validation preference (2026-10-21): the user will run formatting, lint,
and tests when required. Do not execute those checks as the agent. Earlier runs
below predate that instruction; do not rerun them without a new request.

This is the working checklist for investigation, design, implementation, and rollout.
Check an item only when its result has been verified. Record relevant PRs and test
results here as work progresses. Implementation details below are proposals until
the design decisions are approved.

## Resume here

Current working branch: `feat/pending-message-foundation-WPB-26307`, based on
`develop` at `53a362f1b3fe0e0a9ae907b0e532840bd30a8532`. This began as a provisional
merge-queue base with the user's approval; the latest fetch confirms it landed.
See the provisional-base update below. The user clarified the workflow: implement
on this one feature branch and tick off the checklist. The two older branches
are parked investigation history; do not create further stage branches. The
foundation contract is authorized and implemented; validation belongs to the user.
Regular-message queuing/reconnect/restart integration is now implemented behind
the default-off flag, with source coverage added and no build/test execution.
Queued-text editing, draft retention when a send claim wins, and a local Queued
status are now written as well; all validation for these stages belongs to the user.
Classic asset enrollment/retention/recovery is now written with regression source.
The share extension explicitly leaves main-app outbox ownership with the main app.
The 2026-10-22 source review also closes UI Retry/Cancel races with sync-context
send claims and cancellation after asset upload but before message handoff. The
regression source is written; no build, test, lint, or formatting execution occurred.
Follow-up source fixes stop repeated sends after a failed handoff save and ignore
asset preprocessing/upload work after teardown. Sender response-classification
and teardown regressions are written, still unexecuted.
Further source review guards late final-message callbacks and reconnects after
account-context closure. Bounded MLS repair/frozen-content regression source is
also written; it has not been executed.
Uncertain-delivery automatic retry policy remains unresolved before broad activation;
the development implementation exposes manual Retry while retaining frozen content.

Current state: 2026-10-22. The prerequisite bootstrap tracker fix is implemented
on `fix/preserve-bootstrap-trackers-WPB-26307`, with two regression tests and all
13 bootstrap tests passing. Foundation and regular-message integration are written.
New enrollment requires the local flag at stack/session startup. It remains off
by default. Implementation stages 1-4 are written; compilation, execution of new
regressions, device verification, and rollout decisions remain outstanding.
Read `AGENTS.md`, the reported manual results, and the code verification section
before continuing. The user reports that the fix resolves the device upload
problem. The user is handling a separate bug ticket, PR/branch, merge, and
cherry-picks through release branches to `develop`; do not create duplicates.
The separate bug is `WPB-29555`, PR #5427; see the candidate verification below.

Next steps, in order:

1. Inspect the current checkout and preserve unrelated local changes. Confirm
   the prerequisite fix is present on the intended base before beginning feature
   implementation; its merge/backport work is being handled by the user. Check
   the implementation, not only the original commit hash, since cherry-picks or
   squash merges may change the hash.
2. Resume the pending-message feature under `WPB-26307`. Review the regular versus
   asset send paths and remaining open decisions. Known test setup is a physical
   device from Xcode with Wire Drive disabled for the team. Exact build/protocol/
   sync implementation and video receiver confirmation remain unrecorded; do not
   treat those as established. The bootstrap upload bug is separate from this feature
   and should not be reimplemented or backported again by the new session.
3. Foundation and regular-message integration are implemented. User owns
   validation; no checks were executed for the regular-message integration.
   Queued editing/presentation are also written with regression source, without
   executing checks. Classic asset enrollment/retention/recovery is also written.
   See the PR 3/4/5 execution records below. Continue source integration review and
   any fixes alongside user-owned validation; do not run checks without a new
   user instruction. Proteus sender response-classification and asset teardown
   coverage are now written. Bounded MLS repairs and late callbacks after account
   context closure also have unexecuted regression source. Cancellation while
   waiting for sync, interruption during preparation, and full account/session
   lifecycle still need review; these tests have not established runtime correctness.
4. Continue through regular queuing, queued editing, and asset recovery on the
   same branch. Treat the numbered PR checklists below as implementation stages;
   defer PR packaging until there is working code to review. Do not repeat the
   approval loop for the agreed foundation, sequence, or flag direction.

All feature findings and reported observations are recorded in this file. The
temporary RFC is not part of the plan commits. Keep this plan on working branches
as needed and remove it from the final changes before merging into `develop`.

Unrelated local modifications at handoff: `.ruby-version` and
`wire-ios/Wire-iOS/Generated/Strings+Generated.swift`. They were left untouched and
excluded from the handoff commit.

Update for the 2026-10-21 handoff: only `.ruby-version` is currently modified;
the generated strings file is clean. Recheck status when resuming.

If this file is absent from a clean feature branch, recover it from the latest
handoff commit in this repository. Restore or copy only `PENDING_MESSAGES_PLAN.md`;
do not cherry-pick unrelated implementation or investigation history merely to
recover the document. Keep the plan out of final PR changes merged to `develop`.

## Branch roles and merge routing

The two existing `WPB-26307` branches are temporary investigation artifacts. They
are not a planned chain of PRs. Do not merge either branch wholesale into
`develop`, or merge them into each other just to recover the plan.

| Branch or work | Role | Destination |
| --- | --- | --- |
| `chore/pending-messages-plan-WPB-26307` | Original plan snapshot, currently at `852665c942`; superseded by the plan on the staging branch. | No merge planned. Retain until the latest plan is safely carried forward; cleanup can happen later. |
| `fix/preserve-bootstrap-trackers-WPB-26307` | Investigation staging branch containing the isolated code fix plus subsequent plan-only commits. The old feature key does not make this the final bug PR branch. | No wholesale merge planned. Only code/test commit `b75130623b` is intended for the user's separate bug branch/PR. |
| Separate bootstrap bug PR #5427 (`WPB-29555`) | User-owned bug fix and release backports. | Fix reached `develop` at `53a362f1b3`. Do not duplicate the user's PR or backport work. |
| `feat/pending-message-foundation-WPB-26307` | The one active branch for all offline pending-message implementation stages. | Based on `develop` containing the fix; eventual PR targets `develop`. Keep the checklist committed here and remove it from final merge changes. No further stage branches are planned. |

When starting the feature branch, verify the bootstrap implementation on the base
because cherry-picks and squash merges may change its hash. Recover only
`PENDING_MESSAGES_PLAN.md` from the latest handoff commit on the staging branch;
do not cherry-pick the staging branch's history. If this staging branch has moved
or been deleted, use the handoff commit hash supplied in the previous session.
The original `chore/` branch does not contain the latest investigation or handoff.

The staging branch and its latest handoff commits are currently local; the remote
`chore/` branch holds the older snapshot. A new session in this same repository
can read the local commits. Another clone needs the latest plan transferred or
its containing branch pushed before it can resume from that document.

## Resume verification and design review (2026-10-21)

- [x] Read repository guidance and the latest plan at `93d0dd62af`.
- [x] Inspect the checkout: handoff branch is
      `fix/preserve-bootstrap-trackers-WPB-26307`; only `.ruby-version` was
      modified (`3.4.7` to `3.4.11`). Leave that user change untouched.
- [x] Fetch `github/develop` and inspect the bootstrap implementation, rather
      than relying on commit ancestry. The fetched base is `2654de1e4c`.
      `addChangeTrackers:` still copies `changeTrackers.mutableCopy`, and neither
      new regression test is present. The prerequisite has not reached this base.
- [x] Recheck the prerequisite on the authorized provisional feature base and
      confirm it subsequently reached `develop`. The user continues to own the
      separate bug PR and backports.
- [x] Obtain agreement on the feature sequence and default-off flag direction
      during the subsequent lifecycle/schema discussion. Exact schema approval
      remains separate. No feature code or schema changes have been made.

Recommendations recorded at the initial review. The subsequent user agreement
covers the sequence and flag direction; the concrete schema remains a proposal:

1. Retain PRs 1-4 below: foundation; regular-message queuing/recovery; queued
   editing/presentation; classic assets. Use PR 5 only for remaining integration
   and rollout work. Each branch starts from updated `develop`, after its
   dependencies have landed; carry forward only the latest plan file.
2. Use `DeveloperFlag.offlinePendingMessages`, default off. In PR 1, enroll no
   messages. From PR 2, enroll newly submitted supported messages while enabled,
   including online submissions so an ensuing disconnection can be recovered.
   Do not adopt existing legacy/failed messages or hidden protocol traffic.
3. Read the enrollment flag at session startup; require an app restart after a
   toggle. Disabling stops new enrollment while already-enrolled messages retain
   their recovery path. Keep schema migration safe with the flag off.
4. Use an explicit persisted lifecycle distinguishing never-attempted queued
   content, a claimed attempt, uncertain delivery, success, and terminal failure.
   Offline waiting must not consume the attempt timeout. Serialize payload edits
   and send ownership on the managed object context. Once transmission may have
   occurred, preserve that payload until reconciliation establishes its outcome.
5. Before PR 1 schema work, review exact fields/migration and protocol-specific
   lost-acknowledgement recovery. Before later PRs, settle editor/send races,
   ordering, status wording, retention, self-deleting messages, and share-extension
   enrollment. Classic assets match the current device setup; Wire Drive draft
   support requires an explicit scope decision.

No tests were rerun during this read-only code review and plan update. The prior
13 passing bootstrap tests remain the recorded validation of the isolated fix.

### Provisional-base update (2026-10-21)

The user authorized continuing before merge-queue CI completes, using candidate
`53a362f1b3fe0e0a9ae907b0e532840bd30a8532`. This supersedes waiting for the
`develop` ref to advance before branch creation; final feature integration still
targets `develop`. It does not approve unresolved feature design decisions.

- [x] Verify the candidate implementation. It preserves `self.changeTrackers`
      using `arrayWithArray:`, and contains both original regressions plus
      `testThatItKeepsAddedTrackersWhenInitializedWithoutTrackers`.
- [x] Identify the separate fix as `WPB-29555`, PR
      [#5427](https://github.com/wireapp/wire-ios/pull/5427), from candidate commit
      metadata. The user retains ownership of that PR and its backports.
- [x] Create `feat/pending-message-foundation-WPB-26307` at the exact candidate
      and carry forward only this plan from `090bef5898`; do not merge the
      investigation branches. Preserve the user's `.ruby-version` modification.
- [x] Fetch and confirm `github/develop` is exactly `53a362f1b3` in the subsequent
      lifecycle review. The provisional candidate is now the accepted feature
      base; no rebase is necessary. Recheck current `develop` before integration.

Initial lifecycle/schema review: the current messaging model is `2.144.0`.
Schema sources live in `WireData`, while version sequencing/migration support
lives in `wire-ios-data-model`. Both Proteus and MLS encrypt before making their
HTTP send call. Therefore claiming/fixing the content must precede encryption;
changing a managed message during an active attempt is unsafe. Incoming regular
messages look up existing objects by nonce within a conversation, but this alone
does not prove safe end-to-end retry or lost-acknowledgement reconciliation for
both protocols. Those details still require verification before schema approval.

No production or test implementation has started. No new tests have been run.

## PR 1 concrete contract for review (2026-10-21)

The user authorized proceeding on the single feature branch after this review.
Foundation implementation is now in progress. Stage 1 remains
foundation-only: schema, model lifecycle primitives, flag, and meaningful tests;
no creation/edit/send call site enrolls a message yet, even with the flag on.

### Findings that constrain the design

- Proteus retries selected temporary errors and missing-client errors through
  `MessageSender.sendMessage` again. This rebuilds/encrypts from the live managed
  message; there is no persisted attempt ownership or frozen payload today.
- MLS similarly re-enters sending after selected stale-epoch/client/group errors,
  repairing group state where required. Generic transport failures do not provide
  durable reconciliation. Reusing ciphertext is not a universal retry strategy:
  an explicit stale-epoch rejection requires fresh encryption after repair.
- `HttpClientImpl.send` exposes only a final response. The scheduler can reject
  work before transmission when offline, but the current API does not carry a
  durable per-attempt record proving that no bytes were handed off.
- `MessageAPI.mapSuccessResponse` throws `errorDecodingResponse` even after an
  HTTP success. Treating every thrown error as proof of non-delivery is unsafe.
  Recognized positive server acceptance must be distinguished from unreadable
  recipient/status metadata; incomplete metadata may still need reconciliation.
- Incoming messages correlate by conversation/nonce and validate the sender
  client. Existing `ZMClientMessage` content is not overwritten with arbitrary
  new text: its update path applies link-preview updates instead. Reusing an
  original nonce with changed user text cannot implement a delivered-message edit.
- The official [GenericMessage protocol](https://github.com/wireapp/generic-message-proto#message-id)
  defines message IDs as update correlation IDs, with multiple events per ID,
  and permits different handling of invalid collisions. This is not an
  end-to-end exactly-once guarantee. No backend idempotency contract or guaranteed
  self-echo recovery was established by this review.
- Current message dependency ordering stops looking back after three minutes.
  A durable outbox cannot inherit that as its long-term ordering policy. Decide
  asset-versus-text ordering before PR 2; do not change it in PR 1.

Primary local sources inspected: `MessageSender.swift`, `MessageAPI.swift`,
`HttpClientImpl.swift`, `ZMTransportRequestScheduler.m`,
`ZMClientMessage+Encryption.swift`, `ZMOTRMessage+UpdateEvent.swift`,
`ZMClientMessage+UpdateEvent.swift`, `ZMMessage+Dependency.swift`, and existing
message sender/model tests. This is source inspection, not executed validation.

### Proposed persisted representation

Add these **local-only** attributes to abstract Core Data entity `Message`, shared
by `ClientMessage` and `AssetClientMessage`. Expose typed accessors/lifecycle
operations in the data model; add the attributes to ignored modification keys so
they do not become upstream synchronization work. Keep existing delivery fields.

| Attribute | Core Data type/default | Purpose |
| --- | --- | --- |
| `outboxStateRaw` | Integer 16, `0` | `notEnrolled = 0`, `queued = 1`, `preparing = 2`, `sending = 3`, `uncertain = 4`, `sent = 5`, `failed = 6`, `cancelled = 7`. Unknown values must fail closed, without sending or enabling editing. |
| `outboxOperationRaw` | Integer 16, `0` | `none = 0`, `initialMessage = 1`, `edit = 2`, `contentUpdate = 3`. Keep original sends, normal edits, and protocol-supported follow-up content such as link previews distinct. |
| `outboxEnqueuedAt` | Optional Date, nil | Stable accepted-operation time, separate from server and attempt timestamps. It does not itself decide cross-type ordering. |
| `outboxAttemptIdentifier` | Optional UUID, nil | Fresh token when claiming each attempt; callbacks must match the current token, allowed state, and live object. |
| `outboxPayload` | Optional Binary, nil | Foundation `2.145.0` compatibility storage only. Stage 2 replaces new snapshot writes with the EAR-aware `outboxSnapshot` relationship in `2.146.0`; see the execution record. |
| `outboxSnapshot` | Optional to-one relationship to GenericMessageData, nil | Current snapshot storage, with inverse `outboxMessage` and cascade cleanup. Uses existing encryption-at-rest storage/migration. |
| `outboxAttemptCount` | Integer 32, `0` | Persisted bounded backoff bookkeeping; increment on a claimed attempt, never while merely waiting offline. |
| `outboxNextAttemptAt` | Optional Date, nil | Earliest eligible retry time for event-driven/backoff scheduling. It is not a queue expiration deadline. |

The snapshot is the content source, not cached ciphertext. Recheck current
membership, protocol, verification, and legal-hold rules for every attempt. Apply
required current transport/compliance metadata to a derived copy; do not use a
snapshot to bypass current checks. Once sent, release the snapshot and retry
bookkeeping atomically with finalization. Starting a later edit/content update
creates a new operation and invalidates the previous attempt token.
Cancellation, deletion, obfuscation, and account removal must clear the snapshot
alongside existing sensitive content and invalidate callbacks. Enrolling
self-deleting messages remains gated on agreeing their timer policy before PR 2.

### Proposed transition and recovery rules

1. `notEnrolled` retains the entire legacy path. PR 1 never leaves this state
   from production submission, editing, bootstrap, or sending code.
2. Future enrollment persists `queued` and its operation intent before reporting
   successful local acceptance. Network unavailability leaves it queued without
   assigning a network-attempt deadline.
3. Claim on the managed object context: persist `preparing` and a new attempt
   token; capture an immutable content value before encryption. Concurrent claims
   and in-place edits fail atomically. Use the existing persisted snapshot for
   retries, if present. Only initial queued text with no snapshot is eligible
   for the future in-place queued-edit action.
4. Persist `sending` and the content snapshot atomically **before** giving any
   message request to the HTTP client. If saving fails, do not hand off the
   request. Snapshot presence means at least one handoff was possible; keep it
   as a conservative content lock across retries. Start the attempt
   timeout at handoff, keeping the existing message-destruction timer separate.
   This requires later integration inside the sender, not only its outer strategy.
5. Definitive pre-handoff failure or explicitly retryable non-acceptance can
   return to `queued`, preserving any existing snapshot. A first preparation
   failure leaves the snapshot nil and the original text editable again.
   Connectivity recovery alone does not justify unlocking content whose handoff
   was possible. Refining this after a proven negative response requires tracking
   all prior acceptance outcomes, not only the last response.
6. Lost connection/response, ambiguous timeout, or restart from `sending` becomes
   `uncertain`, preserving the snapshot and nonce. Restart from `preparing` can
   return to queued only under the enforced invariant that transport was never
   called in that attempt's preparation state. An existing snapshot remains
   locked; nil means the operation never reached possible handoff. PR 1 tests
   the pure recovery decision; PR 2 integrates it.
7. Accepted send finalizes as `sent`; terminal rejection becomes `failed` with
   the existing actionable failure semantics at integration time. Deletion or
   cancellation invalidates attempt ownership; late callbacks cannot resurrect
   removed content. Queued never-transmitted deletion requires no remote delete.
8. `uncertain` is never silently treated as a never-sent editable message. Do not
   enable automatic resend from it until the protocol/recipient deduplication and
   reconciliation policy is verified and agreed. A conservative manual-retry
   fallback is a proposal, not an approved product behavior. This gate belongs
   before PR 2 activation and does not require choosing a retry policy in PR 1.
9. An open editor must retain its draft if send ownership wins the race. Before
   confirmation, recheck on the sending context without reserving the row while
   the editor is open. Unclaimed content updates in place; confirmed sent content
   uses a normal edit. An active/frozen/uncertain operation rejects confirmation
   and retains the draft. Never change its snapshot to implement an edit.

### Migration, flag, and validation scope

- Create messaging model `2.145.0` from `2.144.0`, update its model identifier and
  `.xccurrentversion`, and add `v145` / `v144 -> v145` to migration sequencing.
  Use an inferred mapping for additive defaulted/optional fields; verify inference
  and an actual SQLite migration rather than assuming compatibility. No migration
  action should enroll or revive existing messages.
- Keep schema defaults safe with `DeveloperFlag.offlinePendingMessages` off.
  Add the flag with a nil bundle override/default false, and tests proving default
  and explicit values. From PR 2, sample enrollment policy at session startup;
  restart applies toggles. Existing enrolled work continues recovery when off.
- Test real SQLite migration for regular, asset, delivered, expired, and edited
  rows: preserve content, nonce, delivery/expiration fields, relationships, and
  local modification keys; all new outbox metadata remains unenrolled/defaulted.
- Test persistence across save/refetch and separate contexts; exclusive claims;
  stale/previous-operation callback rejection; unknown raw state handling;
  snapshot/nonce stability; preparation versus in-flight crash recovery; and
  preservation of legacy behavior. Keep every test tied to a lifecycle invariant.
- Run focused `WireDataModel` migration/lifecycle tests and relevant legacy model
  tests directly with `xcodebuild`. Run flag tests in the utilities target, plus
  formatting/lint appropriate to changed Swift code. Record exact commands and
  results during implementation. No tests were executed for this design review.
- Keep this plan committed on the feature branch and remove it from the final PR
  changes before merging into `develop`.

- [x] User agreement to the staged review, sequence, and default-off flag direction.
- [x] Source review and concrete lifecycle/schema/test proposal prepared.
- [x] Proceed with the concrete foundation contract following the user's
      clarification to start implementation on one branch and tick TODOs.
- [ ] Before PR 2: verify/agree uncertain-delivery recovery and ordering policy.

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
- [x] Agree the staged PR sequence and default-off local flag direction.
- [x] Proceed with the concrete foundation contract on the one active branch.
- [ ] Resolve later product decisions before activating corresponding paths.
- [x] Record the Jira issue key before creating commits or PRs: `WPB-26307`.
- [x] Audit the reported baseline behaviors against the code, including asset
      reconnect handling and the cancel-to-Retry transition. See the verification
      section for supported behaviors, corrections, and remaining uncertainty.
- [ ] Run and record the manual baseline scenarios below before finalizing the design.
- [ ] Implement the feature incrementally.
- [ ] Complete validation and rollout review.

The investigation above is based on source inspection, supplemented by the
user-reported manual baseline results below. Bootstrap regression tests have now
been run for the prerequisite fix and an initial foundation run was recorded;
new regular-message/EAR coverage is written but has not been executed.

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
| Restart | Eligible unsent regular messages recovered at bootstrap are expired (`isFresh == false`). The asset-message strategy does this only for assets already `.uploaded` and eligible at bootstrap; assets still preprocessing/uploading follow a different recovery path. |
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
- [Upload retry bookkeeping](wire-ios-request-strategy/Sources/Object%20Syncs/Upstream/ZMUpstreamModifiedObjectSync.m)
- [Transport scheduler](wire-ios-transport/Source/TransportSession/ZMTransportRequestScheduler.m)
- [Transport session](wire-ios-transport/Source/TransportSession/ZMTransportSession.m)
- [Application status](wire-ios-sync-engine/Source/Synchronization/ApplicationStatusDirectory.swift)
- [Asset storage](wire-ios-data-model/Source/Model/Message/FileAssetCache.swift)
- [Asset cancellation](wire-ios-data-model/Source/Model/Message/ZMAssetClientMessage+FileMessageData.swift)
- [Asset resend](wire-ios-data-model/Source/Model/Message/ZMAssetClientMessage.swift)
- [File action state](wire-ios/Wire-iOS/Sources/UserInterface/Conversation/Content/Cells/FileTransfer/FileTransferView.swift)
- [Video/file upload routing](wire-ios/Wire-iOS/Sources/UserInterface/Conversation/InputBar/ConversationInputBarViewController+Files.swift)
- [Wire Drive draft upload](WireMessaging/Sources/WireMessagingDomain/WireDrive/UseCases/UploadDraftUseCase.swift)
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
- [x] **B7 partial observation: File restart.** The user reports that after
      restarting, they needed to cancel the file upload to expose Retry; Retry
      then worked. The upload's failure to progress has not been reproduced or
      explained by runtime evidence. This is the user's scenario 4 repeated with
      a file, separate from the text result recorded as B4.
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
| B7 | User reports, 2026-10-20/21; physical device from Xcode; Wire Drive disabled for the team; exact build/protocol/sync implementation unknown | Assets appear not editable. A video appeared to send when Wi-Fi was enabled again. After restarting with a file, cancelling its upload exposed Retry, which worked. On Oct 21, the user confirms upload does not start when connectivity returns. | Classic asset path confirmed. Capture breakpoint evidence for restored upload tracking and reconnect polling. Confirm video receipt/playback and whether Retry was used. Image/audio comparisons remain pending. |
| B8 | Not run | Not recorded | |

- [x] Compare reported observations with source paths; record supported behaviors
      and corrections in the verification section below.
- [ ] Reproduce unexplained outcomes with logs, particularly the file upload
      remaining in an uploading state after restart.
- [ ] Confirm the video reconnect result on the receiver and compare with text;
      identify which asset stage waited offline before changing its recovery path.
- [ ] Repeat relevant cases for MLS and Proteus, and each synchronization
      implementation available in the test environment.
- [ ] Refine the design and automated regression cases using the observed results.

The first four user-reported scenarios cover online control, offline text
submission, an offline edit of already-sent text, and relaunch with unsent text.
Manual Retry recovers the reported text failures; automatic recovery was missing
in those runs. This does not establish that every offline text send always fails.
Keep retrying an edit separate from retrying a new
message when designing recovery. Asset editing appears unavailable, consistent
with source inspection. A video tentatively recovered on Wi-Fi reconnection,
unlike the reported text cases. A file required cancellation and Retry after
restart. These observations do not establish the exact failure causes or prove
that all assets behave alike.

Asset tests concern queuing, upload, cancellation, and delivery recovery. They do
not require introducing editing for standalone assets. Editing text in a multipart
message is a separate case from replacing or editing its asset content.

## Code verification of the reported baseline

Audit date: 2026-10-20. Method: source tracing and inspection of existing tests.
No tests were executed in this audit. Source-supported behavior means the code
contains the described path; it does not prove which path ran on the user's device.
Manual-run checkmarks above track reports, not independent verification of every
substep. The tested build, protocol, upload mode, and exact timings remain unknown.

### Regular text, edits, and Retry

- [x] **Normal editing is implemented.** `ZMClientMessage.editText` constructs a
      `MessageEdit`, changes the nonce, sets `updatedTimestamp`, and makes the
      message eligible for sending again. Received edits apply the changed text
      and set the update timestamp. This supports B1.
- [x] **Offline text can become failed-to-send.** The regular strategy invokes
      `MessageSender` directly when an object matches its unsent predicate. Its
      sync observer waits for decryption, not for connectivity. The HTTP adapter
      submits a one-time request to the transport scheduler, whose offline path
      completes requests with `tryAgainLater`. Proteus has bounded immediate
      retries; errors escaping either protocol's sender cause the regular
      strategy to expire the message. The expiration timer is another failure
      path. This supports B2 without proving its specific error or timing.
- [x] **Expired text is excluded from automatic insertion.** The regular
      strategy's predicate requires `isExpired == false`. Connectivity recovery
      does not itself clear that property in the traced send path. The user Retry
      action calls `resend()`, which clears expiration and makes the message
      eligible again. This explains why a failed message needs manual Retry.
- [x] **A failed edit can be retried.** Edits set `delivered = false` and use the
      same regular-message strategy. On expiration, `ZMClientMessage` restores
      the original nonce; on Retry it reapplies the edit with a new edit nonce
      before clearing expiration. This supports B3.
- [x] **Regular-message restart expiration is explicit.** Bootstrap passes
      eligible stored objects to `InsertedObjectSync.addTrackedObjects`, which
      uses `isFresh: false`. The regular strategy expires them. Already-expired
      messages remain excluded by its predicate. This supports B4.
- [x] **Standalone assets are not editable through the existing action.** UI
      `canBeEdited` requires text content and a sent/delivered/read state. Model
      edit eligibility is limited to text, multipart, and edited payloads.

These paths do not imply that every text submitted offline must fail: a send can
still be waiting for sync/dependencies when connectivity returns. Verify timing
and logs before treating an observed result as universal.

### Asset upload and reconnect

- [x] **The classic upload stage supports retry after temporary errors.**
      `AssetV3UploadRequestStrategy` uses `ZMUpstreamModifiedObjectSync`. Its
      `TemporaryError`/`TryAgainLater` branch returns the synchronization token
      to pending work instead of expiring the message. The scheduler limits sync
      request generation to zero while offline; restored reachability restores
      capacity and notifies the operation loop to poll again. Upload can resume
      automatically through this path, consistent with the video observation.
- [x] **Upload and message delivery have different failure policies.** Successful
      upload stores asset identifiers and transitions to `.uploaded` after all
      associated assets are ready. Only then does the asset-message strategy
      invoke `MessageSender`. Errors escaping that stage expire the message.
      Therefore upload auto-retry does not guarantee automatic recovery of final
      message delivery. Permanent upload failures and cancellation/expiration
      also have distinct failure paths.
- [x] **Correct the earlier online-gate explanation.**
      `.allowsRequestsWhileOnline` in the abstract request strategy uses
      `ApplicationStatusDirectory.synchronizationState`, whose `.online` value
      means the client is registered/ready for requests. It does not measure
      Wi-Fi or backend reachability. Actual offline capacity/rejection handling
      is in the transport scheduler. Do not infer connectivity gating from this
      configuration name alone.
- [x] **Creation-time expiration policies differ.** Classic `appendFile` uses
      `expires: false`; classic images and text use `expires: true`. These set
      `shouldExpire`, which controls assignment of a network-attempt expiration
      date. `shouldExpire == false` does not prevent explicit expiration after
      an error or on stale-message handling. It is not a durable-outbox guarantee.
- [x] **The UI has more than one upload path.** Video/file selection uses
      `useWireDrive()` to choose classic `appendFile` versus Wire Drive draft
      uploading. The latter uses `UploadDraftUseCase` and a different upload
      manager. Identify the tested path before attributing a runtime observation
      to classic asset retry logic; a draft upload is not message delivery.

### Asset restart and cancel-to-Retry

- [x] **Correct the blanket asset-restart statement.** The asset-message
      strategy's initial fetch predicate includes `transferState == .uploaded`.
      Its stale expiration branch applies to objects eligible at that bootstrap.
      An older asset still preprocessing/uploading is handled by those trackers;
      if upload finishes later, `objectsDidChange` invokes insertion with
      `isFresh: true`. This flag describes how the tracker encountered the object,
      not a reliable creation time. Restart behavior depends on the asset stage.
- [x] **Cancel exposes Retry by design.** `FileTransferView` routes its action
      button to Cancel while the transfer state is `.uploading`, and to Resend
      for `.uploadingFailed`/`.uploadingCancelled`. `cancelTransfer()` explicitly
      expires the message as cancelled, sets `.uploadingCancelled`, and clears
      progress. The footer's Retry is also associated with failed-to-send state.
      This supports the reported change in available actions after cancellation.
- [x] **Retry can restart the upload.** `ZMAssetClientMessage.resend()` restores
      `.uploading` unless bytes are already uploaded, resets progress, marks
      `transferState` locally modified, and clears expiration through its base
      implementation. This supports the successful manual recovery report.
- [ ] **Explain the stalled file upload after restart.** The UI derives its
      uploading state from persisted transfer state and local file availability;
      it does not prove that an upload task is running. Recovery also depends on
      processing state, required cached bytes, locally modified transfer keys,
      background task handling, and runtime request/dependency state. Logs or a
      deterministic regression are needed to identify the failed condition.
- [ ] Verify video receipt/playback without Retry and identify its actual path.

### Existing test evidence inspected, not executed

- `ZMUpstreamModifiedObjectSyncTests`:
  `testThatItCallsDidNotFinishToSynchronizeTokenWhenTheRequestFailsWithATemporaryError`.
- `AssetV3UploadRequestStrategyTests`: successful upload state/identifier updates
  and `testThatItExpiresTheMessage_OnPermanentFailureResponse`.
- `ClientMessageRequestStrategyTests` and `AssetClientMessageRequestStrategyTests`:
  `testThatItExpiresStaleMessage`. The asset test calls `insert` directly; it does
  not demonstrate which upload states the bootstrap fetch actually selects.
- `ZMClientMessageTests_Editing`:
  `testThatWhenResendingAFailedEditItReappliesTheEdit`.
- `ZMAssetClientMessageTests`: cancellation and resend tests, including
  `testThatItCanCancelsUploadMultipleTimes` and
  `testThatTransferStateIsNotUpdated_WhenResending_IfAlreadyUploaded`.

Add targeted runtime/integration evidence before closing the remaining checks.
Use logs for upload start/success, final message send start/success/failure, stale
expiration, and cancel/resend, correlated by the same message identifier. Record
the build, MLS/Proteus, sync version, classic/Drive path, and connectivity sequence.

### Device breakpoint investigation (2026-10-21)

Confirmed setup: physical device launched from Xcode, Wire Drive disabled for the
team. User confirms that the upload does not start after connectivity returns.
No root cause is established yet. Capture state before Cancel/Retry changes it.

Latest debugger report: the user did not observe `addTrackedObjects` being called;
upload polling and `nextObjectToSync` are reached repeatedly. Repeated shared
breakpoint hits were too noisy. Next capture one paused queue snapshot for the
`AssetV3UploadRequestStrategy` instance before adding more breakpoints. Bootstrap
calls `addTrackedObjects` only when its matching result set is nonempty, so a
missing hit is not by itself proof that bootstrap never ran.

Captured queue snapshot: `self.transcoder` is confirmed as
`WireRequestStrategy.AssetV3UploadRequestStrategy`; `objectWithKeys` is nil;
`self.updatedObjects` reports `hasOutstandingItems 0` with an empty status map.
Thus no queued upload work is available in this tracker at the observed poll.
Next inspect its matching persisted assets on the same context, particularly
their processing state and locally modified keys. This snapshot alone does not
prove why the message was omitted or whether it is waiting on a dependency.

The subsequent LLDB fetch attempt was interrupted by `EXC_BAD_ACCESS` during
expression evaluation. Its later zero count and nil values are not valid evidence
of an empty database result. Do not mark the persisted-message checks complete.
Next verify the selected `nextObjectToSync` frame, native locals, and short
backtrace before evaluating further expressions. The interruption's cause is not
established; do not attribute it to the normal app upload path without evidence.

Follow-up backtrace: the selected `nextObjectToSync` frame is valid and on a
managed-object-context queue, but its caller is
`UserClientRequestStrategy.nextRequest`, not asset upload. This snapshot must not
be used to diagnose the file. The earlier snapshot explicitly showing an asset
transcoder remains valid for that earlier stop. Narrow the shared breakpoint by
capturing `upstreamSync` at `AssetV3UploadRequestStrategy.nextRequestIfAllowed`
and comparing `self` with that exact tracker address. Recapture the address after
each process restart. The LLDB fetch interruption remains unexplained.

The next dump, captured directly from `AssetV3UploadRequestStrategy` in the Swift
frame, confirms an empty `_objectIDsToStatus` map, empty dependency maps, and no
assets currently being preprocessed. The upload strategy uses the background
session. This reinforces the empty-tracker observation for the affected run.
Next inspect the actual file at entry to `cancelTransfer()`, before any state
mutation, to avoid another debugger-driven database fetch. Capture transfer and
processing states, delivered/expired flags, version, locally modified keys, and
object ID. This is initially a UI-context observation; confirm any proposed
tracking/persistence cause against the sync context before declaring a root cause.

- [ ] On relaunch, stop in `ZMUpstreamModifiedObjectSync.addTrackedObjects` at
      its `objectPassesTrackingFilter:mo` check. Limit inspection to the instance
      whose `transcoder` is `AssetV3UploadRequestStrategy`. For the affected file,
      record its object ID, transfer state, processing state, locally modified
      keys, and filter result. Expected for upload-ready content: transfer state
      `.uploading`, processing state `.uploading`, and the local modification key
      `transferState`. Record unexpected values rather than changing them.
- [ ] After enabling Wi-Fi, check whether
      `AssetV3UploadRequestStrategy.nextRequestIfAllowed` is reached. If not,
      investigate scheduler reachability/capacity and operation-loop wake-up.
- [ ] If reached, step into `ZMUpstreamModifiedObjectSync.nextObjectToSync`.
      Record whether `objectWithKeys` is nil, a dependency blocks it, or the
      predicate/filter rejects it. If the queue is empty despite a matching
      restored message, inspect `ZMLocallyModifiedObjectSyncStatus` initialization:
      it rejects objects without locally modified keys to synchronize.
- [ ] If the object survives these checks, stop in the upload strategy's
      `request(forUpdating:forKeys:apiVersion:)`. Inspect `message.assets` and
      whether an unuploaded asset and encrypted data are available.
- [ ] Compare captured state with the state after manual Retry, which explicitly
      marks `transferState` locally modified. Use the difference to formulate a
      deterministic regression test; do not assume missing keys are the cause.

### Root-cause candidate: bootstrap discards its original trackers

The affected file was inspected at entry to `cancelTransfer()`, before mutation:

| Property | Observed value |
| --- | --- |
| `transferState` | `0` / uploading |
| `processingState` | `2` / uploading |
| `delivered` | false |
| `isExpired` | false |
| `version` | 3 |
| `keysThatHaveLocalModifications` | contains `transferState` |

Thus the inspected message is upload-ready with the required key. Missing local
modification keys do not explain this UI-context snapshot. The asset tracker was
separately observed with no queued work or dependency entries.

Source inspection found a concrete defect in `ZMChangeTrackerBootstrap`:

```objc
NSMutableArray* allTrackers = changeTrackers.mutableCopy;
[allTrackers addObjectsFromArray:changeTrackers];
self.changeTrackers = allTrackers;
```

`addChangeTrackers:` copies the incoming list, appends that same incoming list,
and replaces the stored list. The previous trackers are lost. The proposed fix
is to initialize the mutable array from `self.changeTrackers` instead.

The lifecycle supports this as a cause of the observed startup failure:

1. The bootstrap is initially created with the base trackers, including the
   asset upload tracker and preprocessor.
2. Session setup constructs client-related strategies and queues
   `updateClientContextChangeTrackers`, which calls `addChangeTrackers:`.
3. That call immediately fetches the new client trackers and overwrites the
   bootstrap's stored base trackers with duplicate client trackers.
4. If this precedes the first operation-loop bootstrap fetch, that fetch omits
   the upload tracker. An already-preprocessed file can remain upload-ready
   without being placed in its upload queue.
5. Change notifications use `StrategyDirectory.contextChangeTrackers`, which
   still contains the base trackers. Cancel/Retry modifies the message and
   marks its transfer key, allowing this separate path to enqueue the upload.

This defect is now reproduced by two regression tests and fixed by copying
`self.changeTrackers` before appending new trackers. The user subsequently reported
that the device issue appears fixed. The device result is user-reported, not an
independent automated end-to-end verification.

### Prerequisite fix validation (2026-10-21)

Code/test commit: `b75130623b` on `fix/preserve-bootstrap-trackers-WPB-26307`.
The fix commit contains only the production correction and regression tests;
investigation and checklist updates are committed separately.

- [x] Both new regressions failed against the original implementation: existing
      trackers received no objects, and added trackers had incorrect fetch counts.
- [x] Applied the one-line mutable-copy correction.
- [x] Ran all 13 `ZMChangeTrackerBootstrapTests` using `xcodebuild`: 13 passed,
      zero failed, zero skipped, on iPhone 17 / iOS 26.5 Simulator, Xcode 26.6.
- [x] `git diff --check` passes. Only Objective-C production/tests and this plan
      were changed; no Swift formatting/lint changes are required for the fix.
- [x] User reports the device file-restart issue appears fixed after the correction.

Regression result bundle: `/private/tmp/wpb-26307-bootstrap-red.xcresult`.
Passing result bundle: `/private/tmp/wpb-26307-bootstrap-green.xcresult`.
The initial Fastlane attempt hit an assertion-macro syntax issue in the new test;
the corrected regression and final validation runs used direct `xcodebuild`.

Re-run locally:

```sh
xcodebuild test -quiet \
  -workspace wire-ios-mono.xcworkspace \
  -scheme WireRequestStrategy \
  -testPlan AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath DerivedData \
  -disableAutomaticPackageResolution \
  -parallel-testing-enabled NO \
  -only-testing:WireRequestStrategyTests/ZMChangeTrackerBootstrapTests
```

## Proposed design

### Persisted outbox lifecycle

These checks record code written for the supported default-off paths, not runtime
acceptance; validation and activation gates remain separate below.

- [x] Define explicit, persisted outbox metadata alongside the existing delivery
      state, including the additive schema and migration sequence.
- [x] Distinguish waiting locally, an active send attempt, an uncertain delivery
      outcome, successful sending, and terminal failure.
- [x] Distinguish never-sent content from an edit of previously sent content;
      `delivered == false` alone cannot establish that distinction.
- [x] Persist queued intent before reporting successful local submission.
- [x] Keep waiting time separate from network-attempt expiration.
- [x] Implement recovery of eligible messages on reconnect and after app restart.
- [x] Recheck synchronization, membership, protocol readiness, verification, and
      legal-hold requirements before sending.
- [x] Coordinate send ownership and payload snapshots on the managed object
      context so editing cannot race with transport handoff.
- [x] Classify known non-submission separately from permanent and ambiguous errors.
- [x] Implement bounded repairs, delayed non-submission retry, and one send owner
      per conversation; leave main-app ownership out of the share extension.
- [ ] Verify how to reconcile uncertain delivery after a lost acknowledgement;
      do not assume that retrying an arbitrary changed payload is safe.

### Editing

These checks record code written, not runtime validation.

- [x] Update never-sent queued text in place while preserving the original nonce.
- [x] Keep the outgoing payload as original text or multipart content, without a
      `MessageEdit` wrapper or an edited timestamp.
- [x] Preserve mentions, quotes, multipart attachments, and applicable metadata.
- [x] Reset or invalidate obsolete link previews and attachment detection results.
- [x] Preserve normal edit semantics for messages that were previously sent.
- [x] Define behavior when connectivity returns while the editor is open.
- [x] Define behavior when an edit is confirmed after a send attempt has claimed
      or transmitted an earlier payload.
- [x] Ensure queued deletion and empty-edit behavior cannot later send removed
      content or create unnecessary remote delete operations.
- [ ] Validate these paths, including separate-context ordering and asynchronous
      preview/image/upload completion races, using the user-owned checks.

### Assets

- [x] Implement recovery separately for preprocessing, asset upload, and final
      message sending (source only).
- [x] Reuse recorded asset references after successful upload.
- [x] Retain required bytes for the lifetime of a queued asset, accounting for
      cache eviction, cleanup, app restart, and account lifecycle.
- [x] Cancel recorded previous-session background uploads before restoring work
      from retained encrypted bytes/references; do not assume callbacks reattach.
- [x] Handle cancellation and missing local bytes explicitly.
- [x] Guard obsolete upload/preprocessing callbacks against reviving removed work.
- [ ] Validate these paths on device, including interrupted background uploads,
      image/file/audio/video processing, disk-full and failed-save behavior.

### Rollout

Current agreed workflow: implement the stages below on
`feat/pending-message-foundation-WPB-26307`, using a single default-off local
developer flag. Keep the TODO checklist current as code and tests are completed.
The previous recommendation of separate short-lived stage branches is superseded.
Decide PR packaging once working feature code is ready for review; target
`develop` and remove the temporary plan from the final merge changes.

- [x] Agree default-off `DeveloperFlag.offlinePendingMessages` direction.
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

### Proposed prerequisite fix: Preserve bootstrap trackers

This is a correction to existing startup recovery, separate from new outbox
semantics. Recommend a small `fix/` branch and PR before the feature foundation;
no new flag or migration should be required for this correction.

- [x] Confirm proceeding with the narrow bootstrap fix and regression coverage.
- [x] Add a regression demonstrating that adding client trackers before the
      initial full fetch must preserve and fetch original trackers.
- [x] Cover the stored tracker list having each original/new tracker once,
      including successive additions where relevant.
- [x] Change the mutable copy to use `self.changeTrackers`.
- [x] Run the focused bootstrap tests, recording failure before and success after
      the fix, and the relevant existing suite.
- [x] Device retest: user reports the observed issue appears fixed.
- [x] Record separate fix PR #5427 (`WPB-29555`) and verify it reached `develop`
      at `53a362f1b3`; retain the prior test evidence and user-owned backports.

The user is creating the separate bug ticket and PR/branch and handling merges
and release cherry-picks through to `develop`. Code/test commit to cherry-pick:
`b75130623b` (two files only). Do not include the temporary plan commits in that
bug-fix PR or its backports. `WPB-26307` remains the offline pending-message
feature's issue; do not assume it is the new bug ticket.

### PR 1: Outbox foundation

- [x] Agree foundation contract and start implementation on the active branch.
- [x] Add persisted metadata and migration with safe legacy defaults.
- [x] Add the default-off local flag and define enrollment rules.
- [x] Add lifecycle and migration tests (coverage added; final rerun is user-owned).
- [x] Keep actual message enrollment disabled in this foundation PR.
- [ ] Validate that existing sending behavior is unchanged.
- [ ] Record PR URL and validation results.

### Foundation execution record (2026-10-21)

Implemented on the one active feature branch:

- New `2.145.0` messaging model, version selection and migration sequencing.
- Seven local-only outbox fields, excluded from upstream modification tracking.
- Typed lifecycle operations with context-owned claims, per-attempt tokens,
  immutable payload values/snapshots, backoff metadata, terminal states, and
  distinct pre-handoff versus uncertain crash recovery. No sender/creation call
  site enrolls or uses this lifecycle yet.
- Default-off `offlinePendingMessages` developer flag.
- Lifecycle, SQLite migration, and flag regression coverage.

Before the user's instruction to stop automated checks, a direct `xcodebuild`
run completed with **13 passing tests and one failing migration test**. The
failure was the fixture's use of an invalid local modification key `testKey`.
Source inspection confirmed `ZMManagedObject.awakeFromFetch/removeObsoleteKeys`
intentionally removes unknown keys. The fixture now uses actual tracked keys:
`dataSet` for regular messages and `transferState` for assets. This correction
and a deleted-message recovery guard have **not been rerun**, per user preference.
The implementation compiled in the earlier run. Do not present the current tree
as fully validated.

Earlier result bundle: `/private/tmp/wpb-26307-foundation-model.xcresult`.
Earlier build/test log: `/private/tmp/wpb-26307-foundation-model.log`.
Earlier SwiftFormat completed; SwiftLint reported zero violations in the six
Swift files then checked. No further formatting, linting, or test execution is
authorized under the latest preference.

The earlier test selection was `WireDataModelTests/MessageOutboxTests`,
`WireDataModelTests/DatabaseMigrationTests_Outbox`, and
`WireDataModelTests/CoreDataMessagingMigrationVersionTests`, using scheme
`WireDataModel`, test plan `AllTests`, iPhone 17 / iOS 26.5 and local `DerivedData`.
The new utilities flag test has not been executed. No PR has been created.

### PR 2: Regular-message queuing and recovery

- [x] Implement enrollment for text, location, knock, and multipart behind the flag.
- [x] Implement connectivity gating alongside existing synchronization checks.
- [x] Implement queue wake-up after reconnect and context/readiness changes.
- [x] Implement recovery of enrolled messages after restart without stale expiration.
- [x] Implement separate waiting, attempt expiration, retry, and terminal failure.
- [ ] Verify message ordering and avoid duplicate send ownership.
- [ ] Add focused tests for text, location, knock, and multipart messages.
- [ ] Record PR URL and validation results.

### Regular-message execution record (2026-10-21)

The checkmarks above mean code is implemented and source reviewed, not that runtime
acceptance has been verified. **No formatting, lint, build, or test commands were
run for this stage**, following the user's validation preference. No PR is needed
yet; keep implementing on the existing branch. The user's unrelated `.ruby-version`
change remains untouched.

Implemented paths:

- Sample the flag when `CoreDataStack` is created and configure its view/sync
  contexts. Other background contexts do not enroll by default. New supported
  visible regular submissions are enrolled and saved before returning local
  acceptance; hidden protocol traffic, assets, self-deleting content, and MLS
  self-conversation submissions retain existing behavior at this stage.
- Track eligible queued messages without starting tasks/background activities
  while reachability is unavailable. Wake on reachability/context changes and
  serialize regular sends within each conversation using accepted-operation time.
  Existing cross-type dependency/asset ordering still needs review.
- Preserve existing synchronization/dependency checks. Claim on the sync context,
  encrypt an immutable content copy, persist its snapshot and sending state before
  HTTP handoff, and verify current membership/security/legal-hold rules again.
- Add an explicit transport error marker only where the scheduler rejects a
  request before creating a network task. Those provably unsubmitted requests
  return to queued state with persisted bounded backoff and one scheduled wake-up.
  Do not infer non-delivery from arbitrary `tryAgainLater` errors.
- Retry known missing-client/stale-epoch/group rejections through existing repair
  services with a bounded attempt loop. Keep the MLS invalid-leaf reset trigger.
  Recognize HTTP success even when recipient-status decoding fails; never blindly
  retransmit a known accepted request because its body could not be decoded.
- Resume restart-time preparation safely; treat interrupted in-flight work as
  uncertain. Development behavior shows existing Retry for uncertain delivery
  and preserves the operation's payload/nonce on explicit manual Retry. The final
  automatic reconciliation/product policy is still an activation gate.
- Enrolled-message waiting is excluded from the legacy expiration timer; an
  attempt deadline is assigned at handoff. Existing legacy messages retain their
  old strategy and expiration paths. Recovery does not require the enrollment flag.
- Keep normal sent-message edits as `MessageEdit` operations with the edited
  marker; keep link-preview follow-ups separate from the claimed original payload.
  Full editor/send race handling, including a confirmation overlapping an active
  metadata update, remains part of stage 3 before enabling for general use.
- Reject obsolete/cancelled callbacks and clear snapshots when message content
  is deleted or obfuscated. Account/session teardown cancels queue tasks/wake-ups.

Encryption-at-rest correction:

The foundation's raw binary snapshot is unsuitable for new live enrollment when
EAR is enabled. Model `2.146.0` adds `Message.outboxSnapshot` pointing to its own
`GenericMessageData` record, so existing per-record encryption and EAR enable/
disable migrations cover snapshots too. `2.145.0` is retained unchanged for safe
migration from local builds. Its optional legacy payload bytes are preserved and
converted through EAR-aware storage before new handoff; EAR enable migration
also converts any legacy snapshot records before encrypting the message data.
Locked/unreadable snapshots throw; they never become editable/unclaimed content.

Coverage added/updated, **not executed**:

- Flagged submission durability, hidden-traffic exclusion, disabling enrollment
  with existing queued work, and normal sent edits retaining their marker.
- Offline bootstrap retaining queued text and reconnect waking it without Retry.
- EAR-encrypted snapshots and missing-key failures preserving the content lock.
- Additive SQLite migration from both `2.144.0` and local-foundation `2.145.0`
  to `2.146.0`. Existing lifecycle tests now read snapshots through a throwing API.

Remaining stage-2 validation/coverage: location/knock/multipart send integration,
both protocols and sync implementations, scheduler rejection/backoff, positive
response with malformed body, security transitions, and ordering/callback races.
Do not call this feature validated or complete before those user-owned checks.

### PR 3: Queued text editing and presentation

- [x] Allow eligible queued text messages to enter the existing editor.
- [x] Implement in-place updates without the edited marker.
- [x] Cover repeated edits, mentions, quotes, multipart text, and link previews.
- [x] Resolve editor/reconnection and editor/send-claim races in source.
- [x] Preserve normal sent-message editing and its marker.
- [x] Implement local Queued presentation with accessibility support. Wording and
      treatment remain a default-off development choice pending product review.
- [x] Cover queued deletion and empty-edit behavior in source.
- [x] Add model, UI eligibility, draft-retention, observer, preview-race, and
      presentation regression source. None of these new cases has been run.
- [ ] Complete user-owned compilation, tests, and device confirmation.
- [ ] Record PR URL and validation results.

Execution record (2026-10-21, source only; no formatting/lint/build/test commands):

- Confirmation for enrolled messages is applied and saved on the sync context,
  serialized with send claims. Mentions cross contexts as object IDs and ranges.
  UI eligibility includes only never-submitted queued original text/multipart
  content and confirmed sent content, retaining ownership/membership/ephemeral
  restrictions. Pending normal edits and metadata updates cannot be overwritten.
- Opening an editor does not reserve or pause sending. Confirmation updates an
  unclaimed original in place with the same nonce and enqueue time, preserving
  original metadata/quote bytes and multipart attachments. It creates no edit
  envelope or timestamp. If sending has completed, normal edit semantics apply.
- When preparation, transport, uncertainty, or another operation owns the row,
  confirmation returns false and leaves the editor/draft intact. A second tap
  cannot submit concurrently. Text or mentions changed while awaiting completion
  are retained even if the earlier confirmation succeeded. No deferred edit is
  automatically sent; the user confirms again after known delivery. Additional
  feedback for the retained-draft state remains a UX review item before activation.
- Empty queued text follows local deletion; empty multipart text retains its
  attachments. Delete/hide actions for enrolled messages use the sending context.
  A never-submitted initial message, including preparation before handoff, is
  cancelled/deleted locally without emitting remote hide/delete traffic. After
  possible handoff, existing remote deletion semantics apply; cancellation cannot
  retract a request that has already been submitted.
- Preview detection checks its original text before applying asynchronous results,
  then restarts for current content when needed. Image preprocessing supports an
  optional content identity, ignores obsolete results, and requeues current work.
  Upload requests carry a text/preview digest so a previous preview's asset key
  cannot attach to edited content. Outbox preview writes preserve text, edit, and
  multipart envelopes/quotes/attachments rather than flattening them to plain text.
- Queued rows show a clock and localized Queued label using Dynamic Type and a
  VoiceOver label/identifier. Preparing/sending retain the existing sending state.
  Outbox-state observation triggers status refresh even when legacy deliveryState
  remains pending. Base English localization is added; generated strings are untouched.
- Regression source covers repeated queued edits/claims, mentions, unavailable
  quote targets, multipart attachments, empty text, remote-traffic-free deletion,
  normal-edit locking, draft retention/newer drafts, stale preview detection/image
  completion/upload callbacks, eligibility, status, and observer notifications.
- No PR has been opened or pushed. The unrelated `.ruby-version` change is excluded.
  Classic asset implementation is recorded in PR 4 below. Wire Drive remains
  disabled in the user's manual test configuration.

### PR 4: Asset queuing and recovery

- [ ] Verify stage-specific restart behavior on the updated feature base. Reuse
      the bootstrap regressions and user-confirmed device fix recorded above;
      add new regressions only for remaining asset recovery gaps. Do not duplicate
      the user's separate bootstrap bug PR or backports.
- [x] Identify and explicitly scope classic asset versus Wire Drive draft paths.
- [x] Preserve any confirmed automatic reconnect behavior already provided by the
      asset pipeline; target observed gaps rather than replacing it wholesale.
- [x] Enroll classic assets behind the flag, saving intent and original bytes
      before accepting submission. Self-deleting assets keep legacy behavior.
- [x] Implement account-scoped byte retention and cleanup in source.
- [x] Implement preprocessing/interrupted-upload recovery in source.
- [x] Resume final asset-reference sending after an upload already succeeded.
- [x] Implement background task reconciliation, cancellation, and missing-byte
      handling with regression source; no new cases have been executed.
- [x] Reuse the classic appendFile path for files/audio/video and appendImage for
      images; do not replace native media preprocessing or Wire Drive uploads.
- [ ] Validate image, file, audio, and video cases, including receiver playback.
- [ ] Complete user-owned compilation/tests/device confirmation.
- [ ] Record PR URL and validation results.

Execution record (2026-10-21, source only; no formatting/lint/build/test commands):

- Classic appendImage/appendFile enroll non-ephemeral outgoing assets, pin their
  cache keys, write and verify original bytes, and save the row before returning.
  Original/preprocessed/encrypted/transport entries route by on-disk pin markers
  to `AccountData/<account UUID>/PendingMessageAssets`, outside OS-purgeable Caches.
  Both main-session construction paths and the share session use this location.
  The one-argument cache initializer remains compatible with existing callers.
- Encryption verifies retained ciphertext before releasing its original, and
  image processing verifies its replacement before dropping original bytes.
  Originals survive preprocessing until a successful database save records the
  corresponding encryption keys/digest. Recovery and upload preflight compare
  stored ciphertext with that metadata, regenerate an unfinished pair from the
  retained original, and release plaintext only after the persisted pair agrees.
  This closes filesystem/database crash windows without retaining plaintext
  throughout an already-prepared upload's offline wait. Digest reads add I/O for
  pending assets; include larger audio/video attachments in validation.
  Existing preprocessing and temporary-error upload retry mechanisms are reused.
  Uploaded asset data is not re-encrypted when another associated asset still
  needs processing. Native audio/video metadata and encoding remain unchanged.
- The upload tracker restores tracking for queued asset work, cancels any recorded
  previous-process task, reuses encrypted data/remote references, and promotes
  complete recorded uploads to final-message sending. The transport layer has no
  established reattachment of old task callbacks; this implementation restarts
  uploads from retained bytes rather than claiming to resume those callbacks.
- The regular-message outbox scheduler now also owns final asset-reference sends.
  Uploaded assets wait offline/restart without legacy stale-message expiration.
  No new upload is needed when a valid remote reference is already recorded.
  Waiting uploads continue to allow later text through as in the existing
  pipeline; once ready, final asset sends share the per-conversation send owner.
  Cross-type ordering remains a product/activation review item.
- Upload requests carry a generation and encrypted-content digest. Task creation,
  progress, success, and terminal failure cannot revive cancelled/deleted work or
  apply an earlier asset response to a later thumbnail/upload. An optional upstream
  failure hook forwards immutable request metadata for cancellation/expiration as
  well as permanent failures. Existing temporary-error retry behavior is unchanged.
  Upload timeout/cancellation can retry identical encrypted bytes; final-message
  uncertainty remains governed by the conservative manual-Retry behavior.
- Missing original/encrypted bytes, failed preprocessing, and known membership
  removal produce the existing actionable failure state. Retry cannot resurrect
  deleted content; missing bytes fail again instead of waiting indefinitely.
  Final HTTP handoff also checks expiration after preparation.
- Bytes remain retained for queued/in-flight/uncertain/failed operations, including
  explicit user Retry. Final successful message save releases them to ordinary
  cache storage. Local deletion defers durable removal until its context saves;
  rollback preserves retry bytes. Already-uploaded blobs of a locally cancelled,
  never-submitted message are requested for deletion only after that save.
  Normal message-retention deletion releases associated pins after its batch
  deletion succeeds. Account deletion removes the account-data directory.
- Startup reconciles retained pins with persisted rows, releases completed work,
  and sweeps orphan pins older than 24 hours. That grace avoids deleting a second
  process's in-progress acceptance before its row commits. Unknown lifecycle values
  retain their bytes and remain ineligible to send. Retention duration/quotas and
  full conversation-clear/account-removal behavior still need rollout review.
- The share extension disables both enrollment and processing for main-app outbox
  rows, including sending, preprocessing, upload, and preview updates. Its existing
  sharing behavior remains available. This prevents competing process-local sync
  contexts from claiming main-app outbox work without a cross-process lease.
  Enabling offline share submissions requires a separate ownership design.
- Regression source covers enabled image/file acceptance, retained ciphertext
  across cache eviction/recreation, age cleanup, rollback/saved deletion, missing
  bytes, ciphertext/key persistence crash recovery, recorded upload reuse,
  stale success/failure after cancellation/replacement,
  uploaded-asset reconnect sending, and share-scope exclusion. Audio/video and actual
  background tasks still require user device validation. A source-only correction
  also fixes the PR 3 image-preprocessor test's imported argument label.
- This session has not opened a PR or pushed. The branch acquired a remote tracking
  ref during work; do not assume no one else has published it. Preserve unrelated
  `.ruby-version` modifications. Keep this plan committed until final PR cleanup.

### PR 5, if needed: Integration and rollout preparation

- [ ] Complete cross-layer verification and fix integration gaps.
- [x] Source review: route outbox Retry/Cancel to the sync context and recheck
      the current row before applying the action.
- [x] Source review: prevent text Retry from reviving cancelled/deleted work or
      re-enrolling an already completed edit.
- [x] Source review: cancel queued/preparing asset-reference sends even when the
      upload has just finished; retain uploaded references for explicit Retry.
- [x] Source review: fail a handoff-save error without clearing ownership early
      and causing the scheduler to immediately restart the send.
- [x] Source review: ignore late asset preprocessing/upload work after teardown
      and release preprocessing groups independently of preprocessor lifetime.
- [x] Add unexecuted sender regression source for non-submission, rejection,
      unknown delivery, known acceptance with an unreadable body, and failed
      handoff persistence.
- [x] Source review: reject late final-message callbacks after context closure,
      and stop reconnect scheduling against reset account objects.
- [x] Add unexecuted MLS repair regression source for stale epochs, client
      mismatch, missing commit references, and missing group members, checking
      the three-repair limit and retained frozen payload.
- [ ] Confirm rollout and flag-disable behavior.
- [ ] Review failure diagnostics without exposing message content.
- [ ] Decide whether to enable the feature and later remove the temporary flag.
- [ ] Record PR URL and validation results, or explain why a separate PR is unnecessary.

Execution record, 2026-10-22 (source inspection only):

- Retry and Cancel in conversation UI, plus Cancel in collections, previously
  mutated UI-context objects while send claims and callbacks mutated the sync
  context. They now refetch by object ID on the sync queue and save there, using
  the current lifecycle state. Stale Retry cannot replace a newer attempt.
- `ZMClientMessage.resend()` now uses the legacy path only for unenrolled rows.
  Enrolled text retries require live failed/uncertain work; completed, cancelled,
  unknown, or active operations are left untouched.
- Cancelling an enrolled initial asset while queued/preparing now synchronously
  fails the operation and expires it with the existing cancellation reason. An
  upload in progress keeps the existing cancelled transfer state; a completed
  upload retains its uploaded state and remote reference. Retry can reuse it.
  Cancelling after final-message handoff does not claim delivery was prevented.
- Regression source covers two-context Retry/refetch behavior, stale Retry
  during an active send, cancelled text, completed edits, cancellation both before
  and after upload, preparation invalidation, uploaded-reference reuse on Retry,
  and the handoff boundary. None of these tests were executed.
- New action-failure logging uses a fixed diagnostic without message content or
  serialized payload. Broader diagnostics review remains open.
- Source inclusion uses Xcode synchronized folders, including the new model
  versions. Compilation remains unverified. No PR or push was performed here;
  continue on the existing branch. `.ruby-version` remains unrelated and untouched.

Follow-up source review, 2026-10-22 (no validation execution):

- Handoff persistence previously rescheduled the row and cleared its attempt
  token before throwing. The outer handler then reported a stale attempt, so the
  scheduler could immediately start another send for the still-queued row. A
  distinct internal persistence error now retains ownership until the outer
  handler fails the operation. No message request is submitted; the existing
  scheduler failure path can surface Retry without a repeated-send loop.
- Asset preprocessing now has explicit teardown, invoked by the upload strategy.
  New processing and downsample/completion mutations stop after teardown or
  context invalidation. Existing completion operations finish so dispatch groups
  can drain; cancelling those operations would prevent their cleanup blocks.
- Preprocessing completion captures the exact context groups entered at startup,
  and releases those groups even if the preprocessor has been deallocated or the
  context's group registry has changed. Image completion operations retain their
  processing group, rather than relying on a weak preprocessor to leave it.
- The upload strategy stops tracking/request polling after teardown/context
  invalidation, and ignores late upload success/failure callbacks. Existing
  retained bytes and queued rows remain available for recovery by a later session.
- Regression source covers those teardown boundaries and group cleanup. Sender
  source also distinguishes a scheduler-confirmed non-submission (queued with a
  retry date), an ambiguous timeout (uncertain), a definite rejection (failed), and
  known 201 acceptance with an undecodable status body (sent without resubmission).
  A failing-context test exercises the handoff-save boundary before API submission.
- All changes remain source-only. No build, test, lint, formatter, push, or PR was
  run/created here. Full account switching/logout behavior, late final-message
  callbacks around context closure, and MLS repair paths remain review/validation
  items; asset teardown changes do not establish those broader guarantees.

MLS and account-closure source review, 2026-10-22 (no validation execution):

- Existing outbox MLS repair code already uses a per-operation loop with at most
  three repairs after the initial attempt. Its regression source now covers
  stale-message repair, client mismatch, missing commit references, and missing
  members, checking four attempted sends, the expected repair calls, unchanged
  nonce/frozen content, and a persisted failed operation when the limit is reached.
  The retry policy itself was not expanded.
- The strategy directory can outlive account-context closure. Outbox claim,
  preparation, final handoff, and final response guards now check context validity
  before reading managed rows. Late accepted responses after closure leave the
  persisted sending operation for conservative uncertain-delivery recovery in
  the next session. They cannot complete the detached row or resubmit its content.
- MLS now passes the expiration value captured during the handoff save directly
  to the API, avoiding a separate read of the managed message after that boundary.
- A reconnect or task completion reaching a closed outbox context tears down the
  scheduler and releases queued completions without reading or expiring reset
  rows. Regression source covers a queued reconnect after closure.
- Message log-attribute extraction skips reset rows after context invalidation.
  The Proteus payload processor accepts an explicit owning context and checks
  validity before fetching status changes or applying final mutations. This avoids
  deriving a context from a detached message. Its old content-bearing debug log
  now uses a fixed diagnostic without the message payload.
- New sender source exercises both Proteus and MLS acceptance after actual
  context teardown/reset, then refetches the persisted operation and checks
  uncertain recovery with its snapshot retained. Logging after context closure
  also has regression source. None of these tests were executed.
- Full lifecycle acceptance remains unchecked. In particular, review cancellation
  while waiting for sync (the V2 observer uses a continuation), interruption inside
  asynchronous preparation/status-processing work, and actual account switching
  before declaring session lifecycle complete. Keep the developer flag off.

## Decisions to settle before the relevant implementation

- [x] Jira issue key: `WPB-26307`.
- [x] Agree staged PR sequence and default-off flag direction; concrete PR 1
      schema and tests are proposed above for review.
- [x] Agree flag name, enrollment direction, and restart-based toggle policy;
      detailed call-site coverage will be verified before PR 2 enrollment.
- [ ] Exact persisted lifecycle and reconciliation strategy for uncertain delivery.
- [x] Development behavior: no editor reservation; recheck at confirmation and
      retain the draft while ownership/delivery is unresolved (see PR 3).
- [ ] Ordering policy: whether a large pending asset blocks later text messages.
- [ ] Review the implemented local Queued wording/clock treatment before activation.
- [ ] Retention policy for queued messages and attachment bytes.
- [ ] Treatment of self-deleting messages while queued, preserving existing
      editing restrictions and the agreed start of their destruction timer.
- [x] Development scope: main-app enrollment/recovery only. The share extension
      leaves main-app outbox work untouched and uses legacy sharing behavior.
- [ ] Agree any broader offline share-extension support and cross-process ownership.

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

- The prerequisite bootstrap fix is on `develop`; foundation, regular-message
  integration, queued editing/presentation, and classic asset enrollment/retention/
  recovery are written on the one feature branch. Validation and rollout review
  remain outstanding; the local developer flag stays off by default.
- The existing `.ruby-version` and `Strings+Generated.swift` modifications and
  the temporary RFC belong to the user and must remain untouched by this work.
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
