//
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

import Foundation
import WireDataModel
@testable import WireRequestStrategy

final class FetchSupportedProtocolsActionHandlerTests: ActionHandlerTestBase<FetchSupportedProtocolsAction, FetchSupportedProtocolsActionHandler> {

    var userID: QualifiedID!

    override func setUp() {
        super.setUp()
        userID = .random()
        action = FetchSupportedProtocolsAction(userID: userID)
    }

    override func tearDown() {
        userID = nil
        action = nil
        super.tearDown()
    }

    // MARK: - Request

    func test_itGeneratesARequest_APIV5() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v5/users/\(userID.domain)/\(userID.uuid.transportString())/supported-protocols",
            expectedMethod: .get,
            apiVersion: .v5
        )
    }

    func test_itDoesntGenerateRequests_APIV4() {
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v4,
            expectedError: .endpointUnavailable
        )
    }

    func test_itDoesntGenerateRequests_APIV3() {
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v3,
            expectedError: .endpointUnavailable
        )
    }

    func test_itDoesntGenerateRequests_APIV2() {
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v2,
            expectedError: .endpointUnavailable
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

    func test_itDoesntGenerateRequests_InvalidParameters_Domain() {
        action = FetchSupportedProtocolsAction(userID: QualifiedID(
            uuid: .create(),
            domain: ""
        ))

        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v5,
            expectedError: .invalidParameters
        )
    }

    // MARK: - Response

    func test_itHandlesSuccess_200() {
        // Given
        let payload = ["proteus", "mls"] as ZMTransportData

        // When
        let result = test_itHandlesSuccess(
            status: 200,
            payload: payload
        )

        // Then
        XCTAssertEqual(result, [.proteus, .mls])
    }

    func test_itHandlesSuccess_200_InvalidPayload() {
        // Given
        let payload = ["foo", "mls"] as ZMTransportData

        // When, then
        test_itHandlesFailure(
            status: 200,
            payload: payload,
            expectedError: .invalidResponse
        )
    }

    func test_itHandlesSuccess_200_MissingPayload() {
        // Given
        let payload: ZMTransportData? = nil

        // When, then
        test_itHandlesFailure(
            status: 200,
            payload: payload,
            expectedError: .invalidResponse
        )
    }

    func test_itHandlesFailure_400() {
        test_itHandlesFailure(
            status: 400,
            label: nil,
            expectedError: .invalidParameters
        )
    }

}
