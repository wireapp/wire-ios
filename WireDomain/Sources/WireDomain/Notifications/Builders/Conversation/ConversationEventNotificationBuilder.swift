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

struct ConversationEventNotificationBuilder: NotificationBuilder {

    enum Failure: Error {
        case failedToDecryptMLSMessage
        case failedToDecryptProteusMessage
    }

    private struct Context {
        let senderID: UserID
        let conversationID: ConversationID
        let isSelfUser: Bool
        let isConversationMuted: Bool
        let eventTimeStamp: Date?
        let lastReadTimestamp: Date?
    }

    private let event: ConversationEvent
    private let userLocalStore: any UserLocalStoreProtocol
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let messageLocalStore: any MessageLocalStoreProtocol
    private let context: Context

    init(
        event: ConversationEvent,
        userLocalStore: any UserLocalStoreProtocol,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        messageLocalStore: any MessageLocalStoreProtocol
    ) async {
        self.event = event
        self.userLocalStore = userLocalStore
        self.conversationLocalStore = conversationLocalStore
        self.messageLocalStore = messageLocalStore

        let isSelfUser = try? await userLocalStore.isSelfUser(
            id: event.senderID.uuid,
            domain: event.senderID.domain
        ).isSelfUser

        let conversation = await conversationLocalStore.fetchOrCreateConversation(
            id: event.conversationID.uuid,
            domain: event.conversationID.domain
        )

        let conversationMutedMessages = await conversationLocalStore.conversationMutedMessageTypesIncludingAvailability(
            conversation
        )

        let isConversationMuted = conversationMutedMessages != .none

        let eventTimeStamp = event.timestamp
        let lastReadTimestamp = await conversationLocalStore.lastReadServerTimestamp(conversation)

        self.context = Context(
            senderID: event.senderID,
            conversationID: event.conversationID,
            isSelfUser: isSelfUser == true,
            isConversationMuted: isConversationMuted,
            eventTimeStamp: eventTimeStamp,
            lastReadTimestamp: lastReadTimestamp
        )
    }

    func buildContent() async throws -> UserNotification {
        let builder: NotificationBuilder

        switch event {
        case let .mlsMessageAdd(mlsMessageEvent):
            let decryptedMessage = mlsMessageEvent.decryptedMessages.first?.message

            let genericMessage = try decryptMessage(
                decryptedMessage: decryptedMessage,
                isProteus: false
            )

            let callingBuilder = await callingBuilder(
                calling: genericMessage.calling,
                conversationID: mlsMessageEvent.conversationID,
                senderID: mlsMessageEvent.senderID
            )

            if let callingBuilder {
                builder = callingBuilder
            } else {
                builder = try await ConversationMLSMessageAddEventNotificationBuilder(
                    message: genericMessage,
                    conversationID: mlsMessageEvent.conversationID,
                    senderID: mlsMessageEvent.senderID,
                    userLocalStore: userLocalStore,
                    conversationLocalStore: conversationLocalStore,
                    messageLocalStore: messageLocalStore
                )

            }

        case let .proteusMessageAdd(proteusMessageEvent):
            let decryptedMessage = proteusMessageEvent.message.decryptedMessage
            let external = proteusMessageEvent.externalData?.encryptedMessage

            let genericMessage = try decryptMessage(
                decryptedMessage: decryptedMessage,
                external: external
            )

            let callingBuilder = await callingBuilder(
                calling: genericMessage.calling,
                at: proteusMessageEvent.timestamp,
                conversationID: proteusMessageEvent.conversationID,
                senderID: proteusMessageEvent.senderID
            )

            // If there's a call to handle, there will be some value, else, there is no call to handle.
            if let callingBuilder {
                builder = callingBuilder
            } else {
                builder = try await ConversationProteusMessageAddEventNotificationBuilder(
                    message: genericMessage,
                    conversationID: proteusMessageEvent.conversationID,
                    senderID: proteusMessageEvent.senderID,
                    userLocalStore: userLocalStore,
                    conversationLocalStore: conversationLocalStore,
                    messageLocalStore: messageLocalStore
                )
            }

        case let .memberLeave(memberLeaveEvent):
            let removedUserIDs = Set(memberLeaveEvent.removedUserIDs.compactMap(\.uuid))

            builder = await ConversationMemberLeaveEventNotificationBuilder(
                removedUserIDs: removedUserIDs,
                conversationID: memberLeaveEvent.conversationID,
                senderID: memberLeaveEvent.senderID,
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore
            )

        case let .memberJoin(memberJoinEvent):
            let addedUserIDs = Set(memberJoinEvent.members.compactMap(\.id))

            builder = await ConversationMemberJoinEventNotificationBuilder(
                addedUserIDs: addedUserIDs,
                conversationID: memberJoinEvent.conversationID,
                senderID: memberJoinEvent.senderID,
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore
            )

        case let .create(conversationCreateEvent):

            builder = await ConversationCreateEventNotificationBuilder(
                conversationID: conversationCreateEvent.conversationID,
                senderID: conversationCreateEvent.senderID,
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore
            )

        case let .delete(conversationDeleteEvent):

            builder = await ConversationDeleteEventNotificationBuilder(
                conversationID: conversationDeleteEvent.conversationID,
                senderID: conversationDeleteEvent.senderID,
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore
            )

        case let .messageTimerUpdate(messageTimerUpdateEvent):

            builder = await ConversationMessageTimerUpdateEventNotificationBuilder(
                newTimer: messageTimerUpdateEvent.newTimer,
                conversationID: messageTimerUpdateEvent.conversationID,
                senderID: messageTimerUpdateEvent.senderID,
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore
            )

        default:
            return .text(UNMutableNotificationContent())
        }

        guard await builder.shouldBuildNotification() else {
            return .text(UNMutableNotificationContent())
        }

        return try await builder.buildContent()
    }

    func shouldBuildNotification() async -> Bool {
        let isSelfUser = context.isSelfUser
        let isConversationMuted = context.isConversationMuted
        let eventTimeStamp = context.eventTimeStamp
        let lastReadTimestamp = context.lastReadTimestamp

        guard !isSelfUser,
              !isConversationMuted,
              let eventTimeStamp,
              let lastReadTimestamp,
              lastReadTimestamp.compare(eventTimeStamp) != .orderedAscending
        else {
            return false
        }

        return true
    }

    private func callingBuilder(
        calling: Calling,
        at date: Date? = nil,
        conversationID: WireAPI.QualifiedID,
        senderID: WireAPI.QualifiedID
    ) async -> NotificationBuilder? {
        let callKitBuilder = await CallKitNotificationBuilder(
            calling: calling,
            conversationID: conversationID,
            senderID: senderID,
            accountID: UUID(),
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        let callNotificationBuilder = await CallNotificationBuilder(
            calling: calling,
            at: date,
            conversationID: conversationID,
            senderID: senderID,
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )

        // First, let's try to handle a call notification with CallKit.
        // If not, try fallback to regular push notification builder.
        // Else, this is not a call.
        if let callKitBuilder, await callKitBuilder.shouldBuildNotification() {
            return callKitBuilder
        } else if let callNotificationBuilder {
            return callNotificationBuilder
        } else {
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
