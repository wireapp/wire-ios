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

import Foundation
import WireDataModel
import WireNetwork

public struct UserClientsRepository: UserClientsRepositoryProtocol {

    // MARK: - Properties

    private let userClientsAPI: any UserClientsAPI
    private let userRepository: any UserRepositoryProtocol
    private let userClientsLocalStore: any UserClientsLocalStoreProtocol

    // MARK: - Object lifecycle

    init(
        userClientsAPI: any UserClientsAPI,
        userRepository: any UserRepositoryProtocol,
        userClientsLocalStore: any UserClientsLocalStoreProtocol
    ) {
        self.userClientsAPI = userClientsAPI
        self.userRepository = userRepository
        self.userClientsLocalStore = userClientsLocalStore
    }

    // MARK: - Public

    public func fetchSelfClient() async -> WireDataModel.UserClient? {
        await userClientsLocalStore.fetchSelfClient()
    }

    public func fetchClient(
        id: String,
        forUser user: ZMUser,
        createIfNeeded: Bool
    ) async -> UserClient? {
        await userClientsLocalStore.fetchClient(
            id: id,
            forUser: user,
            createIfNeeded: createIfNeeded
        )
    }

    public func fetchOrCreateClient(
        id: String
    ) async -> (client: WireDataModel.UserClient, isNew: Bool) {
        await userClientsLocalStore.fetchOrCreateClient(
            id: id
        )
    }

    public func deleteClient(
        id: String
    ) async {
        await userClientsLocalStore.deleteClient(id: id)
    }

    public func invalidateSelfClient() async {
        await userClientsLocalStore.invalidateSelfClient()
    }

    public func pullSelfClients() async throws {
        let remoteSelfClients = try await userClientsAPI.getSelfClients()

        for remoteSelfClient in remoteSelfClients {
            let localUserClient = await userClientsLocalStore.fetchOrCreateClient(
                id: remoteSelfClient.id
            )

            await updateClient(
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

    public func updateClient(
        id: String,
        from remoteClient: WireNetwork.SelfUserClient,
        isNewClient: Bool
    ) async {
        await userClientsLocalStore.updateClient(
            id: id,
            isNewClient: isNewClient,
            userClientInfo: remoteClient.toDomainModel()
        )
    }

    public func allSelfUserClientsAreActiveMLSClients() async -> Bool {
        await userClientsLocalStore.allSelfUserClientsAreActiveMLSClients()
    }

}
