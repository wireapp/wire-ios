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

final class SyncMLSOneToOneConversationActionHandlerTests: ActionHandlerTestBase<SyncMLSOneToOneConversationAction, SyncMLSOneToOneConversationActionHandler> {

    var qualifiedID: QualifiedID!

    override func setUp() {
        super.setUp()

        qualifiedID = .random()
        action = SyncMLSOneToOneConversationAction(
            userID: qualifiedID.uuid,
            domain: qualifiedID.domain
        )
    }

    override func tearDown() {
        qualifiedID = nil
        action = nil
        super.tearDown()
    }

    // MARK: - Request

    func test_itGeneratesARequest_APIV5() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v5/conversations/one2one/\(qualifiedID.domain)/\(qualifiedID.uuid.transportString())",
            expectedMethod: .methodGET,
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

    // MARK: - Response

    func test_itHandlesSuccess_200() throws {
        try syncMOC.performAndWait {
            // Given
            var payload = Payload.Conversation.stub()
            payload.qualifiedID = QualifiedID.random()
            payload.type = BackendConversationType.oneOnOne.rawValue
            let encoder = JSONEncoder.defaultEncoder
            encoder.setAPIVersion(.v5)
            let jsonString = try payload.encodeToJSONString(encoder: encoder)

            // When
            test_itHandlesSuccess(
                status: 200,
                payload: jsonString as ZMTransportData
            )
        }
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

    func test_itHandlesFailure_400_MLSNotEnabled() {
        test_itHandlesFailure(
            status: 400,
            label: "mls-not-enabled",
            expectedError: .mlsNotEnabled
        )
    }

    func test_itHandlesFailure_403_UsersNotConnected() {
        test_itHandlesFailure(
            status: 403,
            label: "not-connected",
            expectedError: .usersNotConnected
        )
    }

    func test_itHandlesFailure_Unknown() {
        test_itHandlesFailure(
            status: 999,
            label: "some-label",
            expectedError: .unknownn(status: 999, label: "some-label", message: "?")
        )
    }
}
