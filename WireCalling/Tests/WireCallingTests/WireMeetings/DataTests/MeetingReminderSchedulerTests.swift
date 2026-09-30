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

    @Test("does not schedule a reminder whose fire date has passed")
    func skipsPastReminder() async throws {
        let center = NotificationCenterSpy()
        center.status = .authorized

        let scheduled = try await MeetingReminderScheduler(notificationCenter: center).schedule(
            reminder,
            content: UNMutableNotificationContent(),
            now: reminder.fireDate
        )

        #expect(!scheduled)
        #expect(center.addedRequests.isEmpty)
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
    }

    @Test("cancels only the specified occurrence")
    func cancelsReminder() {
        let center = NotificationCenterSpy()

        MeetingReminderScheduler(notificationCenter: center).cancel(reminder)

        #expect(center.removedIdentifiers == [[reminder.identifier]])
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

    func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func pendingRequestIdentifiers() async -> [String] {
        storedPendingIdentifiers
    }

    func add(_ request: UNNotificationRequest) async throws {
        if let addError { throw addError }
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(identifiers)
    }
}
