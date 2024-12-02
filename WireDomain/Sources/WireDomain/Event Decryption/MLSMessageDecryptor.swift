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
/// Decrypt MLS messages.
protocol MLSMessageDecryptorProtocol {

    /// Decrypt a MLS message.
    ///
    /// - Parameter eventData: A payload containing the encrypted message.
    /// - Returns: The payload containing the decrypted message.

    func decryptedEventData(
        from eventData: ConversationMLSMessageAddEvent
    ) async throws -> ConversationMLSMessageAddEvent

}

struct MLSMessageDecryptor: MLSMessageDecryptorProtocol {

    let mlsDecryptionService: any MLSDecryptionServiceInterface
    let mlsService: any MLSServiceInterface
    let conversationLocalStore: any ConversationLocalStoreProtocol

    func decryptedEventData(
        from eventData: ConversationMLSMessageAddEvent
    ) async throws -> ConversationMLSMessageAddEvent {
        let conversationID = eventData.conversationID

        guard let mlsConversation = await conversationLocalStore.fetchConversation(
            id: conversationID.uuid,
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

        let decryptionResults = await decryptMLSMessage(
            message: eventData.message,
            mlsGroupID: mlsGroupID,
            subconversation: eventData.subconversation
        )

        let decryptedMessages = await processMLSMessageDecryptionResults(
            decryptionResults,
            mlsConversation: mlsConversation,
            senderID: eventData.senderID.uuid,
            senderDomain: eventData.senderID.domain,
            date: eventData.timestamp
        )

        var decryptedEvent = eventData
        decryptedEvent.decryptedMessages = decryptedMessages

        return decryptedEvent
    }

    private func decryptMLSMessage(
        message: String,
        mlsGroupID: MLSGroupID,
        subconversation: String?
    ) async -> [MLSDecryptResult] {
        do {
            let subconvType = subconversation != nil ? SubgroupType(rawValue: subconversation!) : nil

            let results = try await mlsDecryptionService.decrypt(
                message: message,
                for: mlsGroupID,
                subconversationType: subconvType
            )

            if results.isEmpty {
                WireLogger.mls.info(
                    "successfully decrypted mls message but no result was returned"
                )

                return []
            }

            return results

        } catch {
            WireLogger.mls.error(
                "failed to decrypt mls message: \(String(describing: error))"
            )

            return []
        }
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
            case .message(let decryptedData, let senderClientID):
                let mlsDecryptedMessage = decryptedData.base64EncodedString()
                decryptedMessages.append(
                    .init(
                        message: mlsDecryptedMessage,
                        senderClientID: senderClientID
                    )
                )

            case .proposal(let commitDelay):
                await conversationLocalStore.commitPendingProposals(
                    conversation: mlsConversation,
                    date: date ?? .now,
                    commitDelay: commitDelay
                )
            }
        }

        return decryptedMessages
    }

}
