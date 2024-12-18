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

enum NotificationTitle {
    
    case newMessage(Format)
    
    enum Format {
        case senderOnly(sender: String)
        case senderInTeam(sender: String, team: String)
        case conversationOnly(conversation: String)
        case conversationInTeam(conversation: String, team: String)
    }
    
    func make() -> String {
        switch self {
        case .newMessage(let format):
            switch format {
            case .senderOnly(let sender):
                "\(sender)"
            case .senderInTeam(let sender, let team):
                "\(sender) in \(team)"
            case .conversationOnly(let conversation):
                "\(conversation)"
            case .conversationInTeam(let conversation, let team):
                "\(conversation) in \(team)"
            }
        }
    }
}
