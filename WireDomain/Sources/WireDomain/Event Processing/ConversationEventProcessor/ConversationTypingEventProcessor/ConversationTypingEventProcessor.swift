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

import WireDataModel
import WireNetwork

struct ConversationTypingEventProcessor: ConversationTypingEventProcessorProtocol {

    let conversationRepository: any ConversationRepositoryProtocol
    let conversationLocalStore: any ConversationLocalStoreProtocol
    let userRepository: any UserRepositoryProtocol
    let onProcessedTypingUsers: ([ConversationTypingUsersInfo]) -> Void

    private let typingUsersTimeout = ConversationTypingUsersTimeout()

    func processEvent(_ event: ConversationTypingEvent) async {
        let conversationID = event.conversationID
        let senderID = event.senderID
        let isTyping = event.isTyping

        let user = await userRepository.fetchOrCreateUser(
            id: senderID.id,
            domain: senderID.domain
        )

        let conversation = await conversationRepository.fetchOrCreateConversation(
            id: conversationID.id,
            domain: conversationID.domain
        )

        typingUsersTimeout.timerFiredCallback = timerDidFire

        // Since we'll be manipulating managed object IDs in `ConversationTypingUsersTimeout`
        // we need to make sure we have valid, consistent IDs for the user and conversation.
        await conversationLocalStore.obtainPermanentIDs(
            user: user,
            conversation: conversation
        )

        let userObjectID = user.objectID
        let conversationObjectID = conversation.objectID

        let wasTyping = typingUsersTimeout.contains(
            userObjectID,
            for: conversationObjectID
        )

        if isTyping {
            let timeout = ConversationTypingUsersTimeout.defaultTimeout // 60 sec

            // Tracks the typing user timeout for a given conversation
            typingUsersTimeout.add(
                userObjectID,
                for: conversationObjectID,
                withTimeout: Date(timeIntervalSinceNow: timeout)
            )
        }

        // Typing status changed
        if wasTyping != isTyping {
            if !isTyping {
                // User is no longer typing, untracking him
                typingUsersTimeout.remove(
                    userObjectID,
                    for: conversationObjectID
                )
            }

            let userObjectIDs = typingUsersTimeout.userIds(
                in: conversationObjectID
            )

            let typingUsersInfo = ConversationTypingUsersInfo(
                users: userObjectIDs,
                conversationID: conversationObjectID
            )

            // Updates non timed out typing users
            onProcessedTypingUsers([typingUsersInfo])
        }

        typingUsersTimeout.updateExpirationIfNeeded()
    }

    /// Called when timer from `ConversationTypingUsersTimeout` fires.
    /// Untrack timed out typing users and updates valid (non timed out) typing users.
    /// Callback is fired when a new timeout value is reached in `timeouts` dictionary.

    private func timerDidFire() async {
        let conversationObjectIDs = typingUsersTimeout.pruneConversationsThatHaveTimoutBefore(
            date: .now
        )

        // Map typing users for each conversation
        let typingUsersInfo: [ConversationTypingUsersInfo] = conversationObjectIDs.map {
            let userObjectIDs = typingUsersTimeout.userIds(in: $0)
            return .init(users: userObjectIDs, conversationID: $0)
        }

        onProcessedTypingUsers(typingUsersInfo)

        typingUsersTimeout.updateExpirationIfNeeded()
    }

}
