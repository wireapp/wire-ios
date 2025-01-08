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

struct NewUserMessageNotificationBodyComposer {
    let format: NotificationBody.UserMessageBodyFormat

    // TODO: [WPB-15153] - Localize strings
    func make() -> String {
        switch format {
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
