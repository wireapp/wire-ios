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

// MARK: - UserNotificationCenterWrapper

public struct UserNotificationCenterWrapper: UserNotificationCenterAbstraction {
    // MARK: Lifecycle

    public init(userNotificationCenter: UNUserNotificationCenter) {
        self.userNotificationCenter = userNotificationCenter
    }

    // MARK: Public

    public var delegate: UNUserNotificationCenterDelegate? {
        get { userNotificationCenter.delegate }
        set { userNotificationCenter.delegate = newValue }
    }

    public func notificationSettings() async -> UNNotificationSettings {
        await userNotificationCenter.notificationSettings()
    }

    @available(*, noasync)
    public func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void) {
        userNotificationCenter.getNotificationSettings(completionHandler: completionHandler)
    }

    public func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        userNotificationCenter.setNotificationCategories(categories)
    }

    public func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await userNotificationCenter.requestAuthorization(options: options)
    }

    @available(*, noasync)
    public func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping (Bool, (any Error)?) -> Void
    ) {
        userNotificationCenter.requestAuthorization(options: options, completionHandler: completionHandler)
    }

    public func add(_ request: UNNotificationRequest) async throws {
        try await userNotificationCenter.add(request)
    }

    @available(*, noasync)
    public func add(
        _ request: UNNotificationRequest,
        withCompletionHandler completionHandler: (((any Error)?) -> Void)?
    ) {
        userNotificationCenter.add(request, withCompletionHandler: completionHandler)
    }

    public func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        userNotificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    // MARK: Private

    private var userNotificationCenter: UNUserNotificationCenter
}

// MARK: - UserNotificationCenterAbstraction + wrapper(_:)

extension UserNotificationCenterAbstraction where Self == UserNotificationCenterWrapper {
    public static func wrapper(_ userNotificationCenter: UNUserNotificationCenter) -> Self {
        .init(userNotificationCenter: userNotificationCenter)
    }
}
