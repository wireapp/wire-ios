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
import WireDataModel
import WireLogging

// sourcery: AutoMockable
protocol PullEventsServiceProtocol {
    func startSync(
        newEventID id: UUID
    ) async throws
}

struct PullEventsService: PullEventsServiceProtocol {
    private let coreData: CoreDataStack
    private let userClientsLocalStore: any UserClientsLocalStoreProtocol
    private let updateEventsLocalStore: any UpdateEventsLocalStoreProtocol
    private let eventsSync: any PullUpdateEventsSyncProtocol
    private let generateNotificationProvider: any GenerateNotificationProvider

    enum Failure: Error {
        case unableToLoadStores(Error)
        case unableToPullPendingEvents(Error)
    }

    init(
        coreData: CoreDataStack,
        userClientsLocalStore: any UserClientsLocalStoreProtocol,
        updateEventsLocalStore: any UpdateEventsLocalStoreProtocol,
        eventsSync: any PullUpdateEventsSyncProtocol,
        generateNotificationProvider: any GenerateNotificationProvider
    ) {
        self.coreData = coreData
        self.userClientsLocalStore = userClientsLocalStore
        self.updateEventsLocalStore = updateEventsLocalStore
        self.eventsSync = eventsSync
        self.generateNotificationProvider = generateNotificationProvider
    }

    /// Starts syncing events with backend.
    /// - parameter newEventID: The notification event id.
    func startSync(
        newEventID id: UUID
    ) async throws {
        try setup()
        
        let selfClientID = await userClientsLocalStore.fetchSelfClientID()
        let lastEventID = updateEventsLocalStore.lastEventID()

        if lastEventID == nil {
            updateEventsLocalStore.storeLastEventID(id: id)
        }

        do {
            let decodedEventsStream = try await eventsSync.pull()
            
            let generateNotificationService = generateNotificationProvider.generateNotificationService(
                eventsStream: decodedEventsStream
            )
            
            await generateNotificationService.process()
            
        } catch {
            throw Failure.unableToPullPendingEvents(error)
        }
    }
    
    /// Setup core data stores and its dependencies.
    private func setup() throws {
        var loadStoresError: Error?

        coreData.loadStores { error in
            loadStoresError = error
        }

        if let loadStoresError {
            throw Failure.unableToLoadStores(loadStoresError)
        }
    }

}
