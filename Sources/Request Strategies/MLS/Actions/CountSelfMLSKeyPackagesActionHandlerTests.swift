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

class CountSelfMLSKeyPackagesActionHandlerTests: MessagingTestBase {

    let clientID = "clientID"
    let requestPath = "/v1/mls/key-package/self/clientID/count"

    typealias Payload = CountSelfMLSKeyPackagesActionHandler.ResponsePayload

    func test_sut_GeneratesValidRequest() throws {
        // Given
        let sut  = CountSelfMLSKeyPackagesActionHandler(context: syncMOC)
        let action = CountSelfMLSKeyPackagesAction(clientID: clientID)
        let apiVersion: APIVersion = .v1

        // When
        let request = try XCTUnwrap(sut.request(for: action, apiVersion: apiVersion))

        // Then
        XCTAssertEqual(request.path, requestPath)
        XCTAssertEqual(request.method, .methodGET)
    }

    func test_sut_FailsToGeneratesRequestForUnsupportedAPIVersion() throws {
        // Given
        let sut  = CountSelfMLSKeyPackagesActionHandler(context: syncMOC)
        var action = CountSelfMLSKeyPackagesAction(clientID: clientID)
        let apiVersion: APIVersion = .v0

        // Expectation
        let didFail = expectation(description: "didFail")

        action.onResult { result in
            guard case .failure(.endpointNotAvailable) = result else { return }
            didFail.fulfill()
        }

        // When
        let request = sut.request(for: action, apiVersion: apiVersion)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNil(request)
    }

    func test_sut_FailsToGeneratesRequestForInvalidClientID() throws {
        // Given
        let sut  = CountSelfMLSKeyPackagesActionHandler(context: syncMOC)
        var action = CountSelfMLSKeyPackagesAction(clientID: "")
        let apiVersion: APIVersion = .v1

        // Expectation
        let didFail = expectation(description: "didFail")

        action.onResult { result in
            guard case .failure(.invalidClientID) = result else { return }
            didFail.fulfill()
        }

        // When
        let request = sut.request(for: action, apiVersion: apiVersion)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNil(request)
    }

    func test_sut_HandlesResponse_200() throws {
        // Given
        let sut = CountSelfMLSKeyPackagesActionHandler(context: syncMOC)
        var action = CountSelfMLSKeyPackagesAction(clientID: clientID)

        // Expectation
        let didSucceed = expectation(description: "didSucceed")
        var receivedKeyPackagesCount: Int = 0

        action.onResult { result in
            guard case .success(let count) = result else { return }
            receivedKeyPackagesCount = count
            didSucceed.fulfill()
        }

        // When
        let payload = Payload(count: 123456789)

        sut.handleResponse(response(payload: payload, status: 200), action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

        // Then
        XCTAssertEqual(receivedKeyPackagesCount, payload.count)
    }

    func test_sut_HandlesResponse_200_MalformedResponse() throws {
        // Given
        let sut = CountSelfMLSKeyPackagesActionHandler(context: syncMOC)
        var action = CountSelfMLSKeyPackagesAction(clientID: clientID)

        // Expectation
        let didFail = expectation(description: "didFail")

        action.onResult { result in
            guard case .failure(.malformedResponse) = result else { return }
            didFail.fulfill()
        }

        // When
        sut.handleResponse(response(status: 200), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_sut_HandlesResponse_404() throws {
        // Given
        let sut = CountSelfMLSKeyPackagesActionHandler(context: syncMOC)
        var action = CountSelfMLSKeyPackagesAction(clientID: clientID)

        // Expectation
        let didFail = expectation(description: "didFail")

        action.onResult { result in
            guard case .failure(.clientNotFound) = result else { return }
            didFail.fulfill()
        }

        // When
        sut.handleResponse(response(status: 404), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_sut_HandlesResponse_UnknownError() throws {
        // Given
        let sut = CountSelfMLSKeyPackagesActionHandler(context: syncMOC)
        var action = CountSelfMLSKeyPackagesAction(clientID: clientID)

        // Expectation
        let didFail = expectation(description: "didFail")

        action.onResult { result in
            guard case .failure(.unknown(status: 999)) = result else { return }
            didFail.fulfill()
        }

        // When
        sut.handleResponse(response(status: 999), action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }
}

// MARK: - Helpers methods
extension CountSelfMLSKeyPackagesActionHandlerTests {

    func response(payload: Payload, status: Int) -> ZMTransportResponse {
        let data = try! JSONEncoder().encode(payload)
        let payloadAsString = String(bytes: data, encoding: .utf8)!
        return response(payload: payloadAsString as ZMTransportData, status: status)
    }

    func response(payload: ZMTransportData? = nil, status: Int) -> ZMTransportResponse {
        return ZMTransportResponse(
            payload: payload,
            httpStatus: status,
            transportSessionError: nil,
            apiVersion: APIVersion.v1.rawValue
        )
    }
}
