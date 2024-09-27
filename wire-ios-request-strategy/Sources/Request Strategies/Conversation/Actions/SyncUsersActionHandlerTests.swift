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

import XCTest
@testable import WireRequestStrategy
@testable import WireRequestStrategySupport

final class SyncUsersActionHandlerTests: ActionHandlerTestBase<SyncUsersAction, SyncUsersActionHandler> {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockProcessor = MockUserProfilePayloadProcessing()
        action = SyncUsersAction(qualifiedIDs: [qualifiedIDs])
        handler = SyncUsersActionHandler(context: syncMOC, payloadProcessor: mockProcessor)
    }

    // MARK: - tearDown

    override func tearDown() {
        action = nil
        handler = nil
        mockProcessor = nil
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
        for item in [.v0, .v1, .v2, .v3] {
            test_itDoesntGenerateARequest(
                action: action,
                apiVersion: item,
                expectedError: .endpointUnavailable
            )
        }
    }

    // MARK: - Response Handling

    func test_ItHandlesSuccess() async throws {
        // GIVEN

        // mock the payload processor method
        mockProcessor.updateUserProfilesFromIn_MockMethod = { _, _ in }

        // set up a failed user
        let uuidString = "99db9768-04e3-4b5d-9268-831b6a25c4ab"
        let domain = "example.com"
        let failedUser = await syncMOC.perform { [self] in
            let failedUser = ZMUser.insertNewObject(in: syncMOC)
            failedUser.remoteIdentifier = UUID(uuidString: uuidString)
            failedUser.domain = domain
            failedUser.isPendingMetadataRefresh = false
            failedUser.needsToBeUpdatedFromBackend = true
            return failedUser
        }

        // set up payload with failed and found users
        let payloadData: [AnyHashable: Any] = [
            "failed": [
                [
                    "domain": domain,
                    "id": uuidString,
                ],
            ],
            "found": [
                [
                    "accent_id": 2_147_483_647,
                    "assets": [
                        [
                            "key": "3-1-47de4580-ae51-4650-acbb-d10c028cb0ac",
                            "size": "preview",
                            "type": "image",
                        ],
                    ],
                    "deleted": true,
                    "email": "string",
                    "expires_at": "2021-05-12T10:52:02.671Z",
                    "handle": "string",
                    "id": "99db9768-04e3-4b5d-9268-831b6a25c4ab",
                    "legalhold_status": "enabled",
                    "name": "string",
                    "picture": [
                        "string",
                    ],
                    "qualified_id": [
                        "domain": "example.com",
                        "id": "99db9768-04e3-4b5d-9268-831b6a25c4ab",
                    ],
                    "service": [
                        "id": "99db9768-04e3-4b5d-9268-831b6a25c4ab",
                        "provider": "99db9768-04e3-4b5d-9268-831b6a25c4ab",
                    ],
                    "supported_protocols": [
                        "proteus",
                    ],
                    "team": "99db9768-04e3-4b5d-9268-831b6a25c4ab",
                ],
            ],
        ]

        // THEN
        test_itHandlesSuccess(
            status: 200,
            payload: payloadData as ZMTransportData,
            apiVersion: .v5
        )

        // assert it marks failed users as unavailable
        await syncMOC.perform {
            XCTAssertTrue(failedUser.isPendingMetadataRefresh)
            XCTAssertFalse(failedUser.needsToBeUpdatedFromBackend)
        }

        // assert the payload processor is called
        XCTAssertEqual(mockProcessor.updateUserProfilesFromIn_Invocations.count, 1)
    }

    func test_itHandlesFailures() {
        test_itHandlesFailure(
            status: 999,
            label: "foo",
            apiVersion: .v5,
            expectedError: .unknownError(code: 999, label: "foo", message: "?")
        )
    }

    // MARK: Private

    // MARK: - Properties

    private let qualifiedIDs = QualifiedID(uuid: .create(), domain: "example.com")
    private var mockProcessor: MockUserProfilePayloadProcessing!
}
