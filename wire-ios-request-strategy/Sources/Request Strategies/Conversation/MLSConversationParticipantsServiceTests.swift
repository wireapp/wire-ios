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
import WireTesting
@testable import WireRequestStrategy

class MLSConversationParticipantsServiceTests: MessagingTestBase {

    // MARK: - Properties

    var sut: MLSConversationParticipantsService!
    var mockClientIDsProvider: MockMLSClientIDsProviding!
    var mockMLSService: MockMLSService!
    var groupID: MLSGroupID = .random()
    var conversation: ZMConversation!
    var user: ZMUser!

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()

        mockClientIDsProvider = MockMLSClientIDsProviding()
        mockMLSService = MockMLSService()

        syncMOC.performAndWait {
            syncMOC.mlsService = mockMLSService
        }

        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.mlsGroupID = groupID
        conversation.domain = "domain.com"
        conversation.remoteIdentifier = .create()

        user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = .create()
        user.domain = "domain.com"

        sut = MLSConversationParticipantsService(
            context: uiMOC,
            clientIDsProvider: mockClientIDsProvider
        )
    }

    override func tearDown() {
        sut = nil
        mockClientIDsProvider = nil
        mockMLSService = nil
        conversation = nil
        user = nil
        super.tearDown()
    }

    // MARK: - Add Participants

    func test_AddParticipants_Succeeds() throws {
        // GIVEN
        let expectedUsers = [MLSUser(from: user)]

        // THEN
        assertMethodCompletesWithSuccess {
            // WHEN
            sut.addParticipants([user], to: conversation, completion: $0)
        }

        // assert call to addMembersToConversation
        let addMembersInvocation = try XCTUnwrap(
            mockMLSService.calls.addMembers.first,
            "expected invocation"
        )

        XCTAssertEqual(addMembersInvocation.users, expectedUsers)
        XCTAssertEqual(addMembersInvocation.groupID, conversation.mlsGroupID)
    }

    func test_AddParticipants_CompletesWithFailure_InvalidOperation() {
        // GIVEN
        conversation.mlsGroupID = nil

        // THEN
        assertMethodCompletesWithError(.invalidOperation) {
            // WHEN
            sut.addParticipants(
                [user],
                to: conversation,
                completion: $0
            )
        }
    }

    func test_AddParticipants_CompletesWithFailure_FailedToAddMembers() {
        // GIVEN
        mockMLSService.addMembersToConversationMock = { _, _ in
            throw ParticipantsError.failedToAddParticipants
        }

        // THEN
        assertMethodCompletesWithError(.failedToAddMLSMembers) {
            // WHEN
            sut.addParticipants(
                [user],
                to: conversation,
                completion: $0
            )
        }
    }

    // MARK: - Remove Participants

    func test_RemoveParticipant_Succeeds() throws {
        // GIVEN
        let clientIDs = [MLSClientID.random()]

        mockClientIDsProvider.fetchUserClientsForIn_MockMethod = { _, _ in
            return clientIDs
        }

        // THEN
        assertMethodCompletesWithSuccess {
            // WHEN
            sut.removeParticipant(user, from: conversation, completion: $0)
        }

        // assert calls to fetchUserClients
        let fetchClientsInvocation = try XCTUnwrap(
            mockClientIDsProvider.fetchUserClientsForIn_Invocations.first,
            "expected invocation"
        )

        XCTAssertEqual(fetchClientsInvocation.userID, user.qualifiedID)

        // assert calls to removeMembers
        let removeMembersInvocation = try XCTUnwrap(
            mockMLSService.calls.removeMembers.first,
            "expected invocation"
        )

        XCTAssertEqual(removeMembersInvocation.clientIDs, clientIDs)
        XCTAssertEqual(removeMembersInvocation.groupID, conversation.mlsGroupID)
    }

    func test_RemoveParticipant_CompletesWithFailure_InvalidOperation() {
        // GIVEN
        conversation.mlsGroupID = nil

        // THEN
        assertMethodCompletesWithError(.invalidOperation) {
            // WHEN
            sut.removeParticipant(user, from: conversation, completion: $0)
        }
    }

    func test_RemoveParticipant_CompletesWithFailure_FailedToRemoveMembers() {
        // GIVEN
        mockClientIDsProvider.fetchUserClientsForIn_MockMethod = { _, _ in
            return [MLSClientID.random()]
        }

        mockMLSService.removeMembersFromConversationMock = { _, _ in
            throw ParticipantsError.failedToRemoveParticipant
        }

        // THEN
        assertMethodCompletesWithError(.failedToRemoveMLSMembers) {
            // WHEN
            sut.removeParticipant(user, from: conversation, completion: $0)
        }
    }

    // MARK: - Helpers

    enum ParticipantsError: Error {
        case failedToAddParticipants
        case failedToRemoveParticipant
    }

}
