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
/// A local store dedicated to conversations.
/// The store uses the injected context to perform `CoreData` operations on conversations objects.
///
/// Conversations can have different types with specific actions for each one of them.
///
/// Check out some of the private methods in `ConversationLocalStore` for a general context.
///
/// Check out the Confluence page for full details [here](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/20514628/Conversations)
public protocol ConversationLocalStoreProtocol {

    /// Fetches or creates a conversation locally.
    /// - Parameters:
    ///     - id: The conversation ID.
    ///     - domain: The conversation domain if any.
    /// - Returns: The `ZMConversation` found or created locally.

    func fetchOrCreateConversation(
        with id: UUID,
        domain: String?
    ) async -> ZMConversation

    /// Stores a given conversation locally.
    /// - Parameter conversation: The conversation to store locally.
    /// - Parameter isFederationEnabled: A flag indicating whether a `Federation` is enabled.

    func storeConversation(
        _ conversation: WireAPI.Conversation,
        isFederationEnabled: Bool
    ) async

    /// Stores a flag indicating whether a conversation requires an update from backend.
    /// - Parameter needsUpdate: A flag indicated whether the qualified conversation needs to be updated from backend.
    /// - Parameter qualifiedId: The conversation qualified ID.

    func storeConversationNeedsBackendUpdate(
        _ needsUpdate: Bool,
        qualifiedId: WireAPI.QualifiedID
    ) async

    /// Stores a given failed conversation locally.
    /// - Parameter qualifiedId: The conversation qualified ID.

    func storeFailedConversation(
        withQualifiedId qualifiedId: WireAPI.QualifiedID
    ) async

    /// Fetches a MLS conversation locally.
    ///
    /// - parameters:
    ///     - groupID: The MLS group ID object.
    ///
    /// - returns : A MLS conversation.

    func fetchMLSConversation(
        with groupID: WireDataModel.MLSGroupID
    ) async -> ZMConversation?

    /// Removes a given user from all conversations.
    ///
    /// - parameters:
    ///     - user: The user to remove from the conversations.
    ///     - date: The date the user was removed from the conversations.

    func removeParticipantFromAllConversations(
        user: ZMUser,
        date: Date
    ) async

    /// Adds a participant to a conversation.
    /// - Parameters:
    ///     - user: The user to add.
    ///     - role: The role of the user.
    ///     - conversation: The conversation to add the user to.

    func addParticipant(
        _ user: ZMUser,
        withRole role: String,
        to conversation: ZMConversation
    ) async

    /// Updates the member muted and archived status.
    /// - Parameters:
    ///     - mutedStatusInfo: The mute status and reference date.
    ///     - archivedStatusInfo: The archived status and reference date.
    ///     - localConversation: The conversation to update statuses for.

    func updateMemberStatus(
        mutedStatusInfo: (status: Int?, referenceDate: Date?),
        archivedStatusInfo: (status: Bool?, referenceDate: Date?),
        for localConversation: ZMConversation
    ) async

}

public final class ConversationLocalStore: ConversationLocalStoreProtocol {

    enum Error: Swift.Error {
        case noBackendConversationID
    }

    // MARK: - Properties

    let context: NSManagedObjectContext
    let mlsService: MLSServiceInterface?
    let eventProcessingLogger = WireLogger.eventProcessing
    let mlsLogger = WireLogger.mls
    let updateEventLogger = WireLogger.updateEvent

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        mlsService: MLSServiceInterface?
    ) {
        self.context = context
        self.mlsService = mlsService
    }

    // MARK: - Public

    public func updateMemberStatus(
        mutedStatusInfo: (status: Int?, referenceDate: Date?),
        archivedStatusInfo: (status: Bool?, referenceDate: Date?),
        for localConversation: ZMConversation
    ) async {
        await context.perform {
            let mutedStatus = mutedStatusInfo.status
            let mutedReference = mutedStatusInfo.referenceDate

            if let mutedStatus, let mutedReference {
                localConversation.updateMutedStatus(
                    status: Int32(mutedStatus),
                    referenceDate: mutedReference
                )
            }

            let archivedStatus = archivedStatusInfo.status
            let archivedReference = archivedStatusInfo.referenceDate

            if let archivedStatus, let archivedReference {
                localConversation.updateArchivedStatus(
                    archived: archivedStatus,
                    referenceDate: archivedReference
                )
            }
        }
    }

    public func fetchOrCreateConversation(
        with id: UUID,
        domain: String?
    ) async -> ZMConversation {
        await context.perform { [context] in
            ZMConversation.fetchOrCreate(
                with: id,
                domain: domain,
                in: context
            )
        }
    }

    public func addParticipant(
        _ user: ZMUser,
        withRole role: String,
        to conversation: ZMConversation
    ) async {
        await context.perform { [context] in
            let role = Role.fetchOrCreateRole(
                with: role,
                teamOrConversation: .matching(conversation),
                in: context
            )

            conversation.addParticipantAndUpdateConversationState(
                user: user,
                role: role
            )
        }
    }

    public func storeConversation(
        _ conversation: WireAPI.Conversation,
        isFederationEnabled: Bool
    ) async {
        guard let conversationType = conversation.type else {
            return
        }

        Flow.createGroup.checkpoint(
            description: "create ZMConversation of type \(conversationType))"
        )

        guard let id = conversation.id ?? conversation.qualifiedID?.uuid else {
            if conversationType == .group {
                Flow.createGroup.fail(
                    Error.noBackendConversationID
                )
            }

            eventProcessingLogger.error(
                "Missing conversationID in \(conversationType) conversation payload, aborting..."
            )

            return
        }

        switch conversationType {
        case .group:
            await updateOrCreateGroupConversation(
                remoteConversation: conversation,
                remoteConversationID: id,
                isFederationEnabled: isFederationEnabled
            )

        case .`self`:
            await updateOrCreateSelfConversation(
                remoteConversation: conversation,
                remoteConversationID: id,
                isFederationEnabled: isFederationEnabled
            )

        case .connection:
            /// Conversations are of type `connection` while the connection
            /// is pending.
            await updateOrCreateConnectionConversation(
                remoteConversation: conversation,
                remoteConversationID: id,
                isFederationEnabled: isFederationEnabled
            )

        case .oneOnOne:
            /// Conversations are of type `oneOnOne` when the connection
            /// is accepted.
            await updateOrCreateOneToOneConversation(
                remoteConversation: conversation,
                remoteConversationID: id,
                isFederationEnabled: isFederationEnabled
            )
        }
    }

    public func storeConversationNeedsBackendUpdate(
        _ needsUpdate: Bool,
        qualifiedId: WireAPI.QualifiedID
    ) async {
        await context.perform { [context] in
            let conversation = ZMConversation.fetch(
                with: qualifiedId.uuid,
                domain: qualifiedId.domain,
                in: context
            )

            conversation?.needsToBeUpdatedFromBackend = needsUpdate
        }
    }

    public func storeFailedConversation(
        withQualifiedId qualifiedId: WireAPI.QualifiedID
    ) async {
        let conversation = await fetchOrCreateConversation(
            with: qualifiedId.uuid,
            domain: qualifiedId.domain
        )

        await context.perform {
            conversation.isPendingMetadataRefresh = true
            conversation.needsToBeUpdatedFromBackend = true
        }
    }

    public func fetchMLSConversation(
        with groupID: WireDataModel.MLSGroupID
    ) async -> ZMConversation? {
        await context.perform { [context] in
            ZMConversation.fetch(
                with: groupID,
                in: context
            )
        }
    }

    public func removeParticipantFromAllConversations(
        user: ZMUser,
        date: Date
    ) async {
        await context.perform {
            let allGroupConversations: [ZMConversation] = user.participantRoles.compactMap {
                guard $0.conversation?.conversationType == .group else {
                    return nil
                }
                return $0.conversation
            }

            for conversation in allGroupConversations {
                if user.isTeamMember, conversation.team == user.team {
                    conversation.appendTeamMemberRemovedSystemMessage(
                        user: user,
                        at: date
                    )
                } else {
                    conversation.appendParticipantRemovedSystemMessage(
                        user: user,
                        at: date
                    )
                }

                conversation.removeParticipantAndUpdateConversationState(
                    user: user,
                    initiatingUser: user
                )
            }
        }
    }

    // MARK: - Private

    /// Updates or creates a conversation of type `connection` locally.
    ///
    /// See <doc:conversations> and <doc:federation> for more information.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter removeConversationID: The conversation ID received from backend.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateConnectionConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID,
        isFederationEnabled: Bool
    ) async {
        let conversation = await fetchOrCreateConversation(
            with: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        )

        await context.perform { [self] in
            conversation.conversationType = .connection

            commonUpdate(
                from: remoteConversation,
                for: conversation,
                isFederationEnabled: isFederationEnabled
            )

            assignMessageProtocol(
                from: remoteConversation,
                for: conversation
            )

            updateConversationStatus(
                from: remoteConversation,
                for: conversation
            )

            conversation.needsToBeUpdatedFromBackend = false
            conversation.isPendingInitialFetch = false
        }

        guard let selfMember = remoteConversation.members?.selfMember else {
            return
        }

        let mutedStatusInfo = (selfMember.mutedStatus, selfMember.mutedReference)
        let archivedStatusInfo = (selfMember.archived, selfMember.archivedReference)

        await updateMemberStatus(
            mutedStatusInfo: mutedStatusInfo,
            archivedStatusInfo: archivedStatusInfo,
            for: conversation
        )
    }

    /// Updates or creates a conversation of type `self` locally.
    ///
    /// See <doc:conversations> and <doc:federation> for more information.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter removeConversationID: The conversation ID received from backend.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateSelfConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID,
        isFederationEnabled: Bool
    ) async {
        let conversation = await fetchOrCreateConversation(
            with: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        )

        let mlsGroupID = await context.perform {
            conversation.mlsGroupID
        }

        await context.perform { [self] in
            conversation.conversationType = .`self`
            conversation.isPendingMetadataRefresh = false

            commonUpdate(
                from: remoteConversation,
                for: conversation,
                isFederationEnabled: isFederationEnabled
            )

            updateMessageProtocol(
                from: remoteConversation,
                for: conversation
            )

            conversation.isPendingInitialFetch = false
            conversation.needsToBeUpdatedFromBackend = false
        }

        if mlsGroupID != nil {
            do {
                try await createOrJoinSelfConversation(from: conversation)
            } catch {
                mlsLogger.error(
                    "createOrJoinSelfConversation threw error: \(String(reflecting: error))"
                )
            }
        }
    }

    /// Updates or creates a conversation of type `group` locally.
    ///
    /// See <doc:conversations> and <doc:federation> for more information.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter removeConversationID: The conversation ID received from backend.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateGroupConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID,
        isFederationEnabled: Bool
    ) async {
        var isInitialFetch = false

        let conversation = await fetchOrCreateConversation(
            with: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        )

        await context.perform { [self] in
            isInitialFetch = conversation.isPendingInitialFetch

            conversation.conversationType = .group
            conversation.remoteIdentifier = remoteConversationID
            conversation.isPendingMetadataRefresh = false
            conversation.isPendingInitialFetch = false

            commonUpdate(
                from: remoteConversation,
                for: conversation,
                isFederationEnabled: isFederationEnabled
            )

            updateConversationStatus(
                from: remoteConversation,
                for: conversation
            )

            if isInitialFetch {
                assignMessageProtocol(
                    from: remoteConversation,
                    for: conversation
                )
            } else {
                updateMessageProtocol(
                    from: remoteConversation,
                    for: conversation
                )
            }

            Flow.createGroup.checkpoint(
                description: "conversation created remote id: \(conversation.remoteIdentifier?.safeForLoggingDescription ?? "<nil>")"
            )
        }

        if let selfMember = remoteConversation.members?.selfMember {
            let mutedStatusInfo = (selfMember.mutedStatus, selfMember.mutedReference)
            let archivedStatusInfo = (selfMember.archived, selfMember.archivedReference)

            await updateMemberStatus(
                mutedStatusInfo: mutedStatusInfo,
                archivedStatusInfo: archivedStatusInfo,
                for: conversation
            )
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

                Flow.createGroup.checkpoint(
                    description: "new system message for conversation inserted"
                )
            }

            /// If we discover this group is actually a fake one on one,
            /// then we should link the one on one user.
            linkOneOnOneUserIfNeeded(for: conversation)
        }
    }

    /// Updates or creates a conversation of type `1:1` locally.
    ///
    /// See <doc:conversations> and <doc:federation> for more information.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter removeConversationID: The conversation ID received from backend.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateOneToOneConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID,
        isFederationEnabled: Bool
    ) async {
        guard let conversationTypeRawValue = remoteConversation.type?.rawValue else {
            return
        }

        let conversation = await fetchOrCreateConversation(
            with: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        )

        await context.perform { [self] in
            let conversationType = BackendConversationType.clientConversationType(
                rawValue: conversationTypeRawValue
            )

            if conversation.oneOnOneUser?.connection?.status == .sent {
                conversation.conversationType = .connection
            } else {
                conversation.conversationType = conversationType
            }

            assignMessageProtocol(
                from: remoteConversation,
                for: conversation
            )

            commonUpdate(
                from: remoteConversation,
                for: conversation,
                isFederationEnabled: isFederationEnabled
            )

            linkOneOnOneUserIfNeeded(for: conversation)

            conversation.needsToBeUpdatedFromBackend = false
            conversation.isPendingInitialFetch = false

            updateConversationStatus(
                from: remoteConversation,
                for: conversation
            )

            if let otherUser = conversation.localParticipantsExcludingSelf.first {
                conversation.isPendingMetadataRefresh = otherUser.isPendingMetadataRefresh
            }
        }

        guard let selfMember = remoteConversation.members?.selfMember else {
            return
        }

        let mutedStatusInfo = (selfMember.mutedStatus, selfMember.mutedReference)
        let archivedStatusInfo = (selfMember.archived, selfMember.archivedReference)

        await updateMemberStatus(
            mutedStatusInfo: mutedStatusInfo,
            archivedStatusInfo: archivedStatusInfo,
            for: conversation
        )
    }

    /// A common update method for all conversations received, no matter the type of the conversation.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter localConversation: The local conversation to update.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func commonUpdate(
        from remoteConversation: WireAPI.Conversation,
        for localConversation: ZMConversation,
        isFederationEnabled: Bool
    ) {
        updateAttributes(
            from: remoteConversation,
            for: localConversation,
            isFederationEnabled: isFederationEnabled
        )

        updateMetadata(
            from: remoteConversation,
            for: localConversation
        )

        updateMembers(
            from: remoteConversation,
            for: localConversation
        )

        updateConversationTimestamps(
            for: localConversation
        )
    }
}
