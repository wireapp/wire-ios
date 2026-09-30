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

public import Foundation
public import UserNotifications
public import WireCallingDomain

protocol MeetingReminderNotificationCenter {
    func authorizationStatus() async -> UNAuthorizationStatus
    func pendingRequestIdentifiers() async -> [String]
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: MeetingReminderNotificationCenter {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }

    func pendingRequestIdentifiers() async -> [String] {
        await withCheckedContinuation { continuation in
            getPendingNotificationRequests { requests in
                continuation.resume(returning: requests.map(\.identifier))
            }
        }
    }
}

/// Schedules one reminder with a fixed UTC fire date. Event reconciliation is handled by callers.
public struct MeetingReminderScheduler {

    private let notificationCenter: any MeetingReminderNotificationCenter

    public init() {
        self.notificationCenter = UNUserNotificationCenter.current()
    }

    init(notificationCenter: any MeetingReminderNotificationCenter) {
        self.notificationCenter = notificationCenter
    }

    /// Returns false if the reminder time has passed or notification authorization is unavailable.
    @discardableResult
    public func schedule(
        _ reminder: MeetingReminder,
        content: UNNotificationContent,
        now: Date = .now
    ) async throws -> Bool {
        guard reminder.fireDate > now else { return false }

        switch await notificationCenter.authorizationStatus() {
        case .authorized, .provisional:
            break
        default:
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.identifier])
            return false
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var fireComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminder.fireDate
        )
        fireComponents.calendar = calendar
        fireComponents.timeZone = calendar.timeZone

        let request = UNNotificationRequest(
            identifier: reminder.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        )
        do {
            try await notificationCenter.add(request)
        } catch {
            // An earlier request with this identifier may still have outdated content.
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.identifier])
            throw error
        }
        return true
    }

    public func cancel(_ reminder: MeetingReminder) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.identifier])
    }

    /// Replaces this account's pending reminders for one meeting with the supplied occurrences.
    /// Obsolete requests are removed before adding replacements so a changed start cannot fire twice.
    public func reconcile(
        accountID: UUID,
        meetingID: QualifiedID,
        occurrenceStarts: [Date],
        now: Date = .now,
        contentForOccurrence: (Date) -> UNNotificationContent
    ) async throws {
        let reminders = Set(occurrenceStarts).map {
            MeetingReminder(accountID: accountID, meetingID: meetingID, occurrenceStart: $0)
        }.filter { $0.fireDate > now }
        let desiredIdentifiers = Set(reminders.map(\.identifier))
        let prefix = MeetingReminder.identifierPrefix(accountID: accountID, meetingID: meetingID)
        let obsoleteIdentifiers = await notificationCenter.pendingRequestIdentifiers()
            .filter { $0.hasPrefix(prefix) && !desiredIdentifiers.contains($0) }

        if !obsoleteIdentifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: obsoleteIdentifiers)
        }

        var firstError: (any Error)?
        for reminder in reminders.sorted(by: { $0.occurrenceStart < $1.occurrenceStart }) {
            do {
                try await schedule(
                    reminder,
                    content: contentForOccurrence(reminder.occurrenceStart),
                    now: now
                )
            } catch {
                if firstError == nil { firstError = error }
            }
        }
        if let firstError { throw firstError }
    }

    /// Replaces this account's reminders after a successful authoritative meeting-list refresh.
    public func reconcileAll(
        accountID: UUID,
        meetings: [Meeting],
        occurrenceLimit: Int,
        now: Date = .now,
        contentForOccurrence: (Meeting, Date) -> UNNotificationContent
    ) async throws {
        let uniqueMeetings = Dictionary(meetings.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
            .values
        let calculator = MeetingReminderOccurrenceCalculator()
        let desired = uniqueMeetings.flatMap { meeting in
            calculator.starts(for: meeting, after: now, limit: occurrenceLimit).map { start in
                ScheduledMeetingReminder(
                    meeting: meeting,
                    reminder: MeetingReminder(accountID: accountID, meetingID: meeting.id, occurrenceStart: start)
                )
            }
        }
        let desiredIdentifiers = Set(desired.map(\.reminder.identifier))
        let accountPrefix = MeetingReminder.accountIdentifierPrefix(accountID: accountID)
        let obsoleteIdentifiers = await notificationCenter.pendingRequestIdentifiers()
            .filter { $0.hasPrefix(accountPrefix) && !desiredIdentifiers.contains($0) }

        if !obsoleteIdentifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: obsoleteIdentifiers)
        }

        var firstError: (any Error)?
        for entry in desired.sorted(by: { $0.reminder.fireDate < $1.reminder.fireDate }) {
            do {
                try await schedule(
                    entry.reminder,
                    content: contentForOccurrence(entry.meeting, entry.reminder.occurrenceStart),
                    now: now
                )
            } catch {
                if firstError == nil { firstError = error }
            }
        }
        if let firstError { throw firstError }
    }

    /// Requests cancellation of every pending occurrence for one qualified meeting and account.
    public func cancelAll(accountID: UUID, meetingID: QualifiedID) async {
        let prefix = MeetingReminder.identifierPrefix(accountID: accountID, meetingID: meetingID)
        let identifiers = await notificationCenter.pendingRequestIdentifiers()
            .filter { $0.hasPrefix(prefix) }

        guard !identifiers.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Requests cancellation of every pending meeting reminder for one account.
    public func cancelAll(accountID: UUID) async {
        let prefix = MeetingReminder.accountIdentifierPrefix(accountID: accountID)
        let identifiers = await notificationCenter.pendingRequestIdentifiers()
            .filter { $0.hasPrefix(prefix) }

        guard !identifiers.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Removes reminders for accounts that are no longer signed in while preserving other notifications.
    public func cancelAll(exceptAccountIDs accountIDs: Set<UUID>) async {
        let retainedPrefixes = accountIDs.map { MeetingReminder.accountIdentifierPrefix(accountID: $0) }
        let identifiers = await notificationCenter.pendingRequestIdentifiers().filter { identifier in
            identifier.hasPrefix(MeetingReminder.identifierNamespace)
                && !retainedPrefixes.contains(where: identifier.hasPrefix)
        }

        guard !identifiers.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

}

private struct ScheduledMeetingReminder {
    let meeting: Meeting
    let reminder: MeetingReminder
}
