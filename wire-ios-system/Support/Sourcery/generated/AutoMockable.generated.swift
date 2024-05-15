// Generated using Sourcery 2.1.7 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif


@testable import WireUtilities





















public class MockUserNotificationCenterAbstraction: UserNotificationCenterAbstraction {

    // MARK: - Life cycle

    public init() {}

    // MARK: - delegate

    public var delegate: UNUserNotificationCenterDelegate?


    // MARK: - notificationSettings

    public var notificationSettings_Invocations: [Void] = []
    public var notificationSettings_MockMethod: (() async -> UNNotificationSettings)?
    public var notificationSettings_MockValue: UNNotificationSettings?

    public func notificationSettings() async -> UNNotificationSettings {
        notificationSettings_Invocations.append(())

        if let mock = notificationSettings_MockMethod {
            return await mock()
        } else if let mock = notificationSettings_MockValue {
            return mock
        } else {
            fatalError("no mock for `notificationSettings`")
        }
    }

    // MARK: - setNotificationCategories

    public var setNotificationCategories_Invocations: [Set<UNNotificationCategory>] = []
    public var setNotificationCategories_MockMethod: ((Set<UNNotificationCategory>) -> Void)?

    public func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        setNotificationCategories_Invocations.append(categories)

        guard let mock = setNotificationCategories_MockMethod else {
            fatalError("no mock for `setNotificationCategories`")
        }

        mock(categories)
    }

    // MARK: - requestAuthorization

    public var requestAuthorizationOptionsCompletionHandler_Invocations: [(options: UNAuthorizationOptions, completionHandler: (Bool, Error?) -> Void)] = []
    public var requestAuthorizationOptionsCompletionHandler_MockMethod: ((UNAuthorizationOptions, @escaping (Bool, Error?) -> Void) -> Void)?

    public func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationOptionsCompletionHandler_Invocations.append((options: options, completionHandler: completionHandler))

        guard let mock = requestAuthorizationOptionsCompletionHandler_MockMethod else {
            fatalError("no mock for `requestAuthorizationOptionsCompletionHandler`")
        }

        mock(options, completionHandler)
    }

    // MARK: - add

    public var addWithCompletionHandler_Invocations: [(request: UNNotificationRequest, withCompletionHandler: ((Error?) -> Void)?)] = []
    public var addWithCompletionHandler_MockMethod: ((UNNotificationRequest, ((Error?) -> Void)?) -> Void)?

    public func add(_ request: UNNotificationRequest, withCompletionHandler: ((Error?) -> Void)?) {
        addWithCompletionHandler_Invocations.append((request: request, withCompletionHandler: withCompletionHandler))

        guard let mock = addWithCompletionHandler_MockMethod else {
            fatalError("no mock for `addWithCompletionHandler`")
        }

        mock(request, withCompletionHandler)
    }

    // MARK: - removePendingNotificationRequests

    public var removePendingNotificationRequestsWithIdentifiers_Invocations: [[String]] = []
    public var removePendingNotificationRequestsWithIdentifiers_MockMethod: (([String]) -> Void)?

    public func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removePendingNotificationRequestsWithIdentifiers_Invocations.append(identifiers)

        guard let mock = removePendingNotificationRequestsWithIdentifiers_MockMethod else {
            fatalError("no mock for `removePendingNotificationRequestsWithIdentifiers`")
        }

        mock(identifiers)
    }

    // MARK: - removeDeliveredNotifications

    public var removeDeliveredNotificationsWithIdentifiers_Invocations: [[String]] = []
    public var removeDeliveredNotificationsWithIdentifiers_MockMethod: (([String]) -> Void)?

    public func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removeDeliveredNotificationsWithIdentifiers_Invocations.append(identifiers)

        guard let mock = removeDeliveredNotificationsWithIdentifiers_MockMethod else {
            fatalError("no mock for `removeDeliveredNotificationsWithIdentifiers`")
        }

        mock(identifiers)
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
