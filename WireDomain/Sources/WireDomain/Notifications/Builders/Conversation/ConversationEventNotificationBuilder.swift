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

struct ConversationEventNotificationBuilder {

    enum Failure: Error {
        case failedToDecryptMLSMessage
        case failedToDecryptProteusMessage
    }
    
    let validator: ConversationEventNotificationBuilder.Validator
    let callKitNotificationBuilder: CallKitNotificationBuilder
    let callNotificationBuilder: CallNotificationBuilder
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
            event: event
        )
        
        guard canDisplayNotification else {
            return nil
        }
        
        switch event {
        case let .mlsMessageAdd(mlsMessageEvent):
            let decryptedMessage = mlsMessageEvent.decryptedMessages.first?.message

            let genericMessage = try decryptMessage(
                decryptedMessage: decryptedMessage,
                isProteus: false
            )

            let callKitNotification = await callKitNotificationBuilder.buildContent(
                calling: genericMessage.calling,
                conversationID: mlsMessageEvent.conversationID,
                senderID: mlsMessageEvent.senderID
            )
            
            let callNotification = await callNotificationBuilder.buildContent(
                calling: genericMessage.calling,
                at: mlsMessageEvent.timestamp,
                conversationID: mlsMessageEvent.conversationID,
                senderID: mlsMessageEvent.senderID
            )
            
            // First, let's try to return a call notification with CallKit.
            // If not, try fallback to regular push notification builder.
            // Else, this is not a call.
            
            if let callKitNotification {
                return callKitNotification
            } else if let callNotification {
                return callNotification
            } else {
                return nil
            }

        case let .proteusMessageAdd(proteusMessageEvent):
            let decryptedMessage = proteusMessageEvent.message.decryptedMessage
            let external = proteusMessageEvent.externalData?.encryptedMessage

            let genericMessage = try decryptMessage(
                decryptedMessage: decryptedMessage,
                external: external
            )

            let callKitNotification = await callKitNotificationBuilder.buildContent(
                calling: genericMessage.calling,
                conversationID: proteusMessageEvent.conversationID,
                senderID: proteusMessageEvent.senderID
            )
            
            let callNotification = await callNotificationBuilder.buildContent(
                calling: genericMessage.calling,
                at: proteusMessageEvent.timestamp,
                conversationID: proteusMessageEvent.conversationID,
                senderID: proteusMessageEvent.senderID
            )
            
            if let callKitNotification {
                return callKitNotification
            } else if let callNotification {
                return callNotification
            } else {
                return nil
            }

        case let .memberLeave(memberLeaveEvent):
            let removedUserIDs = Set(memberLeaveEvent.removedUserIDs.compactMap(\.uuid))

            return await conversationMemberLeaveEventNotificationBuilder.buildContent(
                removedUserIDs: removedUserIDs,
                conversationID: memberLeaveEvent.conversationID,
                senderID: memberLeaveEvent.senderID
            )

        case let .memberJoin(memberJoinEvent):
            let addedUserIDs = Set(memberJoinEvent.members.compactMap(\.id))

            return await conversationMemberJoinEventNotificationBuilder.buildContent(
                addedUserIDs: addedUserIDs,
                conversationID: memberJoinEvent.conversationID,
                senderID: memberJoinEvent.senderID
            )

        case let .create(conversationCreateEvent):

            return await conversationCreateEventNotificationBuilder.buildContent(
                conversationID: conversationCreateEvent.conversationID,
                senderID: conversationCreateEvent.senderID
            )

        case let .delete(conversationDeleteEvent):

            return await conversationDeleteEventNotificationBuilder.buildContent(
                conversationID: conversationDeleteEvent.conversationID,
                senderID: conversationDeleteEvent.senderID
            )

        case let .messageTimerUpdate(messageTimerUpdateEvent):

            return await conversationMessageTimerUpdateEventNotificationBuilder.buildContent(
                newTimer: messageTimerUpdateEvent.newTimer,
                conversationID: messageTimerUpdateEvent.conversationID,
                senderID: messageTimerUpdateEvent.senderID
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
        
        func validate(event: ConversationEvent) async -> Bool {
            let conversation = await conversationLocalStore.fetchOrCreateConversation(
                id: event.conversationID.uuid,
                domain: event.conversationID.domain
            )

            // Validation criteria

            let conversationMutedMessages = await conversationLocalStore.conversationMutedMessageTypesIncludingAvailability(
                conversation
            )

            let isConversationMuted = conversationMutedMessages != .none

            let isSelfUser = try? await userLocalStore.isSelfUser(
                id: event.senderID.uuid,
                domain: event.senderID.domain
            ).isSelfUser

            let eventTimeStamp = event.timestamp
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
