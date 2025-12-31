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
import WireDataModel
import WireNetwork

// sourcery: AutoMockable
protocol ConversationEventNotificationBuilderProtocol {
    func buildContent(
        event: ConversationEvent
    ) async throws -> UserNotification?
}

struct ConversationEventNotificationBuilder: ConversationEventNotificationBuilderProtocol {

    let validator: ConversationEventNotificationBuilder.Validator
    let conversationMessageAddEventNotificationBuilder: ConversationMessageAddEventNotificationBuilder
    let conversationMemberLeaveEventNotificationBuilder: ConversationMemberLeaveEventNotificationBuilder
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

            return try await conversationMessageAddEventNotificationBuilder.buildContent(
                event: .left(mlsMessageEvent)
            )

        case let .proteusMessageAdd(proteusMessageEvent):

            return try await conversationMessageAddEventNotificationBuilder.buildContent(
                event: .right(proteusMessageEvent)
            )

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
                id: conversationID.id,
                domain: conversationID.domain
            )

            let conversationMutedMessages = await conversationLocalStore
                .conversationMutedMessageTypesIncludingAvailability(
                    conversation
                )

            let isConversationMuted = conversationMutedMessages == .all

            let isSenderSelfUser = (try? await userLocalStore.isSelfUser(
                id: senderID.id,
                domain: senderID.domain
            ).isSelfUser) ?? false

            let isSelfConversation = await conversationLocalStore.isSelfConversation(conversation)
            // Reject events from self user, except in self-conversation (e.g., calling "answered elsewhere")
            let shouldAllowSender = isSenderSelfUser ? isSelfConversation : true

            let eventTimeStamp = time
            let lastReadTimestamp = await conversationLocalStore.lastReadServerTimestamp(conversation)

            guard shouldAllowSender,
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
