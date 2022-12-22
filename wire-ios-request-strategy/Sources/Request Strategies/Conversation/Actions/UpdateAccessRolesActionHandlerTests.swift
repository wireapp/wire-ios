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
@testable import WireRequestStrategy

final class UpdateAccessRolesActionHandlerTests: MessagingTestBase {

    var sut: UpdateAccessRolesActionHandler!
    var conversation: ZMConversation!
    var accessMode: ConversationAccessMode!
    var accessRoles: Set<ConversationAccessRoleV2>!

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedBlockAndWait {
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [])!
            let conversationID = UUID()
            conversation.remoteIdentifier = conversationID
            conversation.conversationType = .group
            conversation.domain = self.owningDomain
            self.conversation = conversation
            self.accessMode = .allowGuests
            self.accessRoles = [.teamMember, .nonTeamMember, .guest]
        }

        sut = UpdateAccessRolesActionHandler(context: syncMOC)
    }

    override func tearDown() {
        conversation = nil
        accessMode = nil
        accessRoles = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Request generation

    func testThatItCreatesAnExpectedRequestForUpdatingAccessRoles_V0() throws {
        try syncMOC.performGroupedAndWait { _ in
            // given
            let conversationID = self.conversation.remoteIdentifier!
            let action = UpdateAccessRolesAction(conversation: self.conversation,
                                                 accessMode: self.accessMode,
                                                 accessRoles: self.accessRoles)
            // when
            let request = try XCTUnwrap(self.sut.request(for: action, apiVersion: .v0))

            // then
            XCTAssertEqual(request.path, "/conversations/\(conversationID.transportString())/access")
            let payload = Payload.UpdateConversationAccess(request)
            XCTAssertEqual(payload?.accessRoleV2, self.accessRoles.map(\.rawValue))
            XCTAssertEqual(payload?.access, self.accessMode.stringValue)
        }
    }

    func testThatItCreatesAnExpectedRequestForUpdatingAccessRoles_V1() throws {
        try syncMOC.performGroupedAndWait { [self] _ in
            // given
            let conversationDomain = conversation.domain!
            let conversationID = conversation.remoteIdentifier!
            let action = UpdateAccessRolesAction(conversation: conversation,
                                                 accessMode: accessMode,
                                                 accessRoles: accessRoles)
            // when
            let request = try XCTUnwrap(sut.request(for: action, apiVersion: .v1))

            // then
            XCTAssertEqual(request.path, "/v1/conversations/\(conversationDomain)/\(conversationID.transportString())/access")
            let payload = Payload.UpdateConversationAccess(request)
            XCTAssertEqual(payload?.accessRoleV2, accessRoles.map(\.rawValue))
            XCTAssertEqual(payload?.access, accessMode.stringValue)
        }
    }

    // MARK: - Response handling

    func testThatItParsesAllKnownUpdateAccessRolesErrorResponses() {
        let errorResponses: [(UpdateAccessRolesError, ZMTransportResponse)] = [
            (UpdateAccessRolesError.invalidOperation, ZMTransportResponse(payload: ["label": "invalid-op"] as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)),
            (UpdateAccessRolesError.accessDenied, ZMTransportResponse(payload: ["label": "access-denied"] as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)),
            (UpdateAccessRolesError.actionDenied, ZMTransportResponse(payload: ["label": "action-denied"] as ZMTransportData, httpStatus: 403, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)),
            (UpdateAccessRolesError.conversationNotFound, ZMTransportResponse(payload: ["label": "no-conversation"] as ZMTransportData, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        ]

        for (expectedError, response) in errorResponses {
            for (expectedError, response) in errorResponses {
                guard let error = UpdateAccessRolesError(response: response) else {
                    return XCTFail("Error is invalid")
                }

                if case error = expectedError {
                    // success
                } else {
                    XCTFail("Unexpected error")
                }
            }
        }
    }

    func testThatItProcessUpdateAccessRolesEventInTheResponse() throws {
        syncMOC.performGroupedAndWait { [self] _ in
            // given
            let action = UpdateAccessRolesAction(conversation: self.conversation,
                                                 accessMode: accessMode,
                                                 accessRoles: accessRoles)
            let payload = Payload.UpdateConversationAccess(accessMode: accessMode,
                                                           accessRoles: accessRoles)

            let conversationEvent = conversationEventPayload(from: payload,
                                                             conversationID: conversation.qualifiedID,
                                                             senderID: self.otherUser.qualifiedID)
            let payloadAsString = String(bytes: conversationEvent.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 200,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            // when
            XCTAssertEqual(conversation.accessRoles, [ConversationAccessRoleV2.teamMember,
                                                      ConversationAccessRoleV2.nonTeamMember,
                                                      ConversationAccessRoleV2.guest,
                                                      ConversationAccessRoleV2.service])
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertEqual(conversation.accessRoles, [ConversationAccessRoleV2.teamMember,
                                                      ConversationAccessRoleV2.nonTeamMember,
                                                      ConversationAccessRoleV2.guest])
        }
    }

    func testThatItCallsResultHandler_On200() {
        syncMOC.performGroupedAndWait { [self] _ in
            // given
            var action = UpdateAccessRolesAction(conversation: self.conversation,
                                                 accessMode: accessMode,
                                                 accessRoles: accessRoles)
            let expectation = self.expectation(description: "Result Handler was called")
            action.onResult { (result) in
                if case .success = result {
                    expectation.fulfill()
                }
            }

            let payload = Payload.UpdateConversationAccess(accessMode: accessMode,
                                                           accessRoles: accessRoles)

            let conversationEvent = conversationEventPayload(from: payload,
                                                             conversationID: conversation.qualifiedID,
                                                             senderID: self.otherUser.qualifiedID)
            let payloadAsString = String(bytes: conversationEvent.payloadData()!, encoding: .utf8)!
            let response = ZMTransportResponse(payload: payloadAsString as ZMTransportData,
                                               httpStatus: 200,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItCallsResultHandler_OnError() {
        syncMOC.performGroupedAndWait { [self] _ in
            // given
            var action = UpdateAccessRolesAction(conversation: self.conversation,
                                                 accessMode: accessMode,
                                                 accessRoles: accessRoles)

            let expectation = self.expectation(description: "Result Handler was called")
            action.onResult { (result) in
                if case .failure = result {
                    expectation.fulfill()
                }
            }

            let response = ZMTransportResponse(payload: nil,
                                               httpStatus: 404,
                                               transportSessionError: nil,
                                               apiVersion: APIVersion.v0.rawValue)

            // when
            self.sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

}
