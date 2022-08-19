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
import WireCommonComponents

func log(_ message: String) {
    print(message)
}

final class SimpleNotificationService: UNNotificationServiceExtension {

    // MARK: - Types

    typealias PushPayload = (userID: UUID, eventID: UUID)
    typealias ContentHandler = (UNNotificationContent) -> Void

    // MARK: - Properties

    private let environment: BackendEnvironmentProvider = BackendEnvironment.shared

    // MARK: - Life cycle

    override init() {
        super.init()
    }

    // MARK: - Methods

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping ContentHandler
    ) {
        do {
            log("\(request.identifier): received request")
            let content = try execute(request: request)
            log("\(request.identifier): showing notification")
            contentHandler(content)
        } catch {
            let message = "\(request.identifier): failed with error: \(String(describing: error))"
            log(message)
            contentHandler(.debugMessageIfNeeded(message: message))
        }
    }

    func execute(request: UNNotificationRequest) throws -> UNNotificationContent {
        log("\(request.identifier): executing request")

        let (userID, eventID) = try pushPayload(from: request)

        log("\(request.identifier): request is for user (\(userID)) and event (\(eventID)")

        guard isUserAuthenticated(userID: userID) else {
            throw NotificationServiceError.userNotAuthenticated
        }

        log("\(request.identifier): user (\(userID)) is authenticated")
        log("\(request.identifier): fetching event with id: \(eventID)")

        guard let event = fetchEvent(eventID: eventID) else {
            throw NotificationServiceError.noEvent
        }

        // Is new message? Which conv? Should show it? Show it.

        // Is call message? Which conv? Should show it? Incoming or ended?

        // Convert to notification

        // Return content
        fatalError("not implemented")
    }

    private func pushPayload(from request: UNNotificationRequest) throws -> PushPayload {
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

    private func isUserAuthenticated(userID: UUID) -> Bool {
        guard let serverName = environment.backendURL.host else {
            return false
        }

        let cookieStorage = ZMPersistentCookieStorage(
            forServerName: serverName,
            userIdentifier: userID
        )

        return cookieStorage.isAuthenticated
    }

    private func fetchEvent(eventID: UUID) -> ZMUpdateEvent? {
        // Get an access token.
        // Fetch the event.
        // Parse the response.

        fatalError("not implemented")
    }

    override func serviceExtensionTimeWillExpire() {
        log("extension (\(self) is expiring")
        fatalError("not implemented")
    }

}
