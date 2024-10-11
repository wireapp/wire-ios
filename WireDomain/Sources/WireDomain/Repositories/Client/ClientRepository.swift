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

import CoreData
import Foundation
import WireAPI
import WireDataModel

// sourcery: AutoMockable
/// Facilitate access to clients related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol ClientRepositoryProtocol {

    /// Fetches self user clients.
    /// - returns : A self user clients list.

    func fetchSelfClients() async throws -> [WireAPI.UserClient]

    /// Fetches user clients.
    /// - parameter userIDs: A list of user qualified ids.
    /// - returns : A list of clients for a given user on a given domain.

    func fetchClients(for userIDs: Set<UserID>) async throws -> [WireAPI.UserClients]

    /// Fetches or creates a client locally.
    ///
    /// - parameters:
    ///     - id: The user client id to find or create locally.
    /// - returns: The user client found or created locally and a flag indicating whether or not the user client is new.

    func fetchOrCreateClient(
        with id: String
    ) async throws -> (client: WireDataModel.UserClient, isNew: Bool)

    /// Updates the user client informations locally.
    ///
    /// - parameters:
    ///     - id: The user client id.
    ///     - remoteClient: The up-to-date remote user client.
    ///     - isNewClient: A flag indicating whether the user client is new.

    func updateClient(
        with id: String,
        from remoteClient: WireAPI.UserClient,
        isNewClient: Bool
    ) async throws

    /// Deletes client locally.
    /// - parameter id: The client id.

    func deleteClient(with id: String) async
}

public struct ClientRepository: ClientRepositoryProtocol {

    // MARK: - Properties

    private let clientAPI: any ClientAPI
    private let context: NSManagedObjectContext

    // MARK: - Object lifecycle

    init(
        clientAPI: any ClientAPI,
        context: NSManagedObjectContext
    ) {
        self.clientAPI = clientAPI
        self.context = context
    }

    // MARK: - Public

    public func fetchSelfClients() async throws -> [WireAPI.UserClient] {
        try await clientAPI.getSelfClients()
    }

    public func fetchClients(for userIDs: Set<UserID>) async throws -> [WireAPI.UserClients] {
        try await clientAPI.getClients(for: userIDs)
    }

    public func fetchOrCreateClient(
        with id: String
    ) async throws -> (client: WireDataModel.UserClient, isNew: Bool) {
        let localUserClient = await context.perform { [context] in
            if let existingClient = UserClient.fetchExistingUserClient(
                with: id,
                in: context
            ) {
                return (existingClient, false)
            } else {
                let newClient = UserClient.insertNewObject(in: context)
                newClient.remoteIdentifier = id
                return (newClient, true)
            }
        }

        try context.save()

        return localUserClient
    }

    public func updateClient(
        with id: String,
        from remoteClient: WireAPI.UserClient,
        isNewClient: Bool
    ) async throws {
        guard let localClient = UserClient.fetchExistingUserClient(
            with: id,
            in: context
        ) else {
            return WireLogger.userClient.error(
                "Failed to find existing client with id: \(id)"
            )
        }

        await context.perform { [context] in

            localClient.label = remoteClient.label
            localClient.type = remoteClient.type.toDomainModel()
            localClient.model = remoteClient.model
            localClient.deviceClass = remoteClient.deviceClass?.toDomainModel()
            localClient.activationDate = remoteClient.activationDate
            localClient.lastActiveDate = remoteClient.lastActiveDate
            localClient.remoteIdentifier = remoteClient.id

            let selfUser = ZMUser.selfUser(in: context)
            localClient.user = localClient.user ?? selfUser

            if isNewClient {
                localClient.needsSessionMigration = selfUser.domain == nil
            }

            if localClient.isLegalHoldDevice, isNewClient {
                selfUser.legalHoldRequest = nil
                selfUser.needsToAcknowledgeLegalHoldStatus = true
            }

            if !localClient.isSelfClient() {
                localClient.mlsPublicKeys = .init(
                    ed25519: remoteClient.mlsPublicKeys?.ed25519,
                    ed448: remoteClient.mlsPublicKeys?.ed448,
                    p256: remoteClient.mlsPublicKeys?.p256,
                    p384: remoteClient.mlsPublicKeys?.p384,
                    p521: remoteClient.mlsPublicKeys?.p512
                )
            }

            let selfClient = selfUser.selfClient()
            let isNotSameId = localClient.remoteIdentifier != selfClient?.remoteIdentifier
            let localClientActivationDate = localClient.activationDate
            let selfClientActivationDate = selfClient?.activationDate

            if selfClient != nil, isNotSameId, let localClientActivationDate, let selfClientActivationDate {
                let comparisonResult = localClientActivationDate
                    .compare(selfClientActivationDate)

                if comparisonResult == .orderedDescending {
                    localClient.needsToNotifyUser = true
                }
            }

            selfUser.selfClient()?.addNewClientToIgnored(localClient)
            selfUser.selfClient()?.updateSecurityLevelAfterDiscovering(Set([localClient]))
        }

        try context.save()
    }

    public func deleteClient(with id: String) async {
        guard let localClient = UserClient.fetchExistingUserClient(
            with: id,
            in: context
        ) else {
            return WireLogger.userClient.error(
                "Failed to find existing client with id: \(id)"
            )
        }

        await localClient.deleteClientAndEndSession()
    }
}
