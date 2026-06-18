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

struct ConversationDescriptionUpdateEventProcessor: ConversationDescriptionUpdateEventProcessorProtocol {

    let conversationLocalStore: any ConversationLocalStoreProtocol
    let messageLocalStore: any MessageLocalStoreProtocol
    let mlsService: any MLSServiceInterface

    func processEvent(_ event: ConversationDescriptionUpdateEvent) async throws {
        let userID = event.senderID
        let timestamp = event.timestamp
        let conversationID = event.conversationID
        let localConversation = await conversationLocalStore.fetchOrCreateConversation(id: conversationID.id, domain: conversationID.domain)
        let ciphertext = event.ciphertext.base64DecodedData!
        
        guard let groupID = await conversationLocalStore.mlsConversationInfo(conversation: localConversation)?.mlsGroupID else {
            return
        }
        
        
        let (_, currentVersion) = await conversationLocalStore.conversationDescription(conversation: localConversation)
        
        guard event.version != currentVersion else {
            return
        }
        
        let (secret, epoch) = try await mlsService.groupMetadataSecret(groupID: groupID)
        let descriptionRaw = ciphertext.zmDecryptPrefixedIV(key: secret.copyBytes())
        
        guard let description = String(data: descriptionRaw, encoding: .utf8) else {
            return
        }

        await conversationLocalStore.storeConversation(
            description: description,
            for: localConversation,
            version: event.version,
            epoch: Int(epoch),
            secret: secret.copyBytes()
        )
        
        let messageType: SystemMessageType = .conversationDescriptionChanged(
            sender: (userID.id, userID.domain),
            date: timestamp,
            description: description)

        await messageLocalStore.addSystemMessage(
            messageType: messageType,
            conversationID: conversationID.id,
            conversationDomain: conversationID.domain
        )
    }

}
