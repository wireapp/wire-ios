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

public enum SendMLSMessageFailure: Error, LocalizedError, Equatable {

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
    case mlsInvalidLeafNodeIndex(message: String)
    case mlsInvalidLeafNodeSignature(message: String)

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
    case groupOutOfSync(missingUsers: Set<QualifiedID>)

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

        case let .mlsWelcomeMismatch(message):
            "The list of targets of a welcome message does not match the list of new clients in a group. message: \(message)"

        case let .mlsGroupConversationMismatch(message):
            "Conversation ID resolved from group ID does not match submitted conversation ID. message: \(message)"

        case let .mlsClientSenderUserMismatch(message):
            "User ID resolved from client ID does not match message's sender user ID. message: \(message)"

        case let .mlsSelfRemovalNotAllowed(message):
            "Self removal from group is not allowed. message: \(message)"

        case let .mlsProtocolError(message):
            "MLS protocol error. message: \(message)"

        case .mlsCommitMissingReferences:
            "The commit is not referencing all pending proposals"

        case let .invalidRequestBody(message):
            "Invalid request body. message: \(message)"

        case let .mlsInvalidLeafNodeIndex(message):
            "A referenced leaf node index points to a blank or non-existing node: \(message)"

        case let .mlsInvalidLeafNodeSignature(message):
            "Invalid leaf node signature: \(message)"

        case let .missingLegalHoldConsent(message):
            "Failed to connect to a user or to invite a user to a group because somebody is under legal hold and somebody else has not granted consent. message: \(message)"

        case let .mlsMissingSenderClient(message):
            "The client has to refresh their access token and provide their client ID. message: \(message)"

        case let .legalHoldNotEnabled(message):
            "Legal hold is not enabled for this team. message: \(message)"

        case let .accessDenied(message):
            "Conversation access denied. message: \(message)"

        case let .mlsProposalNotFound(message):
            "A proposal referenced in a commit message could not be found. message: \(message)"

        case let .mlsKeyPackageRefNotFound(message):
            "A referenced key package could not be mapped to a known client. message: \(message)"

        case let .noConversation(message):
            "Conversation not found. message: \(message)"

        case let .noConversationMember(message):
            "Conversation member not found. message: \(message)"

        case .mlsStaleMessage:
            "The conversation epoch in a message is too old"

        case .mlsClientMismatch:
            "A proposal of type Add or Remove does not apply to the full list of clients for a user"

        case let .nonFederatingDomains(domains):
            "Some domains are note fully connected: \(domains)"

        case let .mlsUnsupportedProposal(message):
            "Unsupported proposal type. message: \(message)"

        case let .mlsUnsupportedMessage(message):
            "Attempted to send a message with an unsupported combination of content type and wire format. message: \(message)"

        case let .unknown(status, label, message):
            "Unknown error (response status: \(status), label: \(label), message: \(message))"

        case let .unreachableDomains(domains):
            "Some domains were unreachable: \(domains)"

        case let .groupOutOfSync(missingUsers):
            "The group is missing \(missingUsers.count) users"
        }
    }

    public init?(from response: ZMTransportResponse) {

        let label = response.payloadLabel() ?? ""
        let payloadMessage = response.payloadMessage() ?? ""

        switch (response.httpStatus, label) {
        case (400, "mls-group-conversation-mismatch"):
            self = .mlsGroupConversationMismatch(message: payloadMessage)

        case (400, "mls-client-sender-user-mismatch"):
            self = .mlsClientSenderUserMismatch(message: payloadMessage)

        case (400, "mls-self-removal-not-allowed"):
            self = .mlsSelfRemovalNotAllowed(message: payloadMessage)

        case (400, "mls-commit-missing-references"):
            self = .mlsCommitMissingReferences(message: payloadMessage)

        case (400, "mls-protocol-error"):
            self = .mlsProtocolError(message: payloadMessage)

        case (400, "mls-invalid-leaf-node-index"):
            self = .mlsInvalidLeafNodeIndex(message: payloadMessage)

        case (400, "mls-invalid-leaf-node-signature"):
            self = .mlsInvalidLeafNodeSignature(message: payloadMessage)

        case (400, _):
            self = .invalidRequestBody(message: payloadMessage)

        case (403, "missing-legalhold-consent"):
            self = .missingLegalHoldConsent(message: payloadMessage)

        case (403, "legalhold-not-enabled"):
            self = .legalHoldNotEnabled(message: payloadMessage)

        case (403, "access-denied"):
            self = .accessDenied(message: payloadMessage)

        case (404, "mls-proposal-not-found"):
            self = .mlsProposalNotFound(message: payloadMessage)

        case (404, "mls-key-package-ref-not-found"):
            self = .mlsKeyPackageRefNotFound(message: payloadMessage)

        case (404, "no-conversation"):
            self = .noConversation(message: payloadMessage)

        case (404, "no-conversation-member"):
            self = .noConversationMember(message: payloadMessage)

        case (409, "mls-stale-message"):
            self = .mlsStaleMessage

        case (409, "mls-client-mismatch"):
            self = .mlsClientMismatch

        case (422, "mls-unsupported-proposal"):
            self = .mlsUnsupportedProposal(message: payloadMessage)

        case (422, "mls-unsupported-message"):
            self = .mlsUnsupportedMessage(message: payloadMessage)

        default:
            return nil
        }
    }

}
