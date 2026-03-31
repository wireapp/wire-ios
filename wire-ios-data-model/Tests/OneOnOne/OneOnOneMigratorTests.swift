//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

    private let coreDataStackHelper = CoreDataStackHelper()

    private var coreDataStack: CoreDataStack!
    private var syncContext: NSManagedObjectContext!
    private let localDomain = "local.domain"
    private var mockMLSService: MockMLSServiceInterface!

    override func setUp() async throws {
        try await super.setUp()

        coreDataStack = try await coreDataStackHelper.createStack(at: coreDataStackHelper.storageDirectory)
        syncContext = coreDataStack.syncContext

        mockMLSService = MockMLSServiceInterface()
        mockMLSService.underlyingLocalDomain = localDomain
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
        var conversationID: QualifiedID?

        let mlsConversation = await syncContext.perform { [self] in
            let user = ZMUser.insertNewObject(in: syncContext)
            user.remoteIdentifier = userID.uuid
            user.domain = userID.domain

            let mlsConversation = createMLSConversation(with: mlsGroupID, in: syncContext)
            mlsConversation.oneOnOneUser = user
            mlsConversation.domain = localDomain
            conversationID = mlsConversation.qualifiedID

            return mlsConversation
        }

        // Mock
        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success((try XCTUnwrap(conversationID), mlsGroupID, nil)),
            context: syncContext.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = true

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: syncContext
        )

        // Then
        XCTAssert(mockMLSService.establishGroupForWithRemovalKeys_Invocations.isEmpty)
        XCTAssert(mockMLSService.joinGroupWith_Invocations.isEmpty)

        await syncContext.perform {
            XCTAssertEqual(mlsConversation.oneOnOneUser?.remoteIdentifier, userID.uuid)
            XCTAssertEqual(mlsConversation.allMessages.count, 0, "no system message should be inserted")
        }
        withExtendedLifetime(handler) {}
    }

    func test_migrateToMLS_givenEpochIsZero() async throws {
        // Given
        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID = QualifiedID.random()
        let mlsGroupID = MLSGroupID.random()
        let removalKeys = BackendMLSPublicKeys(removal: .init(ed25519: .init([1, 2, 3])))
        let ciphersuite = MLSCipherSuite.MLS_256_DHKEMP521_AES256GCM_SHA512_P521

        let (connection, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            mlsGroupEpoch: 0,
            in: syncContext
        )
        let id = await syncContext.perform {
            mlsConversation.qualifiedID
        }
        let mlsConversationID = try XCTUnwrap(id)

        // Mock
        mockMLSService.underlyingLocalDomain = mlsConversationID.domain
        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success((mlsConversationID, mlsGroupID, removalKeys)),
            context: syncContext.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = false
        mockMLSService.establishGroupForWithRemovalKeys_MockMethod = { _, _, _ in
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
        XCTAssertEqual(mockMLSService.establishGroupForWithRemovalKeys_Invocations.count, 1)
        let createGroupInvocation = try XCTUnwrap(mockMLSService.establishGroupForWithRemovalKeys_Invocations.first)
        XCTAssertEqual(createGroupInvocation.groupID, mlsGroupID)
        XCTAssertEqual(createGroupInvocation.users, [MLSUser(userID)])
        XCTAssertEqual(createGroupInvocation.removalKeys, removalKeys)

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
        let id = await syncContext.perform {
            mlsConversation.qualifiedID
        }
        let mlsConversationID = try XCTUnwrap(id)

        // Mock
        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success((mlsConversationID, mlsGroupID, nil)),
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
        let id = await syncContext.perform {
            mlsConversation.qualifiedID
        }
        let mlsConversationID = try XCTUnwrap(id)

        // Mock
        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success((mlsConversationID, mlsGroupID, nil)),
            context: syncContext.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = false
        mockMLSService.establishGroupForWithRemovalKeys_MockMethod = { _, _, _ in
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

            message = try proteusConversation.appendImage(
                SendableImage(name: "picture.jpg", utType: .jpeg, data: ZMTBaseTest.verySmallJPEGData()),
                nonce: UUID()
            )
            message.updateServerTimestamp(with: 2)

            XCTAssertEqual(proteusConversation.allMessages.count, 3)
            XCTAssertNil(mlsConversation.lastMessage)
        }

        try await sut.migrateToMLS(
            userID: userID,
            in: syncContext
        )

        // Then
        try await syncContext.perform {
            let mlsMessages = mlsConversation.allMessages.sortedAscendingPrependingNil(by: \.serverTimestamp)
            XCTAssertEqual(mlsMessages.count, 4)
            XCTAssertEqual(mlsMessages[0].textMessageData?.messageText, "Hello World!")
            XCTAssertTrue(mlsMessages[1].isKnock)
            XCTAssertTrue(mlsMessages[2].isImage)

            let systemMessage = try XCTUnwrap(mlsMessages[3] as? ZMSystemMessage)
            XCTAssertEqual(systemMessage.systemMessageType, .mlsMigrationFinalized)

            self.assertDates(for: mlsConversation, from: proteusConversation)

            XCTAssertNil(proteusConversation.lastMessage)
        }
        withExtendedLifetime(handler) {}
    }

    func test_migrateToMLS_moveMessagesFromDuplicateProteusConversations() async throws {
        let modelHelper = ModelHelper()
        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID = QualifiedID(uuid: .create(), domain: "local@domain.com")
        let selfUserID = QualifiedID(uuid: .create(), domain: "local@domain.com")
        let mlsGroupID: MLSGroupID = .random()

        let selfUser = await syncContext.perform {
            modelHelper.createSelfUser(id: selfUserID.uuid, domain: selfUserID.domain, in: self.syncContext)
        }

        let (_, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: syncContext
        )
        let id = await syncContext.perform {
            mlsConversation.qualifiedID
        }
        let mlsConversationID = try XCTUnwrap(id)

        let duplicateProteusConversation = try await syncContext.perform {
            let otherUser = try XCTUnwrap(ZMUser.fetch(with: userID.uuid, domain: userID.domain, in: self.syncContext))
            let team = modelHelper.createTeam(in: self.syncContext)
            modelHelper.addUsers([selfUser, otherUser], to: team, in: self.syncContext)

            proteusConversation.addParticipantAndUpdateConversationState(user: selfUser)
            proteusConversation.addParticipantAndUpdateConversationState(user: otherUser)
            return self.createFakeProteusConversation(
                with: UUID(),
                selfUser: selfUser,
                otherUser: otherUser,
                in: self.syncContext
            )
        }

        // Mock
        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success((mlsConversationID, mlsGroupID, nil)),
            context: syncContext.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = false
        mockMLSService.establishGroupForWithRemovalKeys_MockMethod = { _, _, _ in
            .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519
        }

        // required to add be able to add images
        let cacheLocation = try XCTUnwrap(
            FileManager.default.randomCacheURL
        )

        await syncContext.perform {
            self.syncContext.zm_fileAssetCache = FileAssetCache(location: cacheLocation)
        }

        // True Proteus OneOnOne conversation
        try await syncContext.perform {
            var message = try proteusConversation.appendText(content: "Hello World!")
            message.updateServerTimestamp(with: 0)

            message = try proteusConversation.appendKnock()
            message.updateServerTimestamp(with: 1)

            message = try proteusConversation.appendImage(
                SendableImage(name: "picture.jpg", utType: .jpeg, data: ZMTBaseTest.verySmallJPEGData()),
                nonce: UUID()
            )
            message.updateServerTimestamp(with: 2)

            XCTAssertEqual(proteusConversation.allMessages.count, 3)
            XCTAssertNil(mlsConversation.lastMessage)
        }

        // duplicate Proteus OneOnOne conversation
        try await syncContext.perform {
            var message = try duplicateProteusConversation.appendText(content: "Hello World Dup!")
            message.updateServerTimestamp(with: 10)

            message = try duplicateProteusConversation.appendKnock()
            message.updateServerTimestamp(with: 11)

            message = try duplicateProteusConversation.appendImage(
                SendableImage(name: "picture.jpg", utType: .jpeg, data: ZMTBaseTest.verySmallJPEGData()),
                nonce: UUID()
            )
            message.updateServerTimestamp(with: 12)

            XCTAssertEqual(proteusConversation.allMessages.count, 3)
            XCTAssertNil(mlsConversation.lastMessage)

            // this save is needed, in order for the fetch request to get the correct duplicate OneOnOne conv.
            try self.syncContext.save()
        }

        // When

        try await sut.migrateToMLS(
            userID: userID,
            in: syncContext
        )

        // Then
        await syncContext.perform {
            self.assertDates(for: mlsConversation, from: proteusConversation)

            let mlsMessages = mlsConversation.allMessages.sortedAscendingPrependingNil(by: \.serverTimestamp)
            let expectedMessagesCount = 7
            if mlsMessages.count == expectedMessagesCount {
                XCTAssertEqual(mlsMessages[0].textMessageData?.messageText, "Hello World!")
                XCTAssertTrue(mlsMessages[1].isKnock)
                XCTAssertTrue(mlsMessages[2].isImage)
                XCTAssertEqual(mlsMessages[3].textMessageData?.messageText, "Hello World Dup!")
                XCTAssertTrue(mlsMessages[4].isKnock)
                XCTAssertTrue(mlsMessages[5].isImage)
                XCTAssertTrue(mlsMessages[6].isSystem)
            } else {
                XCTFail("messages count is \(mlsMessages.count) instead of \(expectedMessagesCount)")
            }
            XCTAssertNil(proteusConversation.lastMessage)
        }
        withExtendedLifetime(handler) {}
    }

    func test_migrateToMLS_moveMessagesFromMultipleDuplicateProteusConversations() async throws {
        let modelHelper = ModelHelper()
        let sut = OneOnOneMigrator(mlsService: mockMLSService)
        let userID = QualifiedID(uuid: .create(), domain: "local@domain.com")
        let selfUserID = QualifiedID(uuid: .create(), domain: "local@domain.com")
        let mlsGroupID: MLSGroupID = .random()

        let selfUser = await syncContext.perform {
            modelHelper.createSelfUser(id: selfUserID.uuid, domain: selfUserID.domain, in: self.syncContext)
        }

        let team = await syncContext.perform {
            modelHelper.createTeam(in: self.syncContext)
        }

        let (_, proteusConversation, mlsConversation) = await createConversations(
            userID: userID,
            mlsGroupID: mlsGroupID,
            in: syncContext
        )

        let id = await syncContext.perform {
            mlsConversation.qualifiedID
        }
        let mlsConversationID = try XCTUnwrap(id)

        let duplicateProteusConversation = try await syncContext.perform {
            let otherUser = try XCTUnwrap(ZMUser.fetch(with: userID.uuid, domain: userID.domain, in: self.syncContext))
            modelHelper.addUsers([selfUser, otherUser], to: team, in: self.syncContext)

            proteusConversation.addParticipantAndUpdateConversationState(user: selfUser)
            proteusConversation.addParticipantAndUpdateConversationState(user: otherUser)
            return self.createFakeProteusConversation(
                with: UUID(),
                selfUser: selfUser,
                otherUser: otherUser,
                in: self.syncContext
            )
        }

        let duplicateProteusConversation2 = try await syncContext.perform {
            let otherUser = try XCTUnwrap(ZMUser.fetch(with: userID.uuid, domain: userID.domain, in: self.syncContext))
            modelHelper.addUsers([selfUser, otherUser], to: team, in: self.syncContext)

            proteusConversation.addParticipantAndUpdateConversationState(user: selfUser)
            proteusConversation.addParticipantAndUpdateConversationState(user: otherUser)
            return self.createFakeProteusConversation(
                with: UUID(),
                selfUser: selfUser,
                otherUser: otherUser,
                in: self.syncContext
            )
        }

        // Mock
        let handler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success((mlsConversationID, mlsGroupID, nil)),
            context: syncContext.notificationContext
        )

        mockMLSService.conversationExistsGroupID_MockValue = false
        mockMLSService.establishGroupForWithRemovalKeys_MockMethod = { _, _, _ in
            .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519
        }

        // required to add be able to add images
        let cacheLocation = try XCTUnwrap(
            FileManager.default.randomCacheURL
        )

        await syncContext.perform {
            self.syncContext.zm_fileAssetCache = FileAssetCache(location: cacheLocation)
        }

        // True Proteus OneOnOne conversation
        try await syncContext.perform {
            var message = try proteusConversation.appendText(content: "Hello World!")
            message.updateServerTimestamp(with: 0)

            message = try proteusConversation.appendKnock()
            message.updateServerTimestamp(with: 1)

            message = try proteusConversation.appendImage(
                SendableImage(name: "picture.jpg", utType: .jpeg, data: ZMTBaseTest.verySmallJPEGData()),
                nonce: UUID()
            )
            message.updateServerTimestamp(with: 2)

            XCTAssertEqual(proteusConversation.allMessages.count, 3)
            XCTAssertNil(mlsConversation.lastMessage)
        }

        // duplicate Proteus OneOnOne conversation
        try await syncContext.perform {
            var message = try duplicateProteusConversation.appendText(content: "Hello World Dup!")
            message.updateServerTimestamp(with: 10)

            message = try duplicateProteusConversation.appendKnock()
            message.updateServerTimestamp(with: 11)

            message = try duplicateProteusConversation.appendImage(
                SendableImage(name: "picture.jpg", utType: .jpeg, data: ZMTBaseTest.verySmallJPEGData()),
                nonce: UUID()
            )
            message.updateServerTimestamp(with: 12)

            XCTAssertEqual(proteusConversation.allMessages.count, 3)
            XCTAssertNil(mlsConversation.lastMessage)

            // this save is needed, in order for the fetch request to get the correct duplicate OneOnOne conv.
            try self.syncContext.save()
        }

        // duplicate Proteus OneOnOne conversation
        try await syncContext.perform {
            var message = try duplicateProteusConversation2.appendText(content: "Hello World 1!")
            message.updateServerTimestamp(with: 100)

            message = try duplicateProteusConversation2.appendText(content: "Hello World 2!")
            message.updateServerTimestamp(with: 110)

            message = try duplicateProteusConversation2.appendText(content: "Hello World 3!")
            message.updateServerTimestamp(with: 120)

            XCTAssertEqual(proteusConversation.allMessages.count, 3)
            XCTAssertNil(mlsConversation.lastMessage)

            // this save is needed, in order for the fetch request to get the correct duplicate OneOnOne conv.
            try self.syncContext.save()
        }

        // When

        try await sut.migrateToMLS(
            userID: userID,
            in: syncContext
        )

        // Then
        await syncContext.perform {
            self.assertDates(for: mlsConversation, from: proteusConversation)

            let mlsMessages = mlsConversation.allMessages.sortedAscendingPrependingNil(by: \.serverTimestamp)
            let expectedMessagesCount = 10
            if mlsMessages.count == expectedMessagesCount {
                XCTAssertEqual(mlsMessages[0].textMessageData?.messageText, "Hello World!")
                XCTAssertTrue(mlsMessages[1].isKnock)
                XCTAssertTrue(mlsMessages[2].isImage)
                XCTAssertEqual(mlsMessages[3].textMessageData?.messageText, "Hello World Dup!")
                XCTAssertTrue(mlsMessages[4].isKnock)
                XCTAssertTrue(mlsMessages[5].isImage)
                XCTAssertEqual(mlsMessages[6].textMessageData?.messageText, "Hello World 1!")
                XCTAssertEqual(mlsMessages[7].textMessageData?.messageText, "Hello World 2!")
                XCTAssertEqual(mlsMessages[8].textMessageData?.messageText, "Hello World 3!")
                XCTAssertTrue(mlsMessages[9].isSystem)
            } else {
                XCTFail("messages count is \(mlsMessages.count) instead of \(expectedMessagesCount)")
            }
            XCTAssertNil(proteusConversation.lastMessage)
        }
        withExtendedLifetime(handler) {}
    }

    private func assertDates(for mlsConversation: ZMConversation, from proteusConversation: ZMConversation) {
        XCTAssertEqual(mlsConversation.lastServerTimeStamp, proteusConversation.lastServerTimeStamp)
        XCTAssertEqual(mlsConversation.lastReadServerTimeStamp, proteusConversation.lastReadServerTimeStamp)
        XCTAssertEqual(
            mlsConversation.pendingLastReadServerTimestamp,
            proteusConversation.pendingLastReadServerTimestamp
        )
        XCTAssertEqual(
            mlsConversation.previousLastReadServerTimestamp,
            proteusConversation.previousLastReadServerTimestamp
        )
        XCTAssertEqual(mlsConversation.clearedTimeStamp, proteusConversation.clearedTimeStamp)
        XCTAssertEqual(mlsConversation.archivedChangedTimestamp, proteusConversation.archivedChangedTimestamp)
        XCTAssertEqual(mlsConversation.silencedChangedTimestamp, proteusConversation.silencedChangedTimestamp)
    }

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

            let (connection, proteusConversation) = createProteusConnection(
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

    func createProteusConnection(
        status: ZMConnectionStatus,
        to user: ZMUser,
        in context: NSManagedObjectContext
    ) -> (ZMConnection, ZMConversation) {
        let connection = ZMConnection.insertNewObject(in: context)
        connection.to = user
        connection.message = "Connect to me"
        connection.lastUpdateDate = .now

        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.conversationType = .connection
        conversation.remoteIdentifier = .create()
        conversation.domain = localDomain
        conversation.oneOnOneUser = connection.to

        let selfUser = ZMUser.selfUser(in: context)
        ParticipantRole.create(managedObjectContext: context, user: selfUser, conversation: conversation)
        ParticipantRole.create(managedObjectContext: context, user: user, conversation: conversation)

        // Setting `status` late as it also updates `conversation.conversationType` to be correct.
        connection.status = status

        return (connection, conversation)
    }

    func createFakeProteusConversation(
        with id: UUID,
        selfUser: ZMUser,
        otherUser: ZMUser,
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let oneOnOneConversation = ModelHelper().createGroupConversation(
            id: id,
            with: Set([otherUser, selfUser]),
            team: selfUser.team,
            domain: selfUser.domain,
            in: context
        )
        oneOnOneConversation.messageProtocol = .proteus
        oneOnOneConversation.userDefinedName = nil
        return oneOnOneConversation
    }

    private func createMLSConversation(
        with identifier: MLSGroupID,
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let mlsConversation = ZMConversation.insertNewObject(in: context)
        mlsConversation.remoteIdentifier = .create()
        mlsConversation.domain = localDomain
        mlsConversation.mlsGroupID = identifier
        mlsConversation.messageProtocol = .mls
        mlsConversation.conversationType = .oneOnOne

        return mlsConversation
    }
}
