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

/// Represents the membership of a user to a particular team.

public struct TeamMember: Equatable {
    // MARK: Lifecycle

    /// Create a new `TeamMember`.
    ///
    /// - Parameters:
    ///   - userID: The id of the member.
    ///   - creationDate: When the member was created.
    ///   - creatorID: The id of the user who created this member.
    ///   - legalholdStatus: The legalhold status of the member.
    ///   - permissions: The member's permissions.

    public init(
        userID: UUID,
        creationDate: Date? = nil,
        creatorID: UUID? = nil,
        legalholdStatus: LegalholdStatus? = nil,
        permissions: TeamMemberPermissions? = nil
    ) {
        self.userID = userID
        self.creationDate = creationDate
        self.creatorID = creatorID
        self.legalholdStatus = legalholdStatus
        self.permissions = permissions
    }

    // MARK: Public

    /// The id of the member.

    public let userID: UUID

    /// When the member was created.

    public let creationDate: Date?

    /// The id of user who created this member.

    public let creatorID: UUID?

    /// The legalhold status of the member.

    public let legalholdStatus: LegalholdStatus?

    /// The member's permissions.

    public let permissions: TeamMemberPermissions?
}
