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

/// Which users are allowed to be participants in a conversation.

public enum ConversationAccessRole: String, Codable, Sendable {

    /// Members of the owning team.

    case teamMember = "team_member"

    /// Any user outside the owning team.

    case nonTeamMember = "non_team_member"

    /// Users that are not in the team and are not services.

    case guest

    /// Service users (aka bots).

    case service

}
