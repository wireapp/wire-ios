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
@testable import WireDataModel
@testable import WireDataModelSupport

final class OneOnOneMigratorTests: XCTestCase {

    private let coreDataStackHelper = CoreDataStackHelper()

    var coreDataStack: CoreDataStack!
    var uiMOC: NSManagedObjectContext!

    override func setUp() async throws {
        try await super.setUp()

        coreDataStack = try await coreDataStackHelper.createStack(at: coreDataStackHelper.storageDirectory)
        uiMOC = coreDataStack.viewContext
    }

    override func tearDown() async throws {
        try await super.tearDown()

        uiMOC = nil
        coreDataStack = nil

        try coreDataStackHelper.cleanupDirectory(coreDataStackHelper.storageDirectory)
    }

    // MARK: - Tests

    func test_MigrateToMLS() async throws {
        // Given
        let mockMLSService = makeMockMLSService()
        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID = QualifiedID.random()
        let mlsGroupID = MLSGroupID.random()

        let (connection, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: uiMOC
        )

        await uiMOC.perform {
            XCTAssertEqual(connection.conversation, proteusConversation)
            XCTAssertNil(mlsConversation.connection)
        }

        // Mock
        _ = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: uiMOC.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = false

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(mockMLSService.createGroupForWith_Invocations.count, 1)
        let createGroupInvocation = try XCTUnwrap(mockMLSService.createGroupForWith_Invocations.first)
        XCTAssertEqual(createGroupInvocation.groupID, mlsGroupID)
        XCTAssertEqual(createGroupInvocation.users, [MLSUser(userID)])

        await uiMOC.perform {
            XCTAssertEqual(connection.conversation, mlsConversation)
            XCTAssertNil(proteusConversation.connection)
        }
    }

    func test_MigrateToMLS_ConversationAlreadyExists() async throws {
        // Given
        let mockMLSService = makeMockMLSService()
        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID = QualifiedID.random()
        let mlsGroupID = MLSGroupID.random()

        let (connection, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: uiMOC
        )

        await uiMOC.perform {
            XCTAssertEqual(connection.conversation, proteusConversation)
            XCTAssertNil(mlsConversation.connection)
        }

        // Mock
        _ = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: uiMOC.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = true

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        XCTAssertTrue(mockMLSService.createGroupForWith_Invocations.isEmpty)
        XCTAssertTrue(mockMLSService.addMembersToConversationWithFor_Invocations.isEmpty)

        await uiMOC.perform {
            XCTAssertEqual(connection.conversation, mlsConversation)
            XCTAssertNil(proteusConversation.connection)
        }
    }

    func test_MigrateToMLS_MoveMessages() async throws {
        // Given
        let mockMLSService = makeMockMLSService()
        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID: QualifiedID = .random()
        let mlsGroupID: MLSGroupID = .random()

        let (_, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: uiMOC
        )

        let mockMessage = "Hello World!"
        try await uiMOC.perform {
            _ = try proteusConversation.appendText(content: mockMessage)

            let lastProteusMessage = proteusConversation.lastMessage?.textMessageData?.messageText
            XCTAssertEqual(lastProteusMessage, mockMessage)

            XCTAssertNil(mlsConversation.lastMessage)
        }

        // Mock
        _ = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: uiMOC.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = true

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        await uiMOC.perform {
            let lastMLSMessage = mlsConversation.lastMessage?.textMessageData?.messageText
            XCTAssertEqual(lastMLSMessage, mockMessage)

            XCTAssertNil(proteusConversation.lastMessage)
        }
    }

    // MARK: - Mocks

    private func makeMockMLSService() -> MockMLSServiceInterface {
        let mlsService = MockMLSServiceInterface()
        mlsService.createGroupForWith_MockMethod = { _, _ in }
        mlsService.addMembersToConversationWithFor_MockMethod = { _, _ in}

        return mlsService
    }

    // MARK: - Core Data Objects

    private func createConversations(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID,
        in context: NSManagedObjectContext
    ) async -> (
        connection: ZMConnection,
        proteusConversation: ZMConversation,
        mlsConversation: ZMConversation
    ) {
        await context.perform { [self] in
            let user = ZMUser.insertNewObject(in: context)
            user.remoteIdentifier = userID.uuid
            user.domain = userID.domain

            let (connection, proteusConversation) = createProtheusConnection(
                status: .accepted,
                to: user,
                in: context
            )

            let mlsConversation = createMLSConversation(with: mlsGroupID, in: context)

            return (
                connection,
                proteusConversation,
                mlsConversation
            )
        }
    }

    func createProtheusConnection(
        status: ZMConnectionStatus,
        to user: ZMUser,
        in context: NSManagedObjectContext
    ) -> (ZMConnection, ZMConversation) {
        let connection = ZMConnection.insertNewObject(in: context)
        connection.to = user
        connection.status = status
        connection.message = "Connect to me"
        connection.lastUpdateDate = .now

        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.conversationType = .connection
        conversation.remoteIdentifier = .create()
        conversation.domain = "local@domain.com"
        conversation.connection = connection

        return (connection, conversation)
    }

    private func createMLSConversation(with identifier: MLSGroupID, in context: NSManagedObjectContext) -> ZMConversation {
        let mlsConversation = ZMConversation.insertNewObject(in: context)
        mlsConversation.remoteIdentifier = .create()
        mlsConversation.domain = "local@domain.com"
        mlsConversation.mlsGroupID = identifier
        mlsConversation.messageProtocol = .mls
        mlsConversation.conversationType = .oneOnOne

        return mlsConversation
    }
}
