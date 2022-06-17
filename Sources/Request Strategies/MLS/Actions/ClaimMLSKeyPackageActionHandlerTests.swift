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

class ClaimMLSKeyPackageActionHandlerTests: MessagingTestBase {

    let domain = "example.com"
    let userId = UUID()
    let excludedSelfCliendId = UUID().transportString()
    let clientId = UUID().transportString()

    // MARK: - Request generation

    func test_itGenerateARequest() throws {
        // Given
        let sut = ClaimMLSKeyPackageActionHandler(context: syncMOC)
        let action = ClaimMLSKeyPackageAction(domain: domain, userId: userId, excludedSelfClientId: excludedSelfCliendId)

        // When
        let request = try XCTUnwrap(sut.request(for: action, apiVersion: .v1))

        // Then
        XCTAssertEqual(request.path, "/v1/mls/key-packages/claim/\(domain)/\(userId.transportString())")
        XCTAssertEqual(request.method, .methodPOST)

        let actualPayload = request.payload as? [String: String]
        let expectedPayload = ["skip_own": excludedSelfCliendId]

        XCTAssertEqual(actualPayload, expectedPayload)
    }

    func test_itDoesntGenerateARequest_WhenAPIVersionIsNotSupported() {
        test_itDoesntGenerateARequest(
            action: ClaimMLSKeyPackageAction(domain: domain, userId: userId, excludedSelfClientId: excludedSelfCliendId),
            apiVersion: .v0
        ) {
            guard case .failure(.endpointUnavailable) = $0 else { return false }
            return true
        }
    }

    func test_itDoesntGenerateARequest_WhenDomainIsMissing() {
        APIVersion.domain = nil

        test_itDoesntGenerateARequest(
            action: ClaimMLSKeyPackageAction(domain: "", userId: userId, excludedSelfClientId: excludedSelfCliendId),
            apiVersion: .v1
        ) {
            guard case .failure(.missingDomain) = $0 else { return false }
            return true
        }
    }

    // MARK: - Response handling

    func test_itHandlesResponse_200() {
        // Given
        let sut = ClaimMLSKeyPackageActionHandler(context: syncMOC)
        var action = ClaimMLSKeyPackageAction(domain: domain, userId: userId)
        let keyPackage = KeyPackage(client: clientId, domain: domain, keyPackage: "a2V5IHBhY2thZ2UgZGF0YQo=", keyPackageRef: "string", userID: userId)

        // Expectation
        let didSucceed = expectation(description: "didSucceed")
        var receivedKeyPackages = [KeyPackage]()

        action.onResult { result in
            guard case .success(let keyPackages) = result else { return }
            receivedKeyPackages = keyPackages
            didSucceed.fulfill()
        }

        // When
        let payload = Payload(keyPackages: [keyPackage])

        sut.handleResponse(response(payload: payload, status: 200), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

        // Then
        XCTAssertEqual(receivedKeyPackages.count, 1)
        XCTAssertEqual(receivedKeyPackages.first, keyPackage)
    }

    func test_itHandlesResponse_200_MalformedResponse() {
        test_itHandlesResponse(status: 200) {
            guard case .failure(.malformedResponse) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_400() {
        test_itHandlesResponse(status: 400) {
            guard case .failure(.invalidSelfClientId) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_404() {
        test_itHandlesResponse(status: 404) {
            guard case .failure(.userOrDomainNotFound) = $0 else { return false }
            return true
        }
    }

    func test_itHandlesResponse_UnkownError() {
        test_itHandlesResponse(status: 999) {
            guard case .failure(.unknown(status: 999)) = $0 else { return false }
            return true
        }
    }

    // MARK: - Helpers

    private typealias Payload = ClaimMLSKeyPackageActionHandler.ResponsePayload
    private typealias Result = ClaimMLSKeyPackageAction.Result
    private typealias Failure = ClaimMLSKeyPackageAction.Failure

    private func response(payload: Payload?, status: Int) -> ZMTransportResponse {
        var payloadString: String?
        if let payload = payload {
            let data = try! JSONEncoder().encode(payload)
            payloadString = String(bytes: data, encoding: .utf8)
        }

        return ZMTransportResponse(payload: payloadString as ZMTransportData?, httpStatus: status, transportSessionError: nil, apiVersion: APIVersion.v1.rawValue)
    }

    private func test_itHandlesResponse(status: Int, validateResult: @escaping (Swift.Result<Result, Failure>) -> Bool) {
        // Given
        let sut = ClaimMLSKeyPackageActionHandler(context: syncMOC)
        var action = ClaimMLSKeyPackageAction(domain: domain, userId: userId)

        // Expectation
        let didFail = expectation(description: "didPassValidation")

        action.onResult { result in
            guard validateResult(result) else { return }
            didFail.fulfill()
        }

        // When
        sut.handleResponse(response(payload: nil, status: status), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    private func test_itDoesntGenerateARequest(action: ClaimMLSKeyPackageAction, apiVersion: APIVersion, validateResult: @escaping (Swift.Result<Result, Failure>) -> Bool) {
        // Given
        var action = action
        let sut = ClaimMLSKeyPackageActionHandler(context: syncMOC)

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
