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

public final class SendMLSMessageAction: EntityAction {

    // MARK: - Types

    public typealias Result = [ZMUpdateEvent]

    public enum Failure: LocalizedError, Equatable {

        case endpointUnavailable
        case malformedRequest
        case malformedResponse

        case mlsGroupConversationMismatch
        case mlsClientSenderUserMismatch
        case mlsSelfRemovalNotAllowed
        case mlsCommitMissingReferences
        case mlsProtocolError
        case invalidRequestBody

        case missingLegalHoldConsent
        case legalHoldNotEnabled
        case accessDenied

        case mlsProposalNotFound
        case mlsKeyPackageRefNotFound
        case noConversation
        case noConversationMember

        case mlsStaleMessage
        case mlsClientMismatch
        case mlsUnsupportedProposal
        case mlsUnsupportedMessage

        case unknown(status: Int, label: String, message: String)

        public var errorDescription: String? {
            switch self {
            case .endpointUnavailable:
                return "Endpoint not available"

            case .malformedRequest:
                return "The request could not be formed"

            case .malformedResponse:
                return "The response payload could not be decoded"

            case .mlsGroupConversationMismatch:
                return "Conversation ID resolved from group ID does not match submitted conversation ID"

            case .mlsClientSenderUserMismatch:
                return "User ID resolved from client ID does not match message's sender user ID"

            case .mlsSelfRemovalNotAllowed:
                return "Self removal from group is not allowed"

            case .mlsProtocolError:
                return "MLS protocol error"

            case .mlsCommitMissingReferences:
                return "The commit is not referencing all pending proposals"

            case .invalidRequestBody:
                return "Invalid request body"

            case .missingLegalHoldConsent:
                return "Failed to connect to a user or to invite a user to a group because somebody is under legal hold and somebody else has not granted consent"

            case .legalHoldNotEnabled:
                return "Legal hold is not enabled for this team"

            case .accessDenied:
                return "Conversation access denied"

            case .mlsProposalNotFound:
                return "A proposal referenced in a commit message could not be found"

            case .mlsKeyPackageRefNotFound:
                return "A referenced key package could not be mapped to a known client"

            case .noConversation:
                return "Conversation not found"

            case .noConversationMember:
                return "Conversation member not found"

            case .mlsStaleMessage:
                return "The conversation epoch in a message is too old"

            case .mlsClientMismatch:
                return "A proposal of type Add or Remove does not apply to the full list of clients for a user"

            case .mlsUnsupportedProposal:
                return "Unsupported proposal type"

            case .mlsUnsupportedMessage:
                return "Attempted to send a message with an unsupported combination of content type and wire format"

            case let .unknown(status, label, message):
                return "Unknown error (response status: \(status), label: \(label), message: \(message))"
            }
        }
    }

    // MARK: - Properties

    public var message: Data
    public var resultHandler: ResultHandler?


    // MARK: - Life cycle

    public init(
        message: Data,
        resultHandler: ResultHandler? = nil
    ) {
        self.message = message
        self.resultHandler = resultHandler
    }
}
