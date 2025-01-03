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

struct ConversationNotificationBuilder: NotificationBuilder {

    private struct Context {
        let senderID: UserID
        let conversationID: ConversationID
        let isSelfUser: Bool
        let isConversationMuted: Bool
        let eventTimeStamp: Date?
        let lastReadTimestamp: Date?
    }

    private let event: ConversationEvent
    private let context: Context

    init(
        event: ConversationEvent
    ) async {
        self.event = event

        let conversationLocalStore: ConversationLocalStoreProtocol = Injector.resolve()
        let userRepository: UserRepositoryProtocol = Injector.resolve()

        let isSelfUser = try? await userRepository.isSelfUser(
            id: event.senderID.uuid,
            domain: event.senderID.domain
        )

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

    func buildContent() async -> UNMutableNotificationContent {
        let builder: NotificationBuilder

        switch event {
        case let .mlsMessageAdd(mlsMessageEvent):
            let decryptedMessage = mlsMessageEvent.decryptedMessages.first?.message

            guard let decryptedMessage,
                  let (genericMessage, _) = ProtobufMessageHelper.getProtobufMessage(
                      from: decryptedMessage
                  ) else {
                return UNMutableNotificationContent()
            }

            builder = await NewMessageNotificationBuilder(
                message: genericMessage,
                conversationID: mlsMessageEvent.conversationID,
                senderID: mlsMessageEvent.senderID
            )

        case let .proteusMessageAdd(proteusMessageEvent):
            let decryptedMessage = proteusMessageEvent.message.decryptedMessage
            let externalEncryptedMessage = proteusMessageEvent.externalData?.encryptedMessage

            guard let decryptedMessage,
                  let (genericMessage, _) = ProtobufMessageHelper.getProtobufMessage(
                      from: decryptedMessage,
                      externalData: externalEncryptedMessage
                  ) else {
                return UNMutableNotificationContent()
            }

            builder = await NewMessageNotificationBuilder(
                message: genericMessage,
                conversationID: proteusMessageEvent.conversationID,
                senderID: proteusMessageEvent.senderID
            )

        default: // TODO: [WPB-11175] - Generate notifications for other events
            return UNMutableNotificationContent()
        }

        guard await builder.shouldBuildNotification() else {
            return UNMutableNotificationContent()
        }

        return await builder.buildContent()
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

}
