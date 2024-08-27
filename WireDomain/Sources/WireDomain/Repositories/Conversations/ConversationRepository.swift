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
/// Facilitate access to conversations related domain objects.
public protocol ConversationRepositoryProtocol {

    /// Fetch and persist all conversations

    func pullConversations() async throws

}

public final class ConversationRepository: ConversationRepositoryProtocol {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    private let conversationsAPI: any ConversationsAPI
    private var localStore: ConversationLocalStore
    private let domain: String

    
    // MARK: -  Object lifecycle
    
    public init(
        context: NSManagedObjectContext,
        conversationsAPI: any ConversationsAPI,
        domain: String
    ) {
        self.context = context
        self.conversationsAPI = conversationsAPI
        self.domain = domain
        self.localStore = ConversationLocalStore(context: context)
    }
    
    // MARK: - Public
    
    public func pullConversations() async throws {
        let result = try await conversationsAPI.getLegacyConversationIdentifiers()
        let uuids = try await result.reduce([UUID](), +)
        let qualifiedIds = uuids.map { WireAPI.QualifiedID(uuid: $0, domain: domain) }
        let conversationList = try await conversationsAPI.getConversations(for: qualifiedIds)
        
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for conversation in conversationList.found {
                taskGroup.addTask { [self] in
                    try await storeConversation(conversation, isSlowSync: true)
                }
            }
        }
        
    }
    
    
    // MARK: - Private
    
    private func storeConversation(_ conversation: WireAPI.Conversation, isSlowSync: Bool) async throws {
        switch conversation.type {
        case .group:
            
            await updateOrCreateGroupConversation(
                from: conversation,
                serverTimestamp: .now, 
                isSlowSync: true
            )

        case .`self`:
            
            await updateOrCreateSelfConversation(
                from: conversation,
                serverTimestamp: .now
            )

        case .connection:
            /// Conversations are of type `connection` while the connection
            /// is pending.
            await updateOrCreateConnectionConversation(
                from: conversation,
                serverTimestamp: .now
            )

        case .oneOnOne:
            /// Conversations are of type `oneOnOne` when the connection
            /// is accepted.
            await self.updateOrCreateOneToOneConversation(
                from: conversation,
                serverTimestamp: .now
            )

        default:
            return
        }
        
    }
    
    func updateOrCreateConnectionConversation(
        from payload: WireAPI.Conversation,
        serverTimestamp: Date
    ) async {
        guard let conversationID = payload.id ?? payload.qualifiedID?.uuid else {
            return
        }

        return await context.perform { [self] in
            let conversation = ZMConversation.fetchOrCreate(
                with: conversationID,
                domain: payload.qualifiedID?.domain,
                in: context
            )
            
            conversation.conversationType = .connection
            localStore.updateAttributes(from: payload, for: conversation)
            localStore.assignMessageProtocol(from: payload, for: conversation)
            localStore.updateMetadata(from: payload, for: conversation)
            localStore.updateMembers(from: payload, for: conversation)
            localStore.updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
            localStore.updateConversationStatus(from: payload, for: conversation)

            conversation.needsToBeUpdatedFromBackend = false
            conversation.isPendingInitialFetch = false
        }
    }
    
    func updateOrCreateSelfConversation(
        from payload: WireAPI.Conversation,
        serverTimestamp: Date
    ) async {
        guard let conversationID = payload.id ?? payload.qualifiedID?.uuid else {
            return
        }

        let (conversation, mlsGroupID) = await context.perform { [self] in
            let conversation = ZMConversation.fetchOrCreate(
                with: conversationID,
                domain: payload.qualifiedID?.domain,
                in: context
            )

            conversation.conversationType = .`self`
            conversation.isPendingMetadataRefresh = false
            localStore.updateAttributes(from: payload, for: conversation)
            localStore.updateMetadata(from: payload, for: conversation)
            localStore.updateMembers(from: payload, for: conversation)
            localStore.updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
            localStore.updateMessageProtocol(from: payload, for: conversation)

            conversation.isPendingInitialFetch = false
            conversation.needsToBeUpdatedFromBackend = false

            return (conversation, conversation.mlsGroupID)
        }

        if mlsGroupID != nil {
            do {
                try await localStore.createOrJoinSelfConversation(from: conversation)
            } catch {
                WireLogger.mls.error("createOrJoinSelfConversation threw error: \(String(reflecting: error))")
            }
        }
    }
    
    private func updateOrCreateGroupConversation(
        from payload: WireAPI.Conversation,
        serverTimestamp: Date,
        isSlowSync: Bool
    ) async {
        guard let conversationID = payload.id ?? payload.qualifiedID?.uuid else {
            fatalError()
        }

        var isInitialFetch = false
        let conversation = await context.perform { [self] in

            let conversation = ZMConversation.fetchOrCreate(
                with: conversationID,
                domain: payload.qualifiedID?.domain,
                in: context
            )

            isInitialFetch = conversation.isPendingInitialFetch

            conversation.conversationType = .group
            conversation.remoteIdentifier = conversationID
            conversation.isPendingMetadataRefresh = false
            conversation.isPendingInitialFetch = false
            localStore.updateAttributes(from: payload, for: conversation)
            localStore.updateMetadata(from: payload, for: conversation)
            localStore.updateMembers(from: payload, for: conversation)
            localStore.updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
            localStore.updateConversationStatus(from: payload, for: conversation)

            if isInitialFetch {
                localStore.assignMessageProtocol(from: payload, for: conversation)
            } else {
                localStore.updateMessageProtocol(from: payload, for: conversation)
            }

            return conversation
        }

        await localStore.updateMLSStatus(from: payload, for: conversation, isSlowSync: isSlowSync)
        
        await context.perform { [self] in
            if isInitialFetch {
                /// we just got a new conversation, we display new conversation header
                conversation.appendNewConversationSystemMessage(
                    at: .distantPast,
                    users: conversation.localParticipants
                )

                if isSlowSync {
                    /// Slow synced conversations should be considered read from the start
                    conversation.lastReadServerTimeStamp = conversation.lastModifiedDate
                }
                
            }

            /// If we discover this group is actually a fake one on one,
            /// then we should link the one on one user.
            localStore.linkOneOnOneUserIfNeeded(for: conversation)
        }
    }
    
    func updateOrCreateOneToOneConversation(
        from payload: WireAPI.Conversation,
        serverTimestamp: Date
    ) async {
        guard
            let conversationID = payload.id ?? payload.qualifiedID?.uuid,
            let conversationTypeRawValue = payload.type?.rawValue
        else {
            fatalError()
        }
        
        await context.perform { [self] in
            let conversation = ZMConversation.fetchOrCreate(
                with: conversationID,
                domain: payload.qualifiedID?.domain,
                in: context
            )
            
            let conversationType = BackendConversationType.clientConversationType(
                rawValue: conversationTypeRawValue
            )
            
            if conversation.oneOnOneUser?.connection?.status == .sent {
                conversation.conversationType = .connection
            } else {
                conversation.conversationType = conversationType
            }
            
            localStore.updateAttributes(from: payload, for: conversation)
            localStore.assignMessageProtocol(from: payload, for: conversation)
            localStore.updateMetadata(from: payload, for: conversation)
            localStore.updateMembers(from: payload, for: conversation)
            localStore.updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
            localStore.updateConversationStatus(from: payload, for: conversation)
            localStore.linkOneOnOneUserIfNeeded(for: conversation)

            conversation.needsToBeUpdatedFromBackend = false
            conversation.isPendingInitialFetch = false

            if let otherUser = conversation.localParticipantsExcludingSelf.first {
                conversation.isPendingMetadataRefresh = otherUser.isPendingMetadataRefresh
            }
        }

    }
    
}


