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

final class SyncUsersActionHandlerTests: ActionHandlerTestBase<SyncUsersAction, SyncUsersActionHandler> {

    // MARK: - Properties

    let qualifiedIDs = QualifiedID(uuid: .create(), domain: "example.com")

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        action = SyncUsersAction(qualifiedIDs: [qualifiedIDs])
    }

    // MARK: - tearDown

    override func tearDown() {
        action = nil
        super.tearDown()
    }

    // MARK: - Unit Tests

    // MARK: - Request generation

    func test_ItGenerateRequest_APIV5() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v5/list-users",
            expectedMethod: .post,
            apiVersion: .v5
        )
    }

    func test_ItGenerateRequest_APIV4() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v4/list-users",
            expectedMethod: .post,
            apiVersion: .v4
        )
    }

    func test_itFailsToGenerateRequests_APIBelowV4() throws {
        [.v0, .v1, .v2, .v3].forEach {
            test_itDoesntGenerateARequest(
                action: action,
                apiVersion: $0,
                expectedError: .endpointUnavailable
            )
        }
    }

    // MARK: - Response Handling

    func test_ItHandlesSuccess() throws {
        // GIVEN

        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")
        user.domain = "example.com"
        user.isPendingMetadataRefresh = false
        user.needsToBeUpdatedFromBackend = true

        let payload: [AnyHashable: Any] = [
            "failed": [
                [
                    "domain": "example.com",
                    "id": "99db9768-04e3-4b5d-9268-831b6a25c4ab"
                ]
            ],
            "found": [
                [
                    "accent_id": 2147483647,
                    "assets": [
                        [
                            "key": "3-1-47de4580-ae51-4650-acbb-d10c028cb0ac",
                            "size": "preview",
                            "type": "image"
                        ]
                    ],
                    "deleted": true,
                    "email": "string",
                    "expires_at": "2021-05-12T10:52:02.671Z",
                    "handle": "string",
                    "id": "99db9768-04e3-4b5d-9268-831b6a25c4ab",
                    "legalhold_status": "enabled",
                    "name": "string",
                    "picture": [
                        "string"
                    ],
                    "qualified_id": [
                        "domain": "example.com",
                        "id": "99db9768-04e3-4b5d-9268-831b6a25c4ab"
                    ],
                    "service": [
                        "id": "99db9768-04e3-4b5d-9268-831b6a25c4ab",
                        "provider": "99db9768-04e3-4b5d-9268-831b6a25c4ab"
                    ],
                    "supported_protocols": [
                        "proteus"
                    ],
                    "team": "99db9768-04e3-4b5d-9268-831b6a25c4ab"
                ]
            ]
        ]

        let _: SyncUsersAction.Result = try XCTUnwrap(test_itHandlesSuccess(
            status: 200,
            payload: payload as ZMTransportData
        ))

    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 999, error: .unknownError(code: 999, label: "foo", message: ""))
        ])
    }

}
