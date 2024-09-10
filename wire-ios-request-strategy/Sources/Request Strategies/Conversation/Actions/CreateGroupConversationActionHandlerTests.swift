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

import WireDataModelSupport
@testable import WireRequestStrategy
import WireTransport
import XCTest

final class CreateGroupConversationActionHandlerTests: ActionHandlerTestBase<CreateGroupConversationAction, CreateGroupConversationActionHandler> {

    typealias RequestPayload = Payload.NewConversation
    typealias ResponsePayload = Payload.Conversation
    typealias ErrorResponse = CreateGroupConversationActionHandler.ErrorResponse

    var sut: CreateGroupConversationActionHandler!

    var conversationID: QualifiedID!
    var mlsGroupID: MLSGroupID!
    var teamID: UUID!
    var user1ID: QualifiedID!
    var user2ID: QualifiedID!

    var expectedRequestPayload: RequestPayload!
    var successResponsePayloadProteus: ResponsePayload!
    var successResponsePayloadMLS: ResponsePayload!

    override func setUp() {
        super.setUp()
        sut = CreateGroupConversationActionHandler(context: syncMOC, removeLocalConversationUseCase: MockLocalConversationRemovalUseCase())

        conversationID = .randomID()
        mlsGroupID = MLSGroupID(.init([1, 2, 3]))
        teamID = .create()
        user1ID = .randomID()
        user2ID = .randomID()

        expectedRequestPayload = RequestPayload(
            users: nil,
            qualifiedUsers: [user1ID, user2ID],
            access: ["invite", "code"],
            legacyAccessRole: nil,
            accessRoles: ["guest", "service", "non_team_member", "team_member"],
            name: "foo bar",
            team: .init(teamID: teamID),
            messageTimer: nil,
            readReceiptMode: 1,
            conversationRole: "wire_member",
            creatorClient: nil,
            messageProtocol: "proteus"
        )

        successResponsePayloadProteus = ResponsePayload(
            qualifiedID: conversationID,
            id: conversationID.uuid,
            type: BackendConversationType.group.rawValue,
            creator: user1ID.uuid,
            access: ["invite", "code"],
            legacyAccessRole: nil,
            accessRoles: ["guest", "service", "non_team_member", "team_member"],
            name: "foo bar",
            members: Payload.ConversationMembers(
                selfMember: Payload.ConversationMember(
                    id: user1ID.uuid,
                    qualifiedID: user1ID
                ),
                others: [
                    Payload.ConversationMember(
                        id: user2ID.uuid,
                        qualifiedID: user2ID
                    )
                ]
            ),
            lastEvent: nil,
            lastEventTime: nil,
            teamID: teamID,
            messageTimer: nil,
            readReceiptMode: 1,
            messageProtocol: "proteus",
            mlsGroupID: nil,
            epoch: nil
        )

        successResponsePayloadMLS = successResponsePayloadProteus
        successResponsePayloadMLS.messageProtocol = "mls"
        successResponsePayloadMLS.mlsGroupID = mlsGroupID.data.base64EncodedString()
        successResponsePayloadMLS.epoch = 0

        BackendInfo.apiVersion = .v0
        BackendInfo.domain = "example.com"
    }

    override func tearDown() {
        sut = nil
        conversationID = nil
        mlsGroupID = nil
        teamID = nil
        user1ID = nil
        user2ID = nil
        expectedRequestPayload = nil
        successResponsePayloadProteus = nil
        successResponsePayloadMLS = nil
        super.tearDown()
    }

    private func createAction(messageProtocol: MessageProtocol = .proteus) -> CreateGroupConversationAction {
        return CreateGroupConversationAction(
            messageProtocol: messageProtocol,
            creatorClientID: "creatorClientID",
            qualifiedUserIDs: [user1ID, user2ID],
            unqualifiedUserIDs: [],
            name: "foo bar",
            accessMode: .allowGuests,
            accessRoles: [.guest, .service, .nonTeamMember, .teamMember],
            legacyAccessRole: nil,
            teamID: teamID,
            isReadReceiptsEnabled: true
        )
    }

    private func assertEqual(actualPayload: RequestPayload, expectedPayload: RequestPayload) {
        XCTAssertEqual(actualPayload.users, [])
        XCTAssertEqual(actualPayload.qualifiedUsers, expectedPayload.qualifiedUsers)
        XCTAssertEqual(actualPayload.access.map(Set.init), expectedPayload.access.map(Set.init))
        XCTAssertEqual(actualPayload.legacyAccessRole, expectedPayload.legacyAccessRole)
        XCTAssertEqual(actualPayload.accessRoles.map(Set.init), expectedPayload.accessRoles.map(Set.init))
        XCTAssertEqual(actualPayload.name, expectedPayload.name)
        XCTAssertEqual(actualPayload.team, expectedPayload.team)
        XCTAssertEqual(actualPayload.messageTimer, expectedPayload.messageTimer)
        XCTAssertEqual(actualPayload.readReceiptMode, expectedPayload.readReceiptMode)
        XCTAssertEqual(actualPayload.conversationRole, expectedPayload.conversationRole)
        XCTAssertEqual(actualPayload.creatorClient, expectedPayload.creatorClient)
        XCTAssertEqual(actualPayload.messageProtocol, expectedPayload.messageProtocol)
    }

    // MARK: - Request generation

    func test_RequestGeneration_V0() throws {
        // Given
        BackendInfo.apiVersion = .v0
        let action = createAction()

        // When
        let result = try XCTUnwrap(sut.request(for: action, apiVersion: .v0))

        // Then
        XCTAssertEqual(result.path, "/conversations")
        XCTAssertEqual(result.method, .post)
        XCTAssertEqual(result.apiVersion, 0)

        let payload = try XCTUnwrap(RequestPayload(result))

        assertEqual(
            actualPayload: payload,
            expectedPayload: expectedRequestPayload
        )
    }

    func test_RequestGeneration_V1() throws {
        // Given
        BackendInfo.apiVersion = .v1
        let action = createAction()

        // When
        let result = try XCTUnwrap(sut.request(for: action, apiVersion: .v1))

        // Then
        XCTAssertEqual(result.path, "/v1/conversations")
        XCTAssertEqual(result.method, .post)
        XCTAssertEqual(result.apiVersion, 1)

        let payload = try XCTUnwrap(RequestPayload(result))

        assertEqual(
            actualPayload: payload,
            expectedPayload: expectedRequestPayload
        )
    }

    func test_RequestGeneration_V2() throws {
        // Given
        BackendInfo.apiVersion = .v2
        let action = createAction()

        // When
        let result = try XCTUnwrap(sut.request(for: action, apiVersion: .v2))

        // Then
        XCTAssertEqual(result.path, "/v2/conversations")
        XCTAssertEqual(result.method, .post)
        XCTAssertEqual(result.apiVersion, 2)

        let payload = try XCTUnwrap(RequestPayload(result))

        assertEqual(
            actualPayload: payload,
            expectedPayload: expectedRequestPayload
        )
    }

    func test_RequestGeneration_V3() throws {
        // Given
        BackendInfo.apiVersion = .v3
        let action = createAction()

        // When
        let result = try XCTUnwrap(sut.request(for: action, apiVersion: .v3))

        // Then
        XCTAssertEqual(result.path, "/v3/conversations")
        XCTAssertEqual(result.method, .post)
        XCTAssertEqual(result.apiVersion, 3)

        let payload = try XCTUnwrap(RequestPayload(result))

        assertEqual(
            actualPayload: payload,
            expectedPayload: expectedRequestPayload
        )
    }

    func test_RequestGeneration_V4() throws {
        // Given
        BackendInfo.apiVersion = .v4
        let action = createAction()

        // When
        let result = try XCTUnwrap(sut.request(for: action, apiVersion: .v4))

        // Then
        XCTAssertEqual(result.path, "/v4/conversations")
        XCTAssertEqual(result.method, .post)
        XCTAssertEqual(result.apiVersion, 4)

        let payload = try XCTUnwrap(RequestPayload(result))

        assertEqual(
            actualPayload: payload,
            expectedPayload: expectedRequestPayload
        )
    }

    // MARK: - Response handling

    func test_HandleResponse_200() throws {
        // Given
        let apiVersion = APIVersion.v2
        BackendInfo.apiVersion = apiVersion
        action = createAction()
        handler = sut

        // When
        let payload = try XCTUnwrap(successResponsePayloadProteus.encodeToJSONString())
        let result = try XCTUnwrap(test_itHandlesSuccess(
            status: 200,
            payload: payload as ZMTransportData,
            apiVersion: apiVersion
        ))

        // Then
        try syncMOC.performAndWait {
            let conversation = try XCTUnwrap(syncMOC.existingObject(with: result) as? ZMConversation)
            assertConversationHasCorrectValues(conversation)
        }
    }

    func test_HandleResponse_201() throws {
        // Given
        let apiVersion = APIVersion.v2
        BackendInfo.apiVersion = apiVersion
        action = createAction()
        handler = sut

        // When
        let payload = try XCTUnwrap(successResponsePayloadProteus.encodeToJSONString())
        let result = try XCTUnwrap(test_itHandlesSuccess(
            status: 201,
            payload: payload as ZMTransportData,
            apiVersion: apiVersion
        ))

        // Then
        try syncMOC.performAndWait {
            let conversation = try XCTUnwrap(syncMOC.existingObject(with: result) as? ZMConversation)
            assertConversationHasCorrectValues(conversation)
        }
    }

    private func assertConversationHasCorrectValues(_ conversation: ZMConversation) {
        XCTAssertEqual(conversation.qualifiedID, conversationID)
        XCTAssertEqual(conversation.remoteIdentifier, conversationID.uuid)
        XCTAssertEqual(conversation.teamRemoteIdentifier, teamID)
        XCTAssertEqual(conversation.conversationType, .group)
        XCTAssertEqual(conversation.userDefinedName, "foo bar")
        XCTAssertEqual(conversation.localParticipants.count, 2)
        XCTAssertTrue(conversation.allowGuests)
        XCTAssertTrue(conversation.allowServices)
        XCTAssertTrue(conversation.hasReadReceiptsEnabled)
    }

    func test_ItUpdatesMLSConversation() throws {
        // Given
        let apiVersion = APIVersion.v5
        BackendInfo.apiVersion = apiVersion
        action = createAction(messageProtocol: .mls)
        handler = sut
        let payload = try XCTUnwrap(successResponsePayloadMLS.encodeToJSONString())

        // When
        let result = try XCTUnwrap(test_itHandlesSuccess(
            status: 201,
            payload: payload as ZMTransportData,
            apiVersion: apiVersion
        ))

        // Then
        try syncMOC.performAndWait {
            let conversation = try XCTUnwrap(syncMOC.existingObject(with: result) as? ZMConversation)
            assertConversationHasCorrectValues(conversation)
            XCTAssertEqual(conversation.messageProtocol, .mls)
            XCTAssertEqual(conversation.mlsGroupID, mlsGroupID)
        }
    }

    func test_HandleResponse_Failures() throws {
        // Given
        action = createAction()
        handler = sut

        // Then
        test_itHandlesFailures([
            .failure(status: 400, error: .mlsNotEnabled, label: "mls-not-enabled"),
            .failure(status: 400, error: .nonEmptyMemberList, label: "non-empty-member-list"),
            .failure(status: 400, error: .invalidBody),
            .failure(status: 403, error: .missingLegalholdConsent, label: "missing-legalhold-consent"),
            .failure(status: 403, error: .operationDenied, label: "operation-denied"),
            .failure(status: 403, error: .noTeamMember, label: "no-team-member"),
            .failure(status: 403, error: .notConnected, label: "not-connected"),
            .failure(status: 403, error: .mlsMissingSenderClient, label: "mls-missing-sender-client"),
            .failure(status: 403, error: .accessDenied, label: "access-denied"),
            .failure(status: 999, error: .unknown(code: 999, label: "foo", message: "?"), label: "foo")
        ])
    }

    func testThatItCallsResultHandler_OnUnreachableDomainsError() {
        syncMOC.performGroupedAndWait { [self] in
            // Given
            BackendInfo.apiVersion = .v4
            let unreachableDomain = "foma.wire.link"
            let unreachableUserID = QualifiedID(uuid: UUID(), domain: unreachableDomain)

            action = CreateGroupConversationAction(
                messageProtocol: .proteus,
                creatorClientID: "creatorClientID",
                qualifiedUserIDs: [user1ID, unreachableUserID],
                unqualifiedUserIDs: [],
                name: "foo bar",
                accessMode: .allowGuests,
                accessRoles: [.guest, .service, .nonTeamMember, .teamMember],
                legacyAccessRole: nil,
                teamID: teamID,
                isReadReceiptsEnabled: true
            )
            handler = sut

            let isDone = self.customExpectation(description: "isDone")

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
            let payloadString = payload.payloadString()
            let response = ZMTransportResponse(
                payload: payloadString as? ZMTransportData,
                httpStatus: 533,
                transportSessionError: nil,
                apiVersion: APIVersion.v4.rawValue
            )

            // When
            self.sut.handleResponse(response, action: action)

            // Then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatItCallsResultHandler_OnNonFederatingDomainsError() {
        syncMOC.performGroupedAndWait { [self] in
            // Given
            BackendInfo.apiVersion = .v4
            let applesDomain = "apples@domain.com"
            let bananasDomain = "bananas@domain.com"

            let applesQualifiedID = QualifiedID(uuid: UUID(), domain: applesDomain)
            let bananasQualifiedID = QualifiedID(uuid: UUID(), domain: bananasDomain)

            action = CreateGroupConversationAction(
                messageProtocol: .proteus,
                creatorClientID: "creatorClientID",
                qualifiedUserIDs: [applesQualifiedID, bananasQualifiedID],
                unqualifiedUserIDs: [],
                name: "foo bar",
                accessMode: .allowGuests,
                accessRoles: [.guest, .service, .nonTeamMember, .teamMember],
                legacyAccessRole: nil,
                teamID: teamID,
                isReadReceiptsEnabled: true
            )
            handler = sut

            let isDone = self.customExpectation(description: "isDone")

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
            let payloadString = payload.payloadString()
            let response = ZMTransportResponse(
                payload: payloadString as? ZMTransportData,
                httpStatus: 409,
                transportSessionError: nil,
                apiVersion: APIVersion.v4.rawValue
            )

            // When
            self.sut.handleResponse(response, action: action)

            // Then
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

}
