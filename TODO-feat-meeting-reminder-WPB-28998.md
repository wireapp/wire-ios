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
- [x] Keep the next five recurring occurrences scheduled per meeting, as confirmed. Replenish them when the app or NSE next handles meeting data; broader refresh triggers remain to be implemented below.
- [ ] Confirm acceptable reliability: client-only reminders can be stale or missing if the device does not receive a meeting change before the reminder time. If delivery must be guaranteed despite that, discuss backend-scheduled reminders.

## Implementation

- [x] Add the `MeetingReminder` model and a `UNUserNotificationCenter` scheduler using an absolute occurrence start minus ten minutes. The scheduler skips past reminders and checks notification authorization.
- [x] Give requests stable, feature-owned identifiers containing account, qualified meeting ID, and occurrence start. Add cancellation for one occurrence, all occurrences of one meeting, and all meeting reminders for one account without affecting other accounts.
- [x] In app event processing, cancel reminders on `meeting.delete` and on `conversation.member-leave` for the signed-in user when the meeting-to-conversation mapping is stored locally.
- [x] When the organizer deletes a meeting or a participant leaves it directly in the app, cancel that account's reminders after the server-side operation succeeds; this client may not receive its own delete event.
- [x] Add localized reminder content for the occurrence start time, with either the meeting title or a generic title. Give it a reminder category and account ID so taps open the meetings screen for the correct account.
- [ ] Decide when to show the meeting title based on notification privacy settings, translate the new reminder strings, and route a tap to the specific meeting.
- [x] Schedule and reconcile reminders after the app creates, edits, or successfully syncs the authoritative meeting list. Remove obsolete reminders after full-list replacement without touching other accounts; leave pending reminders unchanged when listing fails.
- [x] Add account-scoped scheduler reconciliation for one meeting: remove obsolete occurrence requests, replace current content, and skip duplicate or past occurrence starts. Other app event paths and the NSE still need to use it.
- [x] Reconcile reminders when the app processes `meeting.create`, including when its conversation was already known. Use generic notification text until the privacy setting is decided.
- [x] Reconcile incoming `meeting.update` and `meeting.member-add` through the app event processor, replacing obsolete occurrences when the schedule changes.
- [x] Reconcile the organizer's meeting when the app's create request succeeds, even if this client receives no `meeting.create` event. A reminder failure must not make meeting creation appear to fail.
- [x] Reconcile app-originated edits from the server's updated meeting, replacing occurrences when the start or recurrence changes. A scheduling failure must not make the edit appear to fail.
- [x] Schedule the next five recurring occurrences when the app creates or receives a changed meeting.
- [x] Reconcile successful authoritative meeting-list refreshes (including the meetings UI's list refresh) and replenish each listed meeting's next five occurrences.
- [ ] Replenish recurring reminders during later NSE activity and other app wakeups that do not fetch the meeting list.
- [x] Add a reusable recurrence start calculator that excludes occurrences whose ten-minute fire time has passed and delegates time-zone, daylight-saving, interval, and end-date handling to `MeetingOccurrencePaginator`.
- [x] On logout or account removal, start account-scoped cancellation for that account ID only; preserve reminders for other signed-in accounts. Covered foreground and background session logout, account deletion, and retained-account data purge (`SessionManager.logout(account:)`, `logoutCurrentSession`, and `logoutBackgroundSessionAndPurgeRetainedAccountData`).
- [ ] Ensure logout cancellation completes reliably if the app closes immediately after logout; consider a startup sweep of reminders for accounts that are no longer signed in.
- [x] Reconcile from the NSE for meeting create, invitation, update, and deletion events, including events without visible notification content. Fetch the current meeting before scheduling; cancel on confirmed absence, but preserve pending reminders after a transient fetch failure.
- [ ] Verify the reconciliation completes within the NSE's limited runtime; invitation and update paths currently fetch the meeting again for visible push content.
- [ ] Complete the self-removal cancellation path in the NSE, independently of `buildMeetingCancellationContent`: that method deliberately returns no visible cancellation notification for self-initiated leave and can also return nil when feature data or sender details are unavailable. Reuse the lookup and invitation-backed local storage from `dc883e4da8`, but retain a way to resolve feature-owned pending requests if the local meeting is absent. Do not treat a transient meeting API failure as a deletion.
- [x] When scheduling from an invitation, use the fetched meeting to establish the meeting-to-conversation mapping in the NSE local store.
- [ ] Reconcile against a successful authoritative meeting-list refresh to remove stale reminders after missed events or removals.
- [x] Use the shared `MeetingReminderOccurrenceCalculator` and `MeetingOccurrencePaginator` in the NSE for a bounded next-five window, including meeting time zone, daylight-saving changes, interval, and end date.
- [ ] Handle pending notification changes, authorization changes, and schedule failures during reconciliation without showing an obsolete reminder. The scheduler already skips reminders whose fire time has passed.
- [ ] Ensure foreground presentation and notification taps route to the correct account and meeting.

## Verification

- [x] Add focused tests for absolute fire date, past and unauthorized reminders, stable identifier-based cancellation, account isolation, event-driven cancellation, and direct app deletion or leave.
- [x] Test reminder content with visible and hidden meeting titles, localized occurrence time, reminder category, and account ID.
- [ ] Add focused tests for recurrence across daylight-saving changes, duplicate events, and rescheduling/cancellation after edits and authoritative refreshes.
- [x] Test scheduler reconciliation for an edited start, duplicate occurrence input, past occurrences, and isolation from other accounts and meetings.
- [x] Test NSE meeting-event reminder routing for create, invitation, update, deletion, confirmed absence, and transient fetch failure.
- [ ] Test organizer and invitee flows, meetings created shortly before start, app termination, and a device that stays offline across a meeting change. With two accounts signed in, verify that logging out or removing one account cancels only its pending reminders, including when it is the background account; the other account's reminders must remain scheduled. Check the asynchronous cancellation window when the app closes immediately after logout.
- [ ] Test the local scheduling flow on a device or simulator; test the NSE path on a build that can receive Wire pushes.
- [ ] Run the relevant SwiftFormat/SwiftLint checks and targeted tests. Record any build or push-testing limitation in the PR.
- [ ] Review the final diff and use a conventional PR title referencing `WPB-28998`.

## Working conclusion

The existing meeting data and update events make a client-only implementation feasible without a new backend reminder endpoint. The main app should own normal reconciliation; the NSE can supplement it when an eligible push wakes it. Cancellation on removal needs the conversation member-leave path in addition to meeting deletion. Neither process can repair a meeting change it has not received. This plan does not claim guaranteed delivery or freshness in that case.
