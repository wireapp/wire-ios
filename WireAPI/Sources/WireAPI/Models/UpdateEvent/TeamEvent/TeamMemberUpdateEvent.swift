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

/// An event where a user's team membership metadata was updated.

public struct TeamMemberUpdateEvent: Equatable, Codable {

    /// The team id.

    public let teamID: UUID

    /// The membership id.

    public let membershipID: UUID

    /// Create a new `TeamMemberUpdateEvent`.
    ///
    /// - Parameters:
    ///   - teamID: The id of the team.
    ///   - membershipID: The membership ID.

    public init(
        teamID: UUID,
        membershipID: UUID
    ) {
        self.teamID = teamID
        self.membershipID = membershipID
    }

}
