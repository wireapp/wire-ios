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
    let sync: PullPendingUpdateEventsSyncProtocol
    let apiVersion: WireAPI.APIVersion
    let userClientsLocalStore: UserClientsLocalStoreProtocol
    let userClientsAPI: UserClientsAPI
    var journal: JournalProtocol

    init(
        sync: PullPendingUpdateEventsSyncProtocol,
        userClientsAPI: UserClientsAPI,
        userClientsLocalStore: UserClientsLocalStoreProtocol,
        apiVersion: WireAPI.APIVersion,
        journal: JournalProtocol
    ) {
        self.sync = sync
        self.apiVersion = apiVersion
        self.userClientsLocalStore = userClientsLocalStore
        self.journal = journal
        self.userClientsAPI = userClientsAPI
    }

    public enum Failure: Error {
        case apiVersionTooLow
        case missingClient
        case missingClientID
    }

    public func migrateToAsyncStream() async throws {
        // 1) register asyncStream capabilities
        guard apiVersion >= .v8 else {
            throw Failure.apiVersionTooLow
        }

        if await !userClientsLocalStore.hasRegisteredAsyncStreamCapable() {
            try await registerAsyncStreamCapability()
        }

        // 2) pull pending events
        WireLogger.sync.debug("pull pending events before migration to async stream")
        try await sync.pull()

        // 3) we're done
        WireLogger.sync.debug("ready for async stream")
        journal[.isSyncV3Enabled] = true
    }

    private func registerAsyncStreamCapability() async throws {
        guard let id = await userClientsLocalStore.fetchSelfClientID() else {
            throw Failure.missingClientID
        }

        WireLogger.sync.debug("registering client with async stream capabilities")
        let payload: ClientUpdate = .init(
            capabilities: [.legalholdConsent, .consumableNotifications]
        )
        try await userClientsAPI.updateClient(id: id, payload: payload)
    }
}
