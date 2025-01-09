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

import WireDataModel
import WireLogging

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
}

public final class UserClientsLocalStore: UserClientsLocalStoreProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let userLocalStore: any UserLocalStoreProtocol

    // MARK: - Object lifecycle

    init(
        context: NSManagedObjectContext,
        userLocalStore: any UserLocalStoreProtocol
    ) {
        self.context = context
        self.userLocalStore = userLocalStore
    }

    public func fetchSelfClient() async -> UserClient? {
        let selfUser = await userLocalStore.fetchSelfUser()

        return await context.perform {
            selfUser.selfClient()
        }
    }

    public func fetchClient(
        id: String,
        forUser user: ZMUser,
        createIfNeeded: Bool
    ) async -> UserClient? {
        await context.perform {
            UserClient.fetchUserClient(
                withRemoteId: id,
                forUser: user,
                createIfNeeded: createIfNeeded
            )
        }
    }

    public func fetchOrCreateClient(
        id: String
    ) async -> (client: WireDataModel.UserClient, isNew: Bool) {
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

    public func deletedSelfClients(
        newClients: [String]
    ) async -> [String] {
        let selfUser = await userLocalStore.fetchSelfUser()

        return await context.perform {
            selfUser.clients
                .compactMap(\.remoteIdentifier)
                .filter {
                    !newClients.contains($0)
                }
        }
    }

    public func deleteClient(
        id: String
    ) async {
        let localClient = await context.perform { [context] in
            return UserClient.fetchExistingUserClient(
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

    public func updateClient(
        id: String,
        isNewClient: Bool,
        userClientInfo: UserClientInfo
    ) async {
        await context.perform { [context] in

            guard let localClient = UserClient.fetchExistingUserClient(
                with: id,
                in: context
            ) else {
                return WireLogger.userClient.error(
                    "Failed to find existing client with id: \(id.redactedAndTruncated())"
                )
            }

            localClient.label = userClientInfo.label
            localClient.type = userClientInfo.type
            localClient.model = userClientInfo.model
            localClient.deviceClass = userClientInfo.deviceClass
            localClient.activationDate = userClientInfo.activationDate
            localClient.lastActiveDate = userClientInfo.lastActiveDate
            localClient.remoteIdentifier = userClientInfo.id

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
                    ed25519: userClientInfo.mlsPublicKeys?.ed25519,
                    ed448: userClientInfo.mlsPublicKeys?.ed448,
                    p256: userClientInfo.mlsPublicKeys?.p256,
                    p384: userClientInfo.mlsPublicKeys?.p384,
                    p521: userClientInfo.mlsPublicKeys?.p512
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

    public func allSelfUserClientsAreActiveMLSClients() async -> Bool {
        let selfUser = await userLocalStore.fetchSelfUser()

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

    public func storeClient(
        discoveryDate: Date,
        client: WireDataModel.UserClient
    ) async {
        await context.perform {
            client.discoveryDate = discoveryDate
        }
    }

    public func addNewClientToIgnored(
        selfClient: WireDataModel.UserClient,
        newClient: WireDataModel.UserClient
    ) async {
        await context.perform {
            selfClient.addNewClientToIgnored(newClient)
        }
    }

    public func proteusSessionID(
        for client: WireDataModel.UserClient
    ) async -> ProteusSessionID? {
        await context.perform {
            client.proteusSessionID
        }
    }

    public func clientSessionCreated(
        selfClient: WireDataModel.UserClient,
        newClient: WireDataModel.UserClient
    ) async {
        await context.perform {
            selfClient.decrementNumberOfRemainingProteusKeys()
            selfClient.updateSecurityLevelAfterDiscovering([newClient])
        }
    }

}
