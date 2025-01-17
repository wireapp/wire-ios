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

import WireAPI
import WireDataModel
import WireLogging

struct ConversationNotificationBuilder: NotificationBuilder {

    private struct Context {
        let senderID: UserID
        let conversationID: ConversationID
        let accountID: UUID
        let isSelfUser: Bool
        let isConversationMuted: Bool
        let eventTimeStamp: Date?
        let lastReadTimestamp: Date?
    }

    private let event: ConversationEvent
    private let context: Context

    init(
        event: ConversationEvent,
        accountID: UUID
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
            accountID: accountID,
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

            guard let genericMessage = getGenericMessage(
                decryptedMessage: decryptedMessage
            ) else { return UNMutableNotificationContent() }

            if genericMessage.hasCalling {

                guard let callBuilder = await makeCallBuilder(
                    calling: genericMessage.calling,
                    at: context.eventTimeStamp
                ) else { return UNMutableNotificationContent() }

                builder = callBuilder

            } else {

                builder = await NewMessageNotificationBuilder(
                    message: genericMessage,
                    conversationID: mlsMessageEvent.conversationID,
                    senderID: mlsMessageEvent.senderID
                )

            }

        case let .proteusMessageAdd(proteusMessageEvent):
            let decryptedMessage = proteusMessageEvent.message.decryptedMessage
            let externalEncryptedMessage = proteusMessageEvent.externalData?.encryptedMessage

            guard let genericMessage = getGenericMessage(
                decryptedMessage: decryptedMessage,
                externalMessage: externalEncryptedMessage
            ) else { return UNMutableNotificationContent() }

            if genericMessage.hasCalling {

                guard let callBuilder = await makeCallBuilder(
                    calling: genericMessage.calling,
                    at: context.eventTimeStamp
                ) else { return UNMutableNotificationContent() }

                builder = callBuilder

            } else {

                builder = await NewMessageNotificationBuilder(
                    message: genericMessage,
                    conversationID: proteusMessageEvent.conversationID,
                    senderID: proteusMessageEvent.senderID
                )

            }

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
        else { return false }

        return true
    }

    // MARK: - Helpers

    private func makeCallBuilder(
        calling: Calling,
        at date: Date?
    ) async -> NotificationBuilder? {
        let callKitBuilder = await makeCallKitNotificationBuilder(
            calling: calling,
            at: date
        )

        // Checking early on that the builder should actually build the `CallKit` notification
        // if not we fallback to the regular call notification builder.
        if let callKitBuilder, await callKitBuilder.shouldBuildNotification() {
            return callKitBuilder
        } else if let callNotifBuilder = await makeCallRegularNotificationBuilder(
            calling: calling,
            at: date
        ) {
            return callNotifBuilder
        } else {
            return nil
        }
    }

    private func makeCallKitNotificationBuilder(
        calling: Calling,
        at date: Date?
    ) async -> NotificationBuilder? {
        guard let callKitNotifBuilder = await CallKitNotificationBuilder(
            calling: calling,
            conversationID: context.conversationID,
            senderID: context.senderID,
            accountID: context.accountID
        ) else {
            return nil
        }

        return callKitNotifBuilder
    }

    private func makeCallRegularNotificationBuilder(
        calling: Calling,
        at date: Date?
    ) async -> NotificationBuilder? {
        guard let callNotifBuilder = await CallNotificationBuilder(
            calling: calling,
            at: date,
            conversationID: context.conversationID,
            senderID: context.senderID
        ) else {
            return nil
        }

        return callNotifBuilder
    }

    private func getGenericMessage(
        decryptedMessage: String?,
        externalMessage: String? = nil
    ) -> GenericMessage? {
        guard let decryptedMessage,
              let (genericMessage, _) = ProtobufMessageHelper.getProtobufMessage(
                  from: decryptedMessage,
                  externalData: externalMessage
              ) else { return nil }

        return genericMessage
    }

}
