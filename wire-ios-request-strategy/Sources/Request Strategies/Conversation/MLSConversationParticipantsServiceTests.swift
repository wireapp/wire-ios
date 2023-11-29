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

        syncMOC.performAndWait { [self] in
            conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.mlsGroupID = groupID
            conversation.domain = "domain.com"
            conversation.remoteIdentifier = .create()

            user = ZMUser.insertNewObject(in: syncMOC)
            user.remoteIdentifier = .create()
            user.domain = "domain.com"
        }

        sut = MLSConversationParticipantsService(
            context: syncMOC,
            mlsService: mockMLSService,
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

    func test_AddParticipants_Succeeds() async throws {
        // GIVEN
        let expectedUsers = await syncMOC.perform { [self] in
            [MLSUser(from: user)]
        }

        // WHEN
        try await sut.addParticipants([user], to: conversation)

        // THEN
        // assert call to addMembersToConversation
        let addMembersInvocation = try XCTUnwrap(
            mockMLSService.calls.addMembers.first,
            "expected invocation"
        )

        XCTAssertEqual(addMembersInvocation.users, expectedUsers)
        XCTAssertEqual(addMembersInvocation.groupID, groupID)
    }

    func test_AddParticipants_Throws_InvalidOperation() async {
        // GIVEN
        await syncMOC.perform { [self] in
            conversation.mlsGroupID = nil
        }

        // THEN
        await assertItThrows(error: MLSConversationParticipantsError.invalidOperation) {
            // WHEN
            try await sut.addParticipants([user], to: conversation)
        }
    }

    func test_AddParticipants_RethrowsErrors() async {
        // GIVEN
        mockMLSService.addMembersToConversationMock = { _, _ in
            throw ParticipantsError.failedToAddParticipants
        }

        // THEN
        await assertItThrows(error: ParticipantsError.failedToAddParticipants) {
            // WHEN
            try await sut.addParticipants([user], to: conversation)
        }
    }

    // MARK: - Remove Participants

    func test_RemoveParticipant_Succeeds() async throws {
        // GIVEN
        let clientIDs = [MLSClientID.random()]

        mockClientIDsProvider.fetchUserClientsForIn_MockMethod = { _, _ in
            return clientIDs
        }

        // WHEN
        try await sut.removeParticipant(user, from: conversation)

        // THEN
        // gather expected values
        let userID = await syncMOC.perform { [self] in user.qualifiedID }

        // assert calls to fetchUserClients
        let fetchClientsInvocation = try XCTUnwrap(
            mockClientIDsProvider.fetchUserClientsForIn_Invocations.first,
            "expected invocation"
        )

        XCTAssertEqual(fetchClientsInvocation.userID, userID)

        // assert calls to removeMembers
        let removeMembersInvocation = try XCTUnwrap(
            mockMLSService.calls.removeMembers.first,
            "expected invocation"
        )

        XCTAssertEqual(removeMembersInvocation.clientIDs, clientIDs)
        XCTAssertEqual(removeMembersInvocation.groupID, groupID)
    }

    func test_RemoveParticipant_Throws_InvalidOperation() async {
        // GIVEN
        await syncMOC.perform { [self] in
            conversation.mlsGroupID = nil
        }

        // THEN
        await assertItThrows(error: MLSConversationParticipantsError.invalidOperation) {
            // WHEN
            try await sut.removeParticipant(user, from: conversation)
        }
    }

    func test_RemoveParticipant_RethrowsErrors() async {
        // GIVEN
        mockClientIDsProvider.fetchUserClientsForIn_MockMethod = { _, _ in
            return [MLSClientID.random()]
        }

        mockMLSService.removeMembersFromConversationMock = { _, _ in
            throw ParticipantsError.failedToRemoveParticipant
        }

        // THEN
        await assertItThrows(error: ParticipantsError.failedToRemoveParticipant) {
            // WHEN
            try await sut.removeParticipant(user, from: conversation)
        }
    }

    // MARK: - Helpers

    enum ParticipantsError: Error {
        case failedToAddParticipants
        case failedToRemoveParticipant
    }

}
