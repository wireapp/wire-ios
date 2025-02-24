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

enum NotificationBody {

    case singleMessage(NewMessageBodyDescriptor)
    case bundled(messagesCount: Int)

    func make() -> String {
        switch self {
        case .singleMessage(let newMessageBodyDescriptor):
            make(bodyDescriptor: newMessageBodyDescriptor)
        case let .bundled(count):
            "\(count) new messages."
        }
    }
    
    private func make(bodyDescriptor: NewMessageBodyDescriptor) -> String {
        switch bodyDescriptor {
        case .sentWithUnknownSender:
            "Someone sent a message"
        case .mentionedWithUnknownSender:
            "Someone mentioned you"
        case .repliedWithUnknownSender:
            "Someone replied to you"
        case let .text(content, senderName):
            senderName != nil ? "\(senderName!): \(content)" : content
        case let .textWithMention(content, senderName):
            senderName != nil ? "Mention from \(senderName!): \(content)" : "Mention: \(content)"
        case let .textWithReply(content, senderName):
            senderName != nil ? "Reply from \(senderName!): \(content)" : "Reply: \(content)"
        case let .sharedPicture(senderName):
            senderName != nil ? "\(senderName!) shared a picture" : "Shared a picture"
        case let .sharedVideo(senderName):
            senderName != nil ? "\(senderName!) shared a video" : "Shared a video"
        case let .sharedAudio(senderName):
            senderName != nil ? "\(senderName!) shared an audio message" : "Shared an audio message"
        case let .sharedFile(senderName):
            senderName != nil ? "\(senderName!) shared a file" : "Shared a file"
        case let .sharedLocation(senderName):
            senderName != nil ? "\(senderName!) shared a location" : "Shared a location"
        case let .ping(senderName):
            senderName != nil ? "\(senderName!) pinged you" : "Pinged you"
        case .hidden:
            "New message"
        }
    }

}

extension NotificationBody {

    /// The expected formats for the body of a new conversation user message notification.
    enum NewMessageBodyDescriptor {
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
}
