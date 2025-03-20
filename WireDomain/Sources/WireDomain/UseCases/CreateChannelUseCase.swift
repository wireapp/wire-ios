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

import WireAPI
import WireLogging
import WireDataModel

/// Channels are MLS conversations which belong to a team and have a name.
public struct CreateChannelUseCase {
    
    public enum Failure: Error {
        case missingSelfClientID
        case missingConversationID
        case conversationNotFound
        case failedToCreateChannel(Error)
        case missingLegalholdConsent
        case nonFederatingDomains
        case notConnected
    }
    
    private let api: ConversationsAPI
    private let store: ConversationLocalStoreProtocol
    private let context: NSManagedObjectContext
    private let isFederationEnabled: Bool
    private let logger: WireLogger = .conversation

    public init(
        api: ConversationsAPI,
        store: ConversationLocalStoreProtocol,
        context: NSManagedObjectContext,
        isFederationEnabled: Bool
    ) {
        self.api = api
        self.store = store
        self.context = context
        self.isFederationEnabled = isFederationEnabled
    }
    
    public func invoke(
        teamID: UUID,
        name: String?,
        users: Set<ZMUser>,
        accessMode: Set<WireAPI.ConversationAccessMode>,
        accessRoles: Set<WireAPI.ConversationAccessRole>,
        enableReceipts: Bool
    ) async throws -> ZMConversation {
        let (selfClientID,
             qualifiedUserIds,
             unqualifiedUserIds,
             usersExcludingSelfUser) = try await context.perform {
            let selfUser = ZMUser.selfUser(in: context)

            guard let selfClientID = selfUser.selfClient()?.remoteIdentifier else {
                throw Failure.missingSelfClientID
            }

            let usersExcludingSelfUser = users.filter { !$0.isSelfUser }
            let qualifiedUserIDs: [WireAPI.QualifiedID]
            let unqualifiedUserIDs: [UUID]

            if let ids = usersExcludingSelfUser.qualifiedUserIDs {
                qualifiedUserIDs = ids.toAPIModel()
                unqualifiedUserIDs = []
            } else {
                qualifiedUserIDs = []
                unqualifiedUserIDs = usersExcludingSelfUser.compactMap(\.remoteIdentifier)
            }
            
            return (selfClientID,
                    qualifiedUserIDs,
                    unqualifiedUserIDs,
                    usersExcludingSelfUser)
        }
        
        do {
            let remoteConversation = try await api.createGroupConversation(
                groupType: .channel,
                messageProtocol: .mls,
                creatorClientID: selfClientID,
                qualifiedUserIDs: qualifiedUserIds,
                unqualifiedUserIDs: unqualifiedUserIds,
                name: name,
                accessMode: accessMode,
                accessRoles: accessRoles,
                legacyAccessRole: nil,
                teamID: teamID,
                isReadReceiptsEnabled: enableReceipts
            )
            
            let localConversation = try await createConversationLocally(
                remoteConversation
            )
            
            try await setupMLS(
                for: localConversation,
                with: users
            )
            
            return localConversation
            
        } catch {
            switch error {
            case let apiError as ConversationsAPIError:
                switch apiError {
                case .notConnected:
                    await context.perform {
                        users.forEach { $0.needsToBeUpdatedFromBackend = true }
                        context.enqueueDelayedSave()
                    }
                    
                    throw Failure.notConnected
                case .missingLegalHoldConsent:
                    throw Failure.missingLegalholdConsent
                case .nonFederatingBackends:
                    throw Failure.nonFederatingDomains
                default:
                    throw Failure.failedToCreateChannel(error)
                }

            default:
                throw Failure.failedToCreateChannel(error)
            }
        }

    }
    
    private func setupMLS(
        for conversation: ZMConversation,
        with participants: Set<ZMUser>
    ) async throws {
        let (mlsGroupID, mlsService) = await context.perform {
            (conversation.mlsGroupID, context.mlsService)
        }
        
        guard let mlsGroupID, let mlsService else { return }
        
        let ciphersuite = try await mlsService.createGroup(
            for: mlsGroupID,
            removalKeys: nil
        )
        
        await context.perform {
            // Self user is creator, so we don't need to process a welcome message
            conversation.mlsStatus = .ready
            conversation.ciphersuite = ciphersuite
            context.saveOrRollback()
        }
        
        // TODO: Factor out logic from `ConversationParticipantsService` and `MLSConversationParticipantsServiceInterface` to add MLS participants.
    }
    
    private func createConversationLocally(
        _ conversation: WireAPI.Conversation
    ) async throws -> ZMConversation {
        await store.storeConversation(
            conversation.toDomainModel(),
            timestamp: .now,
            isFederationEnabled: isFederationEnabled,
            isMLSEnabled: true
        )
        
        let qualifiedID = conversation.qualifiedID?.uuid
        guard let conversationID = conversation.id ?? qualifiedID else {
            throw Failure.missingConversationID
        }
        
        let conversationDomain = conversation.qualifiedID?.domain
        
        let localConversation = await store.fetchConversation(
            id: conversationID,
            domain: conversationDomain
        )
        
        // Conversation should be stored locally
        guard let localConversation else {
            throw Failure.conversationNotFound
        }
        
        return localConversation
    }
}
