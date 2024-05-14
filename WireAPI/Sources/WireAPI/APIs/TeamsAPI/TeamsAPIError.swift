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

/// Errors originating from `TeamsAPI`.

public enum TeamsAPIError: Error {

    /// A supplied team id is not valid.

    case invalidTeamID

    /// The requested team does not exist.

    case teamNotFound

    /// The self user is not part of a team.

    case selfUserIsNotTeamMember

    /// A requested team member could not be found.

    case teamMemberNotFound

    /// A request could not be generated.

    case failedToGenerateRequest

    /// An invalid query parameter was used.

    case invalidQueryParmeter

    /// A request was deemed invalid by the server.

    case invalidRequest

}
