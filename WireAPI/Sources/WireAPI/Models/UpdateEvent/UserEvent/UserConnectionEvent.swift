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

/// An event where a connection between the self user and
/// another user was updated.

public struct UserConnectionEvent: Equatable, Codable, Sendable {

    /// The name of the other user.

    public let userName: String

    /// The connection to the other user.

    public let connection: Connection

    public init(
        userName: String,
        connection: Connection
    ) {
        self.userName = userName
        self.connection = connection
    }

}
