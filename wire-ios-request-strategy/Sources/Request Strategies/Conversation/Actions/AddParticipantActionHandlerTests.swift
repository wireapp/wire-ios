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

final class AddParticipantActionHandlerTests: MessagingTestBase {
    typealias ErrorResponse = AddParticipantActionHandler.ErrorResponse

    var sut: AddParticipantActionHandler!
    var user: ZMUser!
    var conversation: ZMConversation!
    var mockConversationService: MockConversationServiceInterface!

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedAndWait {
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            let userID = UUID()
            user.remoteIdentifier = userID
            user.domain = self.owningDomain
            self.user = user

            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [])!
            let conversationID = UUID()
            conversation.remoteIdentifier = conversationID
            conversation.conversationType = .group
            conversation.domain = self.owningDomain
            self.conversation = conversation
        }

        mockConversationService = MockConversationServiceInterface()
        mockConversationService.syncConversationIfMissingQualifiedID_MockMethod = { _ in }
        mockConversationService.syncConversationQualifiedID_MockMethod = { _ in }
        mockConversationService.syncConversationQualifiedIDCompletion_MockMethod = { _, completion in
            completion()
        }

        sut = AddParticipantActionHandler(
            context: syncMOC,
            eventProcessor: ConversationEventProcessor(
                context: syncMOC,
                conversationService: mockConversationService,
                mlsEventProcessor: MockMLSEventProcessing()
            )
        )
    }

    override func tearDown() {
        sut = nil
        mockConversationService = nil
        super.tearDown()
    }

    // MARK: - Request Generation

    func testThatItCreatesARequestForAddingAParticipant_V0() throws {
        try syncMOC.performGroupedAndWait {
            // given
            let userID = self.user.remoteIdentifier!
            let conversationID = self.conversation.remoteIdentifier!
            let action = AddParticipantAction(users: [self.user], conversation: self.conversation)

            // when
            let request = try XCTUnwrap(self.sut.request(for: action, apiVersion: .v0))

            // then
            XCTAssertEqual(request.path, "/conversations/\(conversationID.transportString())/members")
            let payload = Payload.ConversationAddMember(request)
            XCTAssertEqual(payload?.userIDs, [userID])
        }
    }

    func testThatItCreatesARequestForAddingAParticipant_V1() throws {
        try syncMOC.performGroupedAndWait {
            // given
            let conversationID = self.conversation.remoteIdentifier!
            let action = AddParticipantAction(users: [self.user], conversation: self.conversation)

            // when
            let request = try XCTUnwrap(self.sut.request(for: action, apiVersion: .v1))

            // then
            XCTAssertEqual(request.path, "/v1/conversations/\(conversationID)/members/v2")
            let payload = Payload.ConversationAddMember(request)
            XCTAssertEqual(payload?.qualifiedUserIDs, [self.user.qualifiedID!])
        }
    }

    func testThatItCreatesARequestForAddingAParticipant_V2() throws {
        try syncMOC.performGroupedAndWait {
            // given
            let conversationDomain = self.conversation.domain!
            let conversationID = self.conversation.remoteIdentifier!
            let action = AddParticipantAction(users: [self.user], conversation: self.conversation)

            // when
            let request = try XCTUnwrap(self.sut.request(for: action, apiVersion: .v2))

            // then
            XCTAssertEqual(request.path, "/v2/conversations/\(conversationDomain)/\(conversationID)/members")
            let payload = Payload.ConversationAddMember(request)
            XCTAssertEqual(payload?.qualifiedUserIDs, [self.user.qualifiedID!])
        }
    }

    // MARK: - Request Processing

    func testThatItParsesAllKnownAddParticipantErrorResponses() {
        let errorResponses: [(ConversationAddParticipantsError, ZMTransportResponse)] = [
            (
                ConversationAddParticipantsError.invalidOperation,
                ZMTransportResponse(
                    payload: ["label": "invalid-op"] as ZMTransportData,
                    httpStatus: 403,
                    transportSessionError: nil,
                    apiVersion: APIVersion.v0.rawValue
                )
            ),
            (
                ConversationAddParticipantsError.accessDenied,
                ZMTransportResponse(
                    payload: ["label": "access-denied"] as ZMTransportData,
                    httpStatus: 403,
                    transportSessionError: nil,
                    apiVersion: APIVersion.v0.rawValue
                )
            ),
            (
                ConversationAddParticipantsError.notConnectedToUser,
                ZMTransportResponse(
                    payload: ["label": "not-connected"] as ZMTransportData,
                    httpStatus: 403,
                    transportSessionError: nil,
                    apiVersion: APIVersion.v0.rawValue
                )
            ),
            (
                ConversationAddParticipantsError.conversationNotFound,
                ZMTransportResponse(
                    payload: ["label": "no-conversation"] as ZMTransportData,
                    httpStatus: 404,
                    transportSessionError: nil,
                    apiVersion: APIVersion.v0.rawValue
                )
            ),
            (
                ConversationAddParticipantsError.missingLegalHoldConsent,
                ZMTransportResponse(
                    payload: ["label": "missing-legalhold-consent"] as ZMTransportData,
                    httpStatus: 412,
                    transportSessionError: nil,
                    apiVersion: APIVersion.v0.rawValue
                )
            ),
        ]

        for (expectedError, response) in errorResponses {
            guard let error = ConversationAddParticipantsError(response: response) else {
                return XCTFail("Error is invalid")
            }

            XCTAssertEqual(expectedError, error, "Unexpected error")
        }
    }

    func testThatItProcessMemberJoinEventInTheResponse() throws {
        var response: ZMTransportResponse!
        var action: AddParticipantAction!

        syncMOC.performGroupedAndWait { [self] in
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            action = AddParticipantAction(users: [user], conversation: conversation)
            let member = Payload.ConversationMember(
                id: user.remoteIdentifier,
                qualifiedID: user.qualifiedID,
                conversationRole: ZMConversation.defaultMemberRoleName
            )
            let memberJoined = Payload.UpdateConverationMemberJoin(
                userIDs: [user.remoteIdentifier],
                users: [member]
            )
            let conversationEvent = conversationEventPayload(
                from: memberJoined,
                conversationID: conversation.qualifiedID,
                senderID: selfUser.qualifiedID
            )
            let payloadAsString = String(bytes: conversationEvent.payloadData()!, encoding: .utf8)!
            response = ZMTransportResponse(
                payload: payloadAsString as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
        }

        let waitForHandler = customExpectation(description: "wait for Handler to be called")

        action.resultHandler = { _ in
            waitForHandler.fulfill()
        }
        // when
        sut.handleResponse(response, action: action)

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // then
        syncMOC.performAndWait {
            XCTAssertTrue(conversation.localParticipants.contains(user))
        }
    }

    func testThatItRefetchTeamUsers_On403() {
        syncMOC.performGroupedAndWait { [self] in
            // given
            let team = Team.insertNewObject(in: syncMOC)
            let selfUser = ZMUser.selfUser(in: syncMOC)

            let teamUser = ZMUser.insertNewObject(in: syncMOC)
            teamUser.remoteIdentifier = UUID()
            teamUser.needsToBeUpdatedFromBackend = false

            let nonTeamUser = ZMUser.insertNewObject(in: syncMOC)
            nonTeamUser.remoteIdentifier = UUID()
            nonTeamUser.needsToBeUpdatedFromBackend = false

            _ = Member.getOrUpdateMember(for: selfUser, in: team, context: syncMOC)
            _ = Member.getOrUpdateMember(for: teamUser, in: team, context: syncMOC)

            let action = AddParticipantAction(users: [teamUser, nonTeamUser], conversation: conversation)
            let response = ZMTransportResponse(
                payload: nil,
                httpStatus: 403,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(teamUser.needsToBeUpdatedFromBackend)
            XCTAssertFalse(nonTeamUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatItCallsResultHandler_On200() {
        var action: AddParticipantAction!

        var response: ZMTransportResponse!
        syncMOC.performGroupedAndWait { [self] in
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            action = AddParticipantAction(users: [user], conversation: conversation)
            let expectation = customExpectation(description: "Result Handler was called")
            action.onResult { result in
                if case .success = result {
                    expectation.fulfill()
                } else {
                    XCTFail("called the wrong result")
                }
            }

            let member = Payload.ConversationMember(
                id: user.remoteIdentifier,
                qualifiedID: user.qualifiedID,
                conversationRole: ZMConversation.defaultMemberRoleName
            )
            let memberJoined = Payload.UpdateConverationMemberJoin(
                userIDs: [user.remoteIdentifier],
                users: [member]
            )
            let conversationEvent = conversationEventPayload(
                from: memberJoined,
                conversationID: conversation.qualifiedID,
                senderID: selfUser.qualifiedID
            )
            let payloadAsString = String(bytes: conversationEvent.payloadData()!, encoding: .utf8)!
            response = ZMTransportResponse(
                payload: payloadAsString as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
        }

        // when
        sut.handleResponse(response, action: action)

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCallsResultHandler_On204() {
        syncMOC.performGroupedAndWait { [self] in
            // given
            var action = AddParticipantAction(users: [user], conversation: conversation)

            let expectation = customExpectation(description: "Result Handler was called")
            action.onResult { result in
                if case .success = result {
                    expectation.fulfill()
                }
            }
            let response = ZMTransportResponse(
                payload: nil,
                httpStatus: 204,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItCallsResultHandler_OnError() {
        syncMOC.performGroupedAndWait { [self] in
            // given
            var action = AddParticipantAction(users: [user], conversation: conversation)

            let expectation = customExpectation(description: "Result Handler was called")
            action.onResult { result in
                if case .failure = result {
                    expectation.fulfill()
                }
            }

            let response = ZMTransportResponse(
                payload: nil,
                httpStatus: 404,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            sut.handleResponse(response, action: action)

            // then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItCallsResultHandler_OnNonFederatingDomainsError() {
        syncMOC.performGroupedAndWait { [self] in
            // Given
            let applesDomain = "apples@domain.com"
            let bananasDomain = "bananas@domain.com"

            let applesUser = ZMUser.insertNewObject(in: syncMOC)
            applesUser.remoteIdentifier = UUID()
            applesUser.domain = applesDomain

            let bananasUser = ZMUser.insertNewObject(in: syncMOC)
            bananasUser.remoteIdentifier = UUID()
            bananasUser.domain = bananasDomain

            var action = AddParticipantAction(
                users: [user, applesUser, bananasUser],
                conversation: conversation
            )

            let isDone = customExpectation(description: "isDone")

            action.onResult {
                switch $0 {
                case .failure(.nonFederatingDomains([applesDomain, bananasDomain])):
                    break

                default:
                    XCTFail("unexpected result: \($0)")
                }

                isDone.fulfill()
            }

            let payload = ErrorResponse(non_federating_backends: [applesDomain, bananasDomain])
            let payloadString = payload.payloadString()!
            let response = ZMTransportResponse(
                payload: payloadString as ZMTransportData,
                httpStatus: 409,
                transportSessionError: nil,
                apiVersion: APIVersion.v4.rawValue
            )

            // When
            sut.handleResponse(response, action: action)

            // Then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItCallsResultHandler_OnUnreachableDomainsError() {
        syncMOC.performGroupedAndWait { [self] in
            // Given
            let unreachableDomain = "foma.wire.link"
            let unreachableUser = ZMUser.insertNewObject(in: syncMOC)
            unreachableUser.remoteIdentifier = UUID()
            unreachableUser.domain = unreachableDomain

            var action = AddParticipantAction(
                users: [user, unreachableUser],
                conversation: conversation
            )

            let isDone = customExpectation(description: "isDone")

            action.onResult {
                switch $0 {
                case .failure(.unreachableDomains([unreachableDomain])):
                    break

                default:
                    XCTFail("unexpected result: \($0)")
                }

                isDone.fulfill()
            }

            let payload = ErrorResponse(unreachable_backends: [unreachableDomain])
            let payloadString = payload.payloadString()!
            let response = ZMTransportResponse(
                payload: payloadString as ZMTransportData,
                httpStatus: 533,
                transportSessionError: nil,
                apiVersion: APIVersion.v4.rawValue
            )

            // When
            sut.handleResponse(response, action: action)

            // Then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
}
