//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import Testing
import UserNotifications
import WireFoundation

@testable import WireCallingData
@testable import WireCallingDomain

@Suite("MeetingReminderScheduler Tests")
struct MeetingReminderSchedulerTests {

    private let reminder = MeetingReminder(
        accountID: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        meetingID: QualifiedID(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            domain: "example.com"
        ),
        occurrenceStart: Date(timeIntervalSince1970: 1_900_000_000)
    )

    @Test("schedules an authorized reminder at the absolute UTC fire date")
    func schedulesAtFireDate() async throws {
        let center = NotificationCenterSpy()
        center.status = .authorized
        let content = UNMutableNotificationContent()
        content.title = "Team meeting"

        let scheduled = try await MeetingReminderScheduler(notificationCenter: center).schedule(
            reminder,
            content: content,
            now: reminder.fireDate.addingTimeInterval(-1)
        )

        #expect(scheduled)
        let request = try #require(center.addedRequests.first)
        #expect(request.identifier == reminder.identifier)
        #expect(request.content.title == "Team meeting")
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(!trigger.repeats)
        #expect(trigger.dateComponents.calendar?.date(from: trigger.dateComponents) == reminder.fireDate)
    }

    @Test("does not schedule a reminder after the meeting has started")
    func skipsPastMeeting() async throws {
        let center = NotificationCenterSpy()
        center.status = .authorized

        let scheduled = try await MeetingReminderScheduler(notificationCenter: center).schedule(
            reminder,
            content: UNMutableNotificationContent(),
            now: reminder.occurrenceStart
        )

        #expect(!scheduled)
        #expect(center.addedRequests.isEmpty)
    }

    @Test("sends a short-notice reminder immediately and only once across scheduler instances")
    func sendsShortNoticeReminderOnce() async throws {
        let center = NotificationCenterSpy()
        center.status = .authorized
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let now = reminder.occurrenceStart.addingTimeInterval(-5 * 60)

        try await MeetingReminderScheduler(notificationCenter: center, defaults: defaults).reconcile(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID,
            occurrenceStarts: [reminder.occurrenceStart],
            now: now
        ) { _ in UNMutableNotificationContent() }
        try await MeetingReminderScheduler(notificationCenter: center, defaults: defaults).reconcile(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID,
            occurrenceStarts: [reminder.occurrenceStart],
            now: now
        ) { _ in UNMutableNotificationContent() }

        #expect(center.addedRequests.count == 1)
        let trigger = try #require(center.addedRequests.first?.trigger as? UNTimeIntervalNotificationTrigger)
        #expect(trigger.timeInterval == 1)
        #expect(!trigger.repeats)
    }

    @Test("a calendar reminder that already fired is not sent again during a short-notice refresh")
    func scheduledReminderDoesNotBecomeImmediateDuplicate() async throws {
        let center = NotificationCenterSpy()
        center.status = .authorized
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let scheduler = MeetingReminderScheduler(notificationCenter: center, defaults: defaults)

        try await scheduler.reconcile(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID,
            occurrenceStarts: [reminder.occurrenceStart],
            now: reminder.fireDate.addingTimeInterval(-1)
        ) { _ in UNMutableNotificationContent() }
        try await scheduler.reconcile(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID,
            occurrenceStarts: [reminder.occurrenceStart],
            now: reminder.fireDate.addingTimeInterval(1)
        ) { _ in UNMutableNotificationContent() }

        #expect(center.addedRequests.count == 1)
        #expect(center.addedRequests.first?.trigger is UNCalendarNotificationTrigger)
    }

    @Test("a cancelled calendar reminder is sent immediately when restored during the short-notice window")
    func cancelledReminderCanBecomeImmediate() async throws {
        let center = NotificationCenterSpy()
        center.status = .authorized
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let scheduler = MeetingReminderScheduler(notificationCenter: center, defaults: defaults)

        try await scheduler.schedule(
            reminder,
            content: UNMutableNotificationContent(),
            now: reminder.fireDate.addingTimeInterval(-1)
        )
        center.storedPendingIdentifiers = [reminder.identifier]
        await scheduler.cancelAll(accountID: reminder.accountID)
        center.storedPendingIdentifiers = []
        try await scheduler.schedule(
            reminder,
            content: UNMutableNotificationContent(),
            now: reminder.fireDate.addingTimeInterval(1)
        )

        #expect(center.addedRequests.count == 2)
        #expect(center.addedRequests.last?.trigger is UNTimeIntervalNotificationTrigger)
    }

    @Test("does not schedule without notification authorization")
    func skipsUnauthorizedReminder() async throws {
        let center = NotificationCenterSpy()
        center.status = .denied

        let scheduled = try await MeetingReminderScheduler(notificationCenter: center).schedule(
            reminder,
            content: UNMutableNotificationContent(),
            now: reminder.fireDate.addingTimeInterval(-1)
        )

        #expect(!scheduled)
        #expect(center.addedRequests.isEmpty)
        #expect(center.removedIdentifiers == [[reminder.identifier]])
    }

    @Test("cancels only the specified occurrence")
    func cancelsReminder() {
        let center = NotificationCenterSpy()

        MeetingReminderScheduler(notificationCenter: center).cancel(reminder)

        #expect(center.removedIdentifiers == [[reminder.identifier]])
    }

    @Test("replaces an edited meeting's reminders without touching another account or meeting")
    func reconcilesChangedStart() async throws {
        let center = NotificationCenterSpy()
        center.status = .authorized
        let updatedStart = reminder.occurrenceStart.addingTimeInterval(3600)
        let otherAccount = MeetingReminder(
            accountID: UUID(),
            meetingID: reminder.meetingID,
            occurrenceStart: reminder.occurrenceStart
        )
        let otherMeeting = MeetingReminder(
            accountID: reminder.accountID,
            meetingID: QualifiedID(id: UUID(), domain: reminder.meetingID.domain),
            occurrenceStart: reminder.occurrenceStart
        )
        center.storedPendingIdentifiers = [reminder.identifier, otherAccount.identifier, otherMeeting.identifier]

        try await MeetingReminderScheduler(notificationCenter: center).reconcile(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID,
            occurrenceStarts: [updatedStart, updatedStart],
            now: reminder.fireDate.addingTimeInterval(-1)
        ) { _ in
            let content = UNMutableNotificationContent()
            content.title = "Updated meeting"
            return content
        }

        #expect(center.removedIdentifiers == [[reminder.identifier]])
        #expect(center.addedRequests.count == 1)
        #expect(center.addedRequests.first?.identifier == MeetingReminder(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID,
            occurrenceStart: updatedStart
        ).identifier)
        #expect(center.addedRequests.first?.content.title == "Updated meeting")
    }

    @Test("removes obsolete reminders when the meeting has started")
    func reconcilesPastOccurrences() async throws {
        let center = NotificationCenterSpy()
        center.status = .authorized
        center.storedPendingIdentifiers = [reminder.identifier]

        try await MeetingReminderScheduler(notificationCenter: center).reconcile(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID,
            occurrenceStarts: [reminder.occurrenceStart],
            now: reminder.occurrenceStart
        ) { _ in UNMutableNotificationContent() }

        #expect(center.removedIdentifiers == [[reminder.identifier]])
        #expect(center.addedRequests.isEmpty)
    }

    @Test("removes a meeting's pending reminders when no occurrences are supplied")
    func reconcilesEmptyOccurrences() async throws {
        let center = NotificationCenterSpy()
        let otherAccount = MeetingReminder(
            accountID: UUID(),
            meetingID: reminder.meetingID,
            occurrenceStart: reminder.occurrenceStart
        )
        center.storedPendingIdentifiers = [reminder.identifier, otherAccount.identifier]

        try await MeetingReminderScheduler(notificationCenter: center).reconcile(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID,
            occurrenceStarts: []
        ) { _ in UNMutableNotificationContent() }

        #expect(center.removedIdentifiers == [[reminder.identifier]])
        #expect(center.addedRequests.isEmpty)
    }

    @Test("a failed replacement removes its old request and still schedules later occurrences")
    func reconciliationContinuesAfterOccurrenceError() async {
        let center = NotificationCenterSpy()
        center.status = .authorized
        center.storedPendingIdentifiers = [reminder.identifier]
        center.failingIdentifiers = [reminder.identifier]
        let laterStart = reminder.occurrenceStart.addingTimeInterval(3600)
        let laterReminder = MeetingReminder(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID,
            occurrenceStart: laterStart
        )

        await #expect(throws: TestError.addFailed) {
            try await MeetingReminderScheduler(notificationCenter: center).reconcile(
                accountID: reminder.accountID,
                meetingID: reminder.meetingID,
                occurrenceStarts: [reminder.occurrenceStart, laterStart],
                now: reminder.fireDate.addingTimeInterval(-1)
            ) { _ in UNMutableNotificationContent() }
        }

        #expect(center.removedIdentifiers == [[reminder.identifier]])
        #expect(center.addedRequests.map(\.identifier) == [laterReminder.identifier])
    }

    @Test("authoritative refresh replaces stale meetings and occurrences for only one account")
    func reconcilesAllMeetings() async throws {
        let center = NotificationCenterSpy()
        center.status = .authorized
        let removedMeeting = MeetingReminder(
            accountID: reminder.accountID,
            meetingID: QualifiedID(id: UUID(), domain: "example.com"),
            occurrenceStart: reminder.occurrenceStart
        )
        let otherAccount = MeetingReminder(
            accountID: UUID(),
            meetingID: reminder.meetingID,
            occurrenceStart: reminder.occurrenceStart
        )
        center.storedPendingIdentifiers = [
            reminder.identifier,
            removedMeeting.identifier,
            otherAccount.identifier,
            "unrelated"
        ]
        let updatedStart = reminder.occurrenceStart.addingTimeInterval(3600)

        try await MeetingReminderScheduler(notificationCenter: center).reconcileAll(
            accountID: reminder.accountID,
            meetings: [makeMeeting(id: reminder.meetingID, start: updatedStart)],
            occurrenceLimit: 5,
            now: reminder.fireDate.addingTimeInterval(-1)
        ) { _, _ in UNMutableNotificationContent() }

        #expect(Set(center.removedIdentifiers.joined()) == Set([
            reminder.identifier,
            removedMeeting.identifier
        ]))
        #expect(center.addedRequests.map(\.identifier) == [MeetingReminder(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID,
            occurrenceStart: updatedStart
        ).identifier])
    }

    @Test("authoritative empty list removes only this account's meeting reminders")
    func reconcilesEmptyMeetingList() async throws {
        let center = NotificationCenterSpy()
        let otherAccount = MeetingReminder(
            accountID: UUID(),
            meetingID: reminder.meetingID,
            occurrenceStart: reminder.occurrenceStart
        )
        center.storedPendingIdentifiers = [reminder.identifier, otherAccount.identifier]

        try await MeetingReminderScheduler(notificationCenter: center).reconcileAll(
            accountID: reminder.accountID,
            meetings: [],
            occurrenceLimit: 5
        ) { _, _ in UNMutableNotificationContent() }

        #expect(center.removedIdentifiers == [[reminder.identifier]])
        #expect(center.addedRequests.isEmpty)
    }

    @Test("a scheduling failure does not prevent later meetings from being scheduled")
    func reconciliationContinuesAfterAddError() async {
        let center = NotificationCenterSpy()
        center.status = .authorized
        let firstMeeting = makeMeeting(id: reminder.meetingID, start: reminder.occurrenceStart)
        let secondMeeting = makeMeeting(
            id: QualifiedID(id: UUID(), domain: "example.com"),
            start: reminder.occurrenceStart.addingTimeInterval(3600)
        )
        center.failingIdentifiers = [reminder.identifier]

        await #expect(throws: TestError.addFailed) {
            try await MeetingReminderScheduler(notificationCenter: center).reconcileAll(
                accountID: reminder.accountID,
                meetings: [firstMeeting, secondMeeting],
                occurrenceLimit: 5,
                now: reminder.fireDate.addingTimeInterval(-1)
            ) { _, _ in UNMutableNotificationContent() }
        }

        #expect(center.addedRequests.map(\.identifier) == [MeetingReminder(
            accountID: reminder.accountID,
            meetingID: secondMeeting.id,
            occurrenceStart: secondMeeting.start
        ).identifier])
    }

    @Test("cancels every pending occurrence for only the selected account and qualified meeting")
    func cancelsAllMeetingOccurrences() async {
        let center = NotificationCenterSpy()
        let laterOccurrence = MeetingReminder(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID,
            occurrenceStart: reminder.occurrenceStart.addingTimeInterval(3600)
        )
        let otherAccount = MeetingReminder(
            accountID: UUID(),
            meetingID: reminder.meetingID,
            occurrenceStart: reminder.occurrenceStart
        )
        let otherDomain = MeetingReminder(
            accountID: reminder.accountID,
            meetingID: QualifiedID(id: reminder.meetingID.id, domain: "example.com.evil"),
            occurrenceStart: reminder.occurrenceStart
        )
        center.storedPendingIdentifiers = [
            reminder.identifier,
            laterOccurrence.identifier,
            otherAccount.identifier,
            otherDomain.identifier,
            "unrelated"
        ]

        await MeetingReminderScheduler(notificationCenter: center).cancelAll(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID
        )

        #expect(center.removedIdentifiers.count == 1)
        #expect(Set(center.removedIdentifiers[0]) == Set([reminder.identifier, laterOccurrence.identifier]))
    }

    @Test("does not remove pending requests when no occurrence matches")
    func cancelAllWithoutMatches() async {
        let center = NotificationCenterSpy()
        center.storedPendingIdentifiers = ["unrelated"]

        await MeetingReminderScheduler(notificationCenter: center).cancelAll(
            accountID: reminder.accountID,
            meetingID: reminder.meetingID
        )

        #expect(center.removedIdentifiers.isEmpty)
    }

    @Test("cancels all meeting reminders for one account while preserving other accounts")
    func cancelsAllAccountReminders() async {
        let center = NotificationCenterSpy()
        let anotherMeeting = MeetingReminder(
            accountID: reminder.accountID,
            meetingID: QualifiedID(id: UUID(), domain: "example.com"),
            occurrenceStart: reminder.occurrenceStart
        )
        let otherAccount = MeetingReminder(
            accountID: UUID(),
            meetingID: reminder.meetingID,
            occurrenceStart: reminder.occurrenceStart
        )
        center.storedPendingIdentifiers = [
            reminder.identifier,
            anotherMeeting.identifier,
            otherAccount.identifier,
            "unrelated"
        ]

        await MeetingReminderScheduler(notificationCenter: center).cancelAll(accountID: reminder.accountID)

        #expect(center.removedIdentifiers.count == 1)
        #expect(Set(center.removedIdentifiers[0]) == Set([reminder.identifier, anotherMeeting.identifier]))
    }

    @Test("does not remove pending requests when the account has no meeting reminders")
    func cancelAllAccountWithoutMatches() async {
        let center = NotificationCenterSpy()
        center.storedPendingIdentifiers = ["unrelated"]

        await MeetingReminderScheduler(notificationCenter: center).cancelAll(accountID: reminder.accountID)

        #expect(center.removedIdentifiers.isEmpty)
    }

    @Test("startup sweep removes only reminders for signed-out accounts")
    func cancelsRemindersForMissingAccounts() async {
        let center = NotificationCenterSpy()
        let signedInAccount = UUID()
        let retainedReminder = MeetingReminder(
            accountID: signedInAccount,
            meetingID: reminder.meetingID,
            occurrenceStart: reminder.occurrenceStart
        )
        center.storedPendingIdentifiers = [reminder.identifier, retainedReminder.identifier, "unrelated"]

        await MeetingReminderScheduler(notificationCenter: center).cancelAll(exceptAccountIDs: [signedInAccount])

        #expect(center.removedIdentifiers == [[reminder.identifier]])
    }

    @Test("propagates notification scheduling errors")
    func propagatesAddError() async {
        let center = NotificationCenterSpy()
        center.status = .authorized
        center.addError = TestError.addFailed

        await #expect(throws: TestError.addFailed) {
            try await MeetingReminderScheduler(notificationCenter: center).schedule(
                reminder,
                content: UNMutableNotificationContent(),
                now: reminder.fireDate.addingTimeInterval(-1)
            )
        }
        #expect(center.removedIdentifiers == [[reminder.identifier]])
    }

    private func makeMeeting(id: QualifiedID, start: Date) -> Meeting {
        Meeting(
            id: id,
            title: "Team meeting",
            start: start,
            end: start.addingTimeInterval(3600),
            recurrence: nil,
            conversationID: QualifiedID(id: UUID(), domain: "example.com"),
            creatorID: QualifiedID(id: UUID(), domain: "example.com")
        )
    }

}

private enum TestError: Error {
    case addFailed
}

private final class NotificationCenterSpy: MeetingReminderNotificationCenter {
    var status: UNAuthorizationStatus = .notDetermined
    var addedRequests: [UNNotificationRequest] = []
    var storedPendingIdentifiers: [String] = []
    var removedIdentifiers: [[String]] = []
    var addError: TestError?
    var failingIdentifiers: Set<String> = []

    func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func pendingRequestIdentifiers() async -> [String] {
        storedPendingIdentifiers
    }

    func add(_ request: UNNotificationRequest) async throws {
        if let addError { throw addError }
        if failingIdentifiers.contains(request.identifier) { throw TestError.addFailed }
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(identifiers)
    }
}
