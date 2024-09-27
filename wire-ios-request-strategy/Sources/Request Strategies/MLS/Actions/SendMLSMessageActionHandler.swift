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
import WireDataModel

// MARK: - SendMLSMessageActionHandler

class SendMLSMessageActionHandler: ActionHandler<SendMLSMessageAction> {
    typealias EventPayload = [AnyHashable: Any]

    // MARK: - Methods

    override func request(
        for action: SendMLSMessageAction,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        var action = action

        guard apiVersion >= .v5 else {
            action.fail(with: .endpointUnavailable)
            return nil
        }

        guard !action.message.isEmpty else {
            action.fail(with: .malformedRequest)
            return nil
        }

        return ZMTransportRequest(
            path: "/mls/messages",
            method: .post,
            binaryData: action.message,
            type: "message/mls",
            contentDisposition: nil,
            shouldCompress: false,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: SendMLSMessageAction
    ) {
        var action = action

        if let error = SendMLSMessageAction.Failure(from: response) {
            action.fail(with: error)
        } else {
            guard
                let payload = response.payload?.asDictionary(),
                let eventsData = payload["events"] as? [EventPayload]
            else {
                action.fail(with: .malformedResponse)
                return
            }

            let updateEvents = eventsData.compactMap { eventData in
                ZMUpdateEvent(
                    uuid: nil,
                    payload: eventData,
                    transient: false,
                    decrypted: false,
                    source: .download
                )
            }

            action.succeed(with: updateEvents)
        }
    }
}

extension SendMLSMessageAction.Failure {
    init?(from response: ZMTransportResponse) {
        switch (response.httpStatus, response.payloadLabel()) {
        case (201, _):
            return nil

        case (400, "mls-group-conversation-mismatch"):
            self = .mlsGroupConversationMismatch

        case (400, "mls-client-sender-user-mismatch"):
            self = .mlsClientSenderUserMismatch

        case (400, "mls-self-removal-not-allowed"):
            self = .mlsSelfRemovalNotAllowed

        case (400, "mls-commit-missing-references"):
            self = .mlsCommitMissingReferences

        case (400, "mls-protocol-error"):
            self = .mlsProtocolError

        case (400, _):
            self = .invalidRequestBody

        case (403, "missing-legalhold-consent"):
            self = .missingLegalHoldConsent

        case (403, "legalhold-not-enabled"):
            self = .legalHoldNotEnabled

        case (403, "access-denied"):
            self = .accessDenied

        case (404, "mls-proposal-not-found"):
            self = .mlsProposalNotFound

        case (404, "mls-key-package-ref-not-found"):
            self = .mlsKeyPackageRefNotFound

        case (404, "no-conversation"):
            self = .noConversation

        case (404, "no-conversation-member"):
            self = .noConversationMember

        case (409, "mls-stale-message"):
            self = .mlsStaleMessage

        case (409, "mls-client-mismatch"):
            self = .mlsClientMismatch

        case (422, "mls-unsupported-proposal"):
            self = .mlsUnsupportedProposal

        case (422, "mls-unsupported-message"):
            self = .mlsUnsupportedMessage

        default:
            let errorInfo = response.errorInfo
            self = .unknown(
                status: response.httpStatus,
                label: errorInfo.label,
                message: errorInfo.message
            )
        }
    }
}
