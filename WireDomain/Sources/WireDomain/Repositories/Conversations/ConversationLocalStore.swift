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
import WireAPI
import WireDataModel

// sourcery: AutoMockable
/// A local store dedicated to conversation related work.
/// The store uses the injected context to perform CoreData operations
/// on conversations objects.
public protocol ConversationLocalStoreProtocol {

    func storeConversation(_ conversation: WireAPI.Conversation, withId id: UUID) async throws

    func deleteConversation(
        withQualifiedId qualifiedId: WireAPI.QualifiedID
    ) async throws

    func removeSelfUserFromConversation(
        withQualifiedId qualifiedId: WireAPI.QualifiedID
    ) async

    func storeNeedsToBeUpdatedFromBackend(
        requiresUpdate: Bool,
        conversation: WireAPI.QualifiedID
    ) async

    func storeFailedConversationStatus(_ failedConversation: WireAPI.QualifiedID) async
}

final class ConversationLocalStore: ConversationLocalStoreProtocol {

    // MARK: - Properties

    let context: NSManagedObjectContext

    // MARK: - Object lifecycle

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Public

    func storeConversation(_ conversation: WireAPI.Conversation, withId id: UUID) async throws {

        switch conversation.type {
        case .group:
            await updateOrCreateGroupConversation(
                remoteConversation: conversation,
                remoteConversationID: id
            )

        case .`self`:
            try await updateOrCreateSelfConversation(
                remoteConversation: conversation,
                remoteConversationID: id
            )

        case .connection:
            /// Conversations are of type `connection` while the connection
            /// is pending.
            await updateOrCreateConnectionConversation(
                remoteConversation: conversation,
                remoteConversationID: id
            )

        case .oneOnOne:
            /// Conversations are of type `oneOnOne` when the connection
            /// is accepted.
            await updateOrCreateOneToOneConversation(
                remoteConversation: conversation,
                remoteConversationID: id
            )

        default:
            /// conversation type is nil
            return
        }
    }

    func deleteConversation(
        withQualifiedId qualifiedId: WireAPI.QualifiedID
    ) async throws {
        let conversation = await context.perform { [context] in
            let conversation = ZMConversation.fetch(
                with: qualifiedId.uuid,
                domain: qualifiedId.domain,
                in: context
            )

            return conversation?.conversationType == .group ? conversation : nil
        }

        guard let conversation else { return }

        conversation.isDeletedRemotely = true

        let (mlsService, groupID) = if conversation.messageProtocol == .mls {
            (MLSServiceInterface?.none, MLSGroupID?.none)
        } else {
            (context.mlsService, conversation.mlsGroupID)
        }

        guard let mlsService, let groupID else {
            return
        }

        try await mlsService.wipeGroup(groupID)
    }

    func removeSelfUserFromConversation(
        withQualifiedId qualifiedId: WireAPI.QualifiedID
    ) async {
        await context.perform { [context] in

            let conversation = ZMConversation.fetch(
                with: qualifiedId.uuid,
                domain: qualifiedId.domain,
                in: context
            )

            guard let conversation,
                  conversation.conversationType == .group,
                  conversation.isSelfAnActiveMember
            else {
                return
            }

            let selfUser = ZMUser.selfUser(in: context)

            conversation.removeParticipantAndUpdateConversationState(
                user: selfUser,
                initiatingUser: selfUser
            )
        }
    }

    func storeNeedsToBeUpdatedFromBackend(
        requiresUpdate: Bool,
        conversation: WireAPI.QualifiedID
    ) async {
        await context.perform { [context] in
            let conversation = ZMConversation.fetch(
                with: conversation.uuid,
                domain: conversation.domain,
                in: context
            )

            conversation?.needsToBeUpdatedFromBackend = requiresUpdate
        }
    }

    func storeFailedConversationStatus(_ failedConversation: WireAPI.QualifiedID) async {
        await context.perform { [context] in
            let conversation = ZMConversation.fetchOrCreate(
                with: failedConversation.uuid,
                domain: failedConversation.domain,
                in: context
            )

            conversation.isPendingMetadataRefresh = true
            conversation.needsToBeUpdatedFromBackend = true
        }
    }

    // MARK: - Private

    private func updateOrCreateConnectionConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID
    ) async {
        await fetchOrCreateConversation(
            conversationID: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        ) { [self] in
            $0.conversationType = .connection

            commonUpdate(from: remoteConversation, for: $0)
            assignMessageProtocol(from: remoteConversation, for: $0)
            updateConversationStatus(from: remoteConversation, for: $0)

            $0.needsToBeUpdatedFromBackend = false
            $0.isPendingInitialFetch = false

            return ($0, $0.mlsGroupID)
        }
    }

    private func updateOrCreateSelfConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID
    ) async throws {
        let (conversation, mlsGroupID) = await fetchOrCreateConversation(
            conversationID: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        ) { [self] in

            $0.conversationType = .`self`
            $0.isPendingMetadataRefresh = false

            commonUpdate(from: remoteConversation, for: $0)
            updateMessageProtocol(from: remoteConversation, for: $0)

            $0.isPendingInitialFetch = false
            $0.needsToBeUpdatedFromBackend = false

            return ($0, $0.mlsGroupID)
        }

        if mlsGroupID != nil {
            try await createOrJoinSelfConversation(from: conversation)
        }
    }

    private func updateOrCreateGroupConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID
    ) async {
        var isInitialFetch = false

        let (conversation, _) = await fetchOrCreateConversation(
            conversationID: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        ) { [self] in

            isInitialFetch = $0.isPendingInitialFetch

            $0.conversationType = .group
            $0.remoteIdentifier = remoteConversationID
            $0.isPendingMetadataRefresh = false
            $0.isPendingInitialFetch = false

            commonUpdate(from: remoteConversation, for: $0)
            updateConversationStatus(from: remoteConversation, for: $0)

            isInitialFetch ?
                assignMessageProtocol(from: remoteConversation, for: $0) :
                updateMessageProtocol(from: remoteConversation, for: $0)

            return ($0, $0.mlsGroupID)
        }

        await updateMLSStatus(from: remoteConversation, for: conversation)

        await context.perform { [self] in
            if isInitialFetch {
                /// we just got a new conversation, we display new conversation header
                conversation.appendNewConversationSystemMessage(
                    at: .distantPast,
                    users: conversation.localParticipants
                )

                /// Slow synced conversations should be considered read from the start
                conversation.lastReadServerTimeStamp = conversation.lastModifiedDate
            }

            /// If we discover this group is actually a fake one on one,
            /// then we should link the one on one user.
            linkOneOnOneUserIfNeeded(for: conversation)
        }
    }

    private func updateOrCreateOneToOneConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID
    ) async {
        guard let conversationTypeRawValue = remoteConversation.type?.rawValue else {
            return
        }

        await fetchOrCreateConversation(
            conversationID: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        ) { [self] in
            let conversationType = BackendConversationType.clientConversationType(
                rawValue: conversationTypeRawValue
            )

            if $0.oneOnOneUser?.connection?.status == .sent {
                $0.conversationType = .connection
            } else {
                $0.conversationType = conversationType
            }

            assignMessageProtocol(from: remoteConversation, for: $0)
            commonUpdate(from: remoteConversation, for: $0)
            updateConversationStatus(from: remoteConversation, for: $0)
            linkOneOnOneUserIfNeeded(for: $0)

            $0.needsToBeUpdatedFromBackend = false
            $0.isPendingInitialFetch = false

            if let otherUser = $0.localParticipantsExcludingSelf.first {
                $0.isPendingMetadataRefresh = otherUser.isPendingMetadataRefresh
            }

            return ($0, $0.mlsGroupID)
        }
    }

    @discardableResult
    private func fetchOrCreateConversation(
        conversationID: UUID,
        domain: String?,
        handler: @escaping (ZMConversation) -> (ZMConversation, MLSGroupID?)
    ) async -> (ZMConversation, MLSGroupID?) {
        await context.perform { [self] in
            let conversation = ZMConversation.fetchOrCreate(
                with: conversationID,
                domain: domain,
                in: context
            )

            return handler(conversation)
        }
    }

    private func commonUpdate(
        from remoteConversation: WireAPI.Conversation,
        for localConversation: ZMConversation
    ) {
        updateAttributes(from: remoteConversation, for: localConversation)
        updateMetadata(from: remoteConversation, for: localConversation)
        updateMembers(from: remoteConversation, for: localConversation)
        updateConversationTimestamps(for: localConversation)
    }

}
