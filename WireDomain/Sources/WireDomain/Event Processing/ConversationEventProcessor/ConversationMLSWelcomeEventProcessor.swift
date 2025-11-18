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

struct ConversationMLSWelcomeEventProcessor: ConversationMLSWelcomeEventProcessorProtocol {

    enum Failure: Error {
        case conversationNotFound
    }

    let conversationRepository: any ConversationRepositoryProtocol
    let conversationLocalStore: any ConversationLocalStoreProtocol
    let mlsService: any MLSServiceInterface
    let mlsDecryptionService: any MLSDecryptionServiceInterface
    let oneOnOneResolver: any OneOnOneResolverProtocol

    func processEvent(_ event: ConversationMLSWelcomeEvent) async throws {
        let welcomeMessage = event.welcomeMessage
        let conversationID = event.conversationID

        // Decrypts the welcome message which returns the group ID of the conversation we were added to.
        let groupID = try await mlsDecryptionService.processWelcomeMessage(
            welcomeMessage: welcomeMessage,
            context: nil
        )

        // create conversation if needed and it will be sync by worker
        let conversation = await conversationRepository.fetchOrCreateConversation(
            id: conversationID.id,
            domain: conversationID.domain
        )

        // This conversation is now a MLS one so we need to update its group ID and set MLS status to ready..
        await conversationLocalStore.storeMLSConversationEstablished(
            mlsGroupID: groupID,
            conversation: conversation
        )

        // ..and also update/create the related MLS group.
        await conversationLocalStore.updateOrCreateMLSGroup(
            groupID: groupID
        )

        // Ensures we have MLS valid key packages published otherwise the user can’t be added to any new groups.
        await mlsService.uploadKeyPackagesIfNeeded()

        do {
            // We need to resolve the now MLS 1:1 conversation with the other user
            let otherUserQualifiedID = await conversationLocalStore.fetchOtherUserIDInOneOnOneConversation(
                conversation: conversation
            )

            guard let otherUserQualifiedID else {
                return
            }

            try await oneOnOneResolver.resolveOneOnOneConversation(with: otherUserQualifiedID)
            WireLogger.mls.debug("successfully resolved one on one conversation")
        } catch {
            WireLogger.mls.warn("failed to resolve one on one conversation: \(error)")
        }
    }
}
