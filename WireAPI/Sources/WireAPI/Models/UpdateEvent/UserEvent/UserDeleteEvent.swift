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

/// An event where the account of a user (either the
/// self user or another user) was deleted.

public struct UserDeleteEvent: Equatable, Codable, Sendable {

    /// The user's qualified id.

    public let qualifiedUserID: QualifiedID
    
    /// The time at which the member was deleted.

    public let time: Date
    
    public init(
        qualifiedUserID: QualifiedID,
        time: Date
    ) {
        self.qualifiedUserID = qualifiedUserID
        self.time = time
    }

}
