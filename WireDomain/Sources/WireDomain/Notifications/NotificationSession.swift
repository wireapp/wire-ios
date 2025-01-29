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

import Combine
import WireAPI
import WireDataModel
import WireLogging

/// Observes pending events, process them and generates new notifications content.
final class NotificationSession {

    // MARK: - Properties

    typealias NotificationHandler = (UNMutableNotificationContent) -> Void

    private let authenticationServiceProvider: AuthenticationServiceProvider
    private let notificationHandler: NotificationHandler
    private let eventID: UUID
    private var subscription: AnyCancellable?

    // MARK: - Object lifecycle

    init(
        eventID: UUID,
        authenticationServiceProvider: any AuthenticationServiceProvider,
        notificationHandler: @escaping NotificationHandler
    ) {
        self.eventID = eventID
        self.authenticationServiceProvider = authenticationServiceProvider
        self.notificationHandler = notificationHandler
    }

    deinit {
        subscription?.cancel()
        subscription = nil
    }

    // MARK: - Notifications

    func start() async throws {
        let authenticationService = authenticationServiceProvider.authenticationService
        let authenticatedSession = try await authenticationService.authenticated()
        try await process(with: authenticatedSession)
    }

    private func process(
        with authenticatedSession: AuthenticatedSessionProtocol
    ) async throws {
        try authenticatedSession.setup()

        let decodedEventsStream = try await authenticatedSession.startSync(
            newEventID: eventID
        )

        for await decodedEvents in decodedEventsStream {
            generateNotificationContent(for: decodedEvents)
        }
    }

    private func generateNotificationContent(
        for events: [UpdateEvent]
    ) {
        guard !events.isEmpty else {
            return notificationHandler(UNMutableNotificationContent())
        }
        // TODO: [WPB-11175] - Generate UNNotificationContent from update events
        for event in events {
            let notification = switch event {
            case let .conversation(conversationEvent):
                UNMutableNotificationContent()
            case let .featureConfig(featureConfigEvent):
                UNMutableNotificationContent()
            case let .federation(federationEvent):
                UNMutableNotificationContent()
            case let .user(userEvent):
                UNMutableNotificationContent()
            case let .team(teamEvent):
                UNMutableNotificationContent()
            case let .unknown(eventType):
                UNMutableNotificationContent()
            }

            notificationHandler(notification)
        }
    }
}
