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

import Foundation

enum NotificationBody {

    case singleMessage(NewMessageBodyDescriptor)
    case bundled(messagesCount: Int)

    func make() -> String {
        switch self {
        case let .singleMessage(newMessageBodyDescriptor):
            make(bodyDescriptor: newMessageBodyDescriptor)
        case let .bundled(count):
            String.formated(key: "push.notification.body.bundledMessages", bundle: .module, "\(count)")
        }
    }

    private func make(bodyDescriptor: NewMessageBodyDescriptor) -> String {
        switch bodyDescriptor {
        case .sentWithUnknownSender:
            String.localized(key: "push.notification.body.sentWithUnknownSender", bundle: .module)
        case .mentionedWithUnknownSender:
            String.localized(key: "push.notification.body.mentionedWithUnknownSender", bundle: .module)
        case .repliedWithUnknownSender:
            String.localized(key: "push.notification.body.repliedWithUnknownSender", bundle: .module)
        case let .text(content, senderName):
            if let senderName {
                "\(senderName): \(content)"
            } else {
                content
            }
        case let .textWithMention(content, senderName):
            if let senderName {
                String.formated(
                    key: "push.notification.body.textWithMentionFromSender",
                    bundle: .module,
                    senderName,
                    content
                )
            } else {
                String.formated(key: "push.notification.body.textWithMention", bundle: .module, content)
            }
        case let .textWithReply(content, senderName):
            if let senderName {
                String.formated(
                    key: "push.notification.body.textWithReplyFromSender",
                    bundle: .module,
                    senderName,
                    content
                )
            } else {
                String.formated(key: "push.notification.body.textWithReply", bundle: .module, content)
            }
        case let .sharedPicture(senderName):
            if let senderName {
                String.formated(key: "push.notification.body.senderSharedPicture", bundle: .module, senderName)
            } else {
                String.localized(key: "push.notification.body.sharedPicture", bundle: .module)
            }
        case let .sharedVideo(senderName):
            if let senderName {
                String.formated(key: "push.notification.body.senderSharedVideo", bundle: .module, senderName)
            } else {
                String.localized(key: "push.notification.body.sharedVideo", bundle: .module)
            }
        case let .sharedAudio(senderName):
            if let senderName {
                String.formated(key: "push.notification.body.senderSharedAudio", bundle: .module, senderName)
            } else {
                String.localized(key: "push.notification.body.sharedAudio", bundle: .module)
            }
        case let .sharedFile(senderName):
            if let senderName {
                String.formated(key: "push.notification.body.senderSharedFile", bundle: .module, senderName)
            } else {
                String.localized(key: "push.notification.body.sharedFile", bundle: .module)
            }
        case let .sharedLocation(senderName):
            if let senderName {
                String.formated(key: "push.notification.body.senderSharedLocation", bundle: .module, senderName)
            } else {
                String.localized(key: "push.notification.body.sharedLocation", bundle: .module)
            }
        case let .ping(senderName):
            if let senderName {
                String.formated(key: "push.notification.body.senderPingedYou", bundle: .module, senderName)
            } else {
                String.localized(key: "push.notification.body.ping", bundle: .module)
            }
        case .hidden:
            String.localized(key: "push.notification.body.hidden", bundle: .module)
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
