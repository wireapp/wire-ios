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

extension ConversationCellModel: Identifiable {

    public var id: AnyHashable {
        switch self {

        case .guestsAllowedInfo(let guestsAllowedInfo):
            guestsAllowedInfo.id

        case .timeDivider(let timeDivider):
            timeDivider.id

        case .systemMessage(let systemMessage):
            systemMessage.id

        case .ping(let ping):
            fatalError()

        case .collapsedMessage(let collapsedMessage):
            fatalError()

        case .compositeMessage(let compositeMessage):
            fatalError()

        case .simpleTextMessage(let simpleTextMessage):
            fatalError()

        case .extendedTextMessage(let extendedTextMessage):
            fatalError()

        // case .audioMessage(let audioMessage):
        //     fatalError()

        // case .videoMessage(let videoMessage):
        //     fatalError()

        // case .fileMessage(let fileMessage):
        //     fatalError()

        // case .location(let location):
        //     fatalError()

        case .deletedMessage(let deletedMessage):
            fatalError()

        case .typingIndicator(let typingIndicator):
            fatalError()

        }
    }

}
