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

final class OneOnOneMigratorTests: ZMBaseManagedObjectTest {

    var sut: OneOnOneMigrator!
    var mlsService: MockMLSServiceInterface!

    override func setUp() {
        super.setUp()
        mlsService = MockMLSServiceInterface()
        mlsService.createGroupForWith_MockMethod = { _, _ in }
        mlsService.addMembersToConversationWithFor_MockMethod = { _, _ in}

        sut = OneOnOneMigrator(mlsService: mlsService)
    }

    override func tearDown() {
        sut = nil
        mlsService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_MigrateToMLS() async throws {
        // Given
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

        mlsService.conversationExistsGroupID_MockValue = false

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(mlsService.createGroupForWith_Invocations.count, 1)
        let createGroupInvocation = try XCTUnwrap(mlsService.createGroupForWith_Invocations.first)
        XCTAssertEqual(createGroupInvocation.groupID, mlsGroupID)
        XCTAssertEqual(createGroupInvocation.users, [MLSUser(userID)])

        await uiMOC.perform {
            XCTAssertEqual(connection.conversation, mlsConversation)
            XCTAssertNil(proteusConversation.connection)
        }
    }

    func test_MigrateToMLS_ConversationAlreadyExists() async throws {
        // Given
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

        mlsService.conversationExistsGroupID_MockValue = true

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        XCTAssertTrue(mlsService.createGroupForWith_Invocations.isEmpty)
        XCTAssertTrue(mlsService.addMembersToConversationWithFor_Invocations.isEmpty)

        await uiMOC.perform {
            XCTAssertEqual(connection.conversation, mlsConversation)
            XCTAssertNil(proteusConversation.connection)
        }
    }

    func test_MigrateToMLS_CopyMessages() async throws {
        // Given
        let userID: QualifiedID = .random()
        let mlsGroupID: MLSGroupID = .random()

        let (connection, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: uiMOC
        )

        try await uiMOC.perform {
            _ = try proteusConversation.appendText(content: "Hello World!")
        }

        // Mock
        _ = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: uiMOC.notificationContext
        )

        mlsService.conversationExistsGroupID_MockValue = true

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        await uiMOC.perform {
            let lastMLSMessage = mlsConversation.lastMessage?.textMessageData?.messageText
            XCTAssertEqual(lastMLSMessage, "Hello World!")
        }
    }

    // MARK: Helpers

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
            let user = createUser(id: userID, in: context)

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
