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
import WireNetwork

/// Errors originating from `MLSAPI` that pass through Core Crypto.
///
/// These errors originate from `MLSAPI` and are caught in
/// `MLSTransportImpl` which then need to be encoded to `String`
/// to pass over the CC border. When the errors pass back from CC
/// we'll need to decode them in order to handle them.

public enum MLSTransportError: Error, Codable {
    case invalidRequestBody
    case unsupportedEndpointForAPIVersion
    case mlsNotEnabled
    case mlsStaleMessage
    case mlsClientMismatch
    case mlsCommitMissingReferences
    case mlsInvalidLeafNodeIndex
    case mlsInvalidLeafNodeSignature
    case mlsError(_ label: String, _ message: String)
    case mlsProtocolError(message: String)
    case mlsGroupIdNotSupported(message: String)
    case mlsFederatedResetNotSupported(message: String)
    case actionDenied(message: String)
    case accessDenied(message: String)
    case invalidOperation(message: String)
    case noConversation(message: String)
    case groupOutOfSync(missingUsers: Set<QualifiedID>)

    public init(_ error: MLSAPIError) {
        switch error {
        case .invalidRequestBody:
            self = .invalidRequestBody
        case .unsupportedEndpointForAPIVersion:
            self = .unsupportedEndpointForAPIVersion
        case .mlsNotEnabled:
            self = .mlsNotEnabled
        case .mlsStaleMessage:
            self = .mlsStaleMessage
        case .mlsClientMismatch:
            self = .mlsClientMismatch
        case .mlsCommitMissingReferences:
            self = .mlsCommitMissingReferences
        case .mlsInvalidLeafNodeIndex:
            self = .mlsInvalidLeafNodeIndex
        case .mlsInvalidLeafNodeSignature:
            self = .mlsInvalidLeafNodeSignature
        case let .mlsError(label, message):
            self = .mlsError(label, message)
        case let .mlsProtocolError(message):
            self = .mlsProtocolError(message: message)
        case let .mlsGroupIdNotSupported(message):
            self = .mlsGroupIdNotSupported(message: message)
        case let .mlsFederatedResetNotSupported(message):
            self = .mlsFederatedResetNotSupported(message: message)
        case let .actionDenied(message):
            self = .actionDenied(message: message)
        case let .accessDenied(message):
            self = .accessDenied(message: message)
        case let .invalidOperation(message):
            self = .invalidOperation(message: message)
        case let .noConversation(message):
            self = .noConversation(message: message)
        case let .groupOutOfSync(missingUsers):
            let missingUsers = missingUsers.map {
                QualifiedID(uuid: $0.id, domain: $0.domain)
            }
            self = .groupOutOfSync(missingUsers: Set(missingUsers))
        }
    }
}
