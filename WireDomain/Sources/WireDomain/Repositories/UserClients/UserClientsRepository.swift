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

import Foundation
import WireAPI
import WireDataModel

// sourcery: AutoMockable
/// Facilitate access to user clients related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol UserClientsRepositoryProtocol {

    /// Fetches self client locally.
    /// - returns: The self client if any

    func fetchSelfClient() async -> WireDataModel.UserClient?

    /// Pulls and stores self user clients locally.
    /// Deletes no longer relevant clients locally.
    /// - returns : A self user clients list.

    func pullSelfClients() async throws

    /// Fetches or creates a client locally.
    ///
    /// - parameters:
    ///     - id: The user client id to find or create locally.
    /// - returns: The user client found or created locally and a flag indicating whether or not the user client is new.

    func fetchOrCreateClient(
        id: String
    ) async throws -> (client: WireDataModel.UserClient, isNew: Bool)

    /// Updates the user client informations locally.
    ///
    /// - parameters:
    ///     - id: The user client id.
    ///     - remoteClient: The up-to-date remote user client.
    ///     - isNewClient: A flag indicating whether the user client is new.

    func updateClient(
        id: String,
        from remoteClient: WireAPI.SelfUserClient,
        isNewClient: Bool
    ) async throws

    /// Deletes client locally.
    /// - parameter id: The client id.

    func deleteClient(id: String) async

    /// Indicates whether self user clients are active MLS clients.
    /// - returns: A flag indicating whether all self user clients are active MLS clients.

    func allSelfUserClientsAreActiveMLSClients() async -> Bool

    /// Stores user client discovery date locally.
    /// - Parameters:
    ///     - discoveryDate: The date the client was discovered.
    ///     - The client to update the discovery date for.

    func storeClient(
        discoveryDate: Date,
        client: WireDataModel.UserClient
    ) async

    /// Adds new client to the ignored ones.
    /// - Parameters:
    ///     - selfClient: The self user client to add the new client for.
    ///     - newClient: The new user client.

    func addNewClientToIgnored(
        selfClient: WireDataModel.UserClient,
        newClient: WireDataModel.UserClient
    ) async

    /// Fetches the Proteus session ID of a given client.
    /// - parameter client: The client to get the Proteus session ID for.
    /// - returns: The Proteus session id.

    func proteusSessionID(
        for client: WireDataModel.UserClient
    ) async -> ProteusSessionID?

    /// Indicates a client session was created.
    /// - Parameters:
    ///     - selfClient: The self user client.
    ///     - newClient: The new client that was created.

    func clientSessionCreated(
        selfClient: WireDataModel.UserClient,
        newClient: WireDataModel.UserClient
    ) async

    /// Fetches a client locally.
    /// - Parameters:
    ///     - id: The client id.
    ///     - user: The user linked to the client.
    ///     - createIfNeeded: Creates the client if not found locally.
    /// - returns: The user client fetched or created locally

    func fetchClient(
        id: String,
        forUser user: ZMUser,
        createIfNeeded: Bool
    ) async -> WireDataModel.UserClient?
}

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

    public func fetchOrCreateClient(
        id: String
    ) async throws -> (client: WireDataModel.UserClient, isNew: Bool) {
        await userClientsLocalStore.fetchOrCreateClient(
            id: id
        )
    }

    public func deleteClient(
        id: String
    ) async {
        await userClientsLocalStore.deleteClient(id: id)
    }

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

    public func updateClient(
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

    public func allSelfUserClientsAreActiveMLSClients() async -> Bool {
        await userClientsLocalStore.allSelfUserClientsAreActiveMLSClients()
    }

}
