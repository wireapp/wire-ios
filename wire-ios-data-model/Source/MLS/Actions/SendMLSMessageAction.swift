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

public final class SendMLSMessageAction: EntityAction {

    // MARK: - Types

    public typealias Result = [ZMUpdateEvent]

    public enum Failure: LocalizedError, Equatable {

        case endpointUnavailable
        case malformedRequest
        case malformedResponse

        // 400
        case mlsWelcomeMismatch(message: String)
        case mlsGroupConversationMismatch(message: String)
        case mlsClientSenderUserMismatch(message: String)
        case mlsSelfRemovalNotAllowed(message: String)
        case mlsCommitMissingReferences(message: String)
        case mlsProtocolError(message: String)
        case invalidRequestBody(message: String)

        // 403
        case missingLegalHoldConsent(message: String)
        case mlsMissingSenderClient(message: String)
        case legalHoldNotEnabled(message: String)
        case accessDenied(message: String)

        // 404
        case mlsProposalNotFound(message: String)
        case mlsKeyPackageRefNotFound(message: String)
        case noConversation(message: String)
        case noConversationMember(message: String)

        // 409
        case mlsStaleMessage
        case mlsClientMismatch
        case unreachableDomains(Set<String>)

        // 422
        case mlsUnsupportedProposal(message: String)
        case mlsUnsupportedMessage(message: String)

        // 503
        case nonFederatingDomains(Set<String>)

        case unknown(status: Int, label: String, message: String)

        public var errorDescription: String? {
            switch self {
            case .endpointUnavailable:
                "Endpoint not available"

            case .malformedRequest:
                "The request could not be formed"

            case .malformedResponse:
                "The response payload could not be decoded"

            case .mlsWelcomeMismatch(let message):
                "The list of targets of a welcome message does not match the list of new clients in a group. message: \(message)"

            case .mlsGroupConversationMismatch(let message):
                "Conversation ID resolved from group ID does not match submitted conversation ID. message: \(message)"

            case .mlsClientSenderUserMismatch(let message):
                "User ID resolved from client ID does not match message's sender user ID. message: \(message)"

            case .mlsSelfRemovalNotAllowed(let message):
                "Self removal from group is not allowed. message: \(message)"

            case .mlsProtocolError(let message):
                "MLS protocol error. message: \(message)"

            case .mlsCommitMissingReferences:
                "The commit is not referencing all pending proposals"

            case .invalidRequestBody(let message):
                "Invalid request body. message: \(message)"

            case .missingLegalHoldConsent(let message):
                "Failed to connect to a user or to invite a user to a group because somebody is under legal hold and somebody else has not granted consent. message: \(message)"

            case .mlsMissingSenderClient(let message):
                "The client has to refresh their access token and provide their client ID. message: \(message)"

            case .legalHoldNotEnabled(let message):
                "Legal hold is not enabled for this team. message: \(message)"

            case .accessDenied(let message):
                "Conversation access denied. message: \(message)"

            case .mlsProposalNotFound(let message):
                "A proposal referenced in a commit message could not be found. message: \(message)"

            case .mlsKeyPackageRefNotFound(let message):
                "A referenced key package could not be mapped to a known client. message: \(message)"

            case .noConversation(let message):
                "Conversation not found. message: \(message)"

            case .noConversationMember(let message):
                "Conversation member not found. message: \(message)"

            case .mlsStaleMessage:
                "The conversation epoch in a message is too old"

            case .mlsClientMismatch:
                "A proposal of type Add or Remove does not apply to the full list of clients for a user"

            case let .nonFederatingDomains(domains):
                "Some domains are note fully connected: \(domains)"

            case .mlsUnsupportedProposal(let message):
                "Unsupported proposal type. message: \(message)"

            case .mlsUnsupportedMessage(let message):
                "Attempted to send a message with an unsupported combination of content type and wire format. message: \(message)"

            case let .unknown(status, label, message):
                "Unknown error (response status: \(status), label: \(label), message: \(message))"

            case let .unreachableDomains(domains):
                "Some domains were unreachable: \(domains)"
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
