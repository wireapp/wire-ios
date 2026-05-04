//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import CoreData
import WireNetwork

public struct PullSelfUserClientsSync: PullSelfUserClientsSyncProtocol {

    private let api: any UserClientsAPI
    private let store: any UserClientsLocalStoreProtocol

    public init(
        api: any UserClientsAPI,
        store: any UserClientsLocalStoreProtocol
    ) {
        self.api = api
        self.store = store
    }

    public func pull() async throws {
        let remoteSelfClients = try await api.getSelfClients()

        for remoteSelfClient in remoteSelfClients {
            let localUserClient = await store.fetchOrCreateClient(
                id: remoteSelfClient.id
            )

            try await updateClient(
                id: remoteSelfClient.id,
                from: remoteSelfClient,
                isNewClient: localUserClient.isNew
            )
        }

        let deletedSelfClientsIDs = await store.deletedSelfClients(
            newClients: remoteSelfClients.map(\.id)
        )

        for deletedSelfClientID in deletedSelfClientsIDs {
            await store.deleteClient(id: deletedSelfClientID)
        }
    }

    func updateClient(
        id: String,
        from remoteClient: WireNetwork.SelfUserClient,
        isNewClient: Bool
    ) async throws {
        await store.updateClient(
            id: id,
            isNewClient: isNewClient,
            userClientInfo: remoteClient.toDomainModel()
        )
    }

}
