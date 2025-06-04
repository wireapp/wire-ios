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

protocol AsyncStreamMigratorProtocol {
    func migrateToAsyncStream() async throws
}


public final class AsyncStreamMigrator: AsyncStreamMigratorProtocol {
    let sync: PullPendingUpdateEventsSync
    let apiVersion: WireAPI.APIVersion
    let userClientsLocalStore: UserClientsLocalStore
    var journal: JournalProtocol
    let api: UserClientsAPI

    init(sync: PullPendingUpdateEventsSync,
         api: UserClientsAPI,
         apiVersion: WireAPI.APIVersion,
         userClientsLocalStore: UserClientsLocalStore,
         journal: JournalProtocol) {
        self.sync = sync
        self.apiVersion = apiVersion
        self.userClientsLocalStore = userClientsLocalStore
        self.journal = journal
        self.api = api
    }
    
    enum Failure: Error
    {
        case apiVersionTooLow
        case missingClient
        case missingClientID
    }
    
    public func migrateToAsyncStream() async throws {
        
        // 1) register asyncStream capabilities
        guard apiVersion >= .v8 else {
            throw Failure.apiVersionTooLow
        }
        
        if await !userClientsLocalStore.isClientAsyncStreamCapable() {
            try await registerAsyncStreamCapability()
        }

        // 2) do an initial sync
        WireLogger.sync.debug("do initial sync")
        try await sync.pull()

        // 3) we're done
        WireLogger.sync.debug("ready for sync v3")
        journal[.isSyncV3Enabled] = true
    }
    
    private func registerAsyncStreamCapability() async throws {
        let id = await userClientsLocalStore.fetchSelfClientID()
        
        WireLogger.sync.debug("registering client with async stream capabilities")
        let payload: UpdateClientPayload = .init(
            capabilities: [.consumableNotifications])
        try await api.updateClient(id: id.uuidString, payload: payload)
    }
}
