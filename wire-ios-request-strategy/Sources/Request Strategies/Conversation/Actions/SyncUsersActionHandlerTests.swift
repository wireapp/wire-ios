////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

final class SyncUsersActionHandlerTests: MessagingTestBase {

    // MARK: - Properties

    typealias RequestPayload = SyncUsersActionHandler.RequestPayload
    typealias ResponsePayload = SyncUsersActionHandler.ResponsePayload

    // MARK: - Request Generation

    func testRequestGenerationForUnsupportedAPIVersions() {
        // GIVEN
        let sut = SyncUsersActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")
        let action = SyncUsersAction(qualifiedIDs: [id])

        // Test for each unsupported version
        for version in [APIVersion.v0, .v1, .v2, .v3] {
            // WHEN
            let request = sut.request(for: action, apiVersion: version)

            // THEN
            XCTAssertNil(request, "Request should be nil for API version \(version)")
        }
    }

    func testRequestGenerationForAPIVersionV4() {
        // GIVEN
        let sut = SyncUsersActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")
        let action = SyncUsersAction(qualifiedIDs: [id])

        // WHEN
        let result = try! XCTUnwrap(sut.request(for: action, apiVersion: .v4))

        // Then
        XCTAssertNotNil(result, "Request should not be nil for API version .v4")
        XCTAssertEqual(result.path, "/v4/list-users", "Incorrect path for API version .v4")
        XCTAssertEqual(result.method, .post, "Incorrect HTTP method for API version .v4")
        XCTAssertEqual(result.apiVersion, APIVersion.v4.rawValue, "Incorrect API version set in the request for .v4")

        let payload = try! XCTUnwrap(RequestPayload(result))
        XCTAssertEqual(payload, RequestPayload(qualified_users: [id]))
    }

    func testRequestGenerationForAPIVersionV5() {
        // GIVEN
        let sut = SyncUsersActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")
        let action = SyncUsersAction(qualifiedIDs: [id])

        // WHEN
        let result = try! XCTUnwrap(sut.request(for: action, apiVersion: .v5))

        // THEN
        XCTAssertNotNil(result, "Request should not be nil for API version .v5")
        XCTAssertEqual(result.path, "/v5/list-users", "Incorrect path for API version .v5")
        XCTAssertEqual(result.method, .post, "Incorrect HTTP method for API version .v5")
        XCTAssertEqual(result.apiVersion, APIVersion.v5.rawValue, "Incorrect API version set in the request for .v5")

        let payload = try! XCTUnwrap(RequestPayload(result))
        XCTAssertEqual(payload, RequestPayload(qualified_users: [id]))
    }

    // MARK: - Response Handling

    func testHandleResponse_UnsupportedAPIVersion() throws {
        // GIVEN
        let sut = SyncUsersActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")
        let didFail = expectation(description: "did fail")

        let action = SyncUsersAction(qualifiedIDs: [id]) { result in
            guard case .failure(.endpointUnavailable) = result else {
                XCTFail("unexpected result: \(String(describing: result))")
                return
            }
        }

        didFail.fulfill()

        let payload = [
            "label": "foo",
            "message": "bar"
        ]

        let response = ZMTransportResponse(
            payload: payload as ZMTransportData,
            httpStatus: 999,
            transportSessionError: nil,
            apiVersion: 1
        )

        // When
        sut.handleResponse(response, action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

    }

    func test_HandleResponse_UnknownError() throws {
        // Given
        let sut = SyncUsersActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")

        let didFail = expectation(description: "did fail")
        let action = SyncUsersAction(qualifiedIDs: [id]) { result in
            // Then
            guard case .failure(.unknownError(code: 999, label: "foo", message: "bar")) = result else {
                XCTFail("unexpected result: \(String(describing: result))")
                return
            }

            didFail.fulfill()
        }

        let payload = [
            "label": "foo",
            "message": "bar"
        ]

        let response = ZMTransportResponse(
            payload: payload as ZMTransportData,
            httpStatus: 999,
            transportSessionError: nil,
            apiVersion: 4
        )

        // When
        sut.handleResponse(response, action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

}
