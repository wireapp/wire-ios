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

class SendMLSMessageActionHandler: ActionHandler<SendMLSMessageAction> {

    typealias EventPayload = [AnyHashable: Any]

    // MARK: - Methods

    override func request(
        for action: SendMLSMessageAction,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {

        var action = action

        guard apiVersion > .v0 else {
            action.notifyResult(.failure(.endpointUnavailable))
            return nil
        }

        guard !action.message.isEmpty else {
            action.notifyResult(.failure(.invalidBody))
            return nil
        }

        return ZMTransportRequest(
            path: "/mls/messages",
            method: .methodPOST,
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

        switch (response.httpStatus, response.payloadLabel()) {
        case (201, _):
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

        case (400, "mls-protocol-error"):
            action.fail(with: .mlsProtocolError)

        case (400, _):
            action.fail(with: .invalidBody)

        case (403, "missing-legalhold-consent"):
            action.fail(with: .missingLegalHoldConsent)

        case (403, "legalhold-not-enabled"):
            action.fail(with: .legalHoldNotEnabled)

        case (404, "mls-proposal-not-found"):
            action.fail(with: .mlsProposalNotFound)

        case (404, "mls-key-package-ref-not-found"):
            action.fail(with: .mlsKeyPackageRefNotFound)

        case (404, "no-conversation"):
            action.fail(with: .noConversation)

        case (409, "mls-stale-message"):
            action.fail(with: .mlsStaleMessage)

        case (409, "mls-client-mismatch"):
            action.fail(with: .mlsClientMismatch)

        case (422, "mls-unsupported-proposal"):
            action.fail(with: .mlsUnsupportedProposal)

        case (422, "mls-unsupported-message"):
            action.fail(with: .mlsUnsupportedMessage)

        default:
            action.notifyResult(.failure(.unknown(status: response.httpStatus)))
        }
    }
}
