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

/// Errors originating from `MLSAPI`.

public enum MLSAPIError: Error, Equatable {

    /// Request body is invalid

    case invalidRequestBody

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

    /// A referenced leaf node index points to a blank or non-existing node

    case mlsInvalidLeafNodeIndex

    /// A referenced leaf node signature is invalid

    case mlsInvalidLeafNodeSignature

    /// Generic error for all non recoverable MLS error

    case mlsError(_ label: String, _ message: String)

    /// MLS protocol error

    case mlsProtocolError(message: String)

    /// Key package credential does not match qualified client ID

    case mlsIdentityMismatch

    /// The group ID version of the conversation is not supported by one of the federated backends

    case mlsGroupIdNotSupported(message: String)

    /// Reset is not supported by the owning backend of the conversation

    case mlsFederatedResetNotSupported(message: String)

    /// Insufficient authorization (missing leave_conversation)

    case actionDenied(message: String)

    /// Conversation access denied

    case accessDenied(message: String)

    /// Invalid operation

    case invalidOperation(message: String)

    /// Conversation not found

    case noConversation(message: String)

    /// The MLS group is not in sync with the backend because
    /// some users are missing.

    case groupOutOfSync(missingUsers: Set<QualifiedID>)

    /// Client not found

    case clientNotFound

}

enum MLSAPIV0Error: Error, Codable, Equatable {

    case unsupportedEndpointForAPIVersion
    case mlsNotEnabled
    case mlsStaleMessage
    case mlsClientMismatch
    case mlsCommitMissingReferences
    case mlsError(_ label: String, _ message: String)
    case mlsProtocolError(message: String)
    case mlsGroupIdNotSupported(message: String)
    case mlsFederatedResetNotSupported(message: String)
    case actionDenied(message: String)
    case accessDenied(message: String)
    case invalidOperation(message: String)
    case invalidRequestBody
    case noConversation(message: String)
    case mlsInvalidLeafNodeIndex
    case mlsInvalidLeafNodeSignature
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
        case let .mlsProtocolError(message: message):
            .mlsProtocolError(message: message)
        case let .mlsGroupIdNotSupported(message: message):
            .mlsGroupIdNotSupported(message: message)
        case let .mlsFederatedResetNotSupported(message: message):
            .mlsFederatedResetNotSupported(message: message)
        case let .actionDenied(message: message):
            .actionDenied(message: message)
        case let .accessDenied(message: message):
            .accessDenied(message: message)
        case let .invalidOperation(message: message):
            .invalidOperation(message: message)
        case .invalidRequestBody:
            .invalidRequestBody
        case let .noConversation(message: message):
            .noConversation(message: message)
        case .mlsInvalidLeafNodeIndex:
            .mlsInvalidLeafNodeIndex
        case .mlsInvalidLeafNodeSignature:
            .mlsInvalidLeafNodeSignature
        }
    }
}
