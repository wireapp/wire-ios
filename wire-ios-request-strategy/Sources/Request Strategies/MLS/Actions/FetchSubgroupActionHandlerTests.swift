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

class FetchSubroupActionHandlerTests: ActionHandlerTestBase<FetchSubgroupAction, FetchSubgroupActionHandler> {

    let domain = "example.com"
    let conversationId = UUID()
    let type = SubgroupType.conference

    override func setUp() {
        super.setUp()
        action = FetchSubgroupAction(domain: domain, conversationId: conversationId, type: type)
    }

    override func tearDown() {
        action = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func test_itGeneratesARequest_APIV3() throws {
        try test_itGeneratesARequest(
            for: action,
               expectedPath: "/v3/conversations/\(domain)/\(conversationId.transportString())/subconversations/\(type)",
               expectedMethod: .methodGET,
               apiVersion: .v3
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

    // MARK: - Response handling

    private typealias ResponsePayload = FetchSubgroupActionHandler.Subgroup

    func test_itHandlesSuccess() {
        // Given
        let payload = ResponsePayload(
            cipherSuite: 123,
            epoch: 1,
            epochTimestamp: Date(),
            groupID: UUID().transportString(),
            members: [.init(
                userID: UUID(),
                clientID: UUID().transportString(),
                domain: "domain.com"
            )],
            parentQualifiedID: .init(id: UUID(), domain: "domain.com"),
            subconvID: UUID().transportString()
        )

        // When
        let mlsSubgroup = test_itHandlesSuccess(status: 200, payload: transportData(for: payload))

        // Then
        XCTAssertEqual(mlsSubgroup, payload.mlsSubgroup)
    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 200, error: .malformedResponse),
            .failure(status: 400, error: .invalidParameters),
            .failure(status: 403, error: .accessDenied, label: "access-denied"),
            .failure(status: 403, error: .unsupportedConversationType, label: "mls-subconv-unsupported-convtype"),
            .failure(status: 404, error: .conversationIdOrDomainNotFound),
            .failure(status: 404, error: .noConversation, label: "no-conversation"),
            .failure(status: 999, error: .unknown(status: 999, label: "foo", message: "?"), label: "foo")
        ])
    }

}
