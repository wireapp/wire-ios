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

    func test_migrateToMLS() async throws {
        // Given
        let mockMLSService = MockMLSServiceInterface()
        mockMLSService.createGroupForWith_MockMethod = { _, _ in }

        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID = QualifiedID.random()
        let mlsGroupID = MLSGroupID.random()

        let (connection, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: uiMOC
        )

        // Mock
        _ = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: uiMOC.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = false

        // When
        await uiMOC.perform {
            XCTAssertEqual(proteusConversation.oneOnOneUser?.remoteIdentifier, userID.uuid)
            XCTAssertNil(mlsConversation.oneOnOneUser)
        }

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
            XCTAssertEqual(mlsConversation.oneOnOneUser, connection.to)
            XCTAssertNil(proteusConversation.oneOnOneUser)
        }
    }

    func test_migrateToMLS_conversationAlreadyExists() async throws {
        // Given
        let mockMLSService = MockMLSServiceInterface()
        mockMLSService.conversationExistsGroupID_MockValue = true

        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID = QualifiedID.random()
        let mlsGroupID = MLSGroupID.random()

        let (connection, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: uiMOC
        )

        // Mock
        _ = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: uiMOC.notificationContext
        )

        // When
        await uiMOC.perform {
            XCTAssertEqual(proteusConversation.oneOnOneUser?.remoteIdentifier, userID.uuid)
            XCTAssertNil(mlsConversation.oneOnOneUser)
        }

        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        XCTAssertTrue(mockMLSService.createGroupForWith_Invocations.isEmpty)
        XCTAssertTrue(mockMLSService.addMembersToConversationWithFor_Invocations.isEmpty)

        await uiMOC.perform {
            XCTAssertEqual(mlsConversation.oneOnOneUser, connection.to)
            XCTAssertNil(proteusConversation.oneOnOneUser)
        }
    }

    func test_migrateToMLS_moveMessages() async throws {
        // Given
        let mockMLSService = MockMLSServiceInterface()
        mockMLSService.conversationExistsGroupID_MockValue = true

        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID: QualifiedID = .random()
        let mlsGroupID: MLSGroupID = .random()

        let (_, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: uiMOC
        )

        // Mock
        _ = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: uiMOC.notificationContext
        )

        // required to add be able to add images
        await uiMOC.perform {
            self.uiMOC.zm_fileAssetCache = .init()
        }

        // When
        try await uiMOC.perform {
            try proteusConversation.appendText(content: "Hello World!")
            try proteusConversation.appendKnock()
            try proteusConversation.appendImage(from: ZMTBaseTest.verySmallJPEGData())

            XCTAssertEqual(proteusConversation.allMessages.count, 3)
            XCTAssertNil(mlsConversation.lastMessage)
        }

        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        await uiMOC.perform {
            let mlsMessages = mlsConversation.allMessages.sorted { $0.serverTimestamp < $1.serverTimestamp }
            XCTAssertEqual(mlsMessages.count, 3)
            XCTAssertEqual(mlsMessages[0].textMessageData?.messageText, "Hello World!")
            XCTAssertTrue(mlsMessages[1].isKnock)
            XCTAssertTrue(mlsMessages[2].isImage)

            XCTAssertNil(proteusConversation.lastMessage)
        }
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
        conversation.oneOnOneUser = connection.to

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
