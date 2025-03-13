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

extension ConversationCellModel {

    @MainActor
    public func configureCell(_ cell: UITableViewCell) {
        switch self {

        case .guestsAllowedInfo(let guestsAllowedInfo):
            guard let cell = cell as? ConversationCell<GuestsAllowedInfoModel> else { break }
            return cell.model = guestsAllowedInfo

        case .timeDivider(let timeDivider):
            guard let cell = cell as? ConversationCell<TimeDividerModel> else { break }
            return cell.model = timeDivider

        case .systemMessage(let systemMessage):
            fatalError("not implemented yet")

        case .ping(let ping):
            fatalError("not implemented yet")

        case .collapsedMessage(let collapsedMessage):
            fatalError("not implemented yet")

        case .compositeMessage(let compositeMessage):
            fatalError("not implemented yet")

        case .simpleTextMessage(let simpleTextMessage):
            fatalError("not implemented yet")

        case .extendedTextMessage(let extendedTextMessage):
            fatalError("not implemented yet")

        // case .audioMessage(let audioMessage):
        //     fatalError("not implemented yet")

        // case .videoMessage(let videoMessage):
        //     fatalError("not implemented yet")

        // case .fileMessage(let fileMessage):
        //     fatalError("not implemented yet")

        // case .location(let location):
        //     fatalError("not implemented yet")

         case .typingIndicator(let typingIndicator):
             fatalError("not implemented yet")

        }

        assertionFailure("unexpected cell: \(cell)")
    }

}
