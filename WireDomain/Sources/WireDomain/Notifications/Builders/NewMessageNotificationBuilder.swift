//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

struct NewMessageNotificationBuilder: NotificationBuilder {
    
    private let message: GenericMessage
    private let conversation: ZMConversation
    private let sender: ZMUser
    
    init(
        message: GenericMessage,
        conversation: ZMConversation,
        sender: ZMUser
    ) {
        self.message = message
        self.conversation = conversation
        self.sender = sender
    }
    
    func shouldBuildNotification() -> Bool {
        true
    }
    
    func buildContent() -> UNMutableNotificationContent {
        let shouldHideNotification = Bool.random() // TODO: Use `persistentStoreMetadataForKey` from WireDataModel
        
        guard !shouldHideNotification else {
            return makeHiddenNotification()
        }
        
        let selfUser = ZMUser.selfUser(
            in: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        )
        
        switch message.content {
        case .location:
            return makeLocationNotification()
        case .knock:
            return makePingNotification()
        case .image:
            return makeImageNotification()
        case .ephemeral(let ephemeral):
            return makeEphemeralNotification(ephemeral: ephemeral)
        case .text(let text): break
            return makeTextNotification(text)
        case .composite: break
//            guard let textData = message.composite.items.compactMap(\.text).first else { return nil }
//            self = .text(textData.content, isMention: textData.isMentioningSelf(selfUser), isReply: false)

        case let .asset(assetData): break
//            switch assetData.original.metaData {
//            case .audio?:
//                self = .audio
//            case .video?:
//                self = .video
//            case .image:
//                self = .image
//            default:
//                self = .fileUpload
//            }

        case .hidden:

           return makeHiddenNotification()
            
        default: break
//            return nil
        }
        
        return UNMutableNotificationContent()
    }
    
    // MARK: - Make notifications
    
    private func makeImageNotification() -> UNMutableNotificationContent {
        let selfUser = ZMUser.selfUser(
            in: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        )
        
        let content = UNMutableNotificationContent()
        
        guard let senderName = sender.name,
              let conversationName = conversation.displayName else {
            return content
        }
        
        let teamName = selfUser.team?.name
        let isGroup = conversation.conversationType == .group
        
        let title = notificationTitle(
            sender: senderName,
            conversation: conversationName,
            team: teamName,
            isGroup: isGroup
        )
        
        content.title = title.make()
        
        let body = NotificationBody.newMessage(
            .sharedPicture(senderName: isGroup ? senderName : nil)
        )
        
        content.body = body.make()
        content.categoryIdentifier = NotificationCategory.unmutedConversation.rawValue
        content.sound = UNNotificationSound(named: .init(NotificationSound.default.rawValue))
        content.userInfo = makeNotificationUserInfo(
            selfUser: selfUser,
            sender: sender,
            conversation: conversation
        )
        
        return content
    }
    
    private func makePingNotification() -> UNMutableNotificationContent {
        let selfUser = ZMUser.selfUser(
            in: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        )
        
        let content = UNMutableNotificationContent()
        
        guard let senderName = sender.name,
              let conversationName = conversation.displayName else {
            return content
        }
        
        let teamName = selfUser.team?.name
        let isGroup = conversation.conversationType == .group
        
        let title = notificationTitle(
            sender: senderName,
            conversation: conversationName,
            team: teamName,
            isGroup: isGroup
        )
        
        content.title = title.make()
        content.body = "" // TODO
        content.categoryIdentifier = NotificationCategory.unmutedConversation.rawValue
        content.sound = UNNotificationSound(named: .init(NotificationSound.ping.rawValue))
        content.userInfo = makeNotificationUserInfo(
            selfUser: selfUser,
            sender: sender,
            conversation: conversation
        )
        
        return content
    }
    
    private func makeHiddenNotification() -> UNMutableNotificationContent {
        let selfUser = ZMUser.selfUser(
            in: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        )
        
        let content = UNMutableNotificationContent()
        let body = "New message"
        
        // No title for hidden message, only a body.
        content.body = body
        content.categoryIdentifier = NotificationCategory.unmutedConversation.rawValue
        content.sound = UNNotificationSound(named: .init(NotificationSound.default.rawValue))
        content.userInfo = makeNotificationUserInfo(
            selfUser: selfUser,
            sender: sender,
            conversation: conversation
        )
        
        return content
    }
    
    private func makeTextNotification(_ text: Text?) -> UNMutableNotificationContent {
        let selfUser = ZMUser.selfUser(
            in: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        )
        
        guard let textMessageData = text else {
            return UNMutableNotificationContent()
        }
        
        let text = textMessageData.content.removingExtremeCombiningCharacters
        
        guard !text.isEmpty else {
            return UNMutableNotificationContent()
        }
    
        let quotedMessageId = UUID(uuidString: textMessageData.quote.quotedMessageID)
        let quotedMessage = ZMOTRMessage.fetch(
            withNonce: quotedMessageId,
            for: conversation,
            in: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        )
        
        let isMention = textMessageData.isMentioningSelf(selfUser)
        let isReply = textMessageData.isQuotingSelf(quotedMessage)
        let senderName = sender.name
        
        let content = UNMutableNotificationContent()
        
        let format: NotificationBody.MessageBodyFormat = if isMention {
            .textWithMention(content: text, senderName: senderName)
        } else if isReply {
            .textWithReply(content: text, senderName: senderName)
        } else {
            .text(content: text, senderName: senderName)
        }
        
        let body = NotificationBody.newMessage(
            format
        )
        
        content.body = body.make()
        content.categoryIdentifier = NotificationCategory.unmutedConversation.rawValue
        content.sound = UNNotificationSound(named: .init(NotificationSound.default.rawValue))
        
        content.userInfo = makeNotificationUserInfo(
            selfUser: selfUser,
            sender: sender,
            conversation: conversation
        )
        
        return content
    }
    
    private func makeLocationNotification() -> UNMutableNotificationContent {
        let selfUser = ZMUser.selfUser(
            in: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        )
        
        let content = UNMutableNotificationContent()
        
        guard let senderName = sender.name,
              let conversationName = conversation.displayName else {
            return content
        }
        
        let teamName = selfUser.team?.name
        let isGroup = conversation.conversationType == .group
        
        let title = notificationTitle(
            sender: senderName,
            conversation: conversationName,
            team: teamName,
            isGroup: isGroup
        )
        
        content.title = title.make()
        
        let body = NotificationBody.newMessage(
            .sharedLocation(senderName: isGroup ? senderName : nil)
        )
        
        content.body = body.make()
        content.categoryIdentifier = NotificationCategory.unmutedConversation.rawValue
        content.sound = UNNotificationSound(named: .init(NotificationSound.default.rawValue))
        
        content.userInfo = makeNotificationUserInfo(
            selfUser: selfUser,
            sender: sender,
            conversation: conversation
        )
        
        return content
    }
    
    private func makeEphemeralNotification(ephemeral: Ephemeral) -> UNMutableNotificationContent {
        let selfUser = ZMUser.selfUser(
            in: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        )
        
        let isMention: Bool
        let isReply: Bool
        
        if ephemeral.hasText {
            let textMessageData = ephemeral.text
            let quotedMessageId = UUID(uuidString: textMessageData.quote.quotedMessageID)
            let quotedMessage = ZMOTRMessage.fetch(
                withNonce: quotedMessageId,
                for: conversation,
                in: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            )
            
            isMention = textMessageData.isMentioningSelf(selfUser)
            isReply = textMessageData.isQuotingSelf(quotedMessage)
            
        } else {
            isMention = false
            isReply = false
        }
        
        let content = UNMutableNotificationContent()
        
        let format: NotificationBody.MessageBodyFormat = if isMention {
            .mentionedWithUnknownSender
        } else if isReply {
            .repliedWithUnknownSender
        } else {
            .sentWithUnknownSender
        }
        
        let body = NotificationBody.newMessage(
            format
        )
        
        content.body = body.make()
        content.categoryIdentifier = NotificationCategory.unmutedConversation.rawValue
        content.sound = UNNotificationSound(named: .init(NotificationSound.default.rawValue))
        
        content.userInfo = makeNotificationUserInfo(
            selfUser: selfUser,
            sender: sender,
            conversation: conversation
        )
        
        // only group non ephemeral messages
        content.threadIdentifier = conversation.remoteIdentifier.transportString()
        
        return content
    }
    
    // MARK: - Helpers
    
    private func notificationTitle(
        sender: String,
        conversation: String,
        team: String?,
        isGroup: Bool
    ) -> NotificationTitle {
        let format: NotificationTitle.MessageTitleFormat
        
        if isGroup {
            if let team {
                format = .conversationInTeam(conversation: conversation, team: team)
            } else {
                format = .conversation(conversation: conversation)
            }
        } else {
            if let team {
                format = .senderInTeam(sender: sender, team: team)
            } else {
                format = .sender(sender: sender)
            }
        }
        
        return .newMessage(format)
    }
    
    private func makeNotificationUserInfo(
        selfUser: ZMUser,
        sender: ZMUser,
        conversation: ZMConversation
    ) -> [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = [:]
        
        userInfo["selfUserIDString"] = selfUser.remoteIdentifier
        userInfo["senderIDString"] = sender.remoteIdentifier
        userInfo["conversationIDString"] = conversation.remoteIdentifier
        userInfo["messageNonceString"] = message.messageID
        userInfo["eventIDString"] = "" // TODO:
        userInfo["eventTime"] = "" // TODO:
        userInfo["conversationNameString"] = conversation.displayName
        userInfo["teamNameString"] = selfUser.team?.name
        
        return userInfo
    }

}
