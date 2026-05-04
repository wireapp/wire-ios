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

/// The upgraded account's team information.

public struct UpgradedAccountTeam: Equatable, Sendable {

    /// The team's ID.
    public let teamId: UUID

    /// The team's name.
    public let teamName: String

    /// Create a new `UpgradedAccountTeam`.
    ///
    /// - Parameters:
    ///   - teamId: The team's ID.
    ///   - teamName: The team's name.

    public init(
        teamId: UUID,
        teamName: String
    ) {
        self.teamId = teamId
        self.teamName = teamName
    }

}
