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

public enum MLSAPIError: Error, Equatable {

    public init(from string: String) throws {
        let error = try JSONDecoder().decode(MLSAPIV0Error.self, from: Data(string.utf8))
        self = error.toAPIModel()
    }

    public func encodeAsString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodableObject = toNetworkModel()
        return String(decoding: try encoder.encode(encodableObject), as: UTF8.self)
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

enum MLSAPIV0Error: Error, Codable, Equatable {

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

extension MLSAPIV0Error: ToAPIModelConvertible {

    func toAPIModel() -> MLSAPIError {
        switch self {

        case .unsupportedEndpointForAPIVersion:
            .unsupportedEndpointForAPIVersion
        case .mlsNotEnabled:
            .mlsNotEnabled
        case .mlsStaleMessage:
            .mlsStaleMessage
        case .mlsClientMismatch:
            .mlsClientMismatch
        case .mlsCommitMissingReferences:
            .mlsCommitMissingReferences
        case let .mlsError(label, message):
            .mlsError(label, message)
        }
    }
}

extension MLSAPIError: ToNetworkConvertible {

    func toNetworkModel() -> MLSAPIV0Error {
        switch self {

        case .unsupportedEndpointForAPIVersion:
            .unsupportedEndpointForAPIVersion
        case .mlsNotEnabled:
            .mlsNotEnabled
        case .mlsStaleMessage:
            .mlsStaleMessage
        case .mlsClientMismatch:
            .mlsClientMismatch
        case .mlsCommitMissingReferences:
            .mlsCommitMissingReferences
        case let .mlsError(label, message):
            .mlsError(label, message)
        }
    }
}
