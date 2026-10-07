# Review: PR #5353 — missed-call notification shown when a call was answered elsewhere (WPB-29009)

PR: https://github.com/wireapp/wire-ios/pull/5353
Branch: `fix/missed-call-notification-WPB-29009`

Review rounds:
- Round 1 at `601159df59` (findings 1–10)
- Round 2 at `09dbdc396f`, after the Codex commits `ad37377fa7` ("preserve answered-elsewhere call state in CallKit") and `09dbdc396f` ("track answered-elsewhere conference notifications"). This round adds findings 11–13.

Not built or tested by the reviewer. Run `WireCallCenterV3Tests`, `CallKitManagerTests` and `ConversationCallingEventNotificationBuilderTests`.

## Open items (round 2)

| # | Finding | Severity |
|---|---|---|
| 1 | `WireAVS/Package.swift` still points at a local AVS build | **Blocker** |
| 11 | `PR-5353-review.md` committed in `7c42a7db15 "notes"` | **Blocker** |
| 12 | `conferenceTimestamp: String?` may break decoding of all call messages | **Verify against AVS** |
| 13 | Default argument and protocol-extension default hide the new `callEndReason` parameter | Convention |
| 10 | `TODO` without a JIRA ticket | Goes away with 1 |

## Status of all findings

| # | Finding | Status at `09dbdc396f` |
|---|---|---|
| 1 | Local AVS path | **Open (blocker)** |
| 2 | Group answered-elsewhere ends as `.unanswered` in CallKit | Fixed |
| 3 | `callsAnsweredElsewhere` not cleared when the user joins locally | Fixed |
| 4 | Entry removed by `clearSnapshot` on degraded / can't-join | Fixed |
| 5 | Stale answered-elsewhere flag in the NSE | Largely fixed |
| 6 | Group status unknown before conversation metadata loads | Fixed (in `601159df59`) |
| 7 | Another participant's CONFSTART clears the flag mid-call | Fixed, provided 12 holds |
| 8 | Side effects and non-atomic state inside the validator | Fixed |
| 9 | Line over 120 characters | Fixed |
| 10 | `TODO` without a JIRA ticket | Open (goes away with 1) |
| 11 | Review notes file committed | **Open (blocker)** |
| 12 | `conferenceTimestamp` decoding and meaning | **Open (verify)** |
| 13 | Hidden defaults for `callEndReason` | Open |

---

## Round 2: new findings

### 11. Review notes file committed — BLOCKER
**Commit:** `7c42a7db15 "notes"`

This file (`PR-5353-review.md`) was committed to the branch. Remove it before pushing, or drop the commit.

### 12. `conferenceTimestamp: String?` may break decoding of all call messages — VERIFY
**File:** `WireDomain/Sources/WireDomain/Notifications/Builders/Conversation/Models/CallContent.swift`
(new property `conferenceTimestamp`, JSON key `timestamp`)

`AnsweredElsewhereCallTracker` relies on this value to tell a late or re-sent CONFSTART in the current call apart from a new call (finding 7).

**Risks:**
- **Type:** If AVS sends `timestamp` as a JSON number rather than a string, `Decodable` throws a type mismatch and the whole `CallContent` fails to decode. The notification extension would then stop showing any call notifications, not only missed calls. The test payload builds it as a string (`"timestamp": "\(conferenceTimestamp)"` in `ConversationCallingEventNotificationBuilderTests.swift:~1011`), so the tests wouldn't catch this. The reviewer believes AVS writes it as a string but hasn't confirmed it.
- **Meaning:** The protection only works if every client in the same call sends the same `timestamp` value, including when a message is re-sent. If the value is per message rather than per conference, a late CONFSTART in the same call clears the marker again, and finding 7 comes back.

**To do:**
- Check in wire-avs (the econn message encoder for CONFSTART) whether `timestamp` is a string or a number, and whether it identifies the conference.
- Either way, decode it leniently so a format change can't break call notifications. For example, use a custom `init(from:)` with `try? container.decodeIfPresent(String.self, forKey: .conferenceTimestamp)`, optionally falling back to decoding a number and converting it to a string.

### 13. Defaults hide the new `callEndReason` parameter — CONVENTION
**Files:**
- `wire-ios-sync-engine/Source/Calling/WireCallCenterV3+Notifications.swift`:
  - `WireCallCenterCallStateNotification.init(..., callEndReason: CallClosedReason? = nil)`
  - a `public extension WireCallCenterCallStateObserver` default for the new `callCenterDidChange(..., callEndReason:)` that forwards to the old method
- `wire-ios-sync-engine/Source/Calling/CallKitManager.swift`: the old method forwards to the new one with `callEndReason: nil`

Team convention: when you add a parameter, update all call sites explicitly rather than hiding the new behavior behind a default.

**Fix:**
- Add `callEndReason` to the existing `callCenterDidChange` protocol method instead of adding a second overload.
- Remove the protocol-extension default.
- Update every `WireCallCenterCallStateObserver` conformer.
- Remove the `= nil` from the notification initializer and pass the value explicitly at every call site.

---

## Round 2: how the earlier findings were addressed

### 2. CallKit `.unanswered` for group calls answered elsewhere — FIXED (`ad37377fa7`)
`WireCallCenterV3.handle(callState:...)` now sets `callEndReason = .answeredElsewhere` when `.terminating(.stillOngoing)` is turned into `.incoming(shouldRing: false)` and the conversation is in `callsAnsweredElsewhere`. The reason travels on `WireCallCenterCallStateNotification`, and `CallKitManager` uses `callEndReason?.CXCallEndedReason ?? .unanswered`.
Test: `testThatOngoingGroupCallAnsweredElsewhereEndsCallKitCallAsAnsweredElsewhere`.

### 3. Entry not cleared when joining locally — FIXED (`ad37377fa7`)
`callsAnsweredElsewhere.remove(conversationId)` is called in the `answered-call` and `established-call` handlers.
Test: `testThatJoiningLocallyClearsAnsweredElsewhereForTheFinalCallEnd`.

### 4. `clearSnapshot` wiped the entry — FIXED (`ad37377fa7`)
The removal moved out of `clearSnapshot`. The entry is now removed:
- in `createSnapshot`, and
- on the final close, for any reason other than `.stillOngoing`, where `.normal` is still rewritten to `.answeredElsewhere`.

Test: `testThatAnsweredElsewhereSurvivesSnapshotCleanupUntilTheFinalCallEnd`.

### 5. Stale NSE flag — LARGELY FIXED (`ad37377fa7`, `09dbdc396f`)
- The main app now clears the shared key through `clearAnsweredElsewhereNotificationState`, which uses `VoIPPushHelper.storage` (the app group). It does so on the final call end, and in `createSnapshot` when someone other than self starts the call.
- The key is shared through `WireFoundation.AnsweredElsewhereCallKey.make(accountID:conversationID:)`.
- The NSE ignores markers older than 24 hours (`AnsweredElsewhereCallTracker.maximumAge`).

**What's left:** A marker can survive only if the main app never sees the end of the call and the NSE never sees a CONFSTART with a different timestamp. Even then it expires after 24 hours. That's acceptable.

**1:1 side effect from round 1:** Mostly resolved. The tracker now only reacts to `CONFSTART`/`CONFEND`, so classic 1:1 `SETUP`/`CANCEL` calls are no longer tracked (test: `testOneOnOneStartDoesNotSetConferenceAnsweredElsewhereState`). 1:1 calls that use `CONFSTART` (for example MLS) are still tracked. That's acceptable given the main-app clearing and the 24-hour expiry.

### 7. Late CONFSTART clears the flag — FIXED, provided 12 holds (`09dbdc396f`)
Another user's incoming CONFSTART removes the marker only if both it and the stored marker have a conference timestamp and the two differ.
Test: `testLateStartInSameConferencePreservesAnsweredElsewhereState`.
If the incoming CONFSTART or the stored marker has no timestamp, the marker isn't cleared. In that case it falls back to the main-app clearing and the 24-hour expiry.

### 8. Side effects in the validator — FIXED (`09dbdc396f`)
The tracking moved to the new `AnsweredElsewhereCallTracker`, which the builder calls. `validateCallNotification` now receives `isCallerSelf` and `wasAnsweredElsewhere` as inputs and is a pure check again. A static `NSLock` makes the read-modify-write atomic within one process, which is enough for the NSE.

### 9. Line length — FIXED
The key construction moved to `AnsweredElsewhereCallKey`.

### Note: key format changed
The new key is `answeredElsewhereCall.<accountUUID>.<conversationUUID>`, without the conversation's domain. Both the main app and the NSE use the shared helper, so it's consistent. A clash between conversation UUIDs on different domains is not realistic.

---

## Round 1 findings (for reference)

### 1. WireAVS points at a local build — BLOCKER, STILL OPEN
**File:** `WireAVS/Package.swift:20`

The binary target was changed from the released 10.5.19 URL and checksum to
`../../wire-avs/build/dist/xc/avs.xcframework`, marked `// TODO: undo changes`.

**Failure:** On CI, or any machine without a sibling `wire-avs` checkout built at that path, SwiftPM can't resolve `WireAVS` and nothing builds. Merging this as is would break `develop` for everyone.

**Fix:** Point the target at a published wire-avs release that includes `ANSWERED_ELSEWHERE` (wire-avs#223), with its checksum. Copilot flagged this too.

### 2. Group calls answered elsewhere still show as missed in iOS Recents
**File:** `wire-ios-sync-engine/Source/Calling/WireCallCenterV3+Events.swift:305`

For group calls, `.answeredElsewhere` was changed to `.stillOngoing`. `handle()` then turned that into `.incoming(shouldRing: false)`, and `CallKitManager` reported a non-ringing incoming call as ended with `reason: .unanswered` (`CallKitManager.swift:833`), which iOS Recents logs as a missed call.

### 3. `callsAnsweredElsewhere` not cleared when the user joins locally
The user answers on desktop, then also joins from the iPhone. The final `.normal` end was still rewritten to `.answeredElsewhere`. `CallObserver` then sent it to `onFailedToJoin`, and CallKit reported the wrong end reason.

### 4. Entry removed by `clearSnapshot` before the call ends
The entry was added before `handle()` ran. If the call became `.terminating(.securityDegraded)`, or `canJoinCall` was false, `clearSnapshot` deleted it. The later `.normal` end then produced a "Missed call" system message and a local notification.

### 5. Stale answered-elsewhere flag
The flag was reset only by the NSE, so events the main app handled left it stale and could hide a genuinely missed call. Commit `601159df59` widened this to 1:1 calls by removing the group check.

### 6. Group status unknown before metadata loads (Copilot)
`fetchOrCreateConversation` can return a stub that still needs a backend update. `isGroupConversation` returned `false` for it, so self's CONFSTART was not recorded. Fixed in `601159df59` by removing the group check, which led to the side effect in 5.

### 7. Another participant's CONFSTART clears the flag during the same call
Any CONFSTART with `resp=false` from someone other than self removed the key, even if it was a late or re-sent start in the current call.

### 8. Side effects and non-atomic state inside the validator
`validateCallNotification` wrote and deleted UserDefaults keys and did two read-modify-write steps that weren't atomic. The keys were never cleaned up.

### 9. Line longer than 120 characters
The key construction line in `ConversationCallingEventNotificationBuilder.swift` was about 128 characters.

### 10. `TODO` without a JIRA ticket
`// TODO: undo changes` in `WireAVS/Package.swift` breaks the SwiftLint rule `// TODO: [WPB-123] description`.
