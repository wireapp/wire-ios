# Review: PR #5353 — missed-call notification shown when a call was answered elsewhere (WPB-29009)

PR: https://github.com/wireapp/wire-ios/pull/5353
Branch: `fix/missed-call-notification-WPB-29009`
Reviewed head: `601159df59` ("fix: track answered elsewhere before conversation metadata loads")

## Status summary

| # | Finding | Status at `601159df59` |
|---|---|---|
| 1 | `WireAVS/Package.swift` points at a local AVS build | **Open (blocker)** |
| 2 | Group answered-elsewhere ends as `.unanswered` in CallKit | **Open (blocker)** |
| 3 | `callsAnsweredElsewhere` not cleared when the user joins locally | Open |
| 4 | Entry removed by `clearSnapshot` on degraded / can't-join | Open |
| 5 | Stale answered-elsewhere flag in the NSE | **Open, scope widened by `601159df59`** |
| 6 | Group status unknown before conversation metadata loads | Fixed by `601159df59` |
| 7 | Another participant's CONFSTART clears the flag mid-call | Open |
| 8 | Side effects and non-atomic state inside the validator | Open |
| 9 | Line over 120 characters | Open |
| 10 | `TODO` without a JIRA ticket | Open |

Fix 1 and 2 before merging. Fix 3, 4 and 5 next: each one either brings back a wrong missed call or produces a wrong error.

---

## Blockers

### 1. WireAVS points at a local build
**File:** `WireAVS/Package.swift:20`

The binary target was changed from the released 10.5.19 URL and checksum to
`../../wire-avs/build/dist/xc/avs.xcframework`, marked `// TODO: undo changes`.

**Failure:** On CI, or any machine without a sibling `wire-avs` checkout built at that path, SwiftPM can't resolve `WireAVS` and nothing builds. Merging this as is would break `develop` for everyone.

**Fix:** Point the target at a published wire-avs release that includes `ANSWERED_ELSEWHERE` (wire-avs#223), with its checksum. Copilot flagged this too.

### 2. Group calls answered elsewhere still show as missed in iOS Recents
**File:** `wire-ios-sync-engine/Source/Calling/WireCallCenterV3+Events.swift:305`

For group calls, `.answeredElsewhere` is changed to `.stillOngoing`. `handle()` turns that into `.incoming(shouldRing: false)`, and `CallKitManager` reports a non-ringing incoming call as ended with `reason: .unanswered` (`CallKitManager.swift:833`) instead of `.answeredElsewhere`.

**Failure:** B's iPhone is ringing through CallKit, and B answers the group call in the browser. CallKit ends the iPhone's call as `.unanswered`, so iOS Recents logs a missed call. That is the symptom this PR is meant to fix. Before the change, the call ended as `.answeredElsewhere` → `CXCallEndedReason.answeredElsewhere`.

---

## Main app (`WireCallCenterV3+Events.swift`)

### 3. `callsAnsweredElsewhere` not cleared when the user joins locally
**Line:** 306

**Failure:** The user answers on desktop. The iPhone keeps the call as incoming without ringing, and the user then also joins from the iPhone. When the call ends normally, `.normal` is still rewritten to `.terminating(.answeredElsewhere)`. `CallObserver` sends `.answeredElsewhere` to `onFailedToJoin` instead of `onTerminated`, so the UI may show a failed-to-join error. CallKit also reports the call it was hosting as `answeredElsewhere` instead of `remoteEnded`.

**Fix:** Remove the entry when the self user joins or establishes the call on this device.

### 4. Entry removed by `clearSnapshot` before the call ends
**Line:** 304

The entry is added to `callsAnsweredElsewhere` before `handle()` runs. If the `.stillOngoing` state becomes `.terminating(.securityDegraded)`, or stays `.terminating(.stillOngoing)` because `canJoinCall` is false, `handle()` calls `clearSnapshot`. That deletes both the snapshot and the entry.

**Failure:** A degraded conversation, or one the self user can't join, gets ANSWERED_ELSEWHERE, and the entry is cleared straight away. The later `.normal` end arrives with no entry, so `SystemMessageCallObserver` adds a "Missed call" system message and `CallStateObserver` posts a missed-call local notification.

**Fix:** Keep the answered-elsewhere state separate from the snapshot lifecycle, or don't clear it in those paths.

---

## Notification extension (`WireDomain/.../ConversationCallingEventNotificationBuilder.swift`)

### 5. Stale answered-elsewhere flag (scope widened by `601159df59`)
**Line:** ~527 (`trackAnsweredElsewhereCall`)

The flag in UserDefaults is reset only when the extension itself sees a new incoming start event (`isIncomingCall`) or an end event. Events the main app handles never clear it.

**Failure (group):**
1. Call 1: the extension sees self's CONFSTART (`resp=true`) and stores `true`. The main app is in the foreground and handles CONFEND, so the extension never clears the key.
2. Call 2: someone else starts a group call while the app is still in the foreground, so the extension never sees that CONFSTART and never clears the key.
3. The user backgrounds the app and the call goes unanswered. The extension reads the stale `true` on CONFEND, so **no missed-call notification is shown for a genuinely missed call**.

**How `601159df59` widens this:** The commit removed the `isGroupConversation` check, so tracking now covers every conversation type, including 1:1 calls. `CallContent.isStartCall` includes `SETUP` and `isEndCall` includes `CANCEL` (`CallContent.swift:93-107`).

**Failure (1:1):**
1. The user starts or answers a 1:1 call on desktop. The extension sees self's `SETUP` and stores `true`. The main app is in the foreground and handles the end, so the flag is never cleared.
2. Later the same contact calls while the app is still in the foreground. The extension never sees that `SETUP`, so the flag stays.
3. The user backgrounds the app and the caller cancels. The extension reads the stale `true` and suppresses a real missed-call notification.

Before `601159df59` this could only happen in group calls.

**Possible fixes:**
- Clear the flag from the main app too, whenever it processes the start or end of a call in that conversation. The key is account- and conversation-scoped, and the defaults must be shared through the app group.
- Or bring back a group-only restriction, but base it on the backend-resolved conversation type (as the `needsBackendUpdate` path already fetches) instead of `isGroupConversation` from the local store. Decide this before the end event uses the flag.
- Add a time bound (store a timestamp instead of a `Bool` and ignore old entries), or key the flag by a call or conference identifier if the payload has one.

### 6. Group status unknown before metadata loads — FIXED in `601159df59`
**Line:** 473 (before the fix)

Copilot's comment: `fetchOrCreateConversation` can return a stub that still needs a backend update, and `isGroupConversation` returns `false` for it, so self's CONFSTART was never recorded. The later CONFEND could then resolve as a group and show a missed call.

**Fix applied:** The `isGroupConversation` check was removed, so the flag is recorded no matter what the local store knows about the conversation type. The new test `testSelfAnswerBeforeGroupConversationMetadataLoadsDoesNotShowMissedCall` covers metadata resolving both before and after the end event.

**Caveat:** This is the change that widened point 5 to 1:1 calls (see above).

### 7. Another participant's CONFSTART clears the flag during the same call
**Line:** ~531

Any CONFSTART with `resp=false` from someone other than self removes the key. The code can't tell a new call apart from a re-sent or late CONFSTART in the call that is already running.

**Failure:** Self answers on desktop, so the flag is `true`. Another participant's client sends a CONFSTART with `resp=false` for the same conference (late or retransmitted), which removes the key. When the call ends, the extension shows a missed-call notification.

### 8. Side effects and non-atomic state inside the validator
**Line:** 473

`validateCallNotification` reads like a pure check, but it now writes and deletes UserDefaults keys on every call. The state is spread over two read-modify-write steps that aren't atomic.

**Failure:** Two extension instances, or interleaved `await`s, handle CONFSTART and CONFEND for the same conversation at once. The CONFEND read and remove can run before the CONFSTART set, leaving a stale `true` key (see point 5). The keys are also never removed on logout or conversation deletion.

**Suggestion:** Move this into a dedicated tracker that the builder calls, separate from the validator.

---

## Style (AGENTS.md)

### 9. Line longer than 120 characters
**File:** `ConversationCallingEventNotificationBuilder.swift:~525`

```swift
let key = "\(Constants.answeredElsewhereCall).\(accountID.uuidString).\(conversationID.domain).\(conversationID.id)"
```
This line is about 128 characters including indentation. AGENTS.md sets a 120-character SwiftFormat limit. It is unchanged in `601159df59`.

### 10. `TODO` without a JIRA ticket
**File:** `WireAVS/Package.swift:20`

`// TODO: undo changes` breaks the SwiftLint rule `// TODO: [WPB-123] description`. This goes away once point 1 is fixed.
