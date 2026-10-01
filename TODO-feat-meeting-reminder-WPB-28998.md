# Meeting reminders — WPB-28998

## Resume here

- [x] Work on `feat/meeting-reminder-WPB-28998` before implementing. The checkout is now on this branch.
- [x] Confirm the product rules in **Decisions** below, then implement the client-side approach in **Implementation**.

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

- [x] Remind every participant, including the organizer, on each signed-in device.
- [x] Enable reminders by default regardless of meeting or conversation mute settings; no separate reminder setting.
- [x] Show one immediate reminder when a newly learned occurrence starts in less than ten minutes.
- [x] Show foreground reminders unless the user is already in that meeting's call.
- [x] Keep the next five recurring occurrences scheduled per meeting. Replenish them when the app or NSE next handles meeting data.
- [x] Use client-only best-effort reminders. A device that misses meeting changes can have stale or missing reminders until its next successful reconciliation.

## Review readiness

- [x] Address the confirmed-absence create and update findings from the latest Copilot review (`f74140a770`).
- [x] Decided not to serialize reminder mutations across the app and NSE, and not to add a global pending-request budget. Reminders are best-effort; the next reconciliation and the startup sweep correct stale requests, and iOS keeps the soonest 64 pending requests.
- [x] Respect the account's Meetings feature flag in app and NSE scheduling, and cancel pending reminders when that feature is disabled. The NSE leaves pending reminders untouched when the feature state is unknown.
- [x] Decided not to special-case `cleanupFailed` after a confirmed meeting 404 in create/update processing; the next meeting-list refresh removes the obsolete reminder.
- [x] Track scheduled occurrences per meeting so a fired calendar reminder is not sent again during a short-notice refresh.
- [ ] Review the final PR diff and current CI results after the remaining code changes.
- [x] Use a conventional PR title referencing `WPB-28998`: `feat: add local meeting reminders - WPB-28998`.

## Implementation

- [x] Add the `MeetingReminder` model and a `UNUserNotificationCenter` scheduler using an absolute occurrence start minus ten minutes, with one immediate reminder for short-notice occurrences. Skip meetings that have started and check notification authorization.
- [x] Give requests stable, feature-owned identifiers containing account, qualified meeting ID, and occurrence start. Add cancellation for one occurrence, all occurrences of one meeting, and all meeting reminders for one account without affecting other accounts.
- [x] In app event processing, cancel reminders on `meeting.delete` and on `conversation.member-leave` for the signed-in user when the meeting-to-conversation mapping is stored locally.
- [x] When the organizer deletes a meeting or a participant leaves it directly in the app, cancel that account's reminders after the server-side operation succeeds; this client may not receive its own delete event.
- [x] Add reminder content with the meeting title, occurrence date, and local start and end times, following invitation notifications; use a generic title only when the meeting title is empty. Give it a reminder category and account ID so taps open the meetings screen for the correct account.
- [x] Keep reminder taps aligned with meeting invitations: open the correct account's meetings screen.
- [ ] Add translations for the new reminder strings through the usual localization process; English source text is present.
- [x] Schedule and reconcile reminders after the app creates, edits, or successfully syncs the authoritative meeting list. Remove obsolete reminders after full-list replacement without touching other accounts; leave pending reminders unchanged when listing fails.
- [x] Add account-scoped scheduler reconciliation for one meeting: remove obsolete occurrence requests, replace current content, and skip duplicate or past occurrence starts.
- [x] Reconcile reminders when the app processes `meeting.create`, including when its conversation was already known.
- [x] Reconcile incoming `meeting.update` and `meeting.member-add` through the app event processor, replacing obsolete occurrences when the schedule changes.
- [x] Reconcile the organizer's meeting when the app's create request succeeds, even if this client receives no `meeting.create` event. A reminder failure must not make meeting creation appear to fail.
- [x] Reconcile app-originated edits from the server's updated meeting, replacing occurrences when the start or recurrence changes. A scheduling failure must not make the edit appear to fail.
- [x] Schedule the next five recurring occurrences when the app creates or receives a changed meeting.
- [x] Reconcile successful authoritative meeting-list refreshes (including the meetings UI's list refresh) and replenish each listed meeting's next five occurrences.
- [x] Replenish recurring reminders during later app and NSE meeting events and successful app meeting-list refreshes. An unrelated wakeup does not trigger a meeting fetch.
- [x] Add a reusable recurrence start calculator that includes short-notice occurrences and delegates time-zone, daylight-saving, interval, and end-date handling to `MeetingOccurrencePaginator`.
- [x] On logout or account removal, start account-scoped cancellation for that account ID only; preserve reminders for other signed-in accounts. Covered foreground and background session logout, account deletion, and retained-account data purge (`SessionManager.logout(account:)`, `logoutCurrentSession`, and `logoutBackgroundSessionAndPurgeRetainedAccountData`).
- [x] Persist account-scoped cancellation intent before logout's asynchronous notification-center work. On app startup, sweep feature-owned reminders for signed-out accounts and accounts with unfinished cancellation, preserving other signed-in accounts. Clear each intent only after the cancellation request is made.
- [x] Reconcile from the NSE for meeting create, invitation, update, and deletion events, including events without visible notification content. Fetch the current meeting before scheduling; cancel on confirmed absence, but preserve pending reminders after a transient fetch failure.
- [x] Reuse the NSE reminder fetch for visible invitation and update content, avoiding a second meeting API request on the normal path. Preserve direct builder fetching and visible content when reminder scheduling fails.
- [ ] Verify reconciliation timing within the NSE's limited runtime on a push-capable signed build.
- [x] Cancel reminders in the NSE on `conversation.member-leave` when the signed-in user is removed, before visible notification checks. Match locally stored meetings and feature-owned pending requests by account and qualified conversation ID, so cancellation still works if the local meeting is absent or no visible cancellation is built.
- [x] When scheduling from an invitation, use the fetched meeting to establish the meeting-to-conversation mapping in the NSE local store.
- [x] Reconcile against a successful authoritative meeting-list refresh to remove stale reminders after missed events or removals.
- [x] Use the shared `MeetingReminderOccurrenceCalculator` and `MeetingOccurrencePaginator` in the NSE for a bounded next-five window, including meeting time zone, daylight-saving changes, interval, and end date.
- [x] Re-add missing pending requests on reconciliation, remove a request after authorization loss or failed replacement, and continue scheduling later occurrences after one add failure.
- [x] Route reminder taps through the account ID in the notification payload to that account's meetings screen.
- [x] Present reminders in the foreground unless the matching conversation has an active call.

## Verification

- [x] Add focused tests for absolute fire date, past and unauthorized reminders, stable identifier-based cancellation, account isolation, event-driven cancellation, and direct app deletion or leave.
- [x] Test reminder content with visible and hidden meeting titles, localized occurrence time, reminder category, and account ID.
- [x] Test that a default tap on the reminder category opens the meetings screen for the notification's session. Verified in a WireSyncEngine test run with 20 passing tests after clearing DerivedData.
- [x] Test recurrence across daylight-saving changes, short-notice deduplication, and rescheduling/cancellation after edits and authoritative refreshes.
- [x] Test scheduler reconciliation for an edited start, duplicate occurrence input, past occurrences, and isolation from other accounts and meetings.
- [x] Test NSE meeting-event reminder routing for create, invitation, update, deletion, confirmed absence, and transient fetch failure.
- [x] Test that invitation and update notification content reuse the meeting fetched for reminders, and that scheduling failure still leaves fetched details available.
- [x] Test NSE self-removal cancellation with and without a stored meeting, other-user removal, and pending-request isolation by account and qualified conversation ID.
- [x] Test persisted logout cancellation intent across journal instances, repeated requests for one account, and startup sweep isolation for another signed-in account.
- [ ] Test organizer and invitee flows, meetings created shortly before start, app termination, and a device that stays offline across a meeting change. With two accounts signed in, verify that logging out or removing one account cancels only its pending reminders, including when it is the background account; the other account's reminders must remain scheduled. Check the asynchronous cancellation window when the app closes immediately after logout.
- [ ] Test the local scheduling flow on a device or simulator; test the NSE path on a build that can receive Wire pushes.
- [x] Run SwiftFormat and SwiftLint on changed Swift files and targeted tests: 23 WireCalling and 3 WireDomain tests passed. The earlier reminder-tap run passed 20 WireSyncEngine tests; the new foreground test run was stopped on request after an Xcode cache failure. Record that and the push-testing limitation in the PR.
- [x] Compile the new review fixes with build-only `WireCallingAll` and `WireDomain` Xcode builds; add regression tests without running them, per the request to stop tests.

## Signed-build device checklist

- [ ] With Wire closed, receive a meeting invitation for a meeting more than ten minutes away. Confirm the local reminder appears ten minutes before the start with the meeting title and the occurrence's start and end times.
- [ ] Receive an invitation for a meeting starting within ten minutes. Confirm one immediate reminder, including after reopening or refreshing the meetings list.
- [ ] While Wire is closed, edit a meeting from another client. Confirm the old reminder does not appear and the new time is used. Then cancel a meeting and remove the signed-in user from another meeting; confirm neither leaves a pending reminder.
- [ ] With Wire in the foreground, confirm the reminder banner appears unless the user is already in that meeting's call.
- [ ] With two accounts signed in, log out of one account, including when it is the background account. Confirm that account's reminders stop and the other account's reminder still arrives.

## Working conclusion

The existing meeting data and update events make a client-only implementation feasible without a new backend reminder endpoint. The main app should own normal reconciliation; the NSE can supplement it when an eligible push wakes it. Cancellation on removal needs the conversation member-leave path in addition to meeting deletion. Neither process can repair a meeting change it has not received. This plan does not claim guaranteed delivery or freshness in that case.
