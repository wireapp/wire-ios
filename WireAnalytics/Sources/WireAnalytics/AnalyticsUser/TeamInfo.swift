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

/// A struct representing information about the user's team.

public struct TeamInfo {

    /// The identifier for the team the user belongs to.
    public let id: String

    /// The role of the user within the team.
    public let role: String

    /// The size of the team the user belongs to.
    public let size: UInt

    public init(id: String, role: String, size: UInt) {
        self.id = id
        self.role = role
        self.size = size
    }
}
