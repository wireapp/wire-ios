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

class CountSelfMLSKeyPackagesActionHandlerTests: ActionHandlerTestBase<CountSelfMLSKeyPackagesAction, CountSelfMLSKeyPackagesActionHandler> {

    let clientID = "clientID"
    let requestPath = "/v1/mls/key-packages/self/clientID/count"

    typealias Payload = CountSelfMLSKeyPackagesActionHandler.ResponsePayload

    override func setUp() {
        super.setUp()
        action = CountSelfMLSKeyPackagesAction(clientID: clientID)
    }

    // MARK: - Request Generation

    func test_itGeneratesValidRequest() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: requestPath,
            expectedMethod: .methodGET,
            apiVersion: .v1
        )
    }

    func test_itDoesntGenerateRequests() {
        // When the endpoint is not available
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v0,
            expectedError: .endpointUnavailable
        )

        // When the client ID is invalid
        test_itDoesntGenerateARequest(
            action: CountSelfMLSKeyPackagesAction(clientID: ""),
            apiVersion: .v1,
            expectedError: .invalidClientID
        )
    }

    // MARK: - Response Handling

    func test_itHandlesSuccess() {
        // Given
        let payload = Payload(count: 123456789)

        // When
        let receivedKeyPackagesCount = test_itHandlesSuccess(status: 200, payload: transportData(for: payload))

        // Then
        XCTAssertEqual(receivedKeyPackagesCount, payload.count)
    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 200, error: .malformedResponse),
            .failure(status: 404, error: .clientNotFound),
            .failure(status: 999, error: .unknown(status: 999))
        ])
    }
}
