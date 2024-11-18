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
/// Facilitate access to user clients related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol UserClientsRepositoryProtocol {

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
        from remoteClient: WireAPI.SelfUserClient,
        isNewClient: Bool
    ) async throws

    /// Deletes client locally.
    /// - parameter id: The client id.

    func deleteClient(with id: String) async

    /// Indicates whether self user clients are active MLS clients.
    /// - returns: A flag indicating whether all self user clients are active MLS clients.

    func allSelfUserClientsAreActiveMLSClients() async -> Bool
}

public struct UserClientsRepository: UserClientsRepositoryProtocol {

    // MARK: - Properties

    private let userClientsAPI: any UserClientsAPI
    private let userRepository: any UserRepositoryProtocol
    private let context: NSManagedObjectContext

    // MARK: - Object lifecycle

    init(
        userClientsAPI: any UserClientsAPI,
        userRepository: any UserRepositoryProtocol,
        context: NSManagedObjectContext
    ) {
        self.userClientsAPI = userClientsAPI
        self.userRepository = userRepository
        self.context = context
    }

    // MARK: - Public

    public func pullSelfClients() async throws {
        let remoteSelfClients = try await userClientsAPI.getSelfClients()
        let selfUser = await userRepository.fetchSelfUser()
        let localSelfClients = await context.perform {
            selfUser.clients
        }

        for remoteSelfClient in remoteSelfClients {
            let localUserClient = try await fetchOrCreateClient(with: remoteSelfClient.id)
            try await updateClient(
                with: remoteSelfClient.id,
                from: remoteSelfClient,
                isNewClient: localUserClient.isNew
            )
        }

        let deletedSelfClientsIDs = await context.perform {
            localSelfClients
                .compactMap(\.remoteIdentifier)
                .filter {
                    !remoteSelfClients.map(\.id).contains($0)
                }
        }

        for deletedSelfClientID in deletedSelfClientsIDs {
            await deleteClient(with: deletedSelfClientID)
        }
    }

    public func fetchOrCreateClient(
        with id: String
    ) async throws -> (client: WireDataModel.UserClient, isNew: Bool) {
        await context.perform { [context] in
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
    }

    public func updateClient(
        with id: String,
        from remoteClient: WireAPI.SelfUserClient,
        isNewClient: Bool
    ) async throws {
        await context.perform { [context] in

            guard let localClient = UserClient.fetchExistingUserClient(
                with: id,
                in: context
            ) else {
                return WireLogger.userClient.error(
                    "Failed to find existing client with id: \(id.redactedAndTruncated())"
                )
            }

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
    }

    public func deleteClient(with id: String) async {
        let localClient = await context.perform {
            UserClient.fetchExistingUserClient(
                with: id,
                in: context
            )
        }

        guard let localClient else {
            return WireLogger.userClient.error(
                "Failed to find existing client with id: \(id.redactedAndTruncated())"
            )
        }

        await localClient.deleteClientAndEndSession()
    }

    public func allSelfUserClientsAreActiveMLSClients() async -> Bool {
        let selfUser = await userRepository.fetchSelfUser()

        return await context.perform {
            selfUser.clients.all { userClient in
                let hasMLSIdentity = !userClient.mlsPublicKeys.isEmpty

                let isRecentlyActive: Bool = {
                    if userClient.isSelfClient() {
                        return true
                    }

                    guard let lastActiveDate = userClient.lastActiveDate else {
                        return false
                    }

                    guard lastActiveDate <= Date() else {
                        return true
                    }

                    return lastActiveDate.timeIntervalSinceNow.magnitude < .fourWeeks
                }()

                return hasMLSIdentity && isRecentlyActive
            }
        }
    }
}
