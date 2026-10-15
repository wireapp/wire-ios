# WPB-28035: iOS channel join recovery

## Issue and ticket evidence

After a user is added to an existing channel through Team Management, their iPhone
can display the channel but receive no new messages because the device has not
joined its MLS group.

The ticket reports this on Wire Cloud on 2 October, including iOS 4.26.1 runs.
The owner was initially excluded from the channel, then added themself through
Team Management while their iPhone was backgrounded. The expected iOS behavior is
to join and receive subsequent messages on foreground, without a local send or
restart.

| Reported iOS symptom | How it fits the proposed explanation |
| --- | --- |
| Channel is visible but empty after the membership update. | Downloading conversation metadata does not itself join this device to the MLS group. |
| Five of seven foregrounds in runs A, D, and E left the iPhone unjoined; run D joined on its third foreground. | Each post-sync check can miss activation; a later attempt can succeed with different timing. |
| In run E, messages reached the owner's Android and the existing member, but not the iPhone. | Joining another device does not establish the iPhone's local MLS group state. |
| Force-quit/relaunch restored joining and receipt of new messages in runs D and E. | A cold start can put activation before the recovery check; it is not an MLS requirement. |

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
the key-package response, and failed when that order was reversed. This is a
correlation: the excerpts do not directly log the application's state at the
recovery guard.

## Possible cause supported by the current code

In `ZMUserSession.didFinishIncrementalSync`, pending MLS conversation recovery runs
after MLS initialization and the key-package check, only while
`application.applicationState == .active`. If this check happens while the app is
still inactive during foregrounding, recovery is skipped. Becoming active afterward
does not retry that skipped work. Repeated foregrounds can hit the same timing;
force-quitting and relaunching happened to allow recovery in the reported runs.

This matches the supplied ticket's log excerpts and the current source. It has not
been reproduced on a device as part of this investigation, and the original log
archives have not been independently inspected.

Additional evidence is in `WPB-28035_02_iOS-4.26.1_runD_selfadd.zip`. Only the
11:48 run A in `WPB-28035_03_iOS-4.26.1_runA_owner-adds-other-user.zip` is valid;
the later run used another account. Older customer logs from iOS 4.24.0 report a
membership event without a join in an already-running session, but that version
used a different trigger (once per session or on send). Do not attribute that older
case to the current activation guard. The customer's claim that restarting did
not help remains unverified; in-house restarts succeeded.

## Proposed solution (not implemented)

Retry deferred pending MLS recovery when the app becomes active. Coordinate this
with completion of sync, MLS initialization, and the key-package check so both
activation-before-sync and sync-before-activation work. Keep recovery restricted to
the active app, prevent overlapping recovery loops, and resume remaining batches
after a background/foreground transition. Avoid timers or arbitrary delays.

This should make both timing orders in run E recover automatically. Record the
application state when deferring recovery and when resuming it, plus the channel's
recovery outcome, so a new log can confirm or disprove this explanation.

Relevant code: `wire-ios-sync-engine/Source/UserSession/ZMUserSession/`
(`ZMUserSession.swift` and `ZMUserSession+LifeCycle.swift`) and
`wire-ios-data-model/Source/MLS/MLSService.swift`.

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

- Add a deterministic session regression test: finish post-sync preparation while
  `.inactive`, then activate without another sync. Pending recovery must run.
- Test the reverse order: activate before preparation finishes. Recovery must wait
  for preparation and then run.
- Test repeated activation and overlapping triggers: no duplicate recovery loops.
- Test backgrounding between batches, then activation: remaining work resumes.
- Preserve guards for disabled MLS and background execution; verify failed joins
  remain eligible for a later recovery attempt.
- Repeat the device steps: the iPhone must join on the first foreground and receive
  messages sent after that join, without sending locally or restarting. Verify the
  group-info request/external commit and the persisted `.ready` state. If another
  client already added the iPhone through an MLS Welcome, that run does not exercise
  the pending external-join path.

Extend `test_itRecoversPendingConversationsAfterQuickSyncWhileActive` in
`wire-ios-sync-engine/Tests/Source/UserSession/ZMUserSessionTests.swift`; its current
coverage does not include the inactive-to-active transition. Historical message
backfill is outside this fix's acceptance criteria.
