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

import UserNotifications
import WireCallingData
import WireCallingDomain
import WireDataModel
import WireNetwork

struct ConversationMemberLeaveEventNotificationBuilder: ConversationMemberLeaveEventNotificationBuilderProtocol {

    let context: Context
    let validator: Validator

    func buildContent(
        event: ConversationMemberLeaveEvent
    ) async -> UserNotification? {
        let removedUserIDs = Set(event.removedUserIDs.compactMap(\.id))

        let canBuildNotification = await validator.validate(
            removedUserIDs: removedUserIDs
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

        return buildMemberLeaveNotification(
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            conversationName: conversationName,
            senderName: senderName,
            selfUserID: selfUserID,
            senderID: senderID.id,
            conversationID: conversationID
        )
    }

    func buildMeetingCancellationContent(
        event: ConversationMemberLeaveEvent
    ) async -> UserNotification? {
        let removedUserIDs = Set(event.removedUserIDs.compactMap(\.id))

        guard let selfUserID = await validator.validateMeetingCancellation(
            removedUserIDs: removedUserIDs,
            senderID: event.senderID
        ) else {
            return nil
        }

        guard await validator.isMeetingsFeatureEnabled() else {
            return nil
        }

        let conversation = await context.getConversation(conversationID: event.conversationID)
        let meetingConversation = await context.meetingConversation(
            conversation: conversation,
            conversationID: event.conversationID
        )
        guard meetingConversation.isMeeting else {
            return nil
        }

        let sender = await context.getSender(senderID: event.senderID)
        guard let senderName = await context.senderName(sender: sender), !senderName.isEmpty else {
            return nil
        }

        return buildMeetingCancellationNotification(
            title: meetingConversation.name ?? "",
            senderName: senderName,
            selfUserID: selfUserID
        )
    }

    // MARK: - Build notifications

    private func buildMemberLeaveNotification(
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
            String.formated(key: "push.notification.body.senderRemovedYou", bundle: .module, senderName)
        } else {
            String.localized(key: "push.notification.body.removedYou", bundle: .module)
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

    private func buildMeetingCancellationNotification(
        title: String,
        senderName: String,
        selfUserID: UUID
    ) -> UserNotification {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = String.formated(key: "push.notification.body.senderCanceledMeeting", bundle: .module, senderName)
        content.categoryIdentifier = NotificationCategory.meetingCancellation.rawValue
        content.sound = .default
        content.userInfo = [
            NotificationUserInfoKey.selfUserID: selfUserID.uuidString
        ]

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

extension ConversationMemberLeaveEventNotificationBuilder {
    struct Validator {
        let userLocalStore: any UserLocalStoreProtocol
        let featureConfigLocalStore: (any FeatureConfigLocalStoreProtocol)?

        init(
            userLocalStore: any UserLocalStoreProtocol,
            featureConfigLocalStore: (any FeatureConfigLocalStoreProtocol)? = nil
        ) {
            self.userLocalStore = userLocalStore
            self.featureConfigLocalStore = featureConfigLocalStore
        }

        func validate(
            removedUserIDs: Set<UUID>
        ) async -> Bool {

            let selfUser = await userLocalStore.fetchSelfUser()
            let selfUserID = await userLocalStore.id(for: selfUser)

            return removedUserIDs.contains(selfUserID)
        }

        func validateMeetingCancellation(
            removedUserIDs: Set<UUID>,
            senderID: UserID
        ) async -> UUID? {
            let selfUser = await userLocalStore.fetchSelfUser()
            let selfUserID = await userLocalStore.id(for: selfUser)
            guard removedUserIDs.contains(selfUserID) else { return nil }

            let isSenderSelfUser = (try? await userLocalStore.isSelfUser(
                id: senderID.id,
                domain: senderID.domain
            ).isSelfUser) ?? (senderID.id == selfUserID)

            return isSenderSelfUser ? nil : selfUserID
        }

        func isMeetingsFeatureEnabled() async -> Bool {
            guard let featureConfigLocalStore else { return true }
            guard let feature = try? await featureConfigLocalStore.fetchFeature(name: .meetings) else { return false }
            return await featureConfigLocalStore.isFeatureEnabled(feature: feature)
        }
    }

    struct Context {
        let conversationLocalStore: any ConversationLocalStoreProtocol
        let userLocalStore: any UserLocalStoreProtocol
        let conversationsAPI: (any ConversationsAPI)?
        let meetingLocalStore: (any MeetingLocalStoreProtocol)?

        init(
            conversationLocalStore: any ConversationLocalStoreProtocol,
            userLocalStore: any UserLocalStoreProtocol,
            conversationsAPI: (any ConversationsAPI)? = nil,
            meetingLocalStore: (any MeetingLocalStoreProtocol)? = nil
        ) {
            self.conversationLocalStore = conversationLocalStore
            self.userLocalStore = userLocalStore
            self.conversationsAPI = conversationsAPI
            self.meetingLocalStore = meetingLocalStore
        }

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

        func isMeetingConversation(conversation: ZMConversation) async -> Bool {
            await conversationLocalStore.isMeetingConversation(conversation)
        }

        func meetingConversation(
            conversation: ZMConversation,
            conversationID: ConversationID
        ) async -> (isMeeting: Bool, name: String?) {
            let localName = await conversationName(conversation: conversation)

            let isLocalMeetingConversation = await isMeetingConversation(conversation: conversation)
            guard !isLocalMeetingConversation else {
                return (true, localName)
            }

            if let storedMeeting = await storedMeeting(conversationID: conversationID) {
                return (true, localName ?? storedMeeting.title)
            }

            guard let conversationsAPI,
                  await conversationLocalStore.conversationNeedsBackendUpdate(conversation) else {
                return (false, nil)
            }

            guard let remoteConversation = try? await conversationsAPI.getConversations(for: [conversationID]).found.first,
                  remoteConversation.groupType == .meeting else {
                return (false, nil)
            }

            return (true, localName ?? remoteConversation.name)
        }

        func storedMeeting(
            conversationID: ConversationID
        ) async -> Meeting? {
            await meetingLocalStore?.storedMeetings().first {
                $0.conversationID.id == conversationID.id && $0.conversationID.domain == conversationID.domain
            }
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
