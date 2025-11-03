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

import Foundation
import WireDataModel
import WireFoundation
import WireLegacyLogging
import WireNetwork

public final class UserRepository: UserRepositoryProtocol {

    // MARK: - Properties

    private let usersAPI: any UsersAPI
    private let selfUserAPI: any SelfUserAPI
    private let conversationLabelsRepository: any ConversationLabelsRepositoryProtocol
    private let userLocalStore: any UserLocalStoreProtocol

    private let pullSelfUserSync: PullSelfUserSync
    private let pullKnownUsersSync: PullKnownUsersSync

    // MARK: - Object lifecycle

    public init(
        usersAPI: any UsersAPI,
        selfUserAPI: any SelfUserAPI,
        conversationLabelsRepository: any ConversationLabelsRepositoryProtocol,
        userLocalStore: any UserLocalStoreProtocol
    ) {
        self.usersAPI = usersAPI
        self.selfUserAPI = selfUserAPI
        self.conversationLabelsRepository = conversationLabelsRepository
        self.userLocalStore = userLocalStore
        self.pullSelfUserSync = PullSelfUserSync(
            api: selfUserAPI,
            store: userLocalStore
        )
        self.pullKnownUsersSync = PullKnownUsersSync(
            api: usersAPI,
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

    public func pullKnownUsers() async throws {
        try await pullKnownUsersSync.pull()
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

            await userLocalStore.removeUserFromAllConversations(
                id: id,
                domain: domain,
                date: date
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

    public func selfUserInfo() async -> (id: UUID, clientId: String?) {
        await userLocalStore.selfUserInfo()
    }
}
