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

class FetchMLSConversationGroupInfoActionHandlerTests: FetchMLSGroupInfoActionHandlerTests<FetchMLSConversationGroupInfoAction, FetchMLSConversationGroupInfoActionHandler> {

    override func setUp() {
        super.setUp()
        action = FetchMLSConversationGroupInfoAction(conversationId: conversationId, domain: domain)
    }

    func test_itGeneratesARequest_APIV3() throws {
        try test_itGeneratesARequest(
            for: action,
               expectedPath: "/v3/conversations/\(domain)/\(conversationId.transportString())/groupinfo",
               expectedMethod: .methodGET,
               apiVersion: .v3
        )
    }
}

class FetchMLSSubconversationGroupInfoActionHandlerTests: FetchMLSGroupInfoActionHandlerTests<FetchMLSSubconversationGroupInfoAction, FetchMLSSubconversationGroupInfoActionHandler> {

    let subgroupType: SubgroupType = .conference

    override func setUp() {
        super.setUp()
        action = FetchMLSSubconversationGroupInfoAction(conversationId: conversationId, domain: domain, subgroupType: subgroupType)
    }

    func test_itGeneratesARequest_APIV4() throws {
        try test_itGeneratesARequest(
            for: action,
               expectedPath: "/v4/conversations/\(domain)/\(conversationId.transportString())/subconversations/\(subgroupType.rawValue) groupinfo",
               expectedMethod: .methodGET,
               apiVersion: .v4
        )
    }

    func test_itDoesntGenerateRequests_APIV3() {
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v3,
            expectedError: .endpointUnavailable
        )
    }

}

class FetchMLSGroupInfoActionHandlerTests<
    Action: BaseFetchMLSGroupInfoAction,
    Handler: BaseFetchMLSGroupInfoActionHandler<Action>
>: ActionHandlerTestBase<Action, Handler> {

    let domain = "example.com"
    let conversationId = UUID()

    override func tearDown() {
        action = nil
        super.tearDown()
    }

    // MARK: - Request generation

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

    func test_itHandlesSuccess() {
        // Given
        let groupState = Data([1, 2, 3])
        let payload = Handler.ResponsePayload(groupState: groupState)

        // When
        let receivedGroupState = test_itHandlesSuccess(status: 200, payload: transportData(for: payload))

        // Then
        XCTAssertEqual(receivedGroupState, payload.groupState)
    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 200, error: .malformedResponse),
            .failure(status: 400, error: .invalidParameters),
            .failure(status: 400, error: .mlsNotEnabled, label: "mls-not-enabled"),
            .failure(status: 404, error: .conversationIdOrDomainNotFound),
            .failure(status: 404, error: .noConversation, label: "no-conversation"),
            .failure(status: 404, error: .missingGroupInfo, label: "mls-missing-group-info"),
            .failure(status: 999, error: .unknown(status: 999, label: "foo", message: "?"), label: "foo")
        ])
    }
}
