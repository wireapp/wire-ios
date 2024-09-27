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

import WireTesting
import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport

final class OneOnOneMigratorTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()

        coreDataStack = try await coreDataStackHelper.createStack(at: coreDataStackHelper.storageDirectory)
        syncContext = coreDataStack.syncContext

        mockMLSService = MockMLSServiceInterface()
    }

    override func tearDown() async throws {
        try await super.tearDown()

        mockMLSService = nil

        syncContext = nil
        coreDataStack = nil

        try coreDataStackHelper.cleanupDirectory(coreDataStackHelper.storageDirectory)
    }

    // MARK: - Tests

    func test_migrateToMLS_givenConversationExistsAlready() async throws {
        // Given
        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID = QualifiedID.random()
        let mlsGroupID = MLSGroupID.random()

        let mlsConversation = await syncContext.perform { [self] in
            let user = ZMUser.insertNewObject(in: syncContext)
            user.remoteIdentifier = userID.uuid
            user.domain = userID.domain

            let mlsConversation = createMLSConversation(with: mlsGroupID, in: syncContext)
            mlsConversation.oneOnOneUser = user

            return mlsConversation
        }

        // Mock
        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: syncContext.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = true

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: syncContext
        )

        // Then
        XCTAssert(mockMLSService.establishGroupForWith_Invocations.isEmpty)
        XCTAssert(mockMLSService.joinGroupWith_Invocations.isEmpty)

        await syncContext.perform {
            XCTAssertEqual(mlsConversation.oneOnOneUser?.remoteIdentifier, userID.uuid)
        }
        withExtendedLifetime(handler) {}
    }

    func test_migrateToMLS_givenEpochIsZero() async throws {
        // Given
        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID = QualifiedID.random()
        let mlsGroupID = MLSGroupID.random()
        let ciphersuite = MLSCipherSuite.MLS_256_DHKEMP521_AES256GCM_SHA512_P521

        let (connection, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            mlsGroupEpoch: 0,
            in: syncContext
        )

        // Mock
        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: syncContext.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = false
        mockMLSService.establishGroupForWith_MockMethod = { _, _ in
            ciphersuite
        }

        // When
        await syncContext.perform {
            XCTAssertEqual(proteusConversation.oneOnOneUser?.remoteIdentifier, userID.uuid)
            XCTAssertNil(mlsConversation.oneOnOneUser)
        }

        try await sut.migrateToMLS(
            userID: userID,
            in: syncContext
        )

        // Then
        XCTAssertEqual(mockMLSService.establishGroupForWith_Invocations.count, 1)
        let createGroupInvocation = try XCTUnwrap(mockMLSService.establishGroupForWith_Invocations.first)
        XCTAssertEqual(createGroupInvocation.groupID, mlsGroupID)
        XCTAssertEqual(createGroupInvocation.users, [MLSUser(userID)])

        await syncContext.perform {
            XCTAssertEqual(mlsConversation.oneOnOneUser, connection.to)
            XCTAssertEqual(mlsConversation.ciphersuite, ciphersuite)
            XCTAssertEqual(mlsConversation.mlsStatus, .ready)
            XCTAssertNil(proteusConversation.oneOnOneUser)
        }
        withExtendedLifetime(handler) {}
    }

    func test_migrateToMLS_givenEpochIsNotZero() async throws {
        // Given
        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID = QualifiedID.random()
        let mlsGroupID = MLSGroupID.random()

        let (connection, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            mlsGroupEpoch: 1,
            in: syncContext
        )

        // Mock
        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: syncContext.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = false
        mockMLSService.joinGroupWith_MockMethod = { _ in }

        // When
        await syncContext.perform {
            XCTAssertEqual(proteusConversation.oneOnOneUser?.remoteIdentifier, userID.uuid)
            XCTAssertNil(mlsConversation.oneOnOneUser)
        }

        try await sut.migrateToMLS(
            userID: userID,
            in: syncContext
        )

        // Then
        XCTAssertEqual(mockMLSService.joinGroupWith_Invocations.count, 1)
        let invokedMLSGroupID = try XCTUnwrap(mockMLSService.joinGroupWith_Invocations.first)
        XCTAssertEqual(invokedMLSGroupID, mlsGroupID)

        await syncContext.perform {
            XCTAssertEqual(mlsConversation.oneOnOneUser, connection.to)
            XCTAssertNil(proteusConversation.oneOnOneUser)
        }
        withExtendedLifetime(handler) {}
    }

    func test_migrateToMLS_moveMessages() async throws {
        let sut = OneOnOneMigrator(mlsService: mockMLSService)
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

        mockMLSService.conversationExistsGroupID_MockValue = false
        mockMLSService.establishGroupForWith_MockMethod = { _, _ in
            .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519
        }

        // required to add be able to add images
        let cacheLocation = try XCTUnwrap(
            FileManager.default.randomCacheURL
        )

        await syncContext.perform {
            self.syncContext.zm_fileAssetCache = FileAssetCache(location: cacheLocation)
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
            in: syncContext
        )

        // Then
        await syncContext.perform {
            let mlsMessages = mlsConversation.allMessages.sortedAscendingPrependingNil(by: \.serverTimestamp)
            XCTAssertEqual(mlsMessages.count, 3)
            XCTAssertEqual(mlsMessages[0].textMessageData?.messageText, "Hello World!")
            XCTAssertTrue(mlsMessages[1].isKnock)
            XCTAssertTrue(mlsMessages[2].isImage)

            XCTAssertNil(proteusConversation.lastMessage)
        }
        withExtendedLifetime(handler) {}
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

    // MARK: Private

    private let coreDataStackHelper = CoreDataStackHelper()

    private var coreDataStack: CoreDataStack!
    private var syncContext: NSManagedObjectContext!

    private var mockMLSService: MockMLSServiceInterface!

    // MARK: - Core Data Objects

    private func createConversations(
        userID: QualifiedID,
        mlsGroupID: MLSGroupID,
        mlsGroupEpoch: UInt64? = nil,
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

            if let mlsGroupEpoch {
                mlsConversation.epoch = mlsGroupEpoch
            }

            return (
                connection,
                proteusConversation,
                mlsConversation
            )
        }
    }

    private func createMLSConversation(
        with identifier: MLSGroupID,
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let mlsConversation = ZMConversation.insertNewObject(in: context)
        mlsConversation.remoteIdentifier = .create()
        mlsConversation.domain = "local@domain.com"
        mlsConversation.mlsGroupID = identifier
        mlsConversation.messageProtocol = .mls
        mlsConversation.conversationType = .oneOnOne

        return mlsConversation
    }
}
