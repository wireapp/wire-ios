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
        try await notificationCenter.add(request)
        return true
    }

    public func cancel(_ reminder: MeetingReminder) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.identifier])
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

}
