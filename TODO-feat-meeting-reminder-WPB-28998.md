# Meeting reminders — WPB-28998

## Resume here

- [x] Work on `feat/meeting-reminder-WPB-28998` before implementing. The checkout is now on this branch.
- [ ] Confirm the product rules in **Decisions** below, then implement the client-side approach in **Implementation**.

## Feasibility and constraints

- [x] Confirm that the client has meeting start times and receives meeting create, update, and delete events. See `WireCalling/Sources/WireCallingDomain/WireMeetings/Model/Meeting.swift` and `WireDomain/Sources/WireDomain/Event Processing/MeetingEventProcessor/`.
- [x] Confirm that iOS supports scheduling a local notification for a future date, including from an app extension through `UNUserNotificationCenter`. Once scheduled, the system can deliver it while the app is closed. See [Apple's local notification guide](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app) and [notification center documentation](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter).
- [x] Confirm that Wire's notification service extension (NSE) is invoked by an eligible incoming remote notification, **not** by a timer ten minutes before a meeting. See `wire-ios/Wire Notification Service Extension/NotificationService.swift` and [Apple's NSE documentation](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension).
- [x] Identify a current NSE gap: its meeting invitation and update builders fetch meeting details separately because the NSE does not run the main app's meeting refresh. See `WireDomain/Sources/WireDomain/Notifications/Builders/Meeting/MeetingMemberAddEventNotificationBuilder.swift`.
- [x] Check the current NSE event handling: `MeetingEventNotificationBuilder` ignores `meeting.create`, and notification generation only builds immediate notification content. Reminder reconciliation must explicitly observe all relevant event types, including create events that produce no visible push notification.
- [x] Identify the removal path: there is no `meeting.member-remove` event in the client. Removing a participant from a meeting removes them from its conversation; the client receives `conversation.member-leave` with the conversation ID and removed user IDs. The reminder scheduler must recognize when the signed-in user was removed and map that conversation back to its meeting(s). See `UpdateMeetingUseCase.swift`, `ConversationMemberLeaveEvent.swift`, and `MeetingEventType.swift`.
- [x] Confirm that `UNUserNotificationCenter` is available to an app extension, and that pending requests can be removed by identifier. The NSE itself only runs for eligible remote alerts and has limited execution time; it cannot independently wake at the reminder time. See Apple's `UNUserNotificationCenter` and `UNNotificationServiceExtension` documentation.
- [x] Review merged commit `dc883e4da8` (`WPB-29046`), now on this branch. It adds meeting-aware `conversation.member-leave` handling to both the NSE and foreground notification paths, and stores meeting details fetched for NSE invitations. Its builders show immediate notifications; they do not schedule or cancel reminder requests.
- [ ] Validate on a push-capable, properly signed build that the NSE can add, replace, and cancel Wire's pending local notifications. The repository's `README.md` notes that source builds cannot receive Wire's production APNs notifications.

## Decisions

- [ ] Confirm that the reminder is intended for every meeting participant, including the organizer, on each signed-in device.
- [ ] Confirm whether reminders are on by default, respect muted meetings/conversations, and need a separate user setting.
- [ ] Decide what to show when a meeting is created or learned about less than ten minutes before it starts: immediate reminder or none.
- [ ] Decide whether a reminder should appear while Wire is in the foreground or while the user is already in that meeting.
- [ ] Choose the amount of future recurring occurrences to keep scheduled and how to replenish them when the app or NSE next runs.
- [ ] Confirm acceptable reliability: client-only reminders can be stale or missing if the device does not receive a meeting change before the reminder time. If delivery must be guaranteed despite that, discuss backend-scheduled reminders.

## Implementation

- [ ] Add a small, shared meeting-reminder scheduler accessible from the app and NSE. Use `UNUserNotificationCenter` and an **absolute** fire date of occurrence start minus ten minutes; do not start a ten-minute timer when an event arrives.
- [ ] Give each pending reminder a stable identifier containing account, qualified meeting ID, and occurrence start. Limit replacement/removal to reminders owned by this feature and account.
- [ ] Build reminder content from the meeting title and occurrence time using existing localization, notification privacy, and account-routing conventions. Check notification authorization/settings before scheduling.
- [ ] Reconcile pending reminders after the app creates, edits, deletes, or syncs meetings. Include sign-out/account removal and full meeting-list replacement so obsolete reminders are removed.
- [ ] Reconcile from the NSE when it processes relevant meeting create, invitation, update, or cancellation events, including events for which no immediate notification is built. Fetch the latest meeting details where required, and finish within the NSE's limited runtime. Handle duplicate or out-of-order events safely.
- [ ] On `conversation.member-leave` for the signed-in user, cancel reminders for every meeting tied to that conversation. Run cancellation independently of `buildMeetingCancellationContent`: that method deliberately returns no visible cancellation notification for self-initiated leave and can also return nil when feature data or sender details are unavailable. Reuse the lookup and invitation-backed local storage from `dc883e4da8`, but retain a way to resolve feature-owned pending requests if the local meeting is absent. Do not treat a transient meeting API failure as a deletion.
- [ ] When scheduling from an invitation, use the meeting response to establish the meeting-to-conversation mapping. Reconcile against a successful authoritative meeting-list refresh to remove stale reminders after missed events or removals.
- [ ] Use `MeetingOccurrencePaginator` (or shared equivalent logic) for recurrence, including meeting time zone, daylight-saving changes, interval, and end date. Keep a bounded future window and replenish it on later app/NSE activity.
- [ ] Handle meetings whose reminder time has passed, pending notification changes, authorization changes, and schedule failures without showing an obsolete reminder.
- [ ] Ensure foreground presentation and notification taps route to the correct account and meeting.

## Verification

- [ ] Add focused tests for fire-date calculation, recurrence across daylight-saving changes, stable identifiers, duplicate events, and rescheduling/cancellation after edits and deletes.
- [ ] Test organizer and invitee flows, meetings created shortly before start, multiple accounts, sign-out, app termination, and a device that stays offline across a meeting change.
- [ ] Test the local scheduling flow on a device or simulator; test the NSE path on a build that can receive Wire pushes.
- [ ] Run the relevant SwiftFormat/SwiftLint checks and targeted tests. Record any build or push-testing limitation in the PR.
- [ ] Review the final diff and use a conventional PR title referencing `WPB-28998`.

## Working conclusion

The existing meeting data and update events make a client-only implementation feasible without a new backend reminder endpoint. The main app should own normal reconciliation; the NSE can supplement it when an eligible push wakes it. Cancellation on removal needs the conversation member-leave path in addition to meeting deletion. Neither process can repair a meeting change it has not received. This plan does not claim guaranteed delivery or freshness in that case.
