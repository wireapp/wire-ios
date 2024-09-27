//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import UserNotifications

// MARK: - UserNotificationCenterAbstraction

// TODO: [WPB-9200]: let Sourcery create the mock // sourcery: AutoMockable
/// An abstraction of the `UNUserNotificationCenter` object to facilitate mocking for unit tests.
public protocol UserNotificationCenterAbstraction {
    /// The object that processes incoming notifications and actions.
    var delegate: UNUserNotificationCenterDelegate? { get set }

    func notificationSettings() async -> UNNotificationSettings
    @available(*, noasync)
    func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void)

    /// Registers the notification types and the custom actions they support.
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>)

    /// Requests authorization to use notifications.
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func requestAuthorization() async throws -> Bool
    @available(*, noasync)
    func requestAuthorization(completionHandler: @escaping (Bool, (any Error)?) -> Void)
    @available(*, noasync)
    func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping (Bool, (any Error)?) -> Void
    )

    /// Schedules the request to display a local notification.
    func add(_ request: UNNotificationRequest) async throws
    @available(*, noasync)
    func add(_ request: UNNotificationRequest)
    @available(*, noasync)
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (((any Error)?) -> Void)?)

    /// Unschedules the specified notification requests.
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])

    /// Removes the specified notification requests from Notification Center
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

extension UserNotificationCenterAbstraction {
    public func requestAuthorization() async throws -> Bool {
        try await requestAuthorization(options: [])
    }

    @available(*, noasync)
    public func requestAuthorization(completionHandler: @escaping (Bool, (any Error)?) -> Void) {
        requestAuthorization(options: [], completionHandler: completionHandler)
    }

    @available(*, noasync)
    public func add(_ request: UNNotificationRequest) {
        add(request, withCompletionHandler: nil)
    }
}
