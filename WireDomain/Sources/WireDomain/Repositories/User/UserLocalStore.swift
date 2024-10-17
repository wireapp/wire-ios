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
import WireDataModel
import WireAPI

// sourcery: AutoMockable
/// A local store dedicated to user.
/// The store uses the injected context to perform `CoreData` operations on user objects.
public protocol UserLocalStoreProtocol {
    
    /// Fetch self user from the local store

    func fetchSelfUser() -> ZMUser

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

    /// Fetches or creates a user locally.
    ///
    /// - parameters:
    ///     - uuid: The user id to fetch or create locally.
    ///     - domain: The user domain when federated.

    func fetchOrCreateUser(
        with uuid: UUID,
        domain: String?
    ) -> ZMUser

    /// Removes user push token from storage.

    func deletePushTokenFromUserDefaults()

    /// Fetches or creates a user client locally.
    ///
    /// - parameters:
    ///     - id: The user client id to find or create locally.
    /// - returns: The user client found or created locally and a flag indicating whether or not the user client is new.

    func fetchOrCreateUserClient(
        with id: String
    ) async -> (client: WireDataModel.UserClient, isNew: Bool)

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

    /// Adds a legal hold request to self.
    ///
    /// - parameters:
    ///     - userID: The user ID of the target legalhold subject.
    ///     - clientID: The client ID of the legalhold device.
    ///     - lastPrekey: The last prekey of the legalhold device.
    ///
    /// Legal hold is the ability to provide an auditable transcript of all communication
    /// held by team members that are put under legal hold compliance (from a third-party),
    /// achieved by collecting the content of such communication for later auditing.

    func addSelfLegalHoldRequest(
        for userID: UUID,
        clientID: String,
        lastPrekey: WireDataModel.LegalHoldRequest.Prekey
    ) async

    /// Cancels a self user legal hold request.

    func cancelSelfUserLegalholdRequest() async

    /// Update read receipts flags for self user locally.

    func updateSelfUserReadReceipts(
        isReadReceiptsEnabled: Bool,
        isReadReceiptsEnabledChangedRemotely: Bool
    ) async
    
    /// Fetches users qualified IDs locally.
    /// - returns: A list of qualified IDs.
    
    func fetchUsersQualifiedIDs() async throws -> [WireDataModel.QualifiedID]
    
    /// Indicates whether the user is a self user.
    /// - Parameters:
    ///     - id: The ID of the user
    ///     - domain: The domain of the user if any.
    /// - returns: The user found locally and a flag indicating if this user is a self user.

    func isSelfUser(
        id: UUID,
        domain: String?
    ) async throws -> (user: ZMUser, isSelfUser: Bool)
    
    // swiftlint:disable:next todo_requires_jira_link
    // TODO: Should be factored out
    func postAccountDeletedNotification()
    
    /// Marks a user account as deleted locally.
    /// - parameters:
    ///     - user: The user to mark the account deleted for.
    
    func markAccountAsDeleted(for user: ZMUser) async
    
    // TODO: [WPB-10727] Merge these two methods into a single method (also no API objects should be passed to local store)
    func persistUser(from user: WireAPI.User) async
    func updateUser(from event: UserUpdateEvent) async
    
}

public final class UserLocalStore: UserLocalStoreProtocol {
    
    enum DefaultsKeys: String {
        case pushToken = "PushToken"
    }
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    private let userDefaults: UserDefaults
    
    // MARK: - Object lifecycle
    
    public init(
        context: NSManagedObjectContext,
        userDefaults: UserDefaults = .standard
    ) {
        self.context = context
        self.userDefaults = userDefaults
    }
    
    public func fetchSelfUser() -> ZMUser {
        ZMUser.selfUser(in: context)
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
    
    public func fetchOrCreateUser(
        with uuid: UUID,
        domain: String? = nil
    ) -> ZMUser {
        ZMUser.fetchOrCreate(
            with: uuid,
            domain: domain,
            in: context
        )
    }
    
    public func fetchUsersQualifiedIDs() async throws -> [WireDataModel.QualifiedID] {
        try await context.perform {
            let fetchRequest = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
            let knownUsers = try self.context.fetch(fetchRequest)
            return knownUsers.compactMap(\.qualifiedID)
        }
    }
    
    public func updateSelfUserReadReceipts(
        isReadReceiptsEnabled: Bool,
        isReadReceiptsEnabledChangedRemotely: Bool
    ) async {
        let selfUser = fetchSelfUser()

        await context.perform {
            selfUser.readReceiptsEnabled = isReadReceiptsEnabled
            selfUser.readReceiptsEnabledChangedRemotely = isReadReceiptsEnabledChangedRemotely
        }
    }
    
    public func isSelfUser(
        id: UUID,
        domain: String?
    ) async throws -> (user: ZMUser, isSelfUser: Bool) {
        let user = try await fetchUser(with: id, domain: domain)

        let isSelfUser = await context.perform {
            user.isSelfUser
        }
        
        return (user, isSelfUser)
    }
    
    public func deletePushTokenFromUserDefaults() {
        userDefaults.set(
            nil,
            forKey: DefaultsKeys.pushToken.rawValue
        )
    }
    
    public func addSelfLegalHoldRequest(
        for userID: UUID,
        clientID: String,
        lastPrekey: WireDataModel.LegalHoldRequest.Prekey
    ) async {
        await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)

            let legalHoldRequest = LegalHoldRequest(
                target: userID,
                requester: nil,
                clientIdentifier: clientID,
                lastPrekey: lastPrekey
            )

            selfUser.userDidReceiveLegalHoldRequest(legalHoldRequest)
        }
    }
    
    public func fetchOrCreateUserClient(
        with id: String
    ) async -> (client: WireDataModel.UserClient, isNew: Bool) {
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

        return localUserClient
    }
    
    public func cancelSelfUserLegalholdRequest() async {
        let selfUser = fetchSelfUser()

        await context.perform {
            selfUser.legalHoldRequestWasCancelled()
        }
    }
    
    public func postAccountDeletedNotification() {
        let notification = AccountDeletedNotification(context: context)
        notification.post(in: context.notificationContext)
    }
    
    public func markAccountAsDeleted(for user: ZMUser) async {
        await context.perform {
            user.isAccountDeleted = true
        }
    }
    
    // swiftlint:disable:next todo_requires_jira_link
    // TODO: refactor, do not pass API object (WireAPI.UserClient) directly, merge this method with updateUser method.
    public func persistUser(from user: WireAPI.User) async {
        let persistedUser = fetchOrCreateUser(
            with: user.id.uuid,
            domain: user.id.domain
        )
        
        await context.perform {

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
    
    // TODO: [WPB-10727] reuse `updateUserMetadata` from mentioned ticket's implementation to avoid code duplication
    public func updateUser(from event: UserUpdateEvent) async {
        let user = fetchOrCreateUser(
            with: event.userID
        )
        
        await context.perform {

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
    
    // swiftlint:disable:next todo_requires_jira_link
    // TODO: refactor, do not pass API object (WireAPI.UserClient) directly
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
    
}
