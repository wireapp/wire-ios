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
protocol LoggedInSessionProtocol {
    func setup() throws

    func startSync(
        newEventID id: UUID
    ) async throws -> AsyncStream<[UpdateEvent]>
}

struct LoggedInSession: LoggedInSessionProtocol {
    private let coreDataProvider: any CoreDataProvider
    private let coreServiceProvider: any CoreServiceProvider
    private let localStoresProvider: any UserClientsLocalStoreProvider & UpdateEventsLocalStoreProvider
    private let pullEventsSyncProvider: any PullEventsSyncProvider

    enum Failure: Error {
        case unableToLoadStores(Error)
        case unableToPullPendingEvents(Error)
    }

    init(
        coreDataProvider: any CoreDataProvider,
        coreServiceProvider: any CoreServiceProvider,
        localStoresProvider: any UserClientsLocalStoreProvider & UpdateEventsLocalStoreProvider,
        pullEventsSyncProvider: any PullEventsSyncProvider
    ) {
        self.coreDataProvider = coreDataProvider
        self.coreServiceProvider = coreServiceProvider
        self.localStoresProvider = localStoresProvider
        self.pullEventsSyncProvider = pullEventsSyncProvider
    }

    /// Setup core data stores and its dependencies.
    func setup() throws {
        let coreData = coreDataProvider.coreData
        let proteusService = coreServiceProvider.proteusService
        let featureRepository = coreServiceProvider.featureRepository
        let mlsDecryptionService = coreServiceProvider.mlsDecryptionService

        var loadStoresError: Error?

        coreData.loadStores { error in
            loadStoresError = error
        }

        if let loadStoresError {
            throw Failure.unableToLoadStores(loadStoresError)
        }
    }

    /// Starts syncing events with backend.
    /// - parameter newEventID: The notification event id.
    /// - returns: A stream of decrypted update events.
    func startSync(
        newEventID id: UUID
    ) async throws -> AsyncStream<[UpdateEvent]> {
        let userClientsLocalStore = localStoresProvider.userClientsLocalStore
        let selfClientID = await userClientsLocalStore.fetchSelfClientID()

        let eventsSync = await pullEventsSyncProvider.pullEventsSync(
            selfClientID: selfClientID.uuidString
        )

        let updateEventsLocalStore = localStoresProvider.updateEventsLocalStore
        let lastEventID = updateEventsLocalStore.lastEventID()

        if lastEventID == nil {
            updateEventsLocalStore.storeLastEventID(id: id)
        }

        do {
            return try await eventsSync.pull()
        } catch {
            throw Failure.unableToPullPendingEvents(error)
        }
    }

}
