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

import XCTest
@testable import WireRequestStrategy

final class UpdateConversationProtocolActionHandlerTests: ActionHandlerTestBase<WireRequestStrategy.UpdateConversationProtocolAction, UpdateConversationProtocolActionHandler> {

    var domain: String!
    var conversationID: UUID!

    override func setUp() {
        super.setUp()

        domain = "example.com"
        conversationID = .init(uuidString: "b906579d-60dd-4510-a3ca-14b2ec225f4a")
        action = UpdateConversationProtocolAction(domain: domain, conversationID: conversationID, messageProtocol: .mls)
    }

    override func tearDown() {
        action = nil
        conversationID = nil
        domain = nil

        super.tearDown()
    }

    // MARK: - Request generation
    func test_itGenerateARequest_APIV5() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v5/conversations/example.com/b906579d-60dd-4510-a3ca-14b2ec225f4a/mls",
            expectedMethod: .put,
            expectedData: .none,
            expectedContentType: .none,
            apiVersion: .v5
        )
    }

    func test_itFailsToGenerateRequests_APIBelowV5() {
        [.v0, .v1, .v2, .v3, .v4].forEach {
            test_itDoesntGenerateARequest(
                action: action,
                apiVersion: $0,
                expectedError: .endpointUnavailable
            )
        }
    }

    // MARK: - Response handling

    func test_itHandlesConversationUpdated() throws {
        // Given
        let payload: [AnyHashable: Any] = [
            "events": [
                [
                    "time": "2021-05-12T10:52:02.671Z",
                    "type": "conversation.protocol-update",
                    "from": "99db9768-04e3-4b5d-9268-831b6a25c4ab",
                    "qualified_conversation": [
                        "domain": "example.com",
                        "id": "99db9768-04e3-4b5d-9268-831b6a25c4ab"
                    ],
                    "qualified_from": [
                        "domain": "example.com",
                        "id": "99db9768-04e3-4b5d-9268-831b6a25c4ab"
                    ],
                    "data": []
                ]
            ],
            "time": "2021-05-12T10:52:02.671Z"
        ]

        // When
        let event = test_itHandlesSuccess(
            status: 200,
            payload: payload as ZMTransportData
        )

        XCTAssertEqual(
            event,
            .conversationUpdated(
                .init(
                    id: .init(),
                    data: .init(),
                    from: .init(),
                    qualifiedID: .none,
                    qualifiedFrom: .none,
                    timestamp: .none,
                    type: .none
                )
            )
        )
    }

    func test_itHandlesConversationUnchanged() throws {
        // When
        let event = test_itHandlesSuccess(status: 204)

        // Then
        XCTAssertEqual(event, .conversationUnchanged)
    }

    func test_itHandlesUnexpectedResult() throws {
        // When
        test_itHandlesFailure(
            status: 123,
            payload: [
                "code": 123,
                "label": "unexpected-label",
                "message": "Unexpected message"
            ] as ZMTransportData,
            expectedError: .api(
                statusCode: 123,
                label: "unexpected-label",
                message: "Unexpected message"
            )
        )
    }

}
