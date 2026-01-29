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
import WireLogging
import WireNetwork

struct ConversationMemberJoinEventNotificationBuilder: ConversationMemberJoinEventNotificationBuilderProtocol {

    let context: Context
    let validator: Validator

    func buildContent(
        event: ConversationMemberJoinEvent
    ) async -> UserNotification? {
        let addedUserIDs = Set(event.members.compactMap(\.id))

        let canBuildNotification = await validator.validate(
            addedUserIDs: addedUserIDs,
            conversationID: event.conversationID
        )

        guard canBuildNotification else {
            return nil
        }

        let conversationID = event.conversationID
        let senderID = event.senderID
        let conversation = await context.getConversation(conversationID: conversationID)
        let sender = await context.getSender(senderID: senderID)
        let selfUser = await context.getSelfUser()
        let selfUserID = await context.selfUserID(selfUser: selfUser)
        let senderName = await context.senderName(sender: sender)
        let conversationName = await context.conversationName(conversation: conversation)
        let teamName = await context.teamName(selfUser: selfUser)
        let isGroupConversation = await context.isGroupConversation(
            conversation: conversation
        )

        return buildMemberJoinNotification(
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            conversationName: conversationName,
            senderName: senderName,
            selfUserID: selfUserID,
            senderID: senderID.id,
            conversationID: conversationID
        )
    }

    // MARK: - Build notifications

    private func buildMemberJoinNotification(
        isGroupConversation: Bool,
        teamName: String?,
        conversationName: String?,
        senderName: String?,
        selfUserID: UUID,
        senderID: UUID,
        conversationID: ConversationID
    ) -> UserNotification {
        let content = UNMutableNotificationContent()

        if let title = makeTitle(
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            conversationName: conversationName,
            senderName: senderName
        ) {
            content.title = title
        }

        let body = if let senderName {
            String.formated(key: "push.notification.body.senderAddedYou", bundle: .module, senderName)
        } else {
            String.localized(key: "push.notification.body.addedYou", bundle: .module)
        }

        content.body = body
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.id.transportString()

        return .text(content)
    }

    // MARK: - Helpers

    private func makeTitle(
        isGroupConversation: Bool,
        teamName: String?,
        conversationName: String?,
        senderName: String?
    ) -> String? {

        let format: NotificationTitle.MessageTitleDescriptor? = if isGroupConversation, let conversationName {
            if let teamName {
                .conversationInTeam(conversation: conversationName, team: teamName)
            } else {
                .conversation(conversation: conversationName)
            }
        } else if let senderName {
            if let teamName {
                .senderInTeam(sender: senderName, team: teamName)
            } else {
                .sender(sender: senderName)
            }
        } else {
            nil
        }

        guard let format else { return nil }

        return NotificationTitle
            .conversationMessage(format)
            .make()
    }

    private func makeSound(type: NotificationSound = .default) -> UNNotificationSound {
        let notificationSoundName = UNNotificationSoundName(type.rawValue)
        return UNNotificationSound(named: notificationSoundName)
    }

    private func makeCategory() -> String {
        let category = NotificationCategory.unmutedConversation
        return category.rawValue
    }

    private func makeUserInfo(
        selfUserID: UUID,
        senderID: UUID,
        conversationID: ConversationID
    ) -> [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = [:]

        userInfo[NotificationUserInfoKey.selfUserID] = selfUserID.uuidString
        userInfo[NotificationUserInfoKey.senderID] = senderID.uuidString
        userInfo[NotificationUserInfoKey.conversationID] = conversationID.id.uuidString

        return userInfo
    }

}

extension ConversationMemberJoinEventNotificationBuilder {
    struct Validator {
        let userLocalStore: any UserLocalStoreProtocol
        let conversationLocalStore: any ConversationLocalStoreProtocol

        func validate(
            addedUserIDs: Set<UUID>,
            conversationID: ConversationID
        ) async -> Bool {

            var logAttributes: LogAttributes = [
                LogAttributesKey.conversationId: conversationID.toDomainModel().safeForLoggingDescription
            ]

            let selfUser = await userLocalStore.fetchSelfUser()
            let selfUserID = await userLocalStore.id(for: selfUser)

            // Check if self user is in the added members list
            guard addedUserIDs.contains(selfUserID) else {
                logSkippingNotification(
                    reason: "user isn't in the added members list",
                    attributes: logAttributes
                )
                return false
            }

            // Check if the conversation exists
            guard let conversation = await conversationLocalStore.fetchConversation(
                id: conversationID.id,
                domain: conversationID.domain
            ) else {
                logSkippingNotification(
                    reason: "conversation doesn't exist",
                    attributes: logAttributes
                )
                return false
            }

            // Check if self user is already a participant
            let participants = await conversationLocalStore.localParticipants(in: conversation)

            guard !participants.contains(selfUser) else {
                logSkippingNotification(
                    reason: "self user is already a participant",
                    attributes: logAttributes
                )
                return false
            }

            WireLogger.notifications.info(
                "Creating memberJoin notification: self user is being added",
                attributes: logAttributes,
                .safePublic
            )
            return true
        }

        private func logSkippingNotification(
            reason: String,
            attributes: LogAttributes
        ) {
            WireLogger.notifications.info(
                "Skipping memberJoin notification: \(reason)",
                attributes: attributes,
                .safePublic
            )
        }
    }

    struct Context {
        let conversationLocalStore: any ConversationLocalStoreProtocol
        let userLocalStore: any UserLocalStoreProtocol

        func getConversation(
            conversationID: ConversationID
        ) async -> ZMConversation {
            await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.id,
                domain: conversationID.domain
            )
        }

        func getSelfUser() async -> ZMUser {
            await userLocalStore.fetchSelfUser()
        }

        func getSender(
            senderID: UserID
        ) async -> ZMUser {
            await userLocalStore.fetchOrCreateUser(
                id: senderID.id,
                domain: senderID.domain
            )
        }

        func senderName(
            sender: ZMUser
        ) async -> String? {
            await userLocalStore.name(for: sender)
        }

        func isGroupConversation(conversation: ZMConversation) async -> Bool {
            await conversationLocalStore.isGroupConversation(conversation)
        }

        func selfUserID(selfUser: ZMUser) async -> UUID {
            await userLocalStore.id(for: selfUser)
        }

        func conversationName(
            conversation: ZMConversation
        ) async -> String? {
            await conversationLocalStore.name(for: conversation)
        }

        func teamName(
            selfUser: ZMUser
        ) async -> String? {
            await userLocalStore.teamName(for: selfUser)
        }

    }
}
