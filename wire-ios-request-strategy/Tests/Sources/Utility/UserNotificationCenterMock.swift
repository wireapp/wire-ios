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

import Foundation
import UserNotifications

@objc(ZMUserNotificationCenterMock)
public class UserNotificationCenterMock: NSObject, UserNotificationCenterAbstraction {

    weak public var delegate: UNUserNotificationCenterDelegate?

    /// Identifiers of scheduled notification requests.
    @objc public var scheduledRequests = [UNNotificationRequest]()

    /// Identifiers of removed notifications.
    @objc public var removedNotifications = Set<String>()

    /// The registered notification categories for the app.
    @objc public var registeredNotificationCategories = Set<UNNotificationCategory>()

    /// The requested authorization options for the app.
    @objc public var requestedAuthorizationOptions: UNAuthorizationOptions = []

    public func notificationSettings() async -> UNNotificationSettings {
        fatalError("not implemented yet")
    }

    @available(*, noasync)
    public func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void) {
        fatalError("not implemented yet")
    }

    public func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        registeredNotificationCategories.formUnion(categories)
    }

    public func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestedAuthorizationOptions.insert(options)
        return true
    }

    @available(*, noasync)
    public func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, (any Error)?) -> Void) {
        requestedAuthorizationOptions.insert(options)
        completionHandler(true, nil)
    }

    public func add(_ request: UNNotificationRequest) async throws {
        scheduledRequests.append(request)
    }

    @available(*, noasync)
    public func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (((any Error)?) -> Void)?) {
        scheduledRequests.append(request)
    }

    public func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedNotifications.formUnion(identifiers)
    }

    public func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removedNotifications.formUnion(identifiers)
    }
}
