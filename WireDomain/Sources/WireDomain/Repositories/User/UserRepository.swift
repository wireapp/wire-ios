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
import WireLogging

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
        id: UUID,
        domain: String?
    ) async -> ZMUser

    /// Removes user push token from storage.

    func removePushToken()

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
        userID: UUID,
        clientID: String,
        lastPrekey: Prekey
    ) async

    /// Disables user legal hold.

    func disableUserLegalHold() async

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
        id: UUID,
        domain: String?,
        at date: Date
    ) async throws

    /// Indicates whether a given user is a self user.
    /// - Parameters:
    ///     - id: The user id.
    ///     - domain: The user domain if any.
    /// - Returns: Whether the user is self user.

    func isSelfUser(
        id: UUID,
        domain: String?
    ) async throws -> Bool

    /// Fetches all user IDs that have a one on one conversation
    /// - returns: A list of users' qualified IDs.

    func fetchAllUserIDsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID]

}

public final class UserRepository: UserRepositoryProtocol {

    // MARK: - Properties

    private let usersAPI: any UsersAPI
    private let selfUserAPI: any SelfUserAPI
    private let conversationLabelsRepository: any ConversationLabelsRepositoryProtocol
    private let conversationRepository: any ConversationRepositoryProtocol
    private let userLocalStore: any UserLocalStoreProtocol

    private let pullSelfUserSync: PullSelfUserSync

    // MARK: - Object lifecycle

    public init(
        usersAPI: any UsersAPI,
        selfUserAPI: any SelfUserAPI,
        conversationLabelsRepository: any ConversationLabelsRepositoryProtocol,
        conversationRepository: ConversationRepositoryProtocol,
        userLocalStore: any UserLocalStoreProtocol
    ) {
        self.usersAPI = usersAPI
        self.selfUserAPI = selfUserAPI
        self.conversationLabelsRepository = conversationLabelsRepository
        self.conversationRepository = conversationRepository
        self.userLocalStore = userLocalStore
        self.pullSelfUserSync = PullSelfUserSync(
            api: selfUserAPI,
            store: userLocalStore
        )
    }

    // MARK: - Public

    public func pullSelfUser() async throws {
        try await pullSelfUserSync.pull()
    }

    public func fetchSelfUser() async -> ZMUser {
        await userLocalStore.fetchSelfUser()
    }

    public func fetchOrCreateUser(
        id: UUID,
        domain: String? = nil
    ) async -> ZMUser {
        await userLocalStore.fetchOrCreateUser(
            id: id,
            domain: domain
        )
    }

    public func fetchUser(
        id: UUID,
        domain: String?
    ) async throws -> ZMUser {
        try await userLocalStore.fetchUser(
            id: id,
            domain: domain
        )
    }

    public func pushSelfSupportedProtocols(
        _ supportedProtocols: Set<WireAPI.MessageProtocol>
    ) async throws {
        try await selfUserAPI.pushSupportedProtocols(supportedProtocols)
    }

    public func pullKnownUsers() async throws {
        let knownUserIDs: [WireDataModel.QualifiedID]

        do {
            knownUserIDs = try await userLocalStore.fetchUsersQualifiedIDs()
        } catch {
            throw UserRepositoryError.failedToCollectKnownUsers(error)
        }

        try await pullUsers(userIDs: knownUserIDs)
    }

    public func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws {
        do {
            let userList = try await usersAPI.getUsers(userIDs: userIDs.toAPIModel())

            for user in userList.found {
                await userLocalStore.persistUser(userInfo: user.toDomainModel())
            }

        } catch {
            throw UserRepositoryError.failedToFetchRemotely(error)
        }
    }

    public func updateUser(
        from event: UserUpdateEvent
    ) async {
        await userLocalStore.updateUser(
            userUpdateInfo: event.toDomainModel()
        )
    }

    public func removePushToken() {
        userLocalStore.deletePushToken()
    }

    public func addLegalHoldRequest(
        userID: UUID,
        clientID: String,
        lastPrekey: Prekey
    ) async {
        // prepare data for the local store
        guard let mappedPrekey = lastPrekey.toDomainModel() else {
            return WireLogger.eventProcessing.error(
                "Invalid legal hold request payload: invalid base64 encoded key \(lastPrekey.base64EncodedKey)"
            )
        }

        await userLocalStore.addSelfLegalHoldRequest(
            userID: userID,
            clientID: clientID,
            lastPrekey: mappedPrekey
        )
    }

    public func disableUserLegalHold() async {
        await userLocalStore.cancelSelfUserLegalholdRequest()
    }

    public func updateUserProperty(_ userProperty: UserProperty) async throws {
        switch userProperty {
        case let .areReadReceiptsEnabled(isEnabled):

            await userLocalStore.updateSelfUserReadReceipts(
                isReadReceiptsEnabled: isEnabled,
                isReadReceiptsEnabledChangedRemotely: true
            )

        case let .conversationLabels(conversationLabels):
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

            await userLocalStore.updateSelfUserReadReceipts(
                isReadReceiptsEnabled: false,
                isReadReceiptsEnabledChangedRemotely: true
            )

        case .wireTypingIndicatorMode:
            // TODO: [WPB-726] feature not implemented yet
            break

        case .labels:
            // Already handled with `user.properties-set` event (adding new labels and removing old ones)
            // see `ConversationLabelsRepository`
            break
        }
    }

    public func deleteUserAccount(
        id: UUID,
        domain: String?,
        at date: Date
    ) async throws {
        let (user, isSelfUser) = try await userLocalStore.isSelfUser(
            id: id,
            domain: domain
        )

        if isSelfUser {
            userLocalStore.postAccountDeletedNotification()
        } else {
            await userLocalStore.markAccountAsDeleted(for: user)

            try await conversationRepository.removeParticipantFromAllGroupConversations(
                participantID: id,
                participantDomain: domain,
                removedAt: date
            )
        }
    }

    public func fetchAllUserIDsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID] {
        try await userLocalStore.fetchAllUserIDsWithOneOnOneConversation()
    }

    public func isSelfUser(
        id: UUID,
        domain: String?
    ) async throws -> Bool {
        let (_, isSelfUser) = try await userLocalStore.isSelfUser(
            id: id,
            domain: domain
        )

        return isSelfUser
    }
}
