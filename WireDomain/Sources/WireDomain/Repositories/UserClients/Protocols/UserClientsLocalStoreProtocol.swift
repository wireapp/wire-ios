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

import WireDataModel

// sourcery: AutoMockable
public protocol UserClientsLocalStoreProtocol {

    /// Fetches or creates a client locally.
    ///
    /// - parameters:
    ///     - id: The user client id to find or create locally.
    /// - returns: The user client found or created locally and a flag indicating whether or not the user client is new.

    func fetchOrCreateClient(
        id: String
    ) async -> (client: WireDataModel.UserClient, isNew: Bool)

    /// Retrieves deleted self clients locally based on new self clients.
    /// - parameter newClients: The new self user clients.
    /// - returns: A list of deleted self clients.

    func deletedSelfClients(
        newClients: [String]
    ) async -> [String]

    /// Deletes client locally.
    /// - parameter id: The client id.

    func deleteClient(
        id: String
    ) async

    /// Invalides the self client locally

    func invalidateSelfClient() async

    /// Updates the user client informations locally.
    ///
    /// - parameters:
    ///     - id: The user client id.
    ///     - isNewClient: A flag indicating whether the user client is new.
    ///     - remoteClient: The up-to-date user client info object.

    func updateClient(
        id: String,
        isNewClient: Bool,
        userClientInfo: UserClientInfo
    ) async

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

    /// Fetches self client locally.
    /// - returns: The self client if any

    func fetchSelfClient() async -> WireDataModel.UserClient?

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

    func fetchSelfClientID() async -> String?

    /// Checks if self client has consumable notifications capability
    /// - Returns: True if capability is there, false otherwise
    func hasRegisteredConsumableNotificationsCapable() async -> Bool
}
