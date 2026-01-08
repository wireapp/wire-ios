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

import Foundation

package struct SSOLoginVerificationToken: Codable, Equatable {

    /// The unique identifier of the token.

    let uuid: UUID

    /// The creation date of the token.

    let creationDate: Date

    /// The amount of seconds the token should be considered valid.

    let timeToLive: TimeInterval

    /// Creates a new validation token with an expiration time
    /// of 30 minutes if not specified otherwise.

    init(
        uuid: UUID = .init(),
        creationDate: Date = .init(),
        timeToLive: TimeInterval = 60 * 30
    ) {
        self.uuid = uuid
        self.creationDate = creationDate
        self.timeToLive = timeToLive
    }

    /// Whether the token is no langer valid (older than its time to live).

    var isExpired: Bool {
        abs(creationDate.timeIntervalSinceNow) >= timeToLive
    }

    /// Validates a passed in UUID against the token.
    /// - parameter identifier: The uuid which should be validated against the token.
    /// - returns: Whether the UUID matches the token and the token is still valid.

    func matches(identifier: UUID) -> Bool {
        uuid == identifier && !isExpired
    }

}
