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

import UIKit

public extension ConversationCellModel {

    var cellReuseIdentifier: String {
        switch self {

        case .guestsAllowedInfo:
            "guestsAllowedInfo"

        case .timeDivider:
            "timeDivider"

        case .systemMessage:
            "systemMessage"

        case .ping:
            "ping"

        case .collapsedMessage:
            "collapsedMessage"

        case .compositeMessage:
            "compositeMessage"

        case .simpleTextMessage:
            "simpleTextMessage"

        case .extendedTextMessage:
            "extendedTextMessage"

        // case .audioMessage:
        //     "audioMessage"

        // case .videoMessage:
        //     "videoMessage"

        // case .fileMessage:
        //     "fileMessage"

        // case .location:
        //     "location"

        case .deletedMessage:
            "deletedMessage"

        case .typingIndicator:
            "typingIndicator"
        }
    }

}
