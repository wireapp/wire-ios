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
import WireNetwork

public final class UserLocalStore: UserLocalStoreProtocol {

    enum DefaultsKeys: String {
        case pushToken = "PushToken"
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let messageLocalStore: any MessageLocalStoreProtocol
    private let userDefaults: UserDefaults

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        messageLocalStore: any MessageLocalStoreProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.context = context
        self.userDefaults = userDefaults
        self.messageLocalStore = messageLocalStore
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
        try await context.perform { [context] in
            let fetchRequest = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
            fetchRequest.propertiesToFetch = ["remoteIdentifier_data", "domain"]
            let knownUsers = try context.fetch(fetchRequest)
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

    public func updateSelfUserSupportedProtocols(supportedProtocols: Set<WireDataModel.MessageProtocol>) async {
        await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)
            selfUser.supportedProtocols = supportedProtocols
            context.saveOrRollback()
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

    public func updateSelfUserTrackingID(
        trackingID: UUID,
        conversation: ZMConversation
    ) async {
        await context.perform { [context] in
            guard conversation.isSelfConversation else {
                return
            }

            ZMUser.selfUser(in: context).trackingID = trackingID
        }
    }

    public func removeUserFromAllConversations(
        id: UUID,
        domain: String?,
        date: Date
    ) async {
        let user = await context.perform { [context] in
            ZMUser.fetchOrCreate(
                with: id,
                domain: domain,
                in: context
            )
        }

        let allGroupConversations = await context.perform {
            // swiftformat:disable:next redundantProperty
            let allGroupConversations: [ZMConversation] = user.participantRoles.compactMap {
                guard $0.conversation?.conversationType == .group else {
                    return nil
                }

                return $0.conversation
            }

            return allGroupConversations
        }

        for conversation in allGroupConversations {
            let (userTeam, isTeamMember, conversationTeam, conversationID, conversationDomain) = await context.perform {
                (
                    user.team,
                    user.isTeamMember,
                    conversation.team,
                    conversation.remoteIdentifier as UUID,
                    conversation.domain
                )
            }

            if isTeamMember, conversationTeam == userTeam {

                let systemMessageType: SystemMessageType = .teamMemberRemoved(
                    member: (id, domain),
                    date: date
                )

                await messageLocalStore.addSystemMessage(
                    messageType: systemMessageType,
                    conversationID: conversationID,
                    conversationDomain: conversationDomain
                )

            } else {

                let systemMessageType: SystemMessageType = .participantsRemoved(
                    participants: [(id, domain)],
                    sender: (id, domain),
                    date: date
                )

                await messageLocalStore.addSystemMessage(
                    messageType: systemMessageType,
                    conversationID: conversationID,
                    conversationDomain: conversationDomain
                )
            }

            await context.perform {
                conversation.removeParticipantAndUpdateConversationState(
                    user: user,
                    initiatingUser: user
                )
            }
        }
    }

    public func persistUser(userInfo: NewUserInfo) async {
        let persistedUser = await fetchOrCreateUser(
            id: userInfo.userID.uuid,
            domain: userInfo.userID.domain
        )

        await context.perform {
            guard !userInfo.isDeleted else {
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
            // `type` only exists in v12 or later
            let fallbackType: TypeOfUser = persistedUser.serviceIdentifier != nil ? .bot : .regular
            persistedUser.type = userInfo.type ?? fallbackType
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

    public func fetchSelfUserAvailability() async -> Availability {
        await context.perform { [context] in
            ZMUser.selfUser(in: context).availability
        }
    }

    public func updateUser(with userID: WireDataModel.QualifiedID, availability: Availability) async {
        await context.perform { [context] in
            let user = ZMUser.fetch(with: userID.uuid, domain: userID.domain, in: context)
            user?.updateAvailability(availability)
            context.saveOrRollback()
        }
    }

    public func fetchSelfUserSupportedProtocols() async -> Set<WireDataModel.MessageProtocol> {
        await context.perform { [context] in
            ZMUser.selfUser(in: context).supportedProtocols
        }
    }

}
