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

class SendMLSMessagesActionHandlerTests: MessagingTestBase {

    let mlsMessage = "mlsMessage"
    var sut: SendMLSMessagesActionHandler!

    override func setUp() {
        super.setUp()
        sut = SendMLSMessagesActionHandler(context: syncMOC)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Request generation
    func test_itGenerateARequest() throws {
        // Given
        let action = SendMLSMessagesAction(mlsMessage: mlsMessage)

        // When
        let request = try XCTUnwrap(sut.request(for: action, apiVersion: .v1))

        // Then
        XCTAssertEqual(request.path, "/v1/mls/messages")
        XCTAssertEqual(request.method, .methodPOST)
        XCTAssertEqual(request.payload as? String, mlsMessage)
    }

    func test_itFailsToGeneratesRequestForUnsupportedAPIVersion() {
        test_itDoesntGenerateARequest(
            action: SendMLSMessagesAction(mlsMessage: mlsMessage),
            apiVersion: .v0
        ) {
            guard case .failure(.endpointUnavailable) = $0 else { return false }
            return true
        }
    }

    func test_itFailsToGeneratesRequestForInvalidBody() {
        test_itDoesntGenerateARequest(
            action: SendMLSMessagesAction(mlsMessage: ""),
            apiVersion: .v1
        ) {
            guard case .failure(.invalidBody) = $0 else { return false }
            return true
        }
    }

    // MARK: - Response handling
    func test_itHandlesResponse_201() {
        test_itHandlesResponse(status: 201, label: nil, expectationDescription: "didSucceed") {
            guard case .success = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_400() {
        test_itHandlesFailure(status: 400) {
            guard case .failure(.invalidBody) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_400_mlsProtocolError() {
        test_itHandlesFailure(status: 400, label: "mls-protocol-error") {
            guard case .failure(.mlsProtocolError) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_403_missingLegalHoldConsent() {
        test_itHandlesFailure(status: 403, label: "missing-legalhold-consent") {
            guard case .failure(.missingLegalHoldConsent) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_403_legalHoldNotEnabled() {
        test_itHandlesFailure(status: 403, label: "legalhold-not-enabled") {
            guard case .failure(.legalHoldNotEnabled) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_404_mlsProposalNotFound() {
        test_itHandlesFailure(status: 404, label: "mls-proposal-not-found") {
            guard case .failure(.mlsProposalNotFound) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_404_mlsKeyPackageRefNotFound() {
        test_itHandlesFailure(status: 404, label: "mls-key-package-ref-not-found") {
            guard case .failure(.mlsKeyPackageRefNotFound) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_404_noConversation() {
        test_itHandlesFailure(status: 404, label: "no-conversation") {
            guard case .failure(.noConversation) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_409_mlsStaleMessage() {
        test_itHandlesFailure(status: 409, label: "mls-stale-message") {
            guard case .failure(.mlsStaleMessage) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_409_mlsClientMismatch() {
        test_itHandlesFailure(status: 409, label: "mls-client-mismatch") {
            guard case .failure(.mlsClientMismatch) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_422_mlsUnsupportedProposal() {
        test_itHandlesFailure(status: 422, label: "mls-unsupported-proposal") {
            guard case .failure(.mlsUnsupportedProposal) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_422_mlsUnsupportedMessage() {
        test_itHandlesFailure(status: 422, label: "mls-unsupported-message") {
            guard case .failure(.mlsUnsupportedMessage) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_unkownError() {
        test_itHandlesFailure(status: 999) {
            guard case .failure(.unknown(status: 999)) = $0 else { return false }
            return true
        }
    }
}

// MARK: - Helpers Methods
extension SendMLSMessagesActionHandlerTests {

    private typealias Failure = SendMLSMessagesAction.Failure

    private func response(status: Int, label: String? = nil) -> ZMTransportResponse {
        var payload: [String: String]?
        if let label = label {
            payload = ["label": label]
        }

        return ZMTransportResponse(
            payload: payload as ZMTransportData?,
            httpStatus: status,
            transportSessionError: nil,
            apiVersion: APIVersion.v1.rawValue
        )
    }

    private func test_itHandlesFailure(status: Int, label: String? = nil, validateResult: @escaping (Swift.Result<Void, Failure>) -> Bool) {
        test_itHandlesResponse(status: status, label: label, expectationDescription: "didFail", validateResult: validateResult)
    }

    private func test_itHandlesResponse(status: Int, label: String?, expectationDescription: String, validateResult: @escaping (Swift.Result<Void, Failure>) -> Bool) {
        // Given
        var action = SendMLSMessagesAction(mlsMessage: mlsMessage)

        // Expectation
        let expectation = self.expectation(description: expectationDescription)

        action.onResult { result in
            guard validateResult(result) else { return }
            expectation.fulfill()
        }

        // When
        sut.handleResponse(response(status: status, label: label), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    private func test_itDoesntGenerateARequest(action: SendMLSMessagesAction, apiVersion: APIVersion = .v1, validateResult: @escaping (Swift.Result<Void, Failure>) -> Bool) {
        // Given
        var action = action

        // Expectation
        let expectation = self.expectation(description: "didFail")

        action.onResult { result in
            guard validateResult(result) else { return }
            expectation.fulfill()
        }

        // When
        let request = sut.request(for: action, apiVersion: apiVersion)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNil(request)
    }
}
