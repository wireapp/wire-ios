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

import XCTest
@testable import WireRequestStrategy

class SendMLSMessageActionHandlerTests: ActionHandlerTestBase<SendMLSMessageAction, SendMLSMessageActionHandler> {

    let mlsMessage = "mlsMessage"

    override func setUp() {
        super.setUp()
        action = SendMLSMessageAction(mlsMessage: mlsMessage)
    }

    // MARK: - Request generation
    func test_itGenerateARequest() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v1/mls/messages",
            expectedPayload: mlsMessage,
            expectedMethod: .methodPOST,
            apiVersion: .v1
        )
    }

    func test_itFailsToGenerateRequests() {
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v0,
            expectedError: .endpointUnavailable
        )

        test_itDoesntGenerateARequest(
            action: SendMLSMessageAction(mlsMessage: ""),
            apiVersion: .v1,
            expectedError: .invalidBody
        )
    }

    // MARK: - Response handling
    func test_itHandlesSuccess() {
        test_itHandlesSuccess(status: 201)
    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 400, error: .invalidBody),
            .failure(status: 400, error: .mlsProtocolError, label: "mls-protocol-error"),
            .failure(status: 403, error: .missingLegalHoldConsent, label: "missing-legalhold-consent"),
            .failure(status: 403, error: .legalHoldNotEnabled, label: "legalhold-not-enabled"),
            .failure(status: 404, error: .mlsProposalNotFound, label: "mls-proposal-not-found"),
            .failure(status: 404, error: .mlsKeyPackageRefNotFound, label: "mls-key-package-ref-not-found"),
            .failure(status: 404, error: .noConversation, label: "no-conversation"),
            .failure(status: 409, error: .mlsStaleMessage, label: "mls-stale-message"),
            .failure(status: 409, error: .mlsClientMismatch, label: "mls-client-mismatch"),
            .failure(status: 422, error: .mlsUnsupportedProposal, label: "mls-unsupported-proposal"),
            .failure(status: 422, error: .mlsUnsupportedMessage, label: "mls-unsupported-message"),
            .failure(status: 999, error: .unknown(status: 999))
        ])
    }
}
