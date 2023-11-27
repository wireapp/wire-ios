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

class ConversationParticipantsServiceTests: MessagingTestBase {

    // MARK: - Properties

    var sut: ConversationParticipantsService!
    var mockProteusParticipantsService: MockProteusConversationParticipantsServiceInterface!
    var mockMLSParticipantsService: MockMLSConversationParticipantsServiceInterface!
    var selfUser: ZMUser!
    var conversation: ZMConversation!
    var user: ZMUser!

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()

        mockProteusParticipantsService = MockProteusConversationParticipantsServiceInterface()
        mockMLSParticipantsService = MockMLSConversationParticipantsServiceInterface()

        // Set users and conversation stubs
        selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.remoteIdentifier = .create()

        conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.conversationType = .group

        user = ZMUser.insertNewObject(in: syncMOC)

        // Set up sut
        sut = ConversationParticipantsService(
            context: syncMOC,
            proteusParticipantsService: mockProteusParticipantsService,
            mlsParticipantsService: mockMLSParticipantsService
        )
    }

    override func tearDown() {
        mockProteusParticipantsService = nil
        mockMLSParticipantsService = nil
        selfUser = nil
        conversation = nil
        user = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Adding Participants - Federation Errors

    func test_AddParticipants_InsertsSysMessage_AndRetriesOperation_ForUnreachableDomains() async throws {
        // GIVEN
        let (reachables, unreachables) = createFederationStubs()

        conversation.messageProtocol = .proteus
        conversation.domain = reachables.first?.domain

        mockProteusAddParticipantsFailingOnce(
            with: .unreachableDomains(Set(unreachables.map(\.domain)))
        )

        // WHEN
        try await sut.addParticipants(
            (reachables + unreachables).map(\.user),
            to: conversation
        )

        // THEN
        assertSystemMessageWasInserted(
            forUsers: Set(unreachables.map(\.user)),
            in: conversation
        )

        try assertReachableUsersWereAddedOnRetry(
            expectedUsers: Set(reachables.map(\.user))
        )
    }

    func test_AddParticipants_InsertsSysMessage_AndRetriesOperation_ForNonFederatingDomains() async throws {
        // GIVEN
        let (federating, nonFederating) = createFederationStubs()

        conversation.messageProtocol = .proteus
        conversation.domain = federating.first?.domain

        mockProteusAddParticipantsFailingOnce(
            with: .nonFederatingDomains(Set(nonFederating.map(\.domain)))
        )

        // WHEN
        try await sut.addParticipants(
            (federating + nonFederating).map(\.user),
            to: conversation
        )

        // THEN
        assertSystemMessageWasInserted(
            forUsers: Set(nonFederating.map(\.user)),
            in: conversation
        )

        try assertReachableUsersWereAddedOnRetry(
            expectedUsers: Set(federating.map(\.user))
        )
    }

    func test_AddParticipants_InsertsSysMessage_AndDoesntRetryOperation_NoUsersFromUnreachableDomains() async throws {
        // GIVEN
        let (federating, _) = createFederationStubs()

        conversation.messageProtocol = .proteus
        conversation.domain = federating.first?.domain

        mockProteusAddParticipantsFailingOnce(
            with: .nonFederatingDomains(Set())
        )

        // WHEN
        try await sut.addParticipants(
            federating.map(\.user),
            to: conversation
        )

        // THEN
        assertSystemMessageWasInserted(
            forUsers: Set(federating.map(\.user)),
            in: conversation
        )

        XCTAssertEqual(mockProteusParticipantsService.addParticipantsTo_Invocations.count, 1)
    }

    // MARK: - Adding Participants - Invalid Operations

    func test_AddParticipants_Throws_InvalidOperation_ForWrongConversationType() async {
        // GIVEN
        conversation.conversationType = .oneOnOne

        // THEN
        await assertItThrows(error: ConversationParticipantsError.invalidOperation) {
            // WHEN
            try await sut.addParticipants([user], to: conversation)
        }
    }

    func test_AddParticipants_Throws_InvalidOperation_ForSelfUser() async {

        // THEN
        await assertItThrows(error: ConversationParticipantsError.invalidOperation) {
            // WHEN
            try await sut.addParticipants([selfUser], to: conversation)
        }
    }

    // MARK: - Adding Participants - Message Protocol

    func test_AddParticipants_UsesProteus_WhenMessageProtocol_IsProteus() async throws {
        // GIVEN
        conversation.messageProtocol = .proteus

        mockProteusParticipantsService.addParticipantsTo_MockMethod = { _, _ in }

        // WHEN
        try await sut.addParticipants([user], to: conversation)

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.addParticipantsTo_Invocations.count, 1)
        XCTAssertEqual(mockMLSParticipantsService.addParticipantsTo_Invocations.count, 0)
    }

    func test_AddParticipants_UsesMLS_WhenMessageProtocol_IsMLS() async throws {
        // GIVEN
        conversation.messageProtocol = .mls

        mockMLSParticipantsService.addParticipantsTo_MockMethod = { _, _ in }

        // WHEN
        try await sut.addParticipants([user], to: conversation)

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.addParticipantsTo_Invocations.count, 0)
        XCTAssertEqual(mockMLSParticipantsService.addParticipantsTo_Invocations.count, 1)
    }

    func test_AddParticipants_UsesProteusAndMLS_WhenMessageProtocol_IsMixed() async throws {
        // GIVEN
        conversation.messageProtocol = .mixed

        mockProteusParticipantsService.addParticipantsTo_MockMethod = { _, _ in }
        mockMLSParticipantsService.addParticipantsTo_MockMethod = { _, _ in }

        // WHEN
        try await sut.addParticipants([user], to: conversation)

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.addParticipantsTo_Invocations.count, 1)
        XCTAssertEqual(mockMLSParticipantsService.addParticipantsTo_Invocations.count, 1)
    }

    // MARK: - Removing Participants - Invalid Operations

    func test_RemoveParticipants_InvalidOperation() async {
        conversation.conversationType = .oneOnOne

        await assertItThrows(error: ConversationParticipantsError.invalidOperation) {
            try await sut.removeParticipant(user, from: conversation)
        }
    }

    // MARK: - Removing Participants - Message Protocol

    func test_RemoveParticipants_UsesProteus_WhenMessageProtocol_IsProteus() async throws {
        // GIVEN
        conversation.messageProtocol = .proteus

        mockProteusParticipantsService.removeParticipantFrom_MockMethod = { _, _ in }

        // WHEN
        try await sut.removeParticipant(user, from: conversation)

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.removeParticipantFrom_Invocations.count, 1)
        XCTAssertEqual(mockMLSParticipantsService.removeParticipantFrom_Invocations.count, 0)
    }

    func test_RemoveParticipants_UsesProteus_WhenMessageProtocol_IsMixed() async throws {
        // GIVEN
        conversation.messageProtocol = .mixed

        mockProteusParticipantsService.removeParticipantFrom_MockMethod = { _, _ in }

        // WHEN
        try await sut.removeParticipant(user, from: conversation)

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.removeParticipantFrom_Invocations.count, 1)
        XCTAssertEqual(mockMLSParticipantsService.removeParticipantFrom_Invocations.count, 0)
    }

    func test_RemoveParticipants_UsesProteus_WhenMessageProtocol_IsMLS_forSelfUser() async throws {
        // GIVEN
        conversation.messageProtocol = .mls

        mockProteusParticipantsService.removeParticipantFrom_MockMethod = { _, _ in }

        // WHEN
        try await sut.removeParticipant(selfUser, from: conversation)

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.removeParticipantFrom_Invocations.count, 1)
        XCTAssertEqual(mockMLSParticipantsService.removeParticipantFrom_Invocations.count, 0)
    }

    func test_RemoveParticipants_UsesMLS_WhenMessageProtocol_IsMLS_forOtherUsers() async throws {
        // GIVEN
        conversation.messageProtocol = .mls

        mockMLSParticipantsService.removeParticipantFrom_MockMethod = { _, _ in }

        // WHEN
        try await sut.removeParticipant(user, from: conversation)

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.removeParticipantFrom_Invocations.count, 0)
        XCTAssertEqual(mockMLSParticipantsService.removeParticipantFrom_Invocations.count, 1)
    }
}

// MARK: - Federation tests helpers

private extension ConversationParticipantsServiceTests {
    typealias DomainUserTuple = (domain: String, user: ZMUser)

    func createFederationStubs() -> (reachables: [DomainUserTuple], unreachables: [DomainUserTuple]) {
        let applesDomain = "apples.com"
        let bananasDomain = "bananas.com"
        let carrotsDomain = "carrots.com"

        let applesUser = ZMUser.insertNewObject(in: uiMOC)
        applesUser.remoteIdentifier = .create()
        applesUser.domain = applesDomain

        let bananasUser = ZMUser.insertNewObject(in: uiMOC)
        bananasUser.remoteIdentifier = .create()
        bananasUser.domain = bananasDomain

        let carrotsUser = ZMUser.insertNewObject(in: uiMOC)
        carrotsUser.remoteIdentifier = .create()
        carrotsUser.domain = carrotsDomain

        return (
            reachables: [
                (applesDomain, applesUser)
            ],
            unreachables: [
                (bananasDomain, bananasUser),
                (carrotsDomain, carrotsUser)
            ]
        )
    }

    func assertSystemMessageWasInserted(
        forUsers users: Set<ZMUser>,
        in conversation: ZMConversation,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let systemMessage = conversation.lastMessage?.systemMessageData else {
            return XCTFail("expected system message", file: file, line: line)
        }

        XCTAssertEqual(systemMessage.systemMessageType, .failedToAddParticipants, file: file, line: line)
        XCTAssertEqual(systemMessage.userTypes, users, file: file, line: line)
    }


    func assertReachableUsersWereAddedOnRetry(
        expectedUsers: Set<ZMUser>,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {

        XCTAssertEqual(
            mockProteusParticipantsService.addParticipantsTo_Invocations.count,
            2,
            file: file,
            line: line
        )

        let addedUsers = try XCTUnwrap(
            mockProteusParticipantsService.addParticipantsTo_Invocations.last?.users,
            "expected users to be added",
            file: file,
            line: line
        )

        XCTAssertEqual(
            Set(addedUsers),
            expectedUsers,
            file: file,
            line: line
        )
    }

    func mockProteusAddParticipantsFailingOnce(with error: FederationError) {
        var addAttempts = 0
        mockProteusParticipantsService.addParticipantsTo_MockMethod = { _, _ in
            if addAttempts == 0 {
                throw error
            }
            addAttempts += 1
        }
    }
}
