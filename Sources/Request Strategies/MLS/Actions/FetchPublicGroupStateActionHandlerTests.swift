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

import WireDataModel
@testable import WireRequestStrategy

class FetchPublicGroupStateActionHandlerTests: ActionHandlerTestBase<FetchPublicGroupStateAction, FetchPublicGroupStateActionHandler> {

    let domain = "example.com"
    let conversationId = UUID()

    override func setUp() {
        super.setUp()
        action = FetchPublicGroupStateAction(conversationId: conversationId, domain: domain)
    }

    override func tearDown() {
        action = nil
        super.tearDown()
    }
    // MARK: - Request generation

    func test_itGeneratesARequest_APIV2() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v2/conversations/\(domain)/\(conversationId.transportString())/groupinfo",
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

    private typealias ResponsePayload = FetchPublicGroupStateActionHandler.ResponsePayload

    func test_itHandlesSuccess() {
        // Given
        let groupState = Data([1, 2, 3])
        let payload = ResponsePayload(groupState: groupState)

        // When
        let receivedKeyPackagesCount = test_itHandlesSuccess(status: 200, payload: transportData(for: payload))

        // Then
        XCTAssertEqual(receivedKeyPackagesCount, payload.groupState)
    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 200, error: .malformedResponse),
            .failure(status: 404, error: .conversationIdOrDomainNotFound),
            .failure(status: 404, error: .noConversation, label: "no-conversation"),
            .failure(status: 404, error: .missingGroupInfo, label: "mls-missing-group-info"),
            .failure(status: 999, error: .unknown(status: 999, label: "foo", message: "?"), label: "foo")

        ])
    }

}
