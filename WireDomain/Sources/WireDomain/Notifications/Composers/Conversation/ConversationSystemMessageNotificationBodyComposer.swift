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

struct ConversationSystemMessageNotificationBodyComposer: NotificationComposer {
    let format: NotificationBody.SystemMessageBodyFormat

    // TODO: [WPB-15153] - Localize strings
    func make() -> String {
        switch format {
        case let .createdConversation(senderName):
            senderName != nil ? "\(senderName!) created a conversation" : "Someone created a conversation"
        case let .removedYou(senderName):
            senderName != nil ? "\(senderName!) removed you" : "Someone removed you"
        case let .setMessageTimer(senderName, timeoutValue):
            senderName != nil ? "\(senderName!) set the message timer to \(timeoutValue)" :
                "Someone set the message timer to \(timeoutValue)"
        case let .addedYou(senderName):
            senderName != nil ? "\(senderName!) added you" : "Someone added you"
        case let .turnedOffMessageTimer(senderName):
            senderName != nil ? "\(senderName!) turned off the message timer" : "Someone turned off the message timer"
        case let .deletedGroup(senderName):
            senderName != nil ? "\(senderName!) deleted the group" : "Someone deleted the group"
        }
    }
}
