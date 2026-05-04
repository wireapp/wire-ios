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

enum NotificationTitle {

    case conversationMessage(MessageTitleDescriptor)

    func make() -> String {
        switch self {
        case let .conversationMessage(titleDescriptor):
            make(titleDescriptor: titleDescriptor)
        }
    }

    private func make(titleDescriptor: MessageTitleDescriptor) -> String {
        switch titleDescriptor {
        case let .sender(sender):
            "\(sender)"
        case let .senderInTeam(sender, team):
            String.formated(key: "push.notification.title", bundle: .module, sender, team)
        case let .conversation(conversation):
            "\(conversation)"
        case let .conversationInTeam(conversation, team):
            String.formated(key: "push.notification.title", bundle: .module, conversation, team)
        }
    }

}

extension NotificationTitle {

    /// The expected formats for the title of a new message notification.
    enum MessageTitleDescriptor {
        /// `[sender name]`
        case sender(sender: String)
        /// `[sender name] in [team name]`
        case senderInTeam(sender: String, team: String)
        /// `[conversation name]`
        case conversation(conversation: String)
        /// `[conversation name] in [team name]`
        case conversationInTeam(conversation: String, team: String)
    }

}
