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

import Foundation

/// The Either type represents duality.
/// A value that can either be of a type or another.
enum Either<A, B>{
  case left(A)
  case right(B)
}

enum NotificationBody {

    case conversation(Either<UserMessageBodyFormat, SystemMessageBodyFormat>)
    case user(UserConnectionBodyFormat)
    case bundled(messagesCount: Int)

    func make() -> String {
        switch self {
        case let .conversation(format):
            var composer: NotificationComposer
            
            switch format {
            case .left(let userMessageBodyFormat):
                composer = ConversationUserMessageNotificationBodyComposer(
                    format: userMessageBodyFormat
                )
            case .right(let systemMessageBodyFormat):
                composer = ConversationSystemMessageNotificationBodyComposer(
                    format: systemMessageBodyFormat
                )
            }
            
            return composer.make()
            
        case let .user(userConnectionBodyFormat):
            let userConnectionBodyComposer = UserConnectionNotificationBodyComposer(
                format: userConnectionBodyFormat
            )

            return userConnectionBodyComposer.make()

        case let .bundled(count):
            return "\(count) new messages."
        }
    }

}

extension NotificationBody {

    /// The expected formats for the body of a new conversation user message notification.
    enum UserMessageBodyFormat {
        /// `Someone sent a message`
        case sentWithUnknownSender
        /// `Someone mentioned you`
        case mentionedWithUnknownSender
        /// `Someone replied to you`
        case repliedWithUnknownSender
        /// `[sender name]: [text]` or `[text]` is sender is nil.
        case text(content: String, senderName: String?)
        /// `Mention from [sender name]: [text]` or `Mention: [text]` is sender is nil.
        case textWithMention(content: String, senderName: String?)
        /// `Reply from [sender name]: [text]` or `Reply: [text]` if sender is nil.
        case textWithReply(content: String, senderName: String?)
        /// `[sender name] shared a picture` or `Shared a picture` if sender is nil.
        case sharedPicture(senderName: String?)
        /// `[sender name] shared a video` or `Shared a video` if sender is nil.
        case sharedVideo(senderName: String?)
        /// `[sender name] shared an audio message` or `Shared an audio message` if sender is nil.
        case sharedAudio(senderName: String?)
        /// `[sender name] shared a file` or `Shared a file` if sender is nil.
        case sharedFile(senderName: String?)
        /// `[sender name] shared a location` or `Shared a location` if sender is nil.
        case sharedLocation(senderName: String?)
        /// `[sender name] pinged you` or `Pinged you` if sender is nil
        case ping(senderName: String?)
        /// `New message`
        case hidden
    }

    /// The expected formats for the body of a new conversation system message notification.
    enum SystemMessageBodyFormat {
        /// `[sender name] created a conversation` or `Someone created a conversation` if sender is nil
        case createdConversation(senderName: String?)
        /// `[sender name] added you` or `Someone added you` if sender is nil
        case addedYou(senderName: String?)
        /// `[sender name] removed you` or `Someone removed you` if sender is nil
        case removedYou(senderName: String?)
        /// `[sender name] set the message timer to [value]` or `Someone set the message timer to [value]` if sender is
        /// nil
        case setMessageTimer(senderName: String?, timeoutValue: String)
        /// `[sender name] turned off the message timer` or `Someone turned off the message timer` if sender is nil
        case turnedOffMessageTimer(senderName: String?)
        /// `[sender name] deleted the group` or `Someone deleted the group` if sender is nil
        case deletedGroup(senderName: String?)
    }

    /// The expected formats for the body of a new user connection notification.
    enum UserConnectionBodyFormat {
        /// `[username]` just joined Wire
        case userJoined(username: String)
        /// `[username]` wants to connect
        case userWantsToConnect(username: String)
        /// You and `[username]` are now connected
        case usersConnected(username: String)
    }

}
