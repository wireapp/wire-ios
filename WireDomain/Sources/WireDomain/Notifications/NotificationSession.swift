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

/// Observes pending events, process them and generates new notifications content.
final class NotificationSession {

    // MARK: - Failure

    enum Failure: Error {
        case unableToPullPendingEvents(Error)
    }

    // MARK: - Properties

    private let updateEventsRepository: any UpdateEventsRepositoryProtocol
    private var subscription: AnyCancellable?

    // MARK: - Object lifecycle

    init(
        updateEventsRepository: any UpdateEventsRepositoryProtocol,
        onNotificationContent: @escaping (UNMutableNotificationContent) -> Void
    ) {
        self.updateEventsRepository = updateEventsRepository
        self.subscription = updateEventsRepository.observePendingEvents()
            .collect() // Collects all the events batches.
            .map { $0.flatMap { $0 } }
            .map { events in
                // Uses a Future to bridge between Combine and async/await
                Future<UNMutableNotificationContent, Never> { [self] promise in
                    Task {
                        let notification = await generateNotificationContent(for: events)
                        promise(.success(notification))
                    }
                }
            }
            .switchToLatest()
            .sink(receiveValue: onNotificationContent)
    }

    deinit {
        subscription?.cancel()
        subscription = nil
    }

    // MARK: - Notifications

    func processPushNotification(
        eventID: UUID
    ) async throws {
        let newEventID = eventID
        let lastEventId = updateEventsRepository.fetchLastEventEnvelopeID()

        if lastEventId == nil {
            updateEventsRepository.storeLastEventEnvelopeID(newEventID)
        }

        do {
            try await updateEventsRepository.pullPendingEvents()
        } catch {
            throw Failure.unableToPullPendingEvents(error)
        }
    }

    private func generateNotificationContent(
        for events: [UpdateEvent]
    ) async -> UNMutableNotificationContent {

        var notifications: [UNMutableNotificationContent] = []

        for event in events {
            var notificationBuilder: NotificationBuilder

            switch event {
            case let .conversation(conversationEvent):
                notificationBuilder = await ConversationNotificationBuilder(
                    event: conversationEvent
                )
            // TODO: [WPB-10218] - Generate notif for other update events
            case let .featureConfig(featureConfigEvent):
                continue
            case let .federation(federationEvent):
                continue
            case let .user(userEvent):
                continue
            case let .team(teamEvent):
                continue
            case let .unknown(eventType):
                continue
            }

            guard await notificationBuilder.shouldBuildNotification() else {
                continue
            }

            let notificationContent = await notificationBuilder.buildContent()
            notifications.append(notificationContent)
        }

        var notification = UNMutableNotificationContent()

        if notifications.count > 1 {
            let body = NotificationBody.bundled(messagesCount: notifications.count)
            notification.body = body.make()
        } else if let singleNotification = notifications.first {
            notification = singleNotification
        }

        return notification
    }
}
