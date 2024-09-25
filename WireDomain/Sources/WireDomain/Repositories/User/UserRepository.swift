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
/// Facilitate access to users related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol UserRepositoryProtocol {

    /// Fetch self user from the local store

    func fetchSelfUser() -> ZMUser

    /// Push self user supported protocols
    /// - Parameter supportedProtocols: A list of supported protocols.

    func pushSelfSupportedProtocols(
        _ supportedProtocols: Set<WireAPI.MessageProtocol>
    ) async throws

    /// Fetch and persist all locally known users

    func pullKnownUsers() async throws

    /// Fetch and persist a list of users
    ///
    /// - parameters:
    ///     - userIDs: IDs of users to fetch

    func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws

    /// Fetches or creates a user client locally.
    ///
    /// - parameters:
    ///     - id: The user client id to find or create locally.
    /// - returns: The user client found or created locally and a flag indicating whether or not the user client is new.

    func fetchOrCreateUserClient(
        with id: String
    ) async throws -> (client: WireDataModel.UserClient, isNew: Bool)

    /// Updates the user client informations locally.
    ///
    /// - parameters:
    ///     - localClient: The user client to update locally.
    ///     - remoteClient: The up-to-date remote user client.
    ///     - isNewClient: A flag indicating whether the user client is new.

    func updateUserClient(
        _ localClient: WireDataModel.UserClient,
        from remoteClient: WireAPI.UserClient,
        isNewClient: Bool
    ) async throws

    /// Adds a legal hold request.
    ///
    /// - parameters:
    ///     - userID: The user ID of the target legalhold subject.
    ///     - clientID: The client ID of the legalhold device.
    ///     - lastPrekey: The last prekey of the legalhold device.
    ///
    /// Legal hold is the ability to provide an auditable transcript of all communication
    /// held by team members that are put under legal hold compliance (from a third-party),
    /// achieved by collecting the content of such communication for later auditing.

    func addLegalHoldRequest(
        for userID: UUID,
        clientID: String,
        lastPrekey: Prekey
    ) async

    /// Disables user legal hold.

    func disableUserLegalHold() async throws

    /// Deletes a user property.
    ///
    /// - parameters:
    ///     - key: The user property key to delete.

    func deleteUserProperty(
        withKey key: String
    ) async

}

public final class UserRepository: UserRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let usersAPI: any UsersAPI
    private let selfUserAPI: any SelfUserAPI
    private let logger = WireLogger.eventProcessing

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        usersAPI: any UsersAPI,
        selfUserAPI: any SelfUserAPI
    ) {
        self.context = context
        self.usersAPI = usersAPI
        self.selfUserAPI = selfUserAPI
    }

    // MARK: - Public

    public func fetchSelfUser() -> ZMUser {
        ZMUser.selfUser(in: context)
    }

    public func pushSelfSupportedProtocols(
        _ supportedProtocols: Set<WireAPI.MessageProtocol>
    ) async throws {
        try await selfUserAPI.pushSupportedProtocols(supportedProtocols)
    }

    public func pullKnownUsers() async throws {
        let knownUserIDs: [WireDataModel.QualifiedID]

        do {
            knownUserIDs = try await context.perform {
                let fetchRequest = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
                let knownUsers = try self.context.fetch(fetchRequest)
                return knownUsers.compactMap(\.qualifiedID)
            }
        } catch {
            throw UserRepositoryError.failedToCollectKnownUsers(error)
        }

        try await pullUsers(userIDs: knownUserIDs)
    }

    public func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws {
        do {
            let userList = try await usersAPI.getUsers(userIDs: userIDs.toAPIModel())

            await context.perform {
                for user in userList.found {
                    self.persistUser(from: user)
                }
            }
        } catch {
            throw UserRepositoryError.failedToFetchRemotely(error)
        }
    }

    public func fetchOrCreateUserClient(
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

    public func updateUserClient(
        _ localClient: WireDataModel.UserClient,
        from remoteClient: WireAPI.UserClient,
        isNewClient: Bool
    ) async throws {
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

            let localClientActivationDate = localClient.activationDate

            if let selfClient = selfUser.selfClient(),
               localClient.remoteIdentifier != selfClient.remoteIdentifier, isNewClient,
               let selfClientActivationDate = selfClient.activationDate,
               localClientActivationDate?.compare(selfClientActivationDate) == .orderedDescending {
                localClient.needsToNotifyUser = true
            }

            selfUser.selfClient()?.addNewClientToIgnored(localClient)
            selfUser.selfClient()?.updateSecurityLevelAfterDiscovering(Set([localClient]))
        }

        try context.save()
    }

    public func addLegalHoldRequest(
        for userID: UUID,
        clientID: String,
        lastPrekey: Prekey
    ) async {
        await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)

            guard let prekey = lastPrekey.toDomainModel() else {
                return WireLogger.eventProcessing.error(
                    "Invalid legal hold request payload: invalid base64 encoded key \(lastPrekey.base64EncodedKey)"
                )
            }

            let legalHoldRequest = LegalHoldRequest(
                target: userID,
                requester: nil,
                clientIdentifier: clientID,
                lastPrekey: prekey
            )

            selfUser.userDidReceiveLegalHoldRequest(legalHoldRequest)
        }
    }

    public func disableUserLegalHold() async throws {
        try await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)
            selfUser.legalHoldRequestWasCancelled()

            try context.save()
        }
    }

    public func deleteUserProperty(
        withKey key: String
    ) async {
        let userPropertyKey = UserProperty.Key(rawValue: key)

        switch userPropertyKey {
        case .wireReceiptMode:
            let selfUser = fetchSelfUser()

            await context.perform {
                selfUser.readReceiptsEnabled = false
                selfUser.readReceiptsEnabledChangedRemotely = true
            }

        case .wireTypingIndicatorMode, .labels:
            break

        case nil:
            logger.warn("Unknown user property key: \(key)")
        }
    }

    // MARK: - Private

    private func persistUser(from user: WireAPI.User) {
        let persistedUser = ZMUser.fetchOrCreate(with: user.id.uuid, domain: user.id.domain, in: context)

        guard user.deleted == false else {
            return persistedUser.markAccountAsDeleted(at: Date())
        }

        persistedUser.name = user.name
        persistedUser.handle = user.handle
        persistedUser.teamIdentifier = user.teamID
        persistedUser.accentColorValue = Int16(user.accentID)
        persistedUser.previewProfileAssetIdentifier = user.assets.first(where: { $0.size == .preview })?.key
        persistedUser.previewProfileAssetIdentifier = user.assets.first(where: { $0.size == .complete })?.key
        persistedUser.emailAddress = user.email
        persistedUser.expiresAt = user.expiresAt
        persistedUser.serviceIdentifier = user.service?.id.transportString()
        persistedUser.providerIdentifier = user.service?.provider.transportString()
        persistedUser.supportedProtocols = user.supportedProtocols?.toDomainModel() ?? [.proteus]
        persistedUser.needsToBeUpdatedFromBackend = false
    }

}
