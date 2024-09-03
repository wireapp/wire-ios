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
}

public final class ConversationLocalStore: ConversationLocalStoreProtocol {
    
    enum Error: Swift.Error {
        case noBackendConversationID
    }

    // MARK: - Properties

    let context: NSManagedObjectContext
    let eventProcessingLogger = WireLogger.eventProcessing
    let mlsLogger = WireLogger.mls
    let updateEventLogger = WireLogger.updateEvent

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext
    ) {
        self.context = context
    }

    // MARK: - Public

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
        await fetchOrCreateConversation(
            conversationID: qualifiedId.uuid,
            domain: qualifiedId.domain
        ) {
            $0.isPendingMetadataRefresh = true
            $0.needsToBeUpdatedFromBackend = true

            return ($0, $0.mlsGroupID)
        }
    }

    // MARK: - Private

    /// Updates or creates a conversation of type `connection` locally.
    ///
    /// __What is a `connection` conversation ?__
    ///
    /// In order for two users to become connected, one of them performs a connection request and the other one accepts it.
    /// When the connection is accepted, the other user joins the conversation.
    /// Connections are like “friend requests” on other products.
    ///
    /// __What is a `Federation` ?__
    ///
    /// Businesses that use Wire in their organization have 2 choices, either deploy their teams in the Wire cloud or install an on-prem backend.
    /// On-prem backends are isolated islands that before could not communicate with users from other on-prem islands or Wire cloud users.
    /// Federation allows islands to be connected. Communication can be established between users from different backends the same way as on a single backend.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter removeConversationID: The conversation ID received from backend.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateConnectionConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID,
        isFederationEnabled: Bool
    ) async {
        await fetchOrCreateConversation(
            conversationID: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        ) { [self] in
            $0.conversationType = .connection

            commonUpdate(from: remoteConversation, for: $0, isFederationEnabled: isFederationEnabled)
            assignMessageProtocol(from: remoteConversation, for: $0)
            updateConversationStatus(from: remoteConversation, for: $0)

            $0.needsToBeUpdatedFromBackend = false
            $0.isPendingInitialFetch = false

            return ($0, $0.mlsGroupID)
        }
    }

    /// Updates or creates a conversation of type `self` locally.
    ///
    /// __What is a `self` conversation ?__
    ///
    /// The self conversation is a conversation with exactly one user. This is each user’s private conversation. 
    /// Every user has exactly one self-conversation. The identifier of the self-conversation for one user is the same as the user identifier.
    /// The self conversation is not displayed anywhere in the UI. This conversation is used to send messages to all devices of a given user. 
    /// If a device needs to synchronize something with all the other devices of this user, it will send a message here.
    ///
    /// __What is `Federation` ?__
    ///
    /// Businesses that use Wire in their organization have 2 choices, either deploy their teams in the Wire cloud or install an on-prem backend.
    /// On-prem backends are isolated islands that before could not communicate with users from other on-prem islands or Wire cloud users.
    /// Federation allows islands to be connected. Communication can be established between users from different backends the same way as on a single backend.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter removeConversationID: The conversation ID received from backend.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.
    
    private func updateOrCreateSelfConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID,
        isFederationEnabled: Bool
    ) async {
        let (conversation, mlsGroupID) = await fetchOrCreateConversation(
            conversationID: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        ) { [self] in

            $0.conversationType = .`self`
            $0.isPendingMetadataRefresh = false

            commonUpdate(from: remoteConversation, for: $0, isFederationEnabled: isFederationEnabled)
            updateMessageProtocol(from: remoteConversation, for: $0)

            $0.isPendingInitialFetch = false
            $0.needsToBeUpdatedFromBackend = false

            return ($0, $0.mlsGroupID)
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
    /// __What is a `group` conversation ?__
    ///
    /// A group conversation can contain a group of users.
    /// All members in a group are assigned a role, either when the group is created or by the member who adds a new user to the group.
    /// The roles define which actions a user is allowed to perform within the group.
    /// There are two pre-defined roles: `wire_admin` and `wire_member`
    /// The creator of a group will by default be assigned the `wire_admin` role.
    /// In addition to these pre-defined roles a team can potentially define new roles with a different set of actions.
    ///
    /// __What is `Federation` ?__
    ///
    /// Businesses that use Wire in their organization have 2 choices, either deploy their teams in the Wire cloud or install an on-prem backend.
    /// On-prem backends are isolated islands that before could not communicate with users from other on-prem islands or Wire cloud users.
    /// Federation allows islands to be connected. Communication can be established between users from different backends the same way as on a single backend.
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

        let (conversation, _) = await fetchOrCreateConversation(
            conversationID: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        ) { [self] in

            isInitialFetch = $0.isPendingInitialFetch

            $0.conversationType = .group
            $0.remoteIdentifier = remoteConversationID
            $0.isPendingMetadataRefresh = false
            $0.isPendingInitialFetch = false

            commonUpdate(from: remoteConversation, for: $0, isFederationEnabled: isFederationEnabled)
            updateConversationStatus(from: remoteConversation, for: $0)

            isInitialFetch ?
                assignMessageProtocol(from: remoteConversation, for: $0) :
                updateMessageProtocol(from: remoteConversation, for: $0)
            
            Flow.createGroup.checkpoint(
                description: "conversation created remote id: \($0.remoteIdentifier?.safeForLoggingDescription ?? "<nil>")"
            )

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
    /// __What is a `1:1` conversation ?__
    ///
    /// The implementation differs between Proteus-based conversations and MLS-based conversations.
    ///
    /// *Proteus (not in a team)*
    ///
    /// When a connection is created it also creates an associated conversation. As the name implies a 1:1 conversation is always between two users which can't be changed.
    ///
    /// *Proteus (in a team)*
    ///
    /// A team 1:1 is a conversation between two users that belong to the same team.
    ///
    /// *MLS (whether in team or not in team)*
    ///
    /// MLS 1:1 conversations always implicitly exist when there’s a connection between two users, either via a connection or indirectly when the two users belong to the same team.
    /// Therefore the conversation doesn’t need to be created but the underlying MLS group needs to be established.
    ///
    /// __What is `Federation` ?__
    ///
    /// Businesses that use Wire in their organization have 2 choices, either deploy their teams in the Wire cloud or install an on-prem backend.
    /// On-prem backends are isolated islands that before could not communicate with users from other on-prem islands or Wire cloud users.
    /// Federation allows islands to be connected. Communication can be established between users from different backends the same way as on a single backend.
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
            commonUpdate(from: remoteConversation, for: $0, isFederationEnabled: isFederationEnabled)
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

    /// A helper method (for all conversations) that fetches or creates a conversation locally and executes a completion block.
    ///
    /// - Parameter conversationID: The conversation ID to fetch or create the local conversation from.
    /// - Parameter domain: The domain to fetch or create the conversation from.
    /// - Parameter handler: A completion block that takes a `ZMConversation` as argument and returns
    ///   a `ZMConversation` and an optional `MLSGroupID`.
    ///
    ///  Since storage logic can be different according to the conversation type, the method provides a completion block
    ///  with the conversation fetched or created locally.

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

}
