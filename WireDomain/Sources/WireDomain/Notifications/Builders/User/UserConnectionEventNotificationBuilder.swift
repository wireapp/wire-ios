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
import WireDataModel
import WireNetwork

struct UserConnectionEventNotificationBuilder {

    private enum ConnectionStatus {
        case pending
        case accepted
    }

    let context: Context
    let validator: Validator

    func buildContent(
        event: UserConnectionEvent
    ) async -> UserNotification? {
        let canBuildNotification = await validator.validate(
            connectionStatus: event.connection.status
        )

        guard canBuildNotification else {
            return nil
        }

        var qualifiedID: WireNetwork.QualifiedID?
        let connection = event.connection

        if let qualifiedConversationID = connection.qualifiedConversationID {
            qualifiedID = qualifiedConversationID
        } else if let conversationID = connection.conversationID {
            qualifiedID = .init(id: conversationID, domain: "")
        }

        let isPendingConnection = event.connection.status == .pending
        let connectionStatus = isPendingConnection ? ConnectionStatus.pending : .accepted
        let selfUser = await context.getSelfUser()
        let selfUserID = await context.selfUserID(selfUser: selfUser)
        // The receiver is the user we are connecting with
        let username: String? = if let receiverQualifiedID = connection.receiverQualifiedID {
            await context.username(
                for: context.getUser(
                    id: receiverQualifiedID.id,
                    domain: receiverQualifiedID.domain
                )
            )
        } else if let receiverID = connection.receiverID {
            await context.username(
                for: context.getUser(
                    id: receiverID,
                    domain: nil
                )
            )
        } else {
            nil
        }

        return buildConnectionRequestNotification(
            connectionStatus: connectionStatus,
            username: username ?? event.userName,
            selfUserID: selfUserID,
            senderID: connection.senderID,
            conversationID: qualifiedID
        )

    }

    // MARK: - Build notifications

    private func buildConnectionRequestNotification(
        connectionStatus: ConnectionStatus,
        username: String?,
        selfUserID: UUID,
        senderID: UUID?,
        conversationID: WireNetwork.QualifiedID?
    ) -> UserNotification {
        let content = UNMutableNotificationContent()

        let body = switch connectionStatus {
        case .pending:
            if let username {
                String.formated(
                    key: "push.notification.body.connectionPending",
                    bundle: .module, username
                )
            } else {
                String.formated(
                    key: "push.notification.body.connectionPending.noUsername",
                    bundle: .module
                )
            }
        case .accepted:
            if let username {
                String.formated(
                    key: "push.notification.body.connectionAccepted",
                    bundle: .module, username
                )
            } else {
                String.formated(
                    key: "push.notification.body.connectionAccepted.noUsername",
                    bundle: .module
                )
            }
        }

        content.body = body
        content.categoryIdentifier = makeCategory(
            connectionStatus: connectionStatus
        )
        content.sound = makeSound()
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID,
            conversationID: conversationID
        )

        return .text(content)
    }

    // MARK: - Helpers

    private func makeSound(type: NotificationSound = .default) -> UNNotificationSound {
        let notificationSoundName = UNNotificationSoundName(type.rawValue)
        return UNNotificationSound(named: notificationSoundName)
    }

    private func makeCategory(connectionStatus: ConnectionStatus) -> String {
        switch connectionStatus {
        case .accepted:
            NotificationCategory.nonActionable.rawValue
        case .pending:
            NotificationCategory.incomingConnectionRequest.rawValue
        }
    }

    private func makeUserInfo(
        selfUserID: UUID,
        senderID: UUID?,
        conversationID: WireNetwork.QualifiedID?
    ) -> [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = [:]

        userInfo[NotificationUserInfoKey.selfUserID] = selfUserID.uuidString
        userInfo[NotificationUserInfoKey.senderID] = senderID?.uuidString
        userInfo[NotificationUserInfoKey.conversationID] = conversationID?.id.uuidString

        return userInfo
    }

}

extension UserConnectionEventNotificationBuilder {
    struct Validator {

        func validate(connectionStatus: WireNetwork.ConnectionStatus) async -> Bool {
            switch connectionStatus {
            case .accepted, .pending:
                true
            default:
                false // do not display notifications for other statuses
            }
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

        func getUser(
            id: UUID,
            domain: String?
        ) async -> ZMUser {
            await userLocalStore.fetchOrCreateUser(
                id: id,
                domain: domain
            )
        }

        func username(
            for user: ZMUser
        ) async -> String? {
            await userLocalStore.name(for: user)
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
