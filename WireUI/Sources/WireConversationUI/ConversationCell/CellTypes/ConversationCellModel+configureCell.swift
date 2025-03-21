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

    @MainActor
    func configureCell(_ cell: UITableViewCell) {
        switch self {

        case let .guestsAllowedInfo(guestsAllowedInfo):
            guard let cell = cell as? ConversationCell<GuestsAllowedInfoModel> else { break }
            return cell.model = guestsAllowedInfo

        case let .timeDivider(timeDivider):
            guard let cell = cell as? ConversationCell<TimeDividerModel> else { break }
            return cell.model = timeDivider

        case let .systemMessage(systemMessage):
            fatalError("not implemented yet")

        case let .ping(ping):
            fatalError("not implemented yet")

        case let .collapsedMessage(collapsedMessage):
            fatalError("not implemented yet")

        case let .compositeMessage(compositeMessage):
            fatalError("not implemented yet")

        case let .simpleTextMessage(simpleTextMessage):
            guard let cell = cell as? ConversationCell<SimpleTextMessageModel> else { break }
            return cell.model = simpleTextMessage

        case let .extendedTextMessage(extendedTextMessage):
            fatalError("not implemented yet")

        // case .audioMessage(let audioMessage):
        //     fatalError("not implemented yet")

        // case .videoMessage(let videoMessage):
        //     fatalError("not implemented yet")

        // case .fileMessage(let fileMessage):
        //     fatalError("not implemented yet")

        // case .location(let location):
        //     fatalError("not implemented yet")

        case let .deletedMessage(deletedMessage):
            fatalError("not implemented yet")
        }

        assertionFailure("unexpected cell: \(cell)")
    }

}
