//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

public final class SendMLSMessagesAction: EntityAction {

    // MARK: - Types

    public typealias Result = Void

    public enum Failure: LocalizedError {

        case invalidBody
        case mlsProtocolError
        case missingLegalHoldConsent
        case legalHoldNotEnabled
        case mlsProposalNotFound
        case mlsKeyPackageRefNotFound
        case noConversation
        case mlsStaleMessage
        case mlsClientMismatch
        case mlsUnsupportedProposal
        case mlsUnsupportedMessage
        case endpointUnavailable
        case malformedResponse
        case unknown(status: Int)

        public var errorDescription: String? {
            switch self {
            case .invalidBody:
                return "Invalid body"
            case .mlsProtocolError:
                return "MLS protocol error"
            case .missingLegalHoldConsent:
                return "Failed to connect to a user or to invite a user to a group because somebody is under legal hold and somebody else has not granted consent"
            case .legalHoldNotEnabled:
                return "Legal hold is not enabled for this team"
            case .mlsProposalNotFound:
                return "A proposal referenced in a commit message could not be found"
            case .mlsKeyPackageRefNotFound:
                return "A referenced key package could not be mapped to a known client"
            case .noConversation:
                return "Conversation not found"
            case .mlsStaleMessage:
                return "The conversation epoch in a message is too old"
            case .mlsClientMismatch:
                return "A proposal of type Add or Remove does not apply to the full list of clients for a user"
            case .mlsUnsupportedProposal:
                return "Unsupported proposal type"
            case .mlsUnsupportedMessage:
                return "Attempted to send a message with an unsupported combination of content type and wire format"
            case .endpointUnavailable:
                return "End point not available"
            case .malformedResponse:
                return "Malformed response"
            case .unknown(status: let status):
                return "Unknown error (response status: \(status))"
            }
        }
    }

    // MARK: - Properties

    public var resultHandler: ResultHandler?
    public var mlsMessage: String

    // MARK: - Life cycle

    init(mlsMessage: String,
         resultHandler: ResultHandler? = nil) {
        self.mlsMessage = mlsMessage
        self.resultHandler = resultHandler
    }
}
