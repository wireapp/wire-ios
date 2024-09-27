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

// MARK: - ProteusSessionID

public struct ProteusSessionID: Hashable, Equatable {
    // MARK: - Properties

    public let userID: String
    public let clientID: String
    public let domain: String

    public var rawValue: String {
        guard !userID.isEmpty else {
            return clientID
        }

        guard !domain.isEmpty else {
            return "\(userID)_\(clientID)"
        }

        return "\(domain)_\(userID)_\(clientID)"
    }

    // MARK: - Life cycle

    public init(
        domain: String = "",
        userID: String,
        clientID: String
    ) {
        self.userID = userID
        self.clientID = clientID
        self.domain = domain
    }

    /// Use when migrating from old session identifier to new session identifier.

    init(fromLegacyV1Identifier clientID: String) {
        self.init(userID: "", clientID: clientID)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: ProteusSessionID, rhs: ProteusSessionID) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

// MARK: SafeForLoggingStringConvertible

extension ProteusSessionID: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        "<\(domain.readableHash)>_<\(userID.readableHash)>_<\(clientID.readableHash)>"
    }
}
