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

struct AppVersionMigration_4_8_0: AppVersionMigration {

    let version: SemanticVersion = "4.8.0"
    let contextProvider: ContextProvider
    let conversationLocalStore: (any ConversationLocalStoreProtocol)?
    let messageLocalStore: (any MessageLocalStoreProtocol)?
    let protobufMessageProcessor: (any ConversationProtobufMessageProcessorProtocol)?

    func perform() async throws {

        let context = contextProvider.syncContext
        let unknownMessages = try await context.perform {
            let fetchRequest = UnknownMessage.fetchRequest()
            let unknownMessages = try context.fetch(fetchRequest)
            return unknownMessages.map { ($0, $0.payload) }
        }

        for (unknownMessage, payload) in unknownMessages {
            guard let payload, let message = GenericMessage(from: payload, validate: false) else {
                continue
            }

// TODO: finish implementation

            // new sync

            if let conversationLocalStore, let messageLocalStore, let protobufMessageProcessor {
            /*
            await conversationLocalStore.updateSecurityLevelAfterReceivingMessage(
                conversation: conversation,
                genericMessage: genericMessage,
                date: date
            )

            await conversationLocalStore.addParticipantIfNeeded(
                participantID: senderID.id,
                participantDomain: senderID.domain,
                in: conversation,
                date: date.addingTimeInterval(-0.01)
            )

            try await protobufMessageProcessor.processProtobufMessage(
                genericMessage,
                conversation: conversation,
                conversationID: conversationID,
                senderID: senderID,
                senderClientID: messageSenderClientID,
                date: date,
                eventMessage: "unknown-message"
            )
             */

            } else if false {
                // TODO: old sync?
            } else {
                continue
            }

            await context.perform {
                context.delete(unknownMessage)
            }
        }
    }

}
