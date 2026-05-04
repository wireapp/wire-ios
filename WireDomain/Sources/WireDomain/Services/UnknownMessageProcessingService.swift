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
import GenericMessageProtocol
import WireDataModel
import WireLogging

/// Service responsible for processing stored unknown messages when the app is updated
/// and new protobuf message types become available.
public final class UnknownMessageProcessingService {

    private let contextProvider: ContextProvider
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let protobufMessageProcessor: any ConversationProtobufMessageProcessorProtocol
    private let logger = WireLogger(tag: "UnknownMessageProcessing")

    public init(
        contextProvider: ContextProvider,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        protobufMessageProcessor: any ConversationProtobufMessageProcessorProtocol
    ) {
        self.contextProvider = contextProvider
        self.conversationLocalStore = conversationLocalStore
        self.protobufMessageProcessor = protobufMessageProcessor
    }

    /// Processes all stored unknown messages by attempting to decode them with the current protobuf definitions.
    /// Successfully processed messages are converted to their proper message types and the unknown message is deleted.
    /// Messages that still cannot be decoded remain in the database for future processing.
    public func processStoredUnknownMessages() async throws {
        let context = contextProvider.syncContext

        let unknownMessages = try await context.perform {
            let fetchRequest = UnknownMessage.fetchRequest()
            let unknownMessages = try context.fetch(fetchRequest)
            return unknownMessages.map { ($0, $0.payload) }
        }

        logger.info("Found \(unknownMessages.count) stored unknown messages to process")

        var processedCount = 0
        var failedCount = 0

        for (unknownMessage, payload) in unknownMessages {
            do {
                let wasProcessed = try await processUnknownMessage(unknownMessage, payload: payload)
                if wasProcessed {
                    processedCount += 1
                } else {
                    failedCount += 1
                }
            } catch {
                logger.error("Failed to process unknown message: \(error)")
                failedCount += 1
            }
        }

        try await context.perform {
            if context.hasChanges {
                try context.save()
            }
        }

        logger.info("Unknown message processing completed: \(processedCount) processed, \(failedCount) failed")
    }

    /// Processes a single unknown message by attempting to decode its payload.
    /// Returns true if the message was successfully processed and deleted, false if it still cannot be decoded.
    private func processUnknownMessage(_ unknownMessage: UnknownMessage, payload: Data?) async throws -> Bool {
        guard let payload else {
            logger.warn("Unknown message has no payload, skipping")
            return false
        }

        // Attempt to decode the payload with current protobuf definitions
        guard let genericMessage = GenericMessage(from: payload, validate: false) else {
            logger.warn("Still cannot decode unknown message payload, keeping for future processing")
            return false
        }

        // Check if the message now has content (i.e., can be processed)
        guard genericMessage.content != nil else {
            logger.warn("Unknown message still has no content, keeping for future processing")
            return false
        }

        let context = contextProvider.syncContext
        let messageInfo = await context.perform {
            (
                unknownMessage.conversation,
                unknownMessage.conversation?.qualifiedID,
                unknownMessage.sender?.qualifiedID,
                unknownMessage.senderClientID,
                unknownMessage.eventTimestamp ?? unknownMessage.serverTimestamp ?? Date()
            )
        }

        let (conversation, conversationID, senderID, senderClientID, eventTimestamp) = messageInfo

        guard let conversation,
              let conversationID,
              let senderID else {
            logger.warn("Unknown message missing required context (conversation/sender), deleting")
            await deleteUnknownMessage(unknownMessage)
            return true
        }

        logger.info("Successfully decoded unknown message, processing as \(type(of: genericMessage.content))")

        // Update security level and add participant if needed
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

        // Process the protobuf message
        try await protobufMessageProcessor.processProtobufMessage(
            genericMessage,
            conversation: conversation,
            conversationID: .init(id: conversationID.uuid, domain: conversationID.domain),
            senderID: .init(id: senderID.uuid, domain: senderID.domain),
            senderClientID: senderClientID,
            date: eventTimestamp,
            eventMessage: "unknown-message-retry"
        )

        // Delete the unknown message since it's now been processed
        await deleteUnknownMessage(unknownMessage)
        return true
    }

    /// Deletes an unknown message from the database
    private func deleteUnknownMessage(_ unknownMessage: UnknownMessage) async {
        let context = contextProvider.syncContext
        await context.perform {
            context.delete(unknownMessage)
        }
    }

}
