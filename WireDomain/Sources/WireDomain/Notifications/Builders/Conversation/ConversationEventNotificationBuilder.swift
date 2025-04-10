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

import UserNotifications
import WireAPI
import WireDataModel

// sourcery: AutoMockable
protocol ConversationEventNotificationBuilderProtocol {
    func buildContent(
        event: ConversationEvent
    ) async throws -> UserNotification?
}

struct ConversationEventNotificationBuilder: ConversationEventNotificationBuilderProtocol {
    
    enum Failure: Error {
        case failedToDecryptMLSMessage
        case failedToDecryptProteusMessage
    }
    
    let validator: ConversationEventNotificationBuilder.Validator
    let conversationCallingEventNotificationBuilder: ConversationCallingEventNotificationBuilder
    let conversationMLSMessageAddEventNotificationBuilder: ConversationMLSMessageAddEventNotificationBuilder
    let conversationProteusMessageAddEventNotificationBuilder: ConversationProteusMessageAddEventNotificationBuilder
    let conversationMemberLeaveEventNotificationBuilder:  ConversationMemberLeaveEventNotificationBuilder
    let conversationMemberJoinEventNotificationBuilder: ConversationMemberJoinEventNotificationBuilder
    let conversationCreateEventNotificationBuilder: ConversationCreateEventNotificationBuilder
    let conversationDeleteEventNotificationBuilder: ConversationDeleteEventNotificationBuilder
    let conversationMessageTimerUpdateEventNotificationBuilder: ConversationMessageTimerUpdateEventNotificationBuilder

    func buildContent(
        event: ConversationEvent
    ) async throws -> UserNotification? {
        let canDisplayNotification = await validator.validate(
            conversationID: event.conversationID,
            senderID: event.senderID,
            time: event.timestamp
        )
        
        guard canDisplayNotification else {
            return nil
        }
        
        switch event {
        case let .mlsMessageAdd(mlsMessageEvent):
            let decryptedMessage = mlsMessageEvent.decryptedMessages.first?.message

            // Decrypt the message.
            let genericMessage = try decryptMessage(
                decryptedMessage: decryptedMessage,
                isProteus: false
            )
            
            // Gets its calling payload.
            let calling = genericMessage.calling
            
            // Builds a calling notification - if there's a call.
            let callingNotification = await conversationCallingEventNotificationBuilder.buildContent(
                calling: calling,
                at: mlsMessageEvent.timestamp,
                conversationID: mlsMessageEvent.conversationID,
                senderID: mlsMessageEvent.senderID
            )
            
            if let callingNotification {
                return callingNotification
            } else {
                // Else, builds the message notification.
                return await conversationMLSMessageAddEventNotificationBuilder.buildContent(
                    event: mlsMessageEvent
                )
            }

        case let .proteusMessageAdd(proteusMessageEvent):
            let decryptedMessage = proteusMessageEvent.message.decryptedMessage
            let external = proteusMessageEvent.externalData?.encryptedMessage

            let genericMessage = try decryptMessage(
                decryptedMessage: decryptedMessage,
                external: external
            )
            
            let calling = genericMessage.calling
            
            let callingNotification = await conversationCallingEventNotificationBuilder.buildContent(
                calling: calling,
                at: proteusMessageEvent.timestamp,
                conversationID: proteusMessageEvent.conversationID,
                senderID: proteusMessageEvent.senderID
            )
            
            if let callingNotification {
                return callingNotification
            } else {
                return await conversationProteusMessageAddEventNotificationBuilder.buildContent(
                    event: proteusMessageEvent
                )
            }

        case let .memberLeave(memberLeaveEvent):

            return await conversationMemberLeaveEventNotificationBuilder.buildContent(
                event: memberLeaveEvent
            )

        case let .memberJoin(memberJoinEvent):

            return await conversationMemberJoinEventNotificationBuilder.buildContent(
                event: memberJoinEvent
            )

        case let .create(conversationCreateEvent):

            return await conversationCreateEventNotificationBuilder.buildContent(
                event: conversationCreateEvent
            )

        case let .delete(conversationDeleteEvent):

            return await conversationDeleteEventNotificationBuilder.buildContent(
                event: conversationDeleteEvent
            )

        case let .messageTimerUpdate(messageTimerUpdateEvent):

            return await conversationMessageTimerUpdateEventNotificationBuilder.buildContent(
                event: messageTimerUpdateEvent
            )

        default:
            return nil
        }
    }

    private func decryptMessage(
        decryptedMessage: String?,
        external: String? = nil,
        isProteus: Bool = true
    ) throws -> GenericMessage {
        guard let decryptedMessage,
              let (genericMessage, _) = ProtobufMessageDecoder.getProtobufMessage(
                  from: decryptedMessage,
                  externalData: external
              ) else {
            throw isProteus ? Failure.failedToDecryptProteusMessage : Failure.failedToDecryptMLSMessage
        }

        return genericMessage
    }
}

extension ConversationEventNotificationBuilder {
    struct Validator {
        let userLocalStore: any UserLocalStoreProtocol
        let conversationLocalStore: any ConversationLocalStoreProtocol
        let messageLocalStore: any MessageLocalStoreProtocol
        
        func validate(
            conversationID: ConversationID,
            senderID: UserID,
            time: Date?
        ) async -> Bool {
            let conversation = await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.uuid,
                domain: conversationID.domain
            )

            let conversationMutedMessages = await conversationLocalStore.conversationMutedMessageTypesIncludingAvailability(
                conversation
            )

            let isConversationMuted = conversationMutedMessages != .none

            let isSelfUser = try? await userLocalStore.isSelfUser(
                id: senderID.uuid,
                domain: senderID.domain
            ).isSelfUser

            let eventTimeStamp = time
            let lastReadTimestamp = await conversationLocalStore.lastReadServerTimestamp(conversation)

            guard let isSelfUser,
                    !isSelfUser,
                  !isConversationMuted else {
                return false
            }

            if let timeStamp = eventTimeStamp,
               let lastRead = lastReadTimestamp, lastRead.compare(timeStamp) != .orderedAscending {
                // don't show notifications that have already been read
                return false
            }

            return true
        }
    }
}
