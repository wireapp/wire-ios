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
    
    private var category: NotificationCategory {
        switch message.content {
        default:
            return .unmutedConversation
        }
    }
    
    private var sound: NotificationSound {
        switch message.content {
        case .knock:
            return .ping
        default:
            return .newMessage
        }
    }
    
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
        case .image: break
            // NOTE: is this v2 asset ?
            //            self = .image
            
        case .ephemeral:
        
            return makeEphemeralNotification()
            
        case .text: break
//            guard
//                let textMessageData = message.textData,
//                let text = message.textData?.content.removingExtremeCombiningCharacters, !text.isEmpty
//            else {
//                return nil
//            }
//
//            let quotedMessage = getQuotedMessage(textMessageData, conversation: conversation, in: moc)
//            self = .text(
//                text,
//                isMention: textMessageData.isMentioningSelf(selfUser),
//                isReply: textMessageData.isQuotingSelf(quotedMessage)
//            )

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
        
        let title = makeTitle(
            sender: senderName,
            conversation: conversationName,
            team: teamName,
            isGroup: isGroup
        )
        
        content.title = title.make()
        content.body = "" // TODO
        content.categoryIdentifier = category.rawValue
        content.sound = UNNotificationSound(named: .init(sound.rawValue))
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
        content.categoryIdentifier = category.rawValue
        content.sound = UNNotificationSound(named: .init(sound.rawValue))
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
        
        let title = makeTitle(
            sender: senderName,
            conversation: conversationName,
            team: teamName,
            isGroup: isGroup
        )
        
        content.title = title.make()
        
        let body = if conversation.conversationType == .oneOnOne {
            ""
        } else {
            ""
        }
        
        content.body = body
        content.categoryIdentifier = category.rawValue
        content.sound = UNNotificationSound(named: .init(sound.rawValue))
        
        content.userInfo = makeNotificationUserInfo(
            selfUser: selfUser,
            sender: sender,
            conversation: conversation
        )
        
        return content
    }
    
    private func makeEphemeralNotification() -> UNMutableNotificationContent {
        let selfUser = ZMUser.selfUser(
            in: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        )
        
        let isMention: Bool
        let isReply: Bool
        
        if message.ephemeral.hasText {
            let textMessageData = message.ephemeral.text
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
        
        // No title for ephemeral message, only a body.
        let body = if isMention {
            "Someone mentioned you"
        } else if isReply {
            "Someone replied to you"
        } else {
            "Someone sent a message"
        }
        
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = UNNotificationSound(named: .init(sound.rawValue))
        content.categoryIdentifier = category.rawValue
        
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
    
    private func makeTitle(
        sender: String,
        conversation: String,
        team: String?,
        isGroup: Bool
    ) -> NotificationTitle {
        let format: NotificationTitle.Format
        
        if isGroup {
            if let team {
                format = .conversationInTeam(conversation: conversation, team: team)
            } else {
                format = .conversationOnly(conversation: conversation)
            }
        } else {
            if let team {
                format = .senderInTeam(sender: sender, team: team)
            } else {
                format = .senderOnly(sender: sender)
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
