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
import WireFoundation

// sourcery: AutoMockable
/// Facilitate access to users related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol UserRepositoryProtocol {

    /// Fetch self user from the local store

    func fetchSelfUser() async -> ZMUser

    /// Fetches a user locally
    ///
    /// - parameters
    ///     - id: The ID of the user.
    ///     - domain: The domain of the user.
    /// - returns : A  local`ZMUser`.

    func fetchUser(
        with id: UUID,
        domain: String?
    ) async throws -> ZMUser

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

    /// Updates a user.
    ///
    /// - parameters:
    ///     - event: The event to update the user locally from.

    func updateUser(
        from event: UserUpdateEvent
    ) async

    /// Fetches or creates a user locally.
    ///
    /// - parameters:
    ///     - id: The user id to fetch or create locally.
    ///     - domain: The user domain when federated.

    func fetchOrCreateUser(
        with id: UUID,
        domain: String?
    ) -> ZMUser

    /// Removes user push token from storage.

    func removePushToken()

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

    /// Updates a user property
    ///
    /// - parameters:
    ///     - userProperty: The user property to update.

    func updateUserProperty(
        _ userProperty: WireAPI.UserProperty
    ) async throws

    /// Deletes a user property.
    ///
    /// - parameters:
    ///     - key: The user property key to delete.

    func deleteUserProperty(
        withKey key: UserProperty.Key
    ) async

    /// Deletes the user account.
    ///
    /// - parameters:
    ///     - user: The user to delete the account for.
    ///     - date: The date the user was deleted.

    func deleteUserAccount(
        with id: UUID,
        domain: String?,
        at date: Date
    ) async throws

    /// Whether a given user is a self user.
    /// - Parameters:
    ///     - id: The user id to fetch or create locally.
    ///     - domain: The user domain when federated.
    /// - Returns: Whether the user is self user.

    func isSelfUser(
        id: UUID,
        domain: String?
    ) async throws -> Bool
}

public final class UserRepository: UserRepositoryProtocol {

    enum DefaultsKeys: String {
        case pushToken = "PushToken"
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let usersAPI: any UsersAPI
    private let selfUserAPI: any SelfUserAPI
    private let conversationLabelsRepository: any ConversationLabelsRepositoryProtocol
    private let conversationRepository: any ConversationRepositoryProtocol
    private let storage: UserDefaults

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        usersAPI: any UsersAPI,
        selfUserAPI: any SelfUserAPI,
        conversationLabelsRepository: any ConversationLabelsRepositoryProtocol,
        conversationRepository: ConversationRepositoryProtocol,
        sharedUserDefaults: UserDefaults = .standard
    ) {
        self.context = context
        self.usersAPI = usersAPI
        self.selfUserAPI = selfUserAPI
        self.conversationLabelsRepository = conversationLabelsRepository
        self.conversationRepository = conversationRepository
        storage = sharedUserDefaults
    }

    // MARK: - Public

    public func isSelfUser(
        id: UUID,
        domain: String?
    ) async throws -> Bool {
        let user = try await fetchUser(with: id, domain: domain)

        return await context.perform {
            user.isSelfUser
        }
    }

    public func fetchSelfUser() async -> ZMUser {
        await context.perform { [context] in
            ZMUser.selfUser(in: context)
        }
    }

    public func fetchOrCreateUser(
        with id: UUID,
        domain: String? = nil
    ) -> ZMUser {
        ZMUser.fetchOrCreate(
            with: id,
            domain: domain,
            in: context
        )
    }

    public func fetchUser(
        with id: UUID,
        domain: String?
    ) async throws -> ZMUser {
        try await context.perform { [context] in
            guard let user = ZMUser.fetch(
                with: id,
                domain: domain,
                in: context
            ) else {
                throw UserRepositoryError.failedToFetchUser(id)
            }

            return user
        }
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

    // TODO: [WPB-10727] reuse `updateUserMetadata` from mentioned ticket's implementation to avoid code duplication
    public func updateUser(
        from event: UserUpdateEvent
    ) async {
        await context.perform { [self] in

            let user = fetchOrCreateUser(
                with: event.userID
            )

            if let name = event.name {
                user.name = name
            }

            if let email = event.email {
                user.emailAddress = email
            }

            if let handle = event.handle {
                user.handle = handle
            }

            if let accentColor = event.accentColorID {
                user.accentColorValue = Int16(accentColor)
            }

            let assetKeys: Set<String> = [
                ZMUser.previewProfileAssetIdentifierKey,
                ZMUser.completeProfileAssetIdentifierKey
            ]

            /// Do not update assets if user has local modifications: a possible explanation is that if user has local changes to its assets
            /// we don't want to update them and keep these changes as is until they're synced.
            if !user.hasLocalModifications(forKeys: assetKeys) {
                let previewAssetKey = event.assets?
                    .first(where: { $0.size == .preview })
                    .map(\.key)

                let completeAssetKey = event.assets?
                    .first(where: { $0.size == .complete })
                    .map(\.key)

                if let previewAssetKey {
                    user.previewProfileAssetIdentifier = previewAssetKey
                }

                if let completeAssetKey {
                    user.completeProfileAssetIdentifier = completeAssetKey
                }
            }

            user.supportedProtocols = event.supportedProtocols?.toDomainModel() ?? [.proteus]

            user.isPendingMetadataRefresh = false
        }
    }

    public func removePushToken() {
        storage.set(
            nil,
            forKey: DefaultsKeys.pushToken.rawValue
        )
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
            let isNotSameId = localClient.remoteIdentifier != selfClient?.remoteIdentifier
            let localClientActivationDate = localClient.activationDate
            let selfClientActivationDate = selfClient?.activationDate

            if let selfClient, isNotSameId, let localClientActivationDate, let selfClientActivationDate {
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
        let selfUser = await fetchSelfUser()

        try await context.perform { [context] in
            selfUser.legalHoldRequestWasCancelled()

            try context.save()
        }
    }

    public func updateUserProperty(_ userProperty: UserProperty) async throws {
        switch userProperty {
        case .areReadReceiptsEnabled(let isEnabled):
            let selfUser = await fetchSelfUser()

            await context.perform {
                selfUser.readReceiptsEnabled = isEnabled
                selfUser.readReceiptsEnabledChangedRemotely = true
            }

        case .conversationLabels(let conversationLabels):
            try await conversationLabelsRepository.updateConversationLabels(conversationLabels)

        default:
            WireLogger.updateEvent.warn(
                "\(String(describing: userProperty)) property not handled."
            )
        }
    }

    public func deleteUserProperty(
        withKey key: UserProperty.Key
    ) async {
        switch key {
        case .wireReceiptMode:
            let selfUser = await fetchSelfUser()

            await context.perform {
                selfUser.readReceiptsEnabled = false
                selfUser.readReceiptsEnabledChangedRemotely = true
            }

        case .wireTypingIndicatorMode:
            // TODO: [WPB-726] feature not implemented yet
            break

        case .labels:
            /// Already handled with `user.properties-set` event (adding new labels and removing old ones)
            /// see `ConversationLabelsRepository`
            break
        }
    }

    public func deleteUserAccount(
        with id: UUID,
        domain: String?,
        at date: Date
    ) async throws {
        let user = try await fetchUser(with: id, domain: domain)

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

            try await conversationRepository.removeParticipantFromAllConversations(
                participantID: id,
                participantDomain: domain,
                removedAt: date
            )
        }
    }

    // MARK: - Private

    private func persistUser(from user: WireAPI.User) {
        let persistedUser = fetchOrCreateUser(
            with: user.id.uuid,
            domain: user.id.domain
        )

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
