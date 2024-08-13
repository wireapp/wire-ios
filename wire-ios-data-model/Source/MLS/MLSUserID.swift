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

/// A qualified id for MLS users.

public struct MLSUserID {

    // MARK: - Properties

    public let rawValue: String

    // MARK: - Life cycle

    public init?(rawValue: String) {
        let components = rawValue.split(
            separator: "@",
            omittingEmptySubsequences: false
        )

        guard components.count == 2 else { return nil }

        let userID = components[0]
        let domain = components[1]
        self.init(
            userID: String(userID),
            domain: String(domain)
        )
    }

    public init?(userID: String, domain: String) {
        if userID.isEmpty || domain.isEmpty {
            return nil
        }
        rawValue = "\(userID.lowercased())@\(domain.lowercased())"
    }
}
