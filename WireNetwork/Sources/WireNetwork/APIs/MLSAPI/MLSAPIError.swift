//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// Errors originating from `MLSAPI`.

public enum MLSAPIError: Error, Codable, Equatable {

    public init(from string: String) throws {
        self = try JSONDecoder().decode(MLSAPIError.self, from: Data(string.utf8))
    }

    public func encodeAsString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }

    /// Unsupported endpoint for API version

    case unsupportedEndpointForAPIVersion

    /// MLS is not configured on this backend

    case mlsNotEnabled

    /// Message was sent in an too old epoch

    case mlsStaleMessage

    /// A proposal of type Add or Remove does not apply to the full list of clients for a user

    case mlsClientMismatch

    /// The commit is not referencing all pending proposals

    case mlsCommitMissingReferences

    /// Generic error for all non recoverable MLS error

    case mlsError(_ label: String, _ message: String)

}
