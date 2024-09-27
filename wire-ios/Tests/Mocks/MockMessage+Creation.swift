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

import Foundation
import WireDataModel
import WireLinkPreview
@testable import Wire

extension MockMessage {
    func update(
        mockSystemMessageData: MockSystemMessageData,
        userClients: [AnyHashable]
    ) {
        mockSystemMessageData.clients = Set(userClients)

        backingSystemMessageData = mockSystemMessageData
    }
}

enum MockMessageFactory {
    /// Create a template MockMessage with conversation, serverTimestamp, sender and activeParticipants set.
    /// When sender is not provided, create a new self user and assign as sender of the return message
    ///
    /// - Returns: a MockMessage with default values
    static func messageTemplate<T: MockMessage>(
        sender: UserType? = nil,
        conversation: Conversation? = nil
    ) -> T {
        let message = T()

        var mockZMConversation: MockConversation?
        if let conversation {
            message.conversationLike = conversation
        } else {
            let conversation = MockLoader
                .mockObjects(of: MockConversation.self, fromFile: "conversations-01.json")[0] as? MockConversation
            message.conversation = (conversation as Any) as? ZMConversation
            message.conversationLike = message.conversation
            mockZMConversation = conversation
        }
        message.serverTimestamp = Date(timeIntervalSince1970: 0)

        if let sender = sender as? ZMUser {
            message.senderUser = sender
        } else if let sender {
            message.senderUser = sender
        } else {
            let user = MockUserType.createSelfUser(name: "Tarja Turunen")
            user.zmAccentColor = .blue
            message.senderUser = user
        }

        mockZMConversation?.activeParticipants = [message.senderUser as! MockUserType]

        return message
    }

    static func fileTransferMessage<T: MockMessage>(sender: UserType? = nil) -> T {
        let message: T = MockMessageFactory.messageTemplate(sender: sender)

        message.backingFileMessageData = MockFileMessageData()
        return message
    }

    static func imageMessage<T: MockMessage>(sender: UserType? = nil, with image: UIImage?) -> T {
        let imageData = MockImageMessageData()
        if let image, let data = image.imageData {
            imageData.mockImageData = data
            imageData.mockOriginalSize = image.size
            imageData.isDownloaded = true
        } else {
            imageData.isDownloaded = false
        }

        let message: T = imageMessage(sender: sender)
        message.imageMessageData = imageData

        return message
    }

    static func imageMessage<T: MockMessage>(sender: UserType? = nil) -> T {
        let message: T = MockMessageFactory.messageTemplate(sender: sender)

        message.imageMessageData = MockImageMessageData()

        return message
    }

    static func pendingImageMessage(sender: UserType? = nil) -> MockMessage? {
        let imageData = MockImageMessageData()

        let message: MockMessage? = imageMessage(sender: sender)
        message?.imageMessageData = imageData

        return message
    }

    static func systemMessageAndData(
        with systemMessageType: ZMSystemMessageType,
        conversation: Conversation? = nil,
        users numUsers: Int = 0,
        sender: UserType? = nil,
        reason: ZMParticipantsRemovedReason = .none,
        domains: [String]? = nil
    ) -> (MockMessage?, MockSystemMessageData) {
        let message = MockMessageFactory.messageTemplate(sender: sender, conversation: conversation)

        let mockSystemMessageData = MockSystemMessageData(
            systemMessageType: systemMessageType,
            reason: reason,
            domains: domains
        )

        message.serverTimestamp = Date(timeIntervalSince1970: 12_345_678_564)

        if numUsers > 0 {
            mockSystemMessageData.userTypes = Set(SwiftMockLoader.mockUsers()[0 ... numUsers - 1])
        } else {
            mockSystemMessageData.userTypes = Set()
        }

        return (message, mockSystemMessageData)
    }

    static func systemMessage(
        with systemMessageType: ZMSystemMessageType,
        conversation: Conversation? = nil,
        users numUsers: Int = 0,
        clients numClients: Int = 0,
        sender: UserType? = nil,
        reason: ZMParticipantsRemovedReason = .none,
        domains: [String]? = nil
    ) -> MockMessage? {
        let (message, mockSystemMessageData) = systemMessageAndData(
            with: systemMessageType,
            conversation: conversation,
            users: numUsers,
            sender: sender,
            reason: reason,
            domains: domains
        )

        var userClients: [AnyHashable] = []

        for user: Any in mockSystemMessageData.userTypes {
            if let client = (user as? MockUser)?.feature(withUserClients: numClients) {
                userClients.append(contentsOf: client)
            }
        }

        message!.update(mockSystemMessageData: mockSystemMessageData, userClients: userClients)
        return message
    }

    static func locationMessage<T: MockMessage>(sender: MockUserType? = nil) -> T {
        let message: T = MockMessageFactory.messageTemplate(sender: sender)

        message.backingLocationMessageData = MockLocationMessageData()
        return message
    }

    static func compositeMessage(sender: UserType? = nil) -> MockMessage {
        let message = MockMessageFactory.messageTemplate(sender: sender)
        return message
    }

    static func videoMessage<T: MockMessage>(sender: UserType? = nil, previewImage: UIImage? = nil) -> T {
        let message: T = fileTransferMessage(sender: sender)
        message.backingFileMessageData.mimeType = "video/mp4"
        message.backingFileMessageData.filename = "vacation.mp4"
        message.backingFileMessageData.previewData = previewImage?.jpegData(compressionQuality: 0.9)
        return message
    }

    static func audioMessage(sender: UserType? = nil) -> MockMessage? {
        let message: MockMessage? = fileTransferMessage(sender: sender)
        message?.backingFileMessageData.mimeType = "audio/x-m4a"
        return message
    }

    static func textMessage<T: MockMessage>(
        withText text: String? = "Just a random text message",
        sender: UserType? = nil,
        conversation: Conversation? = nil,
        includingRichMedia shouldIncludeRichMedia: Bool = false
    ) -> T {
        let message: T = MockMessageFactory.messageTemplate(sender: sender, conversation: conversation)

        let textMessageData = MockTextMessageData()
        textMessageData
            .messageText = shouldIncludeRichMedia ?
            "Check this 500lb squirrel! -> https://www.youtube.com/watch?v=0so5er4X3dc" : text!
        message.backingTextMessageData = textMessageData

        return message
    }

    static func linkMessage() -> MockMessage {
        let message = MockMessageFactory.messageTemplate()

        let textData = MockTextMessageData()
        let article = ArticleMetadata(
            originalURLString: "http://foo.bar/baz",
            permanentURLString: "http://foo.bar/baz",
            resolvedURLString: "http://foo.bar/baz",
            offset: 0
        )
        textData.backingLinkPreview = article
        message.backingTextMessageData = textData

        return message
    }

    static func pingMessage<T: MockMessage>() -> T {
        let message: T = MockMessageFactory.messageTemplate()
        message.knockMessageData = MockKnockMessageData()

        return message
    }

    static func expiredMessage(from message: MockMessage?) -> MockMessage? {
        message?.isEphemeral = true
        message?.isObfuscated = true
        message?.hasBeenDeleted = false
        return message
    }

    static func expiredImageMessage() -> MockMessage? {
        expiredMessage(from: imageMessage())
    }

    static func expiredVideoMessage() -> MockMessage? {
        expiredMessage(from: videoMessage())
    }

    static func expiredAudioMessage() -> MockMessage? {
        expiredMessage(from: audioMessage())
    }

    static func expiredFileMessage() -> MockMessage? {
        expiredMessage(from: fileTransferMessage())
    }

    static func expiredLinkMessage() -> MockMessage? {
        expiredMessage(from: linkMessage())
    }

    static func deletedMessage(from message: MockMessage?) -> MockMessage? {
        message?.isEphemeral = false
        message?.isObfuscated = false
        message?.hasBeenDeleted = true
        return message
    }

    static func deletedImageMessage() -> MockMessage? {
        deletedMessage(from: imageMessage())
    }

    static func deletedVideoMessage() -> MockMessage? {
        deletedMessage(from: videoMessage())
    }

    static func deletedAudioMessage() -> MockMessage? {
        deletedMessage(from: audioMessage())
    }

    static func deletedFileMessage() -> MockMessage? {
        deletedMessage(from: fileTransferMessage())
    }

    static func deletedLinkMessage() -> MockMessage? {
        deletedMessage(from: linkMessage())
    }

    static func passFileTransferMessage() -> MockMessage {
        let message = MockMessageFactory.messageTemplate()
        message.backingFileMessageData = MockPassFileMessageData()

        return message
    }

    static func audioMessage(config: ((MockMessage) -> Void)?) -> MockMessage {
        let fileMessage: MockMessage = MockMessageFactory.fileTransferMessage()
        fileMessage.backingFileMessageData.mimeType = "audio/x-m4a"
        fileMessage.backingFileMessageData.filename = "sound.m4a"

        if let config {
            config(fileMessage)
        }

        return fileMessage
    }
}
