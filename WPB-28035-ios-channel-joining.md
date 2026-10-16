# WPB-28035: iOS channel join recovery

> Working notes for the fix branch. This file is deleted before merging; the PR
> description at the end carries the essentials.

## Issue and ticket evidence

After a user is added to an existing channel through Team Management, their iPhone
can display the channel but receive no new messages because the device has not
joined its MLS group.

The ticket reports this on Wire Cloud on 2 October, including iOS 4.26.1 runs.
The owner was initially excluded from the channel, then added themself through
Team Management while their iPhone was backgrounded. The expected iOS behavior is
to join and receive subsequent messages on foreground, without a local send or
restart.

| Reported iOS symptom | How it fits the explanation |
| --- | --- |
| Channel is visible but empty after the membership update. | Downloading conversation metadata only marks the channel `.pendingJoin`; it does not join this device to the MLS group. |
| Five of seven foregrounds in runs A, D, and E left the iPhone unjoined; run D joined on its third foreground. | Each post-sync check can miss activation; a later attempt can succeed with different timing. |
| In run E, messages reached the owner's Android and the existing member, but not the iPhone. | Joining another device does not establish the iPhone's local MLS group state. |
| Force-quit/relaunch restored joining and receipt of new messages in runs D and E. | A cold start sets up the session late enough that activation practically always precedes the recovery check; it is not an MLS requirement. |

The strongest timing example is run E, from
`WPB-28035_01_iOS-4.26.1_runE_selfadd_coldstart.zip`. These are the ticket's
log excerpts, with times in UTC:

```text
12:58:55.801  memberJoin processed for channel 87080d74-...
12:58:55.807  incremental sync completed
12:58:56.214  key-packages count response: 200
12:58:56.374  sceneDidBecomeActive
              No group-info request or external commit for the channel.
13:01:41 and 13:02:33: further foregrounds, still no join.

13:03:30.907  sceneDidBecomeActive after force-quit/relaunch
13:03:31.651  incremental sync completed
13:03:32.026  key-packages count response: 200
13:03:32.122  channel group-info response: 200
13:03:32.171  external join started
13:03:32.273  external join succeeded
```

Across the ticket's listed runs, joining succeeded when scene activation preceded
the key-package response, and failed when that order was reversed.

## Cause

### Code path

1. `ZMUserSession.applicationWillEnterForeground` (`ZMUserSession+LifeCycle.swift`)
   calls `syncAgent?.resume()`. At this point UIKit reports the app as
   `.background`/`.inactive`; it only becomes `.active` with `didBecomeActive`
   afterwards.
2. The quick sync processes the `memberJoin` event. `MLSEventProcessor`
   (`wire-ios-request-strategy/.../MLSEventProcessor.swift`) marks the channel as
   `.pendingJoin` because there is no local MLS group yet.
3. `ZMUserSession.didFinishIncrementalSync` initializes the MLS client, checks key
   packages, and then ran:

   ```swift
   while mlsFeature.isEnabled,
         isBackendMLSEnabled,
         await MainActor.run(body: { [application] in application.applicationState == .active }) {
       guard await mlsService.recoverPendingConversationBatchIfNeeded() else { break }
   }
   ```

   If the app was not yet `.active`, the loop never started. Nothing retried it
   when the app became active a few hundred milliseconds later. The next attempt
   only happened after the *next* incremental sync — which on each subsequent
   foreground can hit the same race. A cold start reliably wins the race.
4. Run E fits exactly: the key-package response arrived at 56.214 (the guard is
   evaluated right after it) and `sceneDidBecomeActive` at 56.374, ~160 ms later.

### When it was introduced

[#5074](https://github.com/wireapp/wire-ios/pull/5074) "fix: recover MLS
conversations after key-package exhaustion - WPB-27395" (commit `82accebc73`,
merged 2026-07-29, first released in **4.25.0**) removed
`mlsService.performPendingJoins()` from `MLSClientManager` (it ran once per
session during MLS client setup, independent of app state) and replaced it with the
`.active`-guarded batch loop above. That is why the older 4.24.0 customer logs
must not be attributed to this guard: that version had a different trigger
(once per session or on send).

[#5081](https://github.com/wireapp/wire-ios/pull/5081) (commit `e6cfe6e3bf`,
WPB-20278) later wrapped the state check in `MainActor.run`; it did not change
the behavior and is not the cause.

### Evidence gap

Neither the skip nor an empty batch were logged: `recoverPendingConversationBatchIfNeeded`
only logs when the batch is non-empty. So the logs alone cannot distinguish
"guard skipped the loop" from "the channel was filtered out" (e.g.
`isSelfAnActiveMember` or `mlsGroupID` not yet set). The latter is unlikely: the
same data recovered on cold start, and later foregrounds also failed. Worth
checking in the archives: for the 13:01:41 and 13:02:33 foregrounds, confirm the
key-package response also preceded `sceneDidBecomeActive`. The fix adds logging for
the deferral and the resume so new logs can confirm or disprove this.

### Other notes

Additional evidence is in `WPB-28035_02_iOS-4.26.1_runD_selfadd.zip`. Only the
11:48 run A in `WPB-28035_03_iOS-4.26.1_runA_owner-adds-other-user.zip` is valid;
the later run used another account. The customer's claim that restarting did not
help remains unverified; in-house restarts succeeded. The original log archives
have not been independently inspected as part of this investigation.

## Fix (implemented)

Keep the `.active` guard (recovery must not run in the background, e.g. on push
wake-ups or background fetch) but remember when it deferred work, and resume on
`didBecomeActive`:

- `ZMUserSession.recoverPendingConversations()` replaces the inline loop. Before
  each batch it reads `applicationState` and sets
  `isPendingConversationRecoveryDeferred` in one main-actor step, then either runs
  the batch or logs the deferral (with the application state) and returns.
- `ZMUserSession.applicationDidBecomeActive` (new `didBecomeActive` observer)
  calls `resumeDeferredPendingConversationRecovery()`, which clears the flag and
  reruns the loop in a `WaitingGroupTask` on the sync context.

Why this covers the cases:

| Order | Behavior |
| --- | --- |
| Activation before post-sync preparation finishes | Loop sees `.active` and runs (unchanged). |
| Post-sync preparation finishes while `.inactive` | Loop defers and sets the flag; `didBecomeActive` resumes it. |
| Backgrounded between batches | Next check defers and sets the flag; next activation resumes the remaining batches. |
| Repeated activation / overlapping triggers | Flag is cleared on resume, so repeated activations are no-ops; `MLSService` already rejects overlapping recovery runs via `isRecoveringPendingConversations`. |
| MLS disabled (feature or backend) | Loop condition fails before the state check; nothing is deferred. |

Because the state read and the flag write happen together on the main actor and
`didBecomeActive` is delivered on the main actor, there is no window in which
activation is missed. The flag is only set after MLS client initialization and the
key-package check, so resuming never runs before that preparation. No timers or
delays are involved.

Failed joins keep their `.pendingJoin` status and remain eligible for the next
recovery (unchanged behavior).

Considered alternative: relaxing the guard to `applicationState != .background`.
Smaller, but it depends on UIKit reporting `.inactive` (not `.background`) at the
moment the sync finishes during foregrounding, which isn't guaranteed, and it
doesn't resume batches interrupted by backgrounding.

### Background execution and the notification service extension

- **Notification service extension:** it does not create a `ZMUserSession` and
  never runs pending conversation recovery; it only decrypts via WireDomain. The
  deferral flag lives only in the app process. App/extension coordination of
  CoreCrypto access is unchanged.
- **Extra background time after resigning:** the sync runs inside
  `withBackgroundTask` (`SyncAgent`, `IncrementalSync*`), so it can finish while
  the app is `.background`. Recovery is then deferred and resumed on the next
  `didBecomeActive`, so no external commits are made in the background.
- **Backgrounded during a batch:** the running batch completes and the next state
  check defers the rest. Each CoreCrypto transaction is wrapped in a background task
  (`SafeCoreCrypto.transaction` with the app's `AppBackgroundTaskExecuter`), so the
  app is not suspended while holding the keystore. If iOS suspends the app between
  transactions (group-info fetch, commit upload), that join fails and the
  conversation stays `.pendingJoin` until the next foreground sync (unchanged).
- **Other short inactive phases** (app lock / Face ID, Control Center, call
  banners) end with `didBecomeActive`, which resumes deferred recovery.
- **Background launches** (push wake-up, background fetch) defer and resume on the
  first activation.

### Known limitations (accepted)

- If the deferral happened while backgrounded and the app is later foregrounded,
  the resumed recovery can run concurrently with the new incremental sync.
  Join-on-send (`MessageSender`) already joins independently of sync, so this is
  not a new class of concurrency.
- Residual delay in that same situation: if the new sync marks *another*
  conversation `.pendingJoin` after the resumed loop has already fetched its
  pending list, that conversation is missed by the resumed loop, and the sync's
  own loop is rejected by `MLSService`'s `isRecoveringPendingConversations` lock.
  It is then joined on the next foreground sync, not stuck until a restart.
  Requires membership changes on both sides of a background period plus
  overlapping timing. A fix would make the resumed loop wait for a running sync and
  let its completion handle recovery; not done given the codebase's retirement
  horizon.

Changed code:

- `wire-ios-sync-engine/Source/UserSession/ZMUserSession/ZMUserSession.swift`
- `wire-ios-sync-engine/Source/UserSession/ZMUserSession/ZMUserSession+LifeCycle.swift`
- `wire-ios-sync-engine/Tests/Source/UserSession/ZMUserSessionTests.swift`

## Reproduce on a device

1. Use a team owner signed into an iPhone and a separate existing channel member.
2. In Team Management, create a channel with that member, excluding the owner.
   Have the member establish the channel by sending a message.
3. Background Wire on the owner's iPhone, then add the owner through Team
   Management. Do not send from any of the owner's devices.
4. Foreground Wire and open the channel. Repeat background/foreground if needed.
5. Check iOS logs: the failure case has processed the membership update, but no
   channel group-info request or external commit follows activation. The channel
   remains unjoined and receives no new messages. The issue is timing-dependent.
6. As a baseline, force-quit and relaunch. The reported runs then fetched group info,
   joined by external commit, and received subsequent messages.

## Tests and verification of the fix

Unit tests in `ZMUserSessionTests`:

- `test_itRecoversPendingConversationsAfterQuickSyncWhileActive` (existing, setup
  extracted into `setUpSessionForPendingConversationRecovery()`).
- `test_itRecoversPendingConversationsWhenBecomingActiveAfterQuickSyncWhileInactive`:
  sync finishes while `.inactive`, nothing recovers; `didBecomeActive` recovers
  without another sync; a second activation does nothing.
- `test_itResumesPendingConversationRecoveryWhenBecomingActiveAfterBackgroundingBetweenBatches`:
  backgrounding after the first batch defers; activation resumes the remaining batches.
- `test_itDoesNotDeferPendingConversationRecoveryWhenBackendMLSIsDisabled`.

On a device: repeat the steps above. The iPhone must join on the first foreground
and receive messages sent after that join, without sending locally or restarting.
Verify in the logs:

- `deferring pending conversation recovery, application state: 1` (inactive)
  followed by `resuming deferred pending conversation recovery`, or no deferral at
  all if activation came first;
- the channel group-info request / external commit and
  `pending conversation recovery batch: recovered 1 of 1`;
- the persisted `.ready` state.

If another client already added the iPhone through an MLS Welcome, that run does
not exercise the pending external-join path. Historical message backfill is
outside this fix's acceptance criteria.

---

## PR description (draft)

**Title:** fix: join pending MLS channels when the app becomes active after sync - WPB-28035

### Issue

After being added to an existing channel (e.g. through Team Management) while the
app is in the background, the iPhone shows the channel on foreground but never
joins its MLS group, so it receives no new messages. Only a force-quit/relaunch
(or sending a message) made it join.

### Cause

Regression from #5074 (WPB-27395, commit `82accebc73`, first released in 4.25.0).
That PR replaced the once-per-session `performPendingJoins()` call in
`MLSClientManager`, which ran regardless of app state, with a batch loop at the end
of `ZMUserSession.didFinishIncrementalSync` that only runs while
`applicationState == .active`. On foreground, `applicationWillEnterForeground`
resumes the sync while the app is still inactive, so a quick sync (plus MLS client
init and key-package check) can finish before `didBecomeActive`. In that case the
recovery loop is skipped and nothing retries it until the next sync — which on the
next foreground can lose the same race. A cold start sets up the session late enough
that the app is already active, which is why relaunching helped.

The ticket's run E shows this order: incremental sync completed at 12:58:55.807,
key-packages response at 56.214, `sceneDidBecomeActive` at 56.374, and no
group-info request / external commit. After relaunch, activation came first and the
external join succeeded within a second.

### Solution

Keep the `.active` guard, but remember when recovery was deferred and resume it on
`didBecomeActive`:

- `recoverPendingConversations()` replaces the inline loop; before each batch it
  reads the application state and records the deferral in one main-actor step.
- A new `didBecomeActive` observer resumes deferred recovery in a
  `WaitingGroupTask` on the sync context.

This covers sync-before-activation, activation-before-sync (unchanged), and
backgrounding between batches. Repeated activations don't start extra loops, and
`MLSService` already prevents overlapping recovery runs. Recovery still never runs
in the background or before MLS client initialization and the key-package check.
Deferral and resume are logged with the application state so future logs show
which path was taken.

The notification service extension is unaffected: it does not run this recovery.
If a sync finishes during the extra background time requested after resigning
active, recovery is deferred and runs on the next activation.

Known limitation: if recovery was deferred while backgrounded and the following
foreground sync marks another conversation as pending join while the resumed
recovery is already running, that conversation is joined on the next foreground
sync instead of immediately. This needs membership changes on both sides of a
background period plus overlapping timing.

### Testing

- Unit tests in `ZMUserSessionTests`: recovery after activation following an
  inactive sync, resuming after backgrounding between batches, no deferral with
  MLS disabled on the backend; the existing active-path test is kept.
- Manual: background the app, add the user to an existing channel via Team
  Management, foreground once → the device fetches group info, joins via external
  commit and receives new messages, without sending or relaunching.
