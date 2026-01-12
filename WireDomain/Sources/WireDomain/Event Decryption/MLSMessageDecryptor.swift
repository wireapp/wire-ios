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

import Foundation
import WireCoreCrypto
import WireDataModel
import WireLogging
import WireNetwork

struct MLSMessageDecryptor: MLSMessageDecryptorProtocol {

    let mlsDecryptionService: any MLSDecryptionServiceInterface
    let conversationLocalStore: any ConversationLocalStoreProtocol

    func decryptedWelcomeMessageEventData(
        from eventData: ConversationMLSWelcomeEvent,
        context: CoreCryptoContextProtocol?
    ) async throws {
        let welcomeMessage = eventData.welcomeMessage
        let conversationID = eventData.conversationID

        let groupID = try await mlsDecryptionService.processWelcomeMessage(
            welcomeMessage: welcomeMessage,
            context: context
        )

        await conversationLocalStore.createMLSConversation(
            conversationID: conversationID.id,
            conversationDomain: conversationID.domain,
            mlsGroupID: groupID
        )
    }

    func decryptedMessageAddEventData(
        from eventData: ConversationMLSMessageAddEvent,
        context: CoreCryptoContextProtocol?
    ) async throws -> ConversationMLSMessageAddEvent {
        let conversationID = eventData.conversationID

        guard let mlsConversation = await conversationLocalStore.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        ) else {
            throw MLSMessageDecryptorError.conversationNotFound
        }

        guard let (mlsGroupID, isMLSReady) = await conversationLocalStore.mlsConversationInfo(
            conversation: mlsConversation
        ) else {
            // MLS conversation should have a group id.
            throw MLSMessageDecryptorError.missingMLSGroupID
        }

        guard isMLSReady else {
            throw MLSMessageDecryptorError.mlsConversationNotReady
        }

        do {
            let decryptionResults = try await decryptMLSMessage(
                message: eventData.message,
                mlsGroupID: mlsGroupID,
                subconversation: eventData.subconversation,
                context: context
            )

            let decryptedMessages = await processMLSMessageDecryptionResults(
                decryptionResults,
                mlsConversation: mlsConversation,
                senderID: eventData.senderID.id,
                senderDomain: eventData.senderID.domain,
                date: eventData.timestamp
            )

            var decryptedEvent = eventData
            decryptedEvent.decryptedMessages = decryptedMessages

            return decryptedEvent
        } catch let error as WireDataModel.MLSDecryptionService.MLSMessageDecryptionError {
            switch error {
            case .wrongEpoch:
                throw MLSMessageDecryptorError.wrongEpoch(mlsGroupID: mlsGroupID)
            default:
                throw error
            }

        }
    }

    private func decryptMLSMessage(
        message: String,
        mlsGroupID: MLSGroupID,
        subconversation: String?,
        context: CoreCryptoContextProtocol?
    ) async throws -> [MLSDecryptResult] {
        let subconvType = subconversation != nil ? SubgroupType(rawValue: subconversation!) : nil

        let results = try await mlsDecryptionService.decrypt(
            message: message,
            for: mlsGroupID,
            subconversationType: subconvType,
            context: context
        )

        if results.isEmpty {
            WireLogger.mls.info(
                "successfully decrypted mls message but no result was returned"
            )

            return []
        }

        return results
    }

    private func processMLSMessageDecryptionResults(
        _ results: [MLSDecryptResult],
        mlsConversation: ZMConversation,
        senderID: UUID,
        senderDomain: String,
        date: Date?
    ) async -> [ConversationMLSMessageAddEvent.DecryptedMessage] {
        var decryptedMessages: [ConversationMLSMessageAddEvent.DecryptedMessage] = []

        for result in results {
            switch result {
            case let .message(decryptedData, senderClientID):
                let mlsDecryptedMessage = decryptedData.base64EncodedString()
                decryptedMessages.append(
                    .init(
                        message: mlsDecryptedMessage,
                        senderClientID: senderClientID
                    )
                )

            case let .proposal(commitDelay):
                await conversationLocalStore.updateCommitPendingProposal(
                    date: date ?? .now,
                    for: mlsConversation,
                    commitDelay: commitDelay
                )
            }
        }

        return decryptedMessages
    }

}
