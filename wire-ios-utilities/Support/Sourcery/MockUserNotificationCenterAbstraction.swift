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
import WireUtilities

// TODO: [WPB-9200]: remove this file as soon as Sourcery correctly generates existential any for `requestAuthorizationCompletionHandler_Invocations`.

public class MockUserNotificationCenterAbstraction: UserNotificationCenterAbstraction {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    // MARK: - delegate

    public var delegate: UNUserNotificationCenterDelegate?

    // MARK: - notificationSettings

    public var notificationSettings_Invocations: [Void] = []
    public var notificationSettings_MockMethod: (() async -> UNNotificationSettings)?
    public var notificationSettings_MockValue: UNNotificationSettings?

    // MARK: - getNotificationSettings

    public var getNotificationSettingsCompletionHandler_Invocations: [(UNNotificationSettings) -> Void] = []
    public var getNotificationSettingsCompletionHandler_MockMethod: (
        (@escaping (UNNotificationSettings) -> Void)
            -> Void
    )?

    // MARK: - setNotificationCategories

    public var setNotificationCategories_Invocations: [Set<UNNotificationCategory>] = []
    public var setNotificationCategories_MockMethod: ((Set<UNNotificationCategory>) -> Void)?

    // MARK: - requestAuthorization

    public var requestAuthorizationOptions_Invocations: [UNAuthorizationOptions] = []
    public var requestAuthorizationOptions_MockError: Error?
    public var requestAuthorizationOptions_MockMethod: ((UNAuthorizationOptions) async throws -> Bool)?
    public var requestAuthorizationOptions_MockValue: Bool?

    // MARK: - requestAuthorization

    public var requestAuthorization_Invocations: [Void] = []
    public var requestAuthorization_MockError: Error?
    public var requestAuthorization_MockMethod: (() async throws -> Bool)?
    public var requestAuthorization_MockValue: Bool?

    // MARK: - requestAuthorization

    public var requestAuthorizationCompletionHandler_Invocations: [(Bool, (any Error)?) -> Void] = []
    public var requestAuthorizationCompletionHandler_MockMethod: ((@escaping (Bool, (any Error)?) -> Void) -> Void)?

    // MARK: - requestAuthorization

    public var requestAuthorizationOptionsCompletionHandler_Invocations: [(
        options: UNAuthorizationOptions,
        completionHandler: (Bool, (any Error)?) -> Void
    )] = []
    public var requestAuthorizationOptionsCompletionHandler_MockMethod: ((
        UNAuthorizationOptions,
        @escaping (Bool, (any Error)?) -> Void
    ) -> Void)?

    // MARK: - add

    public var add_Invocations: [UNNotificationRequest] = []
    public var add_MockError: Error?
    public var add_MockMethod: ((UNNotificationRequest) async throws -> Void)?

    // MARK: - add

    public var addWithCompletionHandler_Invocations: [(
        request: UNNotificationRequest,
        completionHandler: (((any Error)?) -> Void)?
    )] = []
    public var addWithCompletionHandler_MockMethod: ((UNNotificationRequest, (((any Error)?) -> Void)?) -> Void)?

    // MARK: - removePendingNotificationRequests

    public var removePendingNotificationRequestsWithIdentifiers_Invocations: [[String]] = []
    public var removePendingNotificationRequestsWithIdentifiers_MockMethod: (([String]) -> Void)?

    // MARK: - removeDeliveredNotifications

    public var removeDeliveredNotificationsWithIdentifiers_Invocations: [[String]] = []
    public var removeDeliveredNotificationsWithIdentifiers_MockMethod: (([String]) -> Void)?

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

    @available(*, noasync)
    public func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void) {
        getNotificationSettingsCompletionHandler_Invocations.append(completionHandler)

        guard let mock = getNotificationSettingsCompletionHandler_MockMethod else {
            fatalError("no mock for `getNotificationSettingsCompletionHandler`")
        }

        mock(completionHandler)
    }

    public func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        setNotificationCategories_Invocations.append(categories)

        guard let mock = setNotificationCategories_MockMethod else {
            fatalError("no mock for `setNotificationCategories`")
        }

        mock(categories)
    }

    public func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestAuthorizationOptions_Invocations.append(options)

        if let error = requestAuthorizationOptions_MockError {
            throw error
        }

        if let mock = requestAuthorizationOptions_MockMethod {
            return try await mock(options)
        } else if let mock = requestAuthorizationOptions_MockValue {
            return mock
        } else {
            fatalError("no mock for `requestAuthorizationOptions`")
        }
    }

    public func requestAuthorization() async throws -> Bool {
        requestAuthorization_Invocations.append(())

        if let error = requestAuthorization_MockError {
            throw error
        }

        if let mock = requestAuthorization_MockMethod {
            return try await mock()
        } else if let mock = requestAuthorization_MockValue {
            return mock
        } else {
            fatalError("no mock for `requestAuthorization`")
        }
    }

    @available(*, noasync)
    public func requestAuthorization(completionHandler: @escaping (Bool, (any Error)?) -> Void) {
        requestAuthorizationCompletionHandler_Invocations.append(completionHandler)

        guard let mock = requestAuthorizationCompletionHandler_MockMethod else {
            fatalError("no mock for `requestAuthorizationCompletionHandler`")
        }

        mock(completionHandler)
    }

    @available(*, noasync)
    public func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping (Bool, (any Error)?) -> Void
    ) {
        requestAuthorizationOptionsCompletionHandler_Invocations.append((
            options: options,
            completionHandler: completionHandler
        ))

        guard let mock = requestAuthorizationOptionsCompletionHandler_MockMethod else {
            fatalError("no mock for `requestAuthorizationOptionsCompletionHandler`")
        }

        mock(options, completionHandler)
    }

    public func add(_ request: UNNotificationRequest) async throws {
        add_Invocations.append(request)

        if let error = add_MockError {
            throw error
        }

        guard let mock = add_MockMethod else {
            fatalError("no mock for `add`")
        }

        try await mock(request)
    }

    @available(*, noasync)
    public func add(
        _ request: UNNotificationRequest,
        withCompletionHandler completionHandler: (((any Error)?) -> Void)?
    ) {
        addWithCompletionHandler_Invocations.append((request: request, completionHandler: completionHandler))

        guard let mock = addWithCompletionHandler_MockMethod else {
            fatalError("no mock for `addWithCompletionHandler`")
        }

        mock(request, completionHandler)
    }

    public func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removePendingNotificationRequestsWithIdentifiers_Invocations.append(identifiers)

        guard let mock = removePendingNotificationRequestsWithIdentifiers_MockMethod else {
            fatalError("no mock for `removePendingNotificationRequestsWithIdentifiers`")
        }

        mock(identifiers)
    }

    public func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removeDeliveredNotificationsWithIdentifiers_Invocations.append(identifiers)

        guard let mock = removeDeliveredNotificationsWithIdentifiers_MockMethod else {
            fatalError("no mock for `removeDeliveredNotificationsWithIdentifiers`")
        }

        mock(identifiers)
    }
}
