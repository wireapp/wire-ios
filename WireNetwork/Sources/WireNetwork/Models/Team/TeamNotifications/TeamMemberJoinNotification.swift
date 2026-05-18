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

public import Foundation

/// An event where a user joined the team.

public struct TeamMemberJoinNotification: Equatable, Sendable {

    /// The team id.

    public let teamID: UUID

    /// The id of the member who joined.

    public let userID: UUID

    /// The time at which the member joined.

    public let time: Date

    public init(
        teamID: UUID,
        userID: UUID,
        time: Date
    ) {
        self.teamID = teamID
        self.userID = userID
        self.time = time
    }

}
