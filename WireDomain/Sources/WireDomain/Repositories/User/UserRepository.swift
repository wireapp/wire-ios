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

    /// Pulls self user and stores it locally

    func pullSelfUser() async throws

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

    /// Fetches a user with a specific id.
    /// - Parameter id: The ID of the user.
    /// - Parameter domain: The domain of the user.
    /// - Returns: A `ZMUser` object.

    func fetchUser(with id: UUID, domain: String?) async throws -> ZMUser

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

    /// Deletes the user account.
    ///
    /// - parameters:
    ///     - user: The user to delete the account for.
    ///     - date: The date the user was deleted.

    func deleteUserAccount(for user: ZMUser, at date: Date) async

    /// Fetches all user IDs that have a one on one conversation
    /// - returns: A list of users' qualified IDs.

    func fetchAllUserIDsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID]

}

public final class UserRepository: UserRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let usersAPI: any UsersAPI
    private let selfUserAPI: any SelfUserAPI
    private let conversationRepository: any ConversationRepositoryProtocol

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        usersAPI: any UsersAPI,
        selfUserAPI: any SelfUserAPI,
        conversationRepository: ConversationRepositoryProtocol
    ) {
        self.context = context
        self.usersAPI = usersAPI
        self.selfUserAPI = selfUserAPI
        self.conversationRepository = conversationRepository
    }

    // MARK: - Public

    public func pullSelfUser() async throws {
        let selfUser = try await selfUserAPI.getSelfUser()

        await context.perform { [self] in
            persistSelfUser(from: selfUser)
        }
    }

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

    public func fetchUser(with id: UUID, domain: String?) async throws -> ZMUser {
        try await context.perform { [context] in
            guard let user = ZMUser.fetch(with: id, domain: domain, in: context) else {
                throw UserRepositoryError.failedToFetchUser(id)
            }

            return user
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

            let selfClient = selfUser.selfClient()
            let isSameId = localClient.remoteIdentifier != selfClient?.remoteIdentifier
            let localClientActivationDate = localClient.activationDate
            let selfClientActivationDate = selfClient?.activationDate

            if let selfClient, isSameId, let localClientActivationDate, let selfClientActivationDate {
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

    public func deleteUserAccount(
        for user: ZMUser,
        at date: Date
    ) async {
        let isSelfUser = await context.perform {
            user.isSelfUser
        }

        if isSelfUser {
            let notification = AccountDeletedNotification(context: context)
            notification.post(in: context.notificationContext)
        } else {
            await context.perform {
                user.isAccountDeleted = true
            }

            await conversationRepository.removeFromConversations(
                user: user,
                removalDate: date
            )
        }
    }

    public func fetchAllUserIDsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID] {
        try await context.perform { [context] in
            let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
            let predicate = NSPredicate(format: "%K != nil", #keyPath(ZMUser.oneOnOneConversation))
            request.predicate = predicate

            return try context
                .fetch(request)
                .compactMap { user in
                    guard let userID = user.qualifiedID else {
                        WireLogger.conversation.error(
                            "Missing user's qualifiedID"
                        )
                        return nil
                    }
                    return userID
                }
        }
    }

    // MARK: - Private

    private func persistUser(from user: WireAPI.User) {
        let persistedUser = ZMUser.fetchOrCreate(
            with: user.id.uuid,
            domain: user.id.domain,
            in: context
        )

        let previewProfileAssetIdentifier = user.assets.first(where: { $0.size == .preview })?.key
        let completeProfileAssetIdentifier = user.assets.first(where: { $0.size == .complete })?.key

        updateUserMetadata(
            persistedUser,
            deleted: user.deleted == true,
            name: user.name,
            handle: user.handle,
            teamID: user.teamID,
            accentID: user.accentID,
            previewProfileAssetIdentifier: previewProfileAssetIdentifier,
            completeProfileAssetIdentifier: completeProfileAssetIdentifier,
            email: user.email,
            expiresAt: user.expiresAt,
            serviceIdentifier: user.service?.id.transportString(),
            providerIdentifier: user.service?.provider.transportString(),
            supportedProtocols: user.supportedProtocols?.toDomainModel() ?? [.proteus]
        )
    }

    private func persistSelfUser(
        from selfUser: WireAPI.SelfUser
    ) {
        let persistedSelfUser = ZMUser.selfUser(in: context)
        let previewProfileAssetIdentifier = selfUser.assets?.first(where: { $0.size == .preview })?.key
        let completeProfileAssetIdentifier = selfUser.assets?.first(where: { $0.size == .complete })?.key

        updateUserMetadata(
            persistedSelfUser,
            deleted: selfUser.deleted == true,
            name: selfUser.name,
            handle: selfUser.handle,
            teamID: selfUser.teamID,
            accentID: selfUser.accentID,
            previewProfileAssetIdentifier: previewProfileAssetIdentifier,
            completeProfileAssetIdentifier: completeProfileAssetIdentifier,
            email: selfUser.email,
            expiresAt: selfUser.expiresAt,
            serviceIdentifier: selfUser.service?.id.transportString(),
            providerIdentifier: selfUser.service?.provider.transportString(),
            supportedProtocols: selfUser.supportedProtocols?.toDomainModel() ?? [.proteus]
        )

        persistedSelfUser.remoteIdentifier = selfUser.qualifiedID.uuid
        persistedSelfUser.domain = selfUser.qualifiedID.domain
        persistedSelfUser.managedBy = selfUser.managedBy?.rawValue
    }

    private func updateUserMetadata(
        _ user: ZMUser,
        deleted: Bool,
        name: String,
        handle: String?,
        teamID: UUID?,
        accentID: Int,
        previewProfileAssetIdentifier: String?,
        completeProfileAssetIdentifier: String?,
        email: String?,
        expiresAt: Date?,
        serviceIdentifier: String?,
        providerIdentifier: String?,
        supportedProtocols: Set<WireDataModel.MessageProtocol>
    ) {
        guard deleted == false else {
            return user.markAccountAsDeleted(at: .now)
        }

        user.name = name
        user.handle = handle
        user.teamIdentifier = teamID
        user.accentColorValue = Int16(accentID)
        user.previewProfileAssetIdentifier = previewProfileAssetIdentifier
        user.completeProfileAssetIdentifier = completeProfileAssetIdentifier
        user.emailAddress = email
        user.expiresAt = expiresAt
        user.serviceIdentifier = serviceIdentifier
        user.providerIdentifier = providerIdentifier
        user.supportedProtocols = supportedProtocols
        user.needsToBeUpdatedFromBackend = false
    }
}
