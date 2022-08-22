//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireTransport

@available(iOS 15, *)
final class Job: NSObject {

    // MARK: - Types

    enum InitializationError: Error {

        case invalidEnvironment

    }

    typealias PushPayload = (userID: UUID, eventID: UUID)

    // MARK: - Properties

    private let request: UNNotificationRequest
    private let userID: UUID
    private let eventID: UUID

    private let environment: BackendEnvironmentProvider = BackendEnvironment.shared
    private let networkSession: NetworkSession
    private let accessAPIClient: AccessAPIClient

    // MARK: - Life cycle

    init(request: UNNotificationRequest) throws {
        log("\(request.identifier): initializing session")
        self.request = request
        (userID, eventID) = try Self.pushPayload(from: request)
        networkSession = try NetworkSession(userID: userID)
        accessAPIClient = AccessAPIClient(networkSession: networkSession)
        super.init()
    }

    // MARK: - Methods

    func execute() async throws -> UNNotificationContent {
        log("\(request.identifier): executing request")
        log("\(request.identifier): request is for user (\(userID)) and event (\(eventID)")

        guard isUserAuthenticated else {
            throw NotificationServiceError.userNotAuthenticated
        }

        log("\(request.identifier): user (\(userID)) is authenticated")

        networkSession.accessToken = try await fetchAccessToken()

        log("\(request.identifier): fetching event with id: \(eventID)")

        guard let event = try fetchEvent(eventID: eventID) else {
            throw NotificationServiceError.noEvent
        }

        // Is new message? Which conv? Should show it? Show it.

        // Is call message? Which conv? Should show it? Incoming or ended?

        // Convert to notification

        // Return content
        throw NotificationServiceError.notImplemented("returning content")
    }

    private class func pushPayload(from request: UNNotificationRequest) throws -> PushPayload {
        guard
            let notificationData = request.content.userInfo["data"] as? [String: Any],
            let userIDString = notificationData["user"] as? String,
            let userID = UUID(uuidString: userIDString),
            let data = notificationData["data"] as? [String: Any],
            let eventIDString = data["id"] as? String,
            let eventID = UUID(uuidString: eventIDString)
        else {
            throw NotificationServiceError.malformedPushPayload
        }

        return (userID, eventID)
    }

    private var isUserAuthenticated: Bool {
        return networkSession.isAuthenticated
    }

    private func fetchAccessToken() async throws -> AccessToken {
        log("\(request.identifier): fetching access token")
        return try await accessAPIClient.fetchAccessToken()
    }

    private func fetchEvent(eventID: UUID) throws -> ZMUpdateEvent? {
        // Fetch the event.
        // Parse the response.
        throw NotificationServiceError.notImplemented("fetching events")
    }

}
