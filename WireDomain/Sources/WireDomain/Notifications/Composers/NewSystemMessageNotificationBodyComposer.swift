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

struct NewSystemMessageNotificationBodyComposer {
    let format: NotificationBody.SystemMessageBodyFormat

    // TODO: [WPB-15153] - Localize strings
    func make() -> String {
        switch format {
        case .createdConversation(let senderName):
            // TODO: [WPB-11657]
            ""
        case .removedYou(let senderName):
            senderName != nil ? "\(senderName!) removed you" : "Someone removed you"
        case .setMessageTimer(let senderName):
            // TODO: [WPB-11663]
            ""
        case .addedYou(let senderName):
            // TODO: [WPB-11661]
            ""
        case .turnedOffMessageTimer(let senderName):
            // TODO: [WPB-11663]
            ""
        case .deletedGroup(let senderName):
            // TODO: [WPB-11658]
            ""
        }
    }
}
