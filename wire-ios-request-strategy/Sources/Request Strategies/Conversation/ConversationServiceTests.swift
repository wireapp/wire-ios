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
@testable import WireRequestStrategy

final class ConversationServiceTests: MessagingTestBase {

    var sut: ConversationService!
    var mockParticipantsService: MockConversationParticipantsServiceInterface!
    var user1: ZMUser!
    var user2: ZMUser!

    override func setUp() {
        super.setUp()
        mockParticipantsService = MockConversationParticipantsServiceInterface()
        sut = ConversationService(
            context: uiMOC,
            participantsService: mockParticipantsService
        )
        user1 = createUser(alsoCreateClient: true, in: uiMOC)
        user2 = createUser(alsoCreateClient: true, in: uiMOC)
    }

    override func tearDown() {
        mockParticipantsService = nil
        sut = nil
        user1 = nil
        user2 = nil
        super.tearDown()
    }

    // MARK: - Create conversation

    func test_CreateGroupConversation_Team_Success() throws {
        // Given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let team = createTeam(in: uiMOC)

        let groupConversation = createGroupConversation(
            with: user1,
            in: uiMOC
        )

        let didFinish = customExpectation(description: "didFinish")

        // Mock
        let mockActionHandler = MockActionHandler<CreateGroupConversationAction>(
            result: .success(groupConversation.objectID),
            context: uiMOC.notificationContext
        )

        // When
        sut.createGroupConversation(
            name: "Foo Bar",
            users: [user1],
            allowGuests: true,
            allowServices: true,
            enableReceipts: true,
            messageProtocol: .proteus
        ) {
            switch $0 {
            case .success(let conversation):
                // Then we got back newly created conversation.
                XCTAssertEqual(conversation, groupConversation)
                didFinish.fulfill()

            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }
        }

        // Then the action was performed with correct arguments.
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        let performedAction = try XCTUnwrap(mockActionHandler.performedActions.first)

        XCTAssertEqual(performedAction.messageProtocol, .proteus)
        XCTAssertEqual(performedAction.creatorClientID, selfUser.selfClient()?.remoteIdentifier)
        XCTAssertEqual(performedAction.qualifiedUserIDs, [user1.qualifiedID].compactMap(\.self))
        XCTAssertEqual(performedAction.unqualifiedUserIDs, [])
        XCTAssertEqual(performedAction.name, "Foo Bar")
        XCTAssertEqual(performedAction.accessMode, .allowGuests)
        XCTAssertEqual(performedAction.accessRoles, [.guest, .service, .nonTeamMember, .teamMember])
        XCTAssertEqual(performedAction.legacyAccessRole, nil)
        XCTAssertEqual(performedAction.teamID, team.remoteIdentifier)
        XCTAssertEqual(performedAction.isReadReceiptsEnabled, true)
    }

    func test_CreateGroupConversation_NonTeam_Success() throws {
        // Given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        XCTAssertFalse(selfUser.hasTeam)

        let groupConversation = createGroupConversation(
            with: user1,
            in: uiMOC
        )

        let didFinish = customExpectation(description: "didFinish")

        // Mock
        let mockActionHandler = MockActionHandler<CreateGroupConversationAction>(
            result: .success(groupConversation.objectID),
            context: uiMOC.notificationContext
        )

        // When
        sut.createGroupConversation(
            name: "Foo Bar",
            users: [user1],
            allowGuests: true,
            allowServices: true,
            enableReceipts: true,
            messageProtocol: .proteus
        ) {
            switch $0 {
            case .success(let conversation):
                // Then we got back newly created conversation.
                XCTAssertEqual(conversation, groupConversation)
                didFinish.fulfill()

            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }
        }

        // Then the action was performed with correct arguments.
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        let performedAction = try XCTUnwrap(mockActionHandler.performedActions.first)

        XCTAssertEqual(performedAction.messageProtocol, .proteus)
        XCTAssertEqual(performedAction.creatorClientID, selfUser.selfClient()?.remoteIdentifier)
        XCTAssertEqual(performedAction.qualifiedUserIDs, [user1.qualifiedID].compactMap(\.self))
        XCTAssertEqual(performedAction.unqualifiedUserIDs, [])
        XCTAssertEqual(performedAction.name, "Foo Bar")
        XCTAssertEqual(performedAction.accessMode, ConversationAccessMode())
        XCTAssertEqual(performedAction.accessRoles, [])
        XCTAssertEqual(performedAction.legacyAccessRole, nil)
        XCTAssertEqual(performedAction.teamID, nil)
        XCTAssertEqual(performedAction.isReadReceiptsEnabled, false)
    }

    func test_CreateOneToOneConversation_Team_Success() throws {
        // Given
        let team = createTeam(in: uiMOC)
        user1.teamIdentifier = team.remoteIdentifier

        let oneToOneConversation = createOneToOneConversation(
            with: user1,
            in: uiMOC
        )

        let didFinish = customExpectation(description: "didFinish")

        // Mock
        let mockActionHandler = MockActionHandler<CreateGroupConversationAction>(
            result: .success(oneToOneConversation.objectID),
            context: uiMOC.notificationContext
        )

        // When
        sut.createTeamOneToOneConversation(user: user1) {
            switch $0 {
            case .success(let conversation):
                // Then we got back newly created conversation.
                XCTAssertEqual(conversation, oneToOneConversation)
                didFinish.fulfill()

            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }
        }

        // Then the action was performed with correct arguments.
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        let performedAction = try XCTUnwrap(mockActionHandler.performedActions.first)

        XCTAssertEqual(performedAction.messageProtocol, .proteus)
        XCTAssertEqual(performedAction.qualifiedUserIDs, [user1.qualifiedID].compactMap(\.self))
        XCTAssertEqual(performedAction.unqualifiedUserIDs, [])
        XCTAssertEqual(performedAction.name, nil)
        XCTAssertEqual(performedAction.teamID, team.remoteIdentifier)
    }

    func test_CreateGroupConversation_Team_NoPermissionFailure() throws {
        // Given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        createTeam(in: uiMOC)

        selfUser.membership?.permissions.remove(.member)
        XCTAssertFalse(selfUser.canCreateConversation(type: .group))

        let didFinish = customExpectation(description: "didFinish")

        // When
        sut.createGroupConversation(
            name: nil,
            users: [user1],
            allowGuests: true,
            allowServices: true,
            enableReceipts: true,
            messageProtocol: .proteus
        ) {
            switch $0 {
            case .failure(.missingPermissions):
                didFinish.fulfill()

            case .success:
                XCTFail("unexpected success")

            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }
        }

        // Then we got the expected failure.
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_CreateGroupConversation_ConversationNotFoundFailure() throws {
        // Given
        let randomObjectID = otherUser.objectID
        let didFinish = customExpectation(description: "didFinish")

        let mockActionHandler = MockActionHandler<CreateGroupConversationAction>(
            result: .success(randomObjectID),
            context: uiMOC.notificationContext
        )

        // When
        sut.createGroupConversation(
            name: nil,
            users: [user1],
            allowGuests: true,
            allowServices: true,
            enableReceipts: true,
            messageProtocol: .proteus
        ) {
            switch $0 {
            case .failure(.conversationNotFound):
                didFinish.fulfill()

            case .success:
                XCTFail("unexpected success")

            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }
        }

        // Then we got the expected failure.
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(mockActionHandler.performedActions.count, 1)
    }

    func test_CreateGroupConversation_NetworkErrorFailure() throws {
        // Given
        let didFinish = customExpectation(description: "didFinish")

        let mockActionHandler = MockActionHandler<CreateGroupConversationAction>(
            result: .failure(.operationDenied),
            context: uiMOC.notificationContext
        )

        // When
        sut.createGroupConversation(
            name: nil,
            users: [user1],
            allowGuests: true,
            allowServices: true,
            enableReceipts: true,
            messageProtocol: .proteus
        ) {
            switch $0 {
            case .failure(.networkError(.operationDenied)):
                didFinish.fulfill()

            case .success:
                XCTFail("unexpected success")

            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }
        }

        // Then we got the expected failure.
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(mockActionHandler.performedActions.count, 1)
    }

    func test_CreateGroupConversation_UnreachableDomainsFailure() throws {
        // GIVEN
        let didFinish = customExpectation(description: "didFinish")
        let unreachableDomain = "foma.wire.link"
        user2.domain = unreachableDomain

        let groupConversation = createGroupConversation(
            with: user1,
            in: uiMOC
        )

        let mockActionHandler = MockActionHandler<CreateGroupConversationAction>(
            results: [.failure(.unreachableDomains([unreachableDomain])),
                      .success(groupConversation.objectID)],
            context: uiMOC.notificationContext
        )

        // WHEN
        sut.createGroupConversation(
            name: "Test",
            users: [user1, user2],
            allowGuests: true,
            allowServices: true,
            enableReceipts: true,
            messageProtocol: .proteus
        ) {
            defer { didFinish.fulfill() }

            switch $0 {
            case .success(let conversation):
                XCTAssertEqual(conversation, groupConversation)
                // Then a system message is added.
                guard let systemMessage = conversation.lastMessage?.systemMessageData else {
                    return XCTFail("expected system message")
                }

                XCTAssertEqual(systemMessage.systemMessageType, .failedToAddParticipants)

            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }
        }

        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))

        // Then we retried the action with only reachable users.
        XCTAssertEqual(mockActionHandler.performedActions.count, 2)

        if let lastAction = mockActionHandler.performedActions.last {
            XCTAssertEqual(lastAction.qualifiedUserIDs, [user1.qualifiedID])
        }
    }

    func test_CreateGroupConversation_NonFederatingDomainsFailure() throws {
        // GIVEN
        let didFinish = customExpectation(description: "didFinish")

        let mockActionHandler = MockActionHandler<CreateGroupConversationAction>(
            result: .failure(.nonFederatingDomains(["example.com"])),
            context: uiMOC.notificationContext
        )

        // WHEN
        sut.createGroupConversation(
            name: "New",
            users: [user1, user2],
            allowGuests: true,
            allowServices: true,
            enableReceipts: true,
            messageProtocol: .proteus
        ) {
            switch $0 {
            case .failure(.networkError(.nonFederatingDomains)):
                didFinish.fulfill()

            case .success:
                XCTFail("unexpected success")

            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }
        }

        // Then we got the expected failure.
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(mockActionHandler.performedActions.count, 1)
    }

    // MARK: - Sync conversation

    func test_SyncConversation() throws {
        // Given
        let qualifiedID = QualifiedID.randomID()
        let didSync = customExpectation(description: "didSync")

        // Mock
        _ = MockActionHandler<SyncConversationAction>(
            result: .success(()),
            context: uiMOC.notificationContext
        )

        // When
        sut.syncConversation(qualifiedID: qualifiedID) {
            didSync.fulfill()
        }

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

}
