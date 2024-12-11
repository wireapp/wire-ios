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

final class NotificationSession {
    
    // MARK: - Failure
    
    enum Failure: Error {
        case unableToPullPendingEvents(Error)
    }
    
    // MARK: - Properties
    
    private let updateEventsRepository: any UpdateEventsRepositoryProtocol
    private let userID: UUID
    private var subscription: AnyCancellable?
    
    // MARK: - Object lifecycle
    
    init(
        userID: UUID,
        updateEventsRepository: any UpdateEventsRepositoryProtocol
    ) {
        self.updateEventsRepository = updateEventsRepository
        self.userID = userID
        
        // Generate notification for current pending events as we receive them.
        subscription = updateEventsRepository.observePendingEvents()
            .sink { [weak self] updateEvents in
                self?.generateNotification(for: updateEvents)
            }
    }
    
    deinit {
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
    
    private func generateNotification(for events: [UpdateEvent]) {
        // TODO: [WPB-11175] - Generate UNNotificationContent from update events
        for event in events {
            switch event {
            case .conversation(let conversationEvent):
                break
            case .featureConfig(let featureConfigEvent):
                break
            case .federation(let federationEvent):
                break
            case .user(let userEvent):
                break
            case .team(let teamEvent):
                break
            case .unknown(let eventType):
                break
            }
        }
    }
}
