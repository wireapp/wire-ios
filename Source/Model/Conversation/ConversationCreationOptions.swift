//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public struct ConversationCreationOptions {
    var participants: [ZMUser]
    var name: String?
    var team: Team?
    var allowGuests: Bool
    
    public init(participants: [ZMUser], name: String?, team: Team?, allowGuests: Bool) {
        self.participants = participants
        self.name = name
        self.team = team
        self.allowGuests = allowGuests
    }
}

public extension ZMManagedObjectContextProvider {
    public func insertGroup(with options: ConversationCreationOptions) -> ZMConversation {
        return ZMConversation.insertGroupConversation(intoUserSession: self,
                                                      withParticipants: options.participants,
                                                      name: options.name,
                                                      in: options.team,
                                                      allowGuests: options.allowGuests)
    }
}
