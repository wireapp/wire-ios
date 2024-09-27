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

/// Represents a team to which members can belong to.

public struct Team: Identifiable, Equatable {
    // MARK: Lifecycle

    /// Create a new `Team`.
    ///
    /// - Parameters:
    ///   - id: The unique id of the team.
    ///   - name: The team name.
    ///   - creatorID: The user id of the team's creator.
    ///   - logoID: The asset id of the team logo.
    ///   - logoKey: The asset decryption key of the team logo.
    ///   - splashScreenID: The assit id of the team's splash screen.

    public init(
        id: UUID,
        name: String,
        creatorID: UUID,
        logoID: String,
        logoKey: String? = nil,
        splashScreenID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.creatorID = creatorID
        self.logoID = logoID
        self.logoKey = logoKey
        self.splashScreenID = splashScreenID
    }

    // MARK: Public

    /// The unique id of the team.

    public var id: UUID

    /// The team name.

    public let name: String

    /// The user id of the team's creator.

    public let creatorID: UUID

    /// The asset id of the team logo.

    public let logoID: String

    /// The asset decryption key of the team logo.

    public let logoKey: String?

    /// The asset id of the team's splash screen.

    public let splashScreenID: String?
}
