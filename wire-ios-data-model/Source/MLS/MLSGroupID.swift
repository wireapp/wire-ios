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

// MARK: - MLSGroupID

/// Represents the identifer for an MLS group.

public struct MLSGroupID: Equatable, Hashable {
    // MARK: Lifecycle

    public init?(base64Encoded string: String) {
        guard !string.isEmpty, let data = Data(base64Encoded: string) else { return nil }
        self.init(data)
    }

    public init(_ data: Data) {
        self.data = data
    }

    // MARK: Public

    // MARK: - Properties

    public let data: Data
}

// MARK: CustomStringConvertible

extension MLSGroupID: CustomStringConvertible {
    public var description: String {
        data.base64EncodedString()
    }
}

// MARK: SafeForLoggingStringConvertible

extension MLSGroupID: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        data.readableHash
    }
}
