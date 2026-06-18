//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireNetwork

// sourcery: AutoMockable
public protocol UpdateGroupDescriptionUseCaseProtocol: Sendable {

    func invoke(description: String, conversationObjectID: NSManagedObjectID) async throws -> Void

}

// MARK: - UpdateBackendMetadataUseCase

public struct UpdateGroupDescriptionUseCase: UpdateGroupDescriptionUseCaseProtocol, @unchecked Sendable {
    
    let mlsProvider: MLSProvider
    let context: NSManagedObjectContext
    private let conversationsApi: any ConversationsAPI
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let messageLocalStore: any MessageLocalStoreProtocol
    
    init(mlsProvider: MLSProvider, context: NSManagedObjectContext, conversationsApi: any ConversationsAPI, conversationLocalStore: any ConversationLocalStoreProtocol, messageLocalStore: any MessageLocalStoreProtocol) {
        self.mlsProvider = mlsProvider
        self.context = context
        self.conversationsApi = conversationsApi
        self.conversationLocalStore = conversationLocalStore
        self.messageLocalStore = messageLocalStore
    }
    
    public func invoke(description: String, conversationObjectID: NSManagedObjectID) async throws {
        typealias GroupMetadataInfo = (
            groupID: MLSGroupID?,
            qualifiedID: WireDataModel.QualifiedID?
        )
        
        guard let selfUserID = await context.perform({ [context] in
            ZMUser.selfUser(in: context).qualifiedID
        }) else {
            return
        }
        
        let groupMetadataInfo: GroupMetadataInfo = try await context.perform { [context] in
            let conversation = try context.existingObject(
                with: conversationObjectID
            ) as? ZMConversation

            return (
                conversation?.mlsGroupID,
                conversation?.qualifiedID
            )
        }
        
        guard
            let groupID = groupMetadataInfo.groupID,
            let qualifiedID = groupMetadataInfo.qualifiedID else {
            return
        }
                
        let (secret, epoch) = try await mlsProvider.service.groupMetadataSecret(groupID: groupID)
        let ciphertext = Data(description.utf8).zmEncryptPrefixingIV(key: secret.copyBytes())
        
        let currentVersion = (try? await conversationsApi.getConversationDescription(
            conversationID: qualifiedID.toAPIModel()).version) ?? 0
                
        // api push ciphertext to backend
        try await conversationsApi.updateConversationDescripton(
            conversationID: qualifiedID.toAPIModel(),
            currentVersion: currentVersion,
            ciphertext: ciphertext.base64EncodedString()
        )
        
        guard let conversation = await context.perform ({ [context] in
            try? context.existingObject(with: conversationObjectID) as? ZMConversation
        }) else {
            return
        }
            
        await conversationLocalStore.storeConversation(
            description: description,
            for: conversation,
            version: currentVersion + 1,
            epoch: Int(epoch),
            secret: secret.copyBytes()
        )
        
        let systemMessage = SystemMessageType.conversationDescriptionChanged(
            sender: (selfUserID.uuid, selfUserID.domain),
            date: Date(),
            description: description
        )
        
        await messageLocalStore.addSystemMessage(
            messageType: systemMessage,
            conversationID: qualifiedID.uuid,
            conversationDomain: qualifiedID.domain)
        
        
    }
}
