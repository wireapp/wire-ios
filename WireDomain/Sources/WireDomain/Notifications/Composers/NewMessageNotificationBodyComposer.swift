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

struct NewMessageNotificationBodyComposer {
    let format: NotificationBody.MessageBodyFormat
    
    func make() -> String {
        switch format {
        case .sentWithUnknownSender:
            "Someone sent a message"
        case .mentionedWithUnknownSender:
            "Someone mentioned you"
        case .repliedWithUnknownSender:
            "Someone replied to you"
        case .text(let content, let senderName):
            senderName != nil ? "\(senderName!): \(content)" : content
        case .textWithMention(let content, let senderName):
            senderName != nil ? "Mention from \(senderName!): \(content)" : "Mention: \(content)"
        case .textWithReply(let content, let senderName):
            senderName != nil ? "Reply from \(senderName!): \(content)" : "Reply: \(content)"
        case .sharedPicture(let senderName):
            senderName != nil ? "\(senderName!) shared a picture" : "Shared a picture"
        case .sharedVideo(let senderName):
            senderName != nil ? "\(senderName!) shared a video" : "Shared a video"
        case .sharedAudio(let senderName):
            senderName != nil ? "\(senderName!) shared an audio message" : "Shared an audio message"
        case .sharedFile(let senderName):
            senderName != nil ? "\(senderName!) shared a file" : "Shared a file"
        case .sharedLocation(let senderName):
            senderName != nil ? "\(senderName!) shared a location" : "Shared a location"
        }
    }
}
