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

    private var mockMLSService: MockMLSServiceInterface!

    private var coreDataStack: CoreDataStack!
    private var syncContext: NSManagedObjectContext!

    override func setUp() async throws {
        try await super.setUp()

        mockMLSService = MockMLSServiceInterface()

        coreDataStack = try await coreDataStackHelper.createStack(at: coreDataStackHelper.storageDirectory)
        syncContext = coreDataStack.syncContext

        await syncContext.perform { [self] in
            syncContext.mlsService = mockMLSService
        }
    }

    override func tearDown() async throws {
        try await super.tearDown()

        syncContext = nil
        coreDataStack = nil

        mockMLSService = nil

        try coreDataStackHelper.cleanupDirectory(coreDataStackHelper.storageDirectory)
    }

    // MARK: - Tests

    func test_migrateToMLS() async throws {
        // Given
        let sut = OneOnOneMigrator(mlsService: mockMLSService, context: syncContext)
        let userID = QualifiedID.random()
        let mlsGroupID = MLSGroupID.random()

        let (connection, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: syncContext
        )

        // Mock
        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: syncContext.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = false
        mockMLSService.establishGroupForWith_MockMethod = { _, _ in }

        // When
        await syncContext.perform {
            XCTAssertEqual(proteusConversation.oneOnOneUser?.remoteIdentifier, userID.uuid)
            XCTAssertNil(mlsConversation.oneOnOneUser)
        }

        try await sut.migrateToMLS(
            userID: userID,
            mlsGroupID: mlsGroupID
        )

        // Then
        XCTAssertEqual(mockMLSService.establishGroupForWith_Invocations.count, 1)
        let createGroupInvocation = try XCTUnwrap(mockMLSService.establishGroupForWith_Invocations.first)
        XCTAssertEqual(createGroupInvocation.groupID, mlsGroupID)
        XCTAssertEqual(createGroupInvocation.users, [MLSUser(userID)])

        await syncContext.perform {
            XCTAssertEqual(mlsConversation.oneOnOneUser, connection.to)
            XCTAssertNil(proteusConversation.oneOnOneUser)
        }
        withExtendedLifetime(handler) {}
    }

    // TODO: move test to resolver

//    func test_migrateToMLS_conversationAlreadyExists() async throws {
//        // Given
//        let sut = OneOnOneMigrator(mlsService: mockMLSService, context: syncContext)
//        let userID = QualifiedID.random()
//        let mlsGroupID = MLSGroupID.random()
//
//        let (connection, proteusConversation, mlsConversation) = await createConversations(
//            userID: userID,
//            mlsGroupID: mlsGroupID,
//            in: syncContext
//        )
//
//        // Mock
//        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
//            result: .success(mlsGroupID),
//            context: syncContext.notificationContext
//        )
//        mockMLSService.conversationExistsGroupID_MockValue = true
//
//        // When
//        await syncContext.perform {
//            XCTAssertEqual(proteusConversation.oneOnOneUser?.remoteIdentifier, userID.uuid)
//            XCTAssertNil(mlsConversation.oneOnOneUser)
//        }
//
//        try await sut.migrateToMLS(
//            userID: userID,
//            mlsGroupID: mlsGroupID
//        )
//
//        // Then
//        XCTAssertTrue(mockMLSService.establishGroupForWith_Invocations.isEmpty)
//        XCTAssertTrue(mockMLSService.addMembersToConversationWithFor_Invocations.isEmpty)
//
//        await syncContext.perform {
//            XCTAssertEqual(mlsConversation.oneOnOneUser, connection.to)
//            XCTAssertNil(proteusConversation.oneOnOneUser)
//        }
//        withExtendedLifetime(handler) {}
//    }

    func test_migrateToMLS_moveMessages() async throws {
        let sut = OneOnOneMigrator(mlsService: mockMLSService, context: syncContext)
        let userID: QualifiedID = .random()
        let mlsGroupID: MLSGroupID = .random()

        let (_, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: syncContext
        )

        // Mock
        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: syncContext.notificationContext
        )

        mockMLSService.establishGroupForWith_MockMethod = { _, _ in }

        // required to add be able to add images
        await syncContext.perform {
            self.syncContext.zm_fileAssetCache = .init()
        }

        // When
        try await syncContext.perform {
            var message = try proteusConversation.appendText(content: "Hello World!")
            message.updateServerTimestamp(with: 0)

            message = try proteusConversation.appendKnock()
            message.updateServerTimestamp(with: 1)

            message = try proteusConversation.appendImage(from: ZMTBaseTest.verySmallJPEGData())
            message.updateServerTimestamp(with: 2)

            XCTAssertEqual(proteusConversation.allMessages.count, 3)
            XCTAssertNil(mlsConversation.lastMessage)
        }

        try await sut.migrateToMLS(
            userID: userID,
            mlsGroupID: mlsGroupID
        )

        // Then
        await syncContext.perform {
            let mlsMessages = mlsConversation.allMessages.sorted { $0.serverTimestamp < $1.serverTimestamp }
            XCTAssertEqual(mlsMessages.count, 3)
            XCTAssertEqual(mlsMessages[0].textMessageData?.messageText, "Hello World!")
            XCTAssertTrue(mlsMessages[1].isKnock)
            XCTAssertTrue(mlsMessages[2].isImage)

            XCTAssertNil(proteusConversation.lastMessage)
        }
        withExtendedLifetime(handler) {}
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
