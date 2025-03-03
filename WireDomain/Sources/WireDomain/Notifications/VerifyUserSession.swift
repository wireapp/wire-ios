//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAPI
import WireCrypto
import WireDataModel
import WireFoundation
import WireLogging

/// Observes pending events, process them and generates new notifications content.
struct VerifyUserSession {

    enum Constants {
        static let cookieName = "zuid"
    }

    // MARK: - Error

    enum Failure: Error {
        case userUnauthenticated
        case missingUserClient
    }

    // MARK: - Properties

    typealias NotificationHandler = (UNMutableNotificationContent) -> Void

    private let pullEventsServiceProvider: any PullEventsServiceProvider
    private let userLocalStore: any UserLocalStoreProtocol
    private let cookieStorage: any CookieStorageProtocol

    init(
        pullEventsServiceProvider: any PullEventsServiceProvider,
        userLocalStore: any UserLocalStoreProtocol,
        cookieStorage: any CookieStorageProtocol
    ) {
        self.pullEventsServiceProvider = pullEventsServiceProvider
        self.userLocalStore = userLocalStore
        self.cookieStorage = cookieStorage
    }

    /// Ensures user is properly authenticated.
    /// - parameters
    ///     - userID: The user ID to verify the authentication for.
    ///     - handler: Completion block called if the user is authenticated.

    func verify(
        userID: UUID,
        then completion: () async throws -> Void
    ) async throws {
        let cookies = try await cookieStorage.fetchCookies()
        var hasExpirationDate = false

        for cookie in cookies where cookie.name == Constants.cookieName {
            hasExpirationDate = cookie.expiresDate != nil
        }

        guard hasExpirationDate else {
            throw Failure.userUnauthenticated
        }

        try await completion()
    }

    /// Start syncing events.
    /// - parameter eventID: The id to start fetching the events from remotely.

    func startSyncingEvents(
        eventID: UUID
    ) async throws {
        let selfUserInfo = await userLocalStore.selfUserInfo()

        guard let selfClientID = selfUserInfo.clientId else {
            throw Failure.missingUserClient
        }

        let pullEventsService = await pullEventsServiceProvider.pullEventsService(
            selfUserID: selfUserInfo.id,
            selfClientID: selfClientID
        )

        try await pullEventsService.startSync(
            newEventID: eventID
        )
    }
}
