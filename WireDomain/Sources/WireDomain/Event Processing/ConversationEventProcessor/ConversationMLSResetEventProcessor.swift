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

import WireNetwork
import WireDataModel

struct ConversationMLSResetEventProcessor: ConversationMLSResetEventProcessorProtocol {

    enum Failure: Error {
        case conversationNotFound
    }

    let localStore: any ConversationLocalStoreProtocol
    let mlsService: any MLSServiceInterface
    let conversationLocalStore: any ConversationLocalStoreProtocol

    func processEvent(_ event: ConversationMLSResetEvent) async throws {

        let conversationID = event.conversationID
        
        let oldMLSGroupIDBase64 = event.oldMLSGroupIDBase64
        let newMLSGroupIDBase64 = event.newMLSGroupIDBase64
        guard
            let oldMLSGroupID = MLSGroupID(base64Encoded: oldMLSGroupIDBase64),
            let newMLSGroupID = MLSGroupID(base64Encoded: newMLSGroupIDBase64)
        else {
            // TODO: ADD logs
            return
        }

        guard let localConversation = await localStore.fetchMLSConversation(
            groupID: oldMLSGroupID
        ) else {
            throw Failure.conversationNotFound
        }

        do {
            try await mlsService.wipeGroup(oldMLSGroupID)
        } catch {
            // TODO: ADD logs
        }
        
        await conversationLocalStore.storeMLSConversationPendingJoin(
            newMLSGroupID: newMLSGroupID,
            conversation: localConversation
        )
    }

}
