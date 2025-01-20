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
import NeedleFoundation

protocol NotificationSessionDependency: Dependency {
    var userLocalStore: UserLocalStoreProtocol { get }
    var updateEventsAPI: UpdateEventsAPI { get }
    var pushChannel: PushChannelProtocol { get }
    var updateEventsLocalStore: UpdateEventsLocalStoreProtocol { get }
    var updateEventsDecryptor: UpdateEventDecryptorProtocol { get }
    var backendEnvironmentProvider: BackendEnvironmentProvider { get }
}

/// Observes pending events, process them and generates new notifications content.
final class NotificationSession: Component<NotificationSessionDependency> {

    // MARK: - Failure
    
    enum Failure: Error {
        case unableToPullPendingEvents(Error)
        case missingSelfClientID
        case notAuthenticated
    }

    // MARK: - Properties

    private var updateEventsRepository: UpdateEventsRepositoryProtocol!
    private var subscription: AnyCancellable?
    
    // MARK: - Setup
    
    func setup(
        userID: UUID,
        onNotificationContent: @escaping (UNMutableNotificationContent) -> Void
    ) async throws {
        let userLocalStore = dependency.userLocalStore
        let selfUserInfo = await userLocalStore.selfUserInfo()
        let environment = dependency.backendEnvironmentProvider
        
        let cookieStorage = ZMPersistentCookieStorage(
            forServerName: environment.backendURL.host!,
            userIdentifier: userID,
            useCache: false
        )
        
        let isAuthenticated = cookieStorage.isAuthenticated

        guard isAuthenticated else {
            throw Failure.notAuthenticated
        }

        guard let selfClientID = selfUserInfo.clientId else {
            throw Failure.missingSelfClientID
        }
        
        let updateEventsRepository = UpdateEventsRepository(
            userID: userID,
            selfClientID: selfClientID,
            updateEventsAPI: dependency.updateEventsAPI,
            pushChannel: dependency.pushChannel,
            updateEventDecryptor: dependency.updateEventsDecryptor,
            updateEventsLocalStore: dependency.updateEventsLocalStore
        )
        
        self.updateEventsRepository = updateEventsRepository
        self.subscription = updateEventsRepository.observePendingEvents()
            .collect() // Collects all the events batches.
            .map { $0.flatMap { $0 } }
            .map(generateNotificationContent)
            .sink(receiveValue: onNotificationContent)
    }

    // MARK: - Notifications

    func processPushNotification(
        eventID newEventID: UUID
    ) async throws {
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
        // TODO: [WPB-11175] - Generate UNNotificationContent from update events
        for event in events {
            switch event {
            case let .conversation(conversationEvent):
                break
            case let .featureConfig(featureConfigEvent):
                break
            case let .federation(federationEvent):
                break
            case let .user(userEvent):
                break
            case let .team(teamEvent):
                break
            case let .unknown(eventType):
                break
            }
        }

        return UNMutableNotificationContent()
    }
}
