# WPB-28035: iOS channel join recovery

## Issue and cause

After a user is added to an existing channel through Team Management, their iPhone
can display the channel but receive no new messages because the device has not
joined its MLS group.

In `ZMUserSession.didFinishIncrementalSync`, pending MLS conversation recovery runs
after MLS initialization and the key-package check, only while
`application.applicationState == .active`. If this check happens while the app is
still inactive during foregrounding, recovery is skipped. Becoming active afterward
does not retry that skipped work. Repeated foregrounds can hit the same timing;
force-quitting and relaunching happened to allow recovery in the reported runs.

This matches the supplied ticket's log excerpts and the current source. It has not
been reproduced on a device as part of this investigation.

## Proposed solution (not implemented)

Retry deferred pending MLS recovery when the app becomes active. Coordinate this
with completion of sync, MLS initialization, and the key-package check so both
activation-before-sync and sync-before-activation work. Keep recovery restricted to
the active app, prevent overlapping recovery loops, and resume remaining batches
after a background/foreground transition. Avoid timers or arbitrary delays.

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
