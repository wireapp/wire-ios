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

/// The permissions of a team member.
///
/// From Swagger docs: This is just a complicated way of representing
/// a team role. self and copy always have to contain the same integer,
/// and only the following integers are allowed: 1025 (partner),
/// 1587 (member), 5951 (admin), 8191 (owner).

public struct TeamMemberPermissions: Equatable {
    // MARK: Lifecycle

    /// Create a new `TeamMemberPermissions`.
    ///
    /// - Parameters:
    ///   - selfPermissions: The permissions of the member.

    public init(
        copyPermissions: Int64,
        selfPermissions: Int64
    ) {
        self.copyPermissions = copyPermissions
        self.selfPermissions = selfPermissions
    }

    // MARK: Public

    public let copyPermissions: Int64

    /// The permissions of the member.

    public let selfPermissions: Int64
}
