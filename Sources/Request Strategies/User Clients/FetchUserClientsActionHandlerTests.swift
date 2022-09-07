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

import Foundation
import XCTest
@testable import WireRequestStrategy

class FetchUserClientsActionHandlerTests: ActionHandlerTestBase<FetchUserClientsAction, FetchUserClientsActionHandler> {

    typealias RequestPayload = FetchUserClientsActionHandler.RequestPayload
    typealias ResponsePayload = FetchUserClientsActionHandler.ResponsePayload

    // MARK: - Properties

    let userID1 = UUID.create()
    let domain1 = "foo.com"
    let clientID1 = "client1"
    let clientID2 = "client2"

    let userID2 = UUID.create()
    let domain2 = "bar.com"
    let clientID3 = "client3"

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        action = FetchUserClientsAction(userIDs: Set([
            QualifiedID(uuid: userID1, domain: domain1),
            QualifiedID(uuid: userID2, domain: domain2)
        ]))
    }

    override func tearDown() {
        action = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func test_itGenerateARequest_APIV2() throws {
        // Given
        let expectedPayload = try XCTUnwrap(RequestPayload(qualified_users: action.userIDs).payloadString())

        // Then
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v2/users/list-clients",
            expectedPayload: expectedPayload,
            expectedMethod: .methodPOST,
            apiVersion: .v2
        )
    }

    func test_itGenerateARequest_APIV1() throws {
        // Given
        let expectedPayload = try XCTUnwrap(RequestPayload(qualified_users: action.userIDs).payloadString())

        // Then
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v1/users/list-clients",
            expectedPayload: expectedPayload,
            expectedMethod: .methodPOST,
            apiVersion: .v1
        )
    }

    func test_itFailsToGenerateRequest_APIV0() {
        // Then
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v0,
            expectedError: .endpointUnavailable
        )
    }

    // MARK: - Response handling

    func test_itHandlesResponse_200() throws {
        // Given
        let payload = ResponsePayload(qualified_user_map: [
            domain1: [
                userID1.uuidString: [
                    Payload.UserClient(id: clientID1),
                    Payload.UserClient(id: clientID2)
                ]
            ],
            domain2: [
                userID2.uuidString: [
                    Payload.UserClient(id: clientID3)
                ]
            ]
        ])

        let payloadString = try XCTUnwrap(payload.payloadString())

        // When
        let result = test_itHandlesSuccess(
            status: 200,
            payload: payloadString as ZMTransportData
        )

        // Then
        XCTAssertEqual(result, Set([
            QualifiedClientID(
                userID: userID1,
                domain: domain1,
                clientID: clientID1
            ),
            QualifiedClientID(
                userID: userID1,
                domain: domain1,
                clientID: clientID2
            ),
            QualifiedClientID(
                userID: userID2,
                domain: domain2,
                clientID: clientID3
            )
        ]))
    }

    func test_itHandlesResponse_200_FailedToDecode() throws {
        // When
        test_itHandlesResponse(
            action: action,
            status: 200,
            payload: ["foo": "bar"] as ZMTransportData,
            apiVersion: .v1
        ) { result in
            // Then
            guard case .failure(.failedToDecodeResponsePayload) = result else {
                XCTFail("unexpected result: \(String(describing: result))")
                return false
            }

            return true
        }
    }

    func test_itHandlesResponse_400_MalformedRequestPayload() throws {
        test_itHandlesFailure(
            status: 400,
            label: nil,
            expectedError: .malformdRequestPayload
        )
    }

    func test_itHandlesResponse_Unknown() throws {
        test_itHandlesFailure(
            status: 999,
            label: "foo",
            expectedError: .unknown(status: 999, label: "foo", message: "?")
        )
    }

}
