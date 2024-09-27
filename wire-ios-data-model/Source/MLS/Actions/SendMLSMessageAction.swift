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

public final class SendMLSMessageAction: EntityAction {
    // MARK: Lifecycle

    public init(
        message: Data,
        resultHandler: ResultHandler? = nil
    ) {
        self.message = message
        self.resultHandler = resultHandler
    }

    // MARK: Public

    // MARK: - Types

    public typealias Result = [ZMUpdateEvent]

    public enum Failure: LocalizedError, Equatable {
        case endpointUnavailable
        case malformedRequest
        case malformedResponse

        // 400
        case mlsWelcomeMismatch
        case mlsGroupConversationMismatch
        case mlsClientSenderUserMismatch
        case mlsSelfRemovalNotAllowed
        case mlsCommitMissingReferences
        case mlsProtocolError
        case invalidRequestBody

        // 403
        case missingLegalHoldConsent
        case mlsMissingSenderClient
        case legalHoldNotEnabled
        case accessDenied

        // 404
        case mlsProposalNotFound
        case mlsKeyPackageRefNotFound
        case noConversation
        case noConversationMember

        // 409
        case mlsStaleMessage
        case mlsClientMismatch
        case unreachableDomains(Set<String>)

        // 422
        case mlsUnsupportedProposal
        case mlsUnsupportedMessage

        // 503
        case nonFederatingDomains(Set<String>)

        case unknown(status: Int, label: String, message: String)

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .endpointUnavailable:
                "Endpoint not available"

            case .malformedRequest:
                "The request could not be formed"

            case .malformedResponse:
                "The response payload could not be decoded"

            case .mlsWelcomeMismatch:
                "The list of targets of a welcome message does not match the list of new clients in a group"

            case .mlsGroupConversationMismatch:
                "Conversation ID resolved from group ID does not match submitted conversation ID"

            case .mlsClientSenderUserMismatch:
                "User ID resolved from client ID does not match message's sender user ID"

            case .mlsSelfRemovalNotAllowed:
                "Self removal from group is not allowed"

            case .mlsProtocolError:
                "MLS protocol error"

            case .mlsCommitMissingReferences:
                "The commit is not referencing all pending proposals"

            case .invalidRequestBody:
                "Invalid request body"

            case .missingLegalHoldConsent:
                "Failed to connect to a user or to invite a user to a group because somebody is under legal hold and somebody else has not granted consent"

            case .mlsMissingSenderClient:
                "The client has to refresh their access token and provide their client ID"

            case .legalHoldNotEnabled:
                "Legal hold is not enabled for this team"

            case .accessDenied:
                "Conversation access denied"

            case .mlsProposalNotFound:
                "A proposal referenced in a commit message could not be found"

            case .mlsKeyPackageRefNotFound:
                "A referenced key package could not be mapped to a known client"

            case .noConversation:
                "Conversation not found"

            case .noConversationMember:
                "Conversation member not found"

            case .mlsStaleMessage:
                "The conversation epoch in a message is too old"

            case .mlsClientMismatch:
                "A proposal of type Add or Remove does not apply to the full list of clients for a user"

            case let .nonFederatingDomains(domains):
                "Some domains are note fully connected: \(domains)"

            case .mlsUnsupportedProposal:
                "Unsupported proposal type"

            case .mlsUnsupportedMessage:
                "Attempted to send a message with an unsupported combination of content type and wire format"

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
}
