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

final class OneOnOneResolverTests: XCTestCase {

    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var mockCoreDataStack: CoreDataStack!
    private var mockMLSService: MockMLSServiceInterface!
    private var mockMigrator: MockActorOneOnOneMigrator!
    private var mockProtocolSelector: MockActorOneOnOneProtocolSelector!

    private var syncContext: NSManagedObjectContext { mockCoreDataStack.syncContext }

    override func setUp() async throws {
        try await super.setUp()

        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()

        mockCoreDataStack = try await coreDataStackHelper.createStack()

        mockProtocolSelector = MockActorOneOnOneProtocolSelector()
        mockMLSService = MockMLSServiceInterface()
        mockMigrator = MockActorOneOnOneMigrator()
    }

    override func tearDown() async throws {
        mockProtocolSelector = nil
        mockCoreDataStack = nil
        mockMLSService = nil

        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil

        try await super.tearDown()
    }

    // MARK: - Tests

    func test_resolveAllOneOnOneConversations_givenZeroUsers() async throws {
        // Given
        let resolver = makeResolver()

        // When
        try await resolver.resolveAllOneOnOneConversations(in: syncContext)

        // Then
        let selectorInvocationsIsEmpty = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.isEmpty
        XCTAssertTrue(selectorInvocationsIsEmpty)
    }

    func test_resolveAllOneOnOneConversations_givenMultipleUsers_thenMigrateAll() async throws {
        // Given
        let resolver = makeResolver()

        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockMethod { _, _, _ in }
        mockMLSService.conversationExistsGroupID_MockValue = false

        // mockHandler must be retained to catch notifications
        let mockHandler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            results: [.success(.random()), .success(.random())],
            context: syncContext.notificationContext
        )

        await syncContext.perform { [self] in
            makeOneOnOneConversation(in: syncContext)
            makeOneOnOneConversation(in: syncContext)
        }

        // When
        try await resolver.resolveAllOneOnOneConversations(in: syncContext)

        // Then
        let selectorInvocationsCount = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.count
        XCTAssertEqual(selectorInvocationsCount, 2)
        XCTAssertEqual(mockHandler.performedActions.count, 2)
    }

    func test_resolveAllOneOnOneConversations_givenUserWithoutConnection_thenSkipOneMigration() async throws {
        // Given
        let resolver = makeResolver()

        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockMethod { _, _, _ in }
        mockMLSService.conversationExistsGroupID_MockValue = false

        // mockHandler must be retained to catch notifications
        let mockHandler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            results: [.success(.random())],
            context: syncContext.notificationContext
        )

        await syncContext.perform { [self] in
            modelHelper.createUser(
                domain: "local@domain.com",
                in: syncContext
            )

            makeOneOnOneConversation(in: syncContext)
        }

        // When
        try await resolver.resolveAllOneOnOneConversations(in: syncContext)

        // Then
        let selectorInvocationsCount = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.count
        XCTAssertEqual(selectorInvocationsCount, 1)

        let migratorInvocationsCount = await mockMigrator.migrateToMLSUserIDMlsGroupIDIn_Invocations.count
        XCTAssertEqual(migratorInvocationsCount, 1)

        XCTAssertEqual(mockHandler.performedActions.count, 1)
    }

    func test_resolveAllOneOnOneConversations_givenUserWithoutDomain_thenSkipOneMigration() async throws {
        // Given
        let resolver = makeResolver()

        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockMethod { _, _, _ in }
        mockMLSService.conversationExistsGroupID_MockValue = false

        // mockHandler must be retained to catch notifications
        let mockHandler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            results: [.success(.random())],
            context: syncContext.notificationContext
        )

        await syncContext.perform { [self] in
            makeOneOnOneConversation(domain: nil, in: syncContext)
            makeOneOnOneConversation(domain: "local@domain.com", in: syncContext)
        }

        // When
        try await resolver.resolveAllOneOnOneConversations(in: syncContext)

        // Then
        let selectorInvocationsCount = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.count
        XCTAssertEqual(selectorInvocationsCount, 1)

        let migratorInvocationsCount = await mockMigrator.migrateToMLSUserIDMlsGroupIDIn_Invocations.count
        XCTAssertEqual(migratorInvocationsCount, 1)

        XCTAssertEqual(mockHandler.performedActions.count, 1)
    }

    func test_resolveAllOneOnOneConversations_givenMigrationFailure() async throws {
        // Given
        let resolver = makeResolver()

        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDMlsGroupIDIn_MockError(MockOneOnOneResolverError.failed)
        mockMLSService.conversationExistsGroupID_MockValue = false

        // mockHandler must be retained to catch notifications
        let mockHandler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            results: [.success(.random()), .success(.random())],
            context: syncContext.notificationContext
        )

        await syncContext.perform { [self] in
            makeOneOnOneConversation(in: syncContext)
            makeOneOnOneConversation(in: syncContext)
        }

        // When
        try await resolver.resolveAllOneOnOneConversations(in: syncContext)

        // Then
        let selectorCount = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.count
        XCTAssertEqual(selectorCount, 2)

        let migratorCount = await mockMigrator.migrateToMLSUserIDMlsGroupIDIn_Invocations.count
        XCTAssertEqual(migratorCount, 2)

        XCTAssertEqual(mockHandler.performedActions.count, 2)
    }

    func test_resolveOneOnOneConversation_MLSSupported() async throws {
        // Given
        let userID: QualifiedID = .random()
        let resolver = makeResolver()

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockMethod { _, _, _ in }
        mockMLSService.conversationExistsGroupID_MockValue = false

        // mockHandler must be retained to catch notifications
        let mockHandler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            results: [.success(.random())],
            context: syncContext.notificationContext
        )

        await syncContext.perform { [self] in
            let conversation = makeOneOnOneConversation(qualifiedID: userID, in: syncContext)
            conversation.messageProtocol = .proteus
        }

        // When
        try await resolver.resolveOneOnOneConversation(with: userID, in: syncContext)

        // Then
        let invocations = await mockMigrator.migrateToMLSUserIDMlsGroupIDIn_Invocations
        XCTAssertEqual(invocations.count, 1)
        XCTAssertEqual(invocations.first?.userID, userID)

        XCTAssertEqual(mockHandler.performedActions.count, 1)
    }

    func test_ResolveOneOnOneConversation_MLSSupported_conversationExists() async throws {
        // Given
        let userID: QualifiedID = .random()
        let resolver = makeResolver()

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockMethod { _, _, _ in }
        mockMLSService.conversationExistsGroupID_MockValue = true

        // mockHandler must be retained to catch notifications
        let mockHandler = MockActionHandler<SyncMLSOneToOneConversationAction>(
            results: [.success(.random())],
            context: syncContext.notificationContext
        )

        await syncContext.perform { [self] in
            let conversation = makeOneOnOneConversation(qualifiedID: userID, in: syncContext)
            conversation.messageProtocol = .mls
        }

        // When
        try await resolver.resolveOneOnOneConversation(with: userID, in: syncContext)

        // Then
        let invocations = await mockMigrator.migrateToMLSUserIDMlsGroupIDIn_Invocations
        XCTAssert(invocations.isEmpty)

        XCTAssertEqual(mockHandler.performedActions.count, 1)
    }

    func test_ResolveOneOnOneConversation_ProteusSupported() async throws {
        // Given
        let userID: QualifiedID = .random()
        let resolver = makeResolver()

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.proteus)

        // When
        try await resolver.resolveOneOnOneConversation(with: userID, in: syncContext)

        // Then
        let invocations = await mockMigrator.migrateToMLSUserIDMlsGroupIDIn_Invocations
        XCTAssert(invocations.isEmpty)
    }

    func test_ResolveOneOnOneConversation_NoCommonProtocols_forSelfUser() async throws {
        // Given
        let userID: QualifiedID = .random()
        let resolver = makeResolver()

        let conversation = await syncContext.perform { [self] in
            let conversation = makeOneOnOneConversation(qualifiedID: userID, in: syncContext)

            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertFalse(conversation.isForcedReadOnly)

            return conversation
        }

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.some(nil))

        // When
        try await resolver.resolveOneOnOneConversation(with: userID, in: syncContext)

        // Then
        await syncContext.perform {
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertTrue(conversation.isForcedReadOnly)
            XCTAssertEqual(conversation.lastMessage?.systemMessageData?.systemMessageType, .mlsNotSupportedSelfUser)
        }
    }

    func test_ResolveOneOnOneConversation_NoCommonProtocols_forOtherUser() async throws {
        // Given
        let userID: QualifiedID = .random()
        let selfUserID: QualifiedID = .random()
        let resolver = makeResolver()

        let conversation = await syncContext.perform { [self] in
            let user = modelHelper.createUser(
                qualifiedID: userID,
                in: syncContext
            )
            user.supportedProtocols = [.proteus]

            let selfUser = modelHelper.createSelfUser(qualifiedID: selfUserID, in: syncContext)
            selfUser.supportedProtocols = [.mls]

            let (_, conversation) = modelHelper.createConnection(
                status: .accepted,
                to: user,
                in: syncContext
            )

            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertFalse(conversation.isForcedReadOnly)

            return conversation
        }

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.some(nil))

        // When
        try await resolver.resolveOneOnOneConversation(with: userID, in: syncContext)

        // Then
        await syncContext.perform {
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertTrue(conversation.isForcedReadOnly)
            XCTAssertEqual(conversation.lastMessage?.systemMessageData?.systemMessageType, .mlsNotSupportedOtherUser)
        }
    }

    // MARK: Helpers

    private func makeResolver() -> OneOnOneResolver {
        makeResolver(
            migrator: mockMigrator,
            mlsService: mockMLSService
        )
    }

    private func makeResolver(
        migrator: OneOnOneMigratorInterface?,
        mlsService: MLSServiceInterface?
    ) -> OneOnOneResolver {
        OneOnOneResolver(
            protocolSelector: mockProtocolSelector,
            migrator: migrator,
            mlsService: mlsService
        )
    }

    @discardableResult
    private func makeOneOnOneConversation(
        domain: String? = "local@domain.com",
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let user = modelHelper.createUser(
            domain: domain,
            in: context
        )
        let (_, conversation) = modelHelper.createConnection(status: .accepted, to: user, in: context)
        return conversation
    }

    @discardableResult
    private func makeOneOnOneConversation(
        qualifiedID: QualifiedID,
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let user = modelHelper.createUser(
            qualifiedID: qualifiedID,
            in: context
        )
        let (_, conversation) = modelHelper.createConnection(status: .accepted, to: user, in: context)
        return conversation
    }
}

// MARK: - Mock Error

private enum MockOneOnOneResolverError: Error {
    case failed
}
