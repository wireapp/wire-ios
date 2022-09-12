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
import WireDataModel
@testable import WireRequestStrategy

class FetchBackendMLSPublicKeysActionHandlerTests: ActionHandlerTestBase<FetchBackendMLSPublicKeysAction, FetchBackendMLSPublicKeysActionHandler> {

    override func setUp() {
        super.setUp()
        action = FetchBackendMLSPublicKeysAction()
    }

    override func tearDown() {
        action = nil
        super.tearDown()
    }
    // MARK: - Request generation

    func test_itGeneratesARequest_APIV2() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v2/mls/public-keys",
            expectedMethod: .methodGET,
            apiVersion: .v2
        )
    }

    func test_itDoesntGenerateRequests_APIV1() {
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v1,
            expectedError: .endpointUnavailable
        )
    }

    func test_itDoesntGenerateRequests_APIV0() {
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v0,
            expectedError: .endpointUnavailable
        )
    }

    // MARK: - Response handling

    private typealias ResponsePayload = FetchBackendMLSPublicKeysActionHandler.ResponsePayload

    func test_itHandlesSuccess() {
        // Given
        let removalKey = Data([1, 2, 3])
        let payload = ResponsePayload(
            removal: .init(ed25519: removalKey.base64EncodedString())
        )

        // When
        let result = test_itHandlesSuccess(
            status: 200,
            payload: transportData(for: payload)
        )

        // Then
        XCTAssertEqual(result, BackendMLSPublicKeys(removal: .init(ed25519: removalKey)))
    }

    func test_itHandlesResponse_MalformedResponse() throws {
        // Given
        let payload: ZMTransportData? = nil

        // When
        test_itHandlesFailure(
            status: 200,
            payload: payload,
            expectedError: .malformedResponse
        )
    }

    func test_itHandlesResponse_Unknown() throws {
        test_itHandlesFailure(
            status: 999,
            label: "foo",
            expectedError: .unknown(status: 999, label: "foo", message: "?")
        )
    }
}
