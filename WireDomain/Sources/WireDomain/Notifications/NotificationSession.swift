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

import WireAPI
import WireDataModel
import Combine

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
            .map(generateNotificationContent)
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
    ) -> UNMutableNotificationContent {
        
        for event in events {
            let builder = makeBuilder(for: event)
            
            guard builder.shouldBuildNotification() else {
                fatalError() // TODO: Implement me
            }
            
            return builder.build()
        }
        
        return UNMutableNotificationContent()
    }
    
    private func makeBuilder(for event: UpdateEvent) -> NotificationBuilder {
        switch event {
        case .conversation(let conversationEvent):
            let conversationNotificationBuilder = ConversationNotificationBuilder(
                event: conversationEvent
            )
            
            return conversationNotificationBuilder
        case .featureConfig(let featureConfigEvent):
            fatalError()
        case .federation(let federationEvent):
            fatalError()
        case .user(let userEvent):
            fatalError()
        case .team(let teamEvent):
            fatalError()
        case .unknown(let eventType):
            fatalError()
        }
    }
}
