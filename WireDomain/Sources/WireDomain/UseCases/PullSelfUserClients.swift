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
import CoreData

public struct PullSelfUserClients {
    private let userClientsAPI: any UserClientsAPI
    private let userClientsLocalStore: any UserClientsLocalStoreProtocol

    public func pullSelfClients() async throws {
        let remoteSelfClients = try await userClientsAPI.getSelfClients()

        for remoteSelfClient in remoteSelfClients {
            let localUserClient = await userClientsLocalStore.fetchOrCreateClient(
                id: remoteSelfClient.id
            )

            try await updateClient(
                id: remoteSelfClient.id,
                from: remoteSelfClient,
                isNewClient: localUserClient.isNew
            )
        }

        let deletedSelfClientsIDs = await userClientsLocalStore.deletedSelfClients(
            newClients: remoteSelfClients.map(\.id)
        )

        for deletedSelfClientID in deletedSelfClientsIDs {
            await userClientsLocalStore.deleteClient(id: deletedSelfClientID)
        }
    }
    
    
    func updateClient(
        id: String,
        from remoteClient: WireAPI.SelfUserClient,
        isNewClient: Bool
    ) async throws {
        await userClientsLocalStore.updateClient(
            id: id,
            isNewClient: isNewClient,
            userClientInfo: remoteClient.toDomainModel()
        )
    }

    
}

public extension PullSelfUserClients {
    
    static func make(apiService: any APIServiceProtocol,
                            apiVersion: WireAPI.APIVersion,
                            context: NSManagedObjectContext) -> PullSelfUserClients {
        let userClientsAPI = UserClientsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
        
        let userLocalStore = UserLocalStore(context: context)
        let userClientsLocalStore = UserClientsLocalStore(context: context, userLocalStore: userLocalStore)
        
        return PullSelfUserClients(userClientsAPI: userClientsAPI, userClientsLocalStore: userClientsLocalStore)
    }
}
