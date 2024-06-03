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

/// An event concerning teams.

public enum TeamEvent: Equatable {

    /// A team conversation was created.

    case conversationCreate

    /// A team conversation was deleted.

    case conversationDelete

    /// The self team was deleted.

    case delete

    /// A user has left a team.

    case memberLeave(TeamMemberLeaveEventData)

    /// A member of the self team has updated their metadata.

    case memberUpdate

}
