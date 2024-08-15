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

import Foundation
import WireDataModel
@testable import WireRequestStrategy

final class DeleteSubgroupActionHandlerTests: ActionHandlerTestBase<DeleteSubgroupAction, DeleteSubgroupActionHandler> {

    let conversationID = UUID()
    let domain = "example.com"
    let subgroupType = SubgroupType.conference
    let epoch = 1
    let groupID = MLSGroupID(Data())

    override func setUp() {
        super.setUp()
        action = DeleteSubgroupAction(
            conversationID: conversationID,
            domain: domain,
            subgroupType: subgroupType,
            epoch: epoch,
            groupID: groupID
        )
        handler = DeleteSubgroupActionHandler(context: syncMOC)
    }

    override func tearDown() {
        action = nil
        super.tearDown()
    }

    // MARK: - Request

    func test_itGeneratesARequest_APIV4() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v4/conversations/\(domain)/\(conversationID.transportString())/subconversations/\(subgroupType)",
            expectedMethod: .delete,
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

    func test_itDosentGenerateRequests_InvalidParameters_Domain() {
        action = DeleteSubgroupAction(
            conversationID: conversationID,
            domain: "",
            subgroupType: subgroupType,
            epoch: 1,
            groupID: MLSGroupID(Data())
        )

        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v4,
            expectedError: .invalidParameters
        )
    }

    // MARK: - Response

    func test_itHandlesSuccess() {
        // When, then
        test_itHandlesSuccess(status: 200)
    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 400, error: .mlsNotEnabled, label: "mls-not-enabled"),
            .failure(status: 400, error: .invalidParameters),
            .failure(status: 403, error: .accessDenied, label:
                    "access-denied"),
            .failure(status: 404, error: .noConversation, label: "no-conversation"),
            .failure(status: 409, error: .mlsStaleMessage, label: "mls-stale-message"),
            .failure(status: 999, error: .unknown(status: 999, label: "foo", message: "?"), label: "foo")
        ])
    }

}
