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
/// A local store dedicated to user.
/// The store uses the injected context to perform `CoreData` operations on user objects.
public protocol UserLocalStoreProtocol {

    /// Fetch self user from the local store

    func fetchSelfUser() async -> ZMUser

    /// Fetches a user locally
    ///
    /// - parameters
    ///     - id: The ID of the user.
    ///     - domain: The domain of the user.
    /// - returns : A  local`ZMUser`.

    func fetchUser(
        id: UUID,
        domain: String?
    ) async throws -> ZMUser

    /// Fetches or creates a user locally.
    ///
    /// - parameters:
    ///     - id: The user id to fetch or create locally.
    ///     - domain: The user domain when federated.

    func fetchOrCreateUser(
        id: UUID,
        domain: String?
    ) async -> ZMUser

    /// Fetches or creates users locally.
    ///
    /// - parameters:
    ///     - userIDs: The users id to fetch or create locally.
    /// - returns: A list of users fetched or created locally.

    func fetchOrCreateUsers(
        userIDs: [(id: UUID, domain: String?)]
    ) async -> Set<ZMUser>

    /// Removes user push token from storage.

    func deletePushToken()

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
        userID: UUID,
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

    func updateSelfUserAnalyticsID(
        analyticsID: String,
        conversation: ZMConversation
    ) async

    // TODO: [WPB-10727] Merge these two methods into a single method
    func persistUser(userInfo: NewUserInfo) async
    func updateUser(userUpdateInfo: UserUpdateInfo) async

    /// Fetches all user IDs that have a one on one conversation
    /// - returns: A list of users' qualified IDs.

    func fetchAllUserIDsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID]

    /// Fetches self user info : user ID and client ID.
    /// - returns: the user ID and the client ID.

    func selfUserInfo() async -> (id: UUID, clientId: String?)

    func removeUserFromAllConversations(
        id: UUID,
        domain: String?,
        date: Date
    ) async throws
    /// The name of a given user.
    /// - Parameter user: The user to fetch the name for.
    /// - returns: The user name.

    func name(
        for user: ZMUser
    ) async -> String?

    /// The team name of a given user.
    /// - Parameter user: The user to fetch the team for.
    /// - returns: The team name if any.

    func teamName(
        for user: ZMUser
    ) async -> String?

    /// The identifier for a given user
    /// - parameter user: The user to get the ID for.
    /// - returns: The user UUID.

    func id(
        for user: ZMUser
    ) async -> UUID
}

public final class UserLocalStore: UserLocalStoreProtocol {

    enum DefaultsKeys: String {
        case pushToken = "PushToken"
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let userDefaults: UserDefaults

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.context = context
        self.userDefaults = userDefaults
        self.conversationLocalStore = conversationLocalStore
    }

    public func fetchSelfUser() async -> ZMUser {
        await context.perform { [context] in
            ZMUser.selfUser(in: context)
        }
    }

    public func fetchUser(
        id: UUID,
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
        id: UUID,
        domain: String? = nil
    ) async -> ZMUser {
        await context.perform { [context] in
            ZMUser.fetchOrCreate(
                with: id,
                domain: domain,
                in: context
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
        let selfUser = await fetchSelfUser()

        await context.perform {
            selfUser.readReceiptsEnabled = isReadReceiptsEnabled
            selfUser.readReceiptsEnabledChangedRemotely = isReadReceiptsEnabledChangedRemotely
        }
    }

    public func isSelfUser(
        id: UUID,
        domain: String?
    ) async throws -> (user: ZMUser, isSelfUser: Bool) {
        let user = try await fetchUser(id: id, domain: domain)

        let isSelfUser = await context.perform {
            user.isSelfUser
        }

        return (user, isSelfUser)
    }

    public func deletePushToken() {
        userDefaults.set(
            nil,
            forKey: DefaultsKeys.pushToken.rawValue
        )
    }

    public func name(
        for user: ZMUser
    ) async -> String? {
        await context.perform {
            user.name
        }
    }

    public func teamName(
        for user: ZMUser
    ) async -> String? {
        await context.perform {
            user.teamName
        }
    }

    public func id(
        for user: ZMUser
    ) async -> UUID {
        await context.perform {
            user.remoteIdentifier
        }
    }

    public func addSelfLegalHoldRequest(
        userID: UUID,
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

    public func fetchOrCreateUsers(
        userIDs: [(id: UUID, domain: String?)]
    ) async -> Set<ZMUser> {

        await context.perform { [context] in

            let users = userIDs.map {
                ZMUser.fetchOrCreate(
                    with: $0.id,
                    domain: $0.domain,
                    in: context
                )
            }

            return Set(users)
        }
    }

    public func cancelSelfUserLegalholdRequest() async {
        let selfUser = await fetchSelfUser()

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

    public func updateSelfUserAnalyticsID(
        analyticsID: String,
        conversation: ZMConversation
    ) async {
        await context.perform { [context] in
            guard conversation.isSelfConversation else {
                return
            }

            ZMUser.selfUser(in: context).analyticsIdentifier = analyticsID
        }
    }

    public func removeUserFromAllConversations(
        id: UUID,
        domain: String?,
        date: Date
    ) async throws {
        try await conversationLocalStore.removeParticipantFromAllGroupConversations(
            participantID: id,
            participantDomain: domain,
            date: date
        )
    }

    public func persistUser(userInfo: NewUserInfo) async {
        let persistedUser = await fetchOrCreateUser(
            id: userInfo.userID.uuid,
            domain: userInfo.userID.domain
        )

        await context.perform {
            guard userInfo.deleted == false else {
                return persistedUser.markAccountAsDeleted(at: Date())
            }

            persistedUser.name = userInfo.name
            persistedUser.handle = userInfo.handle
            persistedUser.teamIdentifier = userInfo.teamID
            persistedUser.accentColorValue = Int16(userInfo.accentID)
            persistedUser.previewProfileAssetIdentifier = userInfo.previewAssetKey
            persistedUser.previewProfileAssetIdentifier = userInfo.completeAssetKey
            persistedUser.emailAddress = userInfo.email
            persistedUser.expiresAt = userInfo.expiresAt
            persistedUser.serviceIdentifier = userInfo.serviceID?.transportString()
            persistedUser.providerIdentifier = userInfo.serviceProvider?.transportString()
            persistedUser.supportedProtocols = userInfo.supportedProtocols ?? [.proteus]
            persistedUser.needsToBeUpdatedFromBackend = false
        }
    }

    // TODO: [WPB-10727] reuse `updateUserMetadata` from mentioned ticket's implementation to avoid code duplication
    public func updateUser(userUpdateInfo: UserUpdateInfo) async {
        let user = await fetchOrCreateUser(
            id: userUpdateInfo.userID
        )

        await context.perform {
            if let name = userUpdateInfo.name {
                user.name = name
            }

            if let email = userUpdateInfo.email {
                user.emailAddress = email
            }

            if let handle = userUpdateInfo.handle {
                user.handle = handle
            }

            if let accentColor = userUpdateInfo.accentColorID {
                user.accentColorValue = Int16(accentColor)
            }

            let assetKeys: Set<String> = [
                ZMUser.previewProfileAssetIdentifierKey,
                ZMUser.completeProfileAssetIdentifierKey
            ]

            /// Do not update assets if user has local modifications: a possible explanation is that if user has local
            /// changes to its assets
            /// we don't want to update them and keep these changes as is until they're synced.
            if !user.hasLocalModifications(forKeys: assetKeys) {
                let previewAssetKey = userUpdateInfo.previewAssetKey

                let completeAssetKey = userUpdateInfo.completeAssetKey

                if let previewAssetKey {
                    user.previewProfileAssetIdentifier = previewAssetKey
                }

                if let completeAssetKey {
                    user.completeProfileAssetIdentifier = completeAssetKey
                }
            }

            user.supportedProtocols = userUpdateInfo.supportedProtocols ?? [.proteus]

            user.isPendingMetadataRefresh = false
        }
    }

    public func selfUserInfo() async -> (id: UUID, clientId: String?) {
        let selfUser = await fetchSelfUser()

        return await context.perform {
            (
                id: selfUser.remoteIdentifier,
                clientId: selfUser.selfClient()?.remoteIdentifier
            )
        }
    }
}
