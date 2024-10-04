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

/// A Proteus client prekey used to establish a Proteus session.

public struct Prekey: Equatable, Codable, Sendable {

    /// The prekey id.

    public let id: Int

    /// The base64-encoded prekey key.

    public let base64EncodedKey: String

    public init(
        id: Int,
        base64EncodedKey: String
    ) {
        self.id = id
        self.base64EncodedKey = base64EncodedKey
    }

}
