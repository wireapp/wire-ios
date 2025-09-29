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

import GenericMessageProtocol
import WireDataModel
import WireDomain
import WireNetwork

struct AppVersionMigration_4_8_0: AppVersionMigration {

    let version: SemanticVersion = "4.8.0"
    let contextProvider: ContextProvider
    let conversationLocalStore: (any ConversationLocalStoreProtocol)?
    let protobufMessageProcessor: (any ConversationProtobufMessageProcessorProtocol)?

    func perform() async throws {
        try await processUnknownMessages()
    }

    /// This code will never run, but it is a template for future migrations after the protobuf declaration changes and clients potentially have stored unprocessed events for later re-processing.

    private func processUnknownMessages() async throws {

        let context = contextProvider.syncContext
        let unknownMessages = try await context.perform {
            let fetchRequest = UnknownMessage.fetchRequest()
            let unknownMessages = try context.fetch(fetchRequest)
            return unknownMessages.map { ($0, $0.payload) }
        }

        for (unknownMessage, payload) in unknownMessages {
            guard let payload, let genericMessage = GenericMessage(from: payload, validate: false) else {
                continue
            }

            let (
                conversation,
                conversationID,
                senderID,
                senderClientID,
                eventTimestamp
            ) = await context.perform {
                (
                    unknownMessage.conversation,
                    unknownMessage.conversation?.qualifiedID,
                    unknownMessage.sender?.qualifiedID,
                    unknownMessage.senderClientID,
                    unknownMessage.eventTimestamp
                )
            }

            if
                let conversationLocalStore,
                let protobufMessageProcessor,
                let conversation,
                let conversationID,
                let senderID,
                let eventTimestamp {

                await conversationLocalStore.updateSecurityLevelAfterReceivingMessage(
                    conversation: conversation,
                    genericMessage: genericMessage,
                    date: eventTimestamp
                )

                await conversationLocalStore.addParticipantIfNeeded(
                    participantID: senderID.uuid,
                    participantDomain: senderID.domain,
                    in: conversation,
                    date: eventTimestamp.addingTimeInterval(-0.01)
                )

                try await protobufMessageProcessor.processProtobufMessage(
                    genericMessage,
                    conversation: conversation,
                    conversationID: .init(id: conversationID.uuid, domain: conversationID.domain),
                    senderID: .init(id: senderID.uuid, domain: senderID.domain),
                    senderClientID: senderClientID,
                    date: eventTimestamp,
                    eventMessage: "unknown-message"
                )

            } else {
                continue
            }

            await context.perform {
                context.delete(unknownMessage)
            }
        }
    }

}
