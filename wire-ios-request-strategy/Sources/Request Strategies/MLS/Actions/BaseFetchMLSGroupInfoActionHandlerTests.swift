//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import WireDataModel
@testable import WireRequestStrategy
import XCTest

class BaseFetchMLSGroupInfoActionHandlerTests<
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

    func test_itDoesntGenerateRequests_APIBelowV5() {
        [.v0, .v1, .v2, .v3, .v4].forEach {
            test_itDoesntGenerateARequest(
                action: action,
                apiVersion: $0,
                expectedError: .endpointUnavailable
            )
        }
    }

    // MARK: - Response handling

    func test_itHandlesSuccess() throws {
        // Given
        let groupState = Data([1, 2, 3])
        let payload = try XCTUnwrap(String(decoding: groupState, as: UTF8.self)) as ZMTransportData

        // When
        let receivedGroupState = test_itHandlesSuccess(status: 200, payload: payload)

        // Then
        XCTAssertEqual(receivedGroupState, groupState)
    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 400, error: .invalidParameters),
            .failure(status: 400, error: .mlsNotEnabled, label: "mls-not-enabled"),
            .failure(status: 404, error: .conversationIdOrDomainNotFound),
            .failure(status: 404, error: .noConversation, label: "no-conversation"),
            .failure(status: 404, error: .missingGroupInfo, label: "mls-missing-group-info"),
            .failure(status: 999, error: .unknown(status: 999, label: "foo", message: "?"), label: "foo")
        ])
    }
}
