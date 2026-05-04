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
import WireNetwork

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
    ) async -> (client: WireDataModel.UserClient, isNew: Bool)

    /// Updates the user client informations locally.
    ///
    /// - parameters:
    ///     - id: The user client id.
    ///     - remoteClient: The up-to-date remote user client.
    ///     - isNewClient: A flag indicating whether the user client is new.

    func updateClient(
        id: String,
        from remoteClient: WireNetwork.SelfUserClient,
        isNewClient: Bool
    ) async

    /// Deletes client locally.
    /// - parameter id: The client id.

    func deleteClient(id: String) async

    /// Invalides the self client locally

    func invalidateSelfClient() async

    /// Indicates whether self user clients are active MLS clients.
    /// - returns: A flag indicating whether all self user clients are active MLS clients.

    func allSelfUserClientsAreActiveMLSClients() async -> Bool

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
