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
    
    let message: GenericMessage
    let conversation: ZMConversation
    let sender: ZMUser
    
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
    
    func build() -> UNMutableNotificationContent {
        let shouldHideNotification = Bool.random() // TODO: Use `persistentStoreMetadataForKey` from WireDataModel
        
        guard !shouldHideNotification else {
            return makeHiddenNotification()
        }
        
        switch message.content {
        case .location:
            return makeLocationNotification()
        case .knock: break
            //            self = .knock
            
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
        
    }
    
    private func makeHiddenNotification() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let title = ""
        let body = "New message"
        
        content.title = title
        content.body = body
        content.sound = .default
    }
    
    private func makeLocationNotification() -> UNMutableNotificationContent {
        let selfUser = ZMUser.selfUser(
            in: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        )
        
        let content = UNMutableNotificationContent()
        
        let teamName = selfUser.teamName
        let conversationName = conversation.displayName
        
        let title: String? = if let conversationName, let teamName {
            "\(conversationName) in \(teamName)"
        } else if let conversationName {
            conversationName
        } else if let teamName {
            teamName
        } else {
            nil
        }
        
        if let title {
            content.title = title
        }
        
        let body = if conversation.conversationType == .oneOnOne {
            ""
        } else {
            ""
        }
        
        content.body = body
        content.categoryIdentifier = "unmutedConversation"
        content.sound = .default
        
        var userInfo: [AnyHashable: Any] = [:]
        userInfo["selfUserIDString"] = selfUser.remoteIdentifier
        userInfo["senderIDString"] = sender.remoteIdentifier
        userInfo["conversationIDString"] = conversation.remoteIdentifier
        userInfo["messageNonceString"] = message.messageID
        userInfo["eventIDString"] = "" // TODO:
        userInfo["eventTime"] = "" // TODO:
        userInfo["conversationNameString"] = conversation.displayName
        userInfo["teamNameString"] = selfUser.team?.name
        
        content.userInfo = userInfo
        
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
        
        let title = "" // No title for ephemeral message
        let body = if isMention {
            "Someone mentioned you"
        } else if isReply {
            "Someone replied to you"
        } else {
            "Someone sent a message"
        }
        
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "unmutedConversation"
        
        var userInfo: [AnyHashable: Any] = [:]
        userInfo["selfUserIDString"] = selfUser.remoteIdentifier
        userInfo["senderIDString"] = sender.remoteIdentifier
        userInfo["conversationIDString"] = conversation.remoteIdentifier
        userInfo["messageNonceString"] = message.messageID
        userInfo["eventIDString"] = "" // TODO:
        userInfo["eventTime"] = "" // TODO:
        userInfo["conversationNameString"] = conversation.displayName
        userInfo["teamNameString"] = selfUser.team?.name
        
        content.userInfo = userInfo
        
        // only group non ephemeral messages
        content.threadIdentifier = conversation.remoteIdentifier.transportString()
        
        return content
    }

}
