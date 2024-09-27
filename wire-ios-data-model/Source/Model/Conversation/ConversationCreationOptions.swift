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

public struct ConversationCreationOptions {
    // MARK: Lifecycle

    public init(participants: [ZMUser] = [], name: String? = nil, team: Team? = nil, allowGuests: Bool = true) {
        self.participants = participants
        self.name = name
        self.team = team
        self.allowGuests = allowGuests
    }

    // MARK: Internal

    var participants: [ZMUser] = []
    var name: String?
    var team: Team?
    var allowGuests = true
}
