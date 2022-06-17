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
@testable import WireRequestStrategy

class SendMLSWelcomeActionHandlerTests: MessagingTestBase {

    let body = "abc123"

    // MARK: - Request generation

    func test_itGenerateARequest() throws {
        // Given
        let sut = SendMLSWelcomeActionHandler(context: syncMOC)
        let action = SendMLSWelcomeAction(body: body)

        // When
        let request = try XCTUnwrap(sut.request(for: action, apiVersion: .v1))

        // Then
        XCTAssertEqual(request.path, "/v1/mls/welcome")
        XCTAssertEqual(request.method, .methodPOST)
        XCTAssertEqual(request.payload as? String, body)
    }

    func test_itDoesntGenerateARequest_WhenAPIVersionIsNotSupported() {
        test_itDoesntGenerateARequest(
            action: SendMLSWelcomeAction(body: body),
            apiVersion: .v0
        ) {
            guard case .failure(.endpointUnavailable) = $0 else { return false }
            return true
        }
    }

    func test_itDoesntGenerateARequest_WhenParametersAreEmpty() {
        test_itDoesntGenerateARequest(
            action: SendMLSWelcomeAction(body: ""),
            apiVersion: .v1
        ) {
            guard case .failure(.emptyParameters) = $0 else { return false }
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

    func test_itHandlesResponse_404() {
        test_itHandlesFailure(status: 404, label: "mls-key-package-ref-not-found") {
            guard case .failure(.keyPackageRefNotFound) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_UnkownError() {
        test_itHandlesFailure(status: 999) {
            guard case .failure(.unknown(status: 999)) = $0 else { return false }
            return true
        }
    }

    // MARK: - Helpers

    private typealias Failure = SendMLSWelcomeAction.Failure

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
        let sut = SendMLSWelcomeActionHandler(context: syncMOC)
        var action = SendMLSWelcomeAction(body: body)

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

    private func test_itDoesntGenerateARequest(action: SendMLSWelcomeAction, apiVersion: APIVersion, validateResult: @escaping (Swift.Result<Void, Failure>) -> Bool) {
        // Given
        var action = action
        let sut = SendMLSWelcomeActionHandler(context: syncMOC)

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
