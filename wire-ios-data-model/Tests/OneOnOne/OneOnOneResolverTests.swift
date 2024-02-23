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

    private var sut: OneOnOneResolver!

    private var mockCoreDataStack: CoreDataStack!
    private var mockProtocolSelector: MockActorOneOnOneProtocolSelector!
    private var mockMigrator: MockActorOneOnOneMigrator!

    private var viewContext: NSManagedObjectContext { mockCoreDataStack.viewContext }

    override func setUp() async throws {
        try await super.setUp()

        coreDataStackHelper = CoreDataStackHelper()

        mockCoreDataStack = try await coreDataStackHelper.createStack()
        mockProtocolSelector = MockActorOneOnOneProtocolSelector()
        mockMigrator = MockActorOneOnOneMigrator()
        sut = OneOnOneResolver(protocolSelector: mockProtocolSelector, migrator: mockMigrator)
    }

    override func tearDown() async throws {
        sut = nil
        mockProtocolSelector = nil
        mockMigrator = nil
        mockCoreDataStack = nil

        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil

        try await super.tearDown()
    }

    // MARK: - Tests

    func test_resolveAllOneOnOneConversations_givenZeroUsers() async throws {
        // Given

        // When
        try await sut.resolveAllOneOnOneConversations(in: viewContext)

        // Then
        let selectorInvocationsIsEmpty = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.isEmpty
        XCTAssertTrue(selectorInvocationsIsEmpty)

        let migratorInvocationsIsEmpty = await mockMigrator.migrateToMLSUserIDIn_Invocations.isEmpty
        XCTAssertTrue(migratorInvocationsIsEmpty)
    }

    func test_resolveAllOneOnOneConversations_givenMultipleUsers_thenMigrateAll() async throws {
        // Given
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockValue(.random())

        await viewContext.perform { [self] in
            let userA = createUser(in: viewContext)
            createConnection(status: .accepted, to: userA, in: viewContext)

            let userB = createUser(in: viewContext)
            createConnection(status: .accepted, to: userB, in: viewContext)
        }

        // When
        try await sut.resolveAllOneOnOneConversations(in: viewContext)

        // Then
        let selectorInvocationsCount = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.count
        XCTAssertEqual(selectorInvocationsCount, 2)

        let migratorInvocationsCount = await mockMigrator.migrateToMLSUserIDIn_Invocations.count
        XCTAssertEqual(migratorInvocationsCount, 2)
    }

    func test_resolveAllOneOnOneConversations_givenUserWithoutConnection_thenSkipOneMigration() async throws {
        // Given
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockValue(.random())

        await viewContext.perform { [self] in
            _ = createUser(in: viewContext)

            let userB = createUser(in: viewContext)
            createConnection(status: .accepted, to: userB, in: viewContext)
        }

        // When
        try await sut.resolveAllOneOnOneConversations(in: viewContext)

        // Then
        let selectorInvocationsCount = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.count
        XCTAssertEqual(selectorInvocationsCount, 1)

        let migratorInvocationsCount = await mockMigrator.migrateToMLSUserIDIn_Invocations.count
        XCTAssertEqual(migratorInvocationsCount, 1)
    }

    func test_resolveAllOneOnOneConversations_givenUserWithoutDomain_thenSkipOneMigration() async throws {
        // Given
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockValue(.random())

        await viewContext.perform { [self] in
            let userA = createUser(in: viewContext)
            userA.domain = nil
            createConnection(status: .accepted, to: userA, in: viewContext)

            let userB = createUser(in: viewContext)
            createConnection(status: .accepted, to: userB, in: viewContext)
        }

        // When
        try await sut.resolveAllOneOnOneConversations(in: viewContext)

        // Then
        let selectorInvocationsCount = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.count
        XCTAssertEqual(selectorInvocationsCount, 1)

        let migratorInvocationsCount = await mockMigrator.migrateToMLSUserIDIn_Invocations.count
        XCTAssertEqual(migratorInvocationsCount, 1)
    }

    func test_resolveAllOneOnOneConversations_givenMigrationFailure() async throws {
        // Given
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockError(MockOneOnOneResolverError.failed)

        await viewContext.perform { [self] in
            let userA = createUser(in: viewContext)
            createConnection(status: .accepted, to: userA, in: viewContext)

            let userB = createUser(in: viewContext)
            createConnection(status: .accepted, to: userB, in: viewContext)
        }

        // When
        try await sut.resolveAllOneOnOneConversations(in: viewContext)

        // Then
        let selectorCount = await mockMigrator.migrateToMLSUserIDIn_Invocations.count
        XCTAssertEqual(selectorCount, 2)

        let migratorCount = await mockMigrator.migrateToMLSUserIDIn_Invocations.count
        XCTAssertEqual(migratorCount, 2)
    }

    func test_ResolveOneOnOneConversation_MLSSupported() async throws {
        // Given
        let userID: QualifiedID = .random()

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockValue(.random())

        // When
        try await sut.resolveOneOnOneConversation(with: userID, in: viewContext)

        // Then
        let invocations = await mockMigrator.migrateToMLSUserIDIn_Invocations
        XCTAssertEqual(invocations.count, 1)
        XCTAssertEqual(invocations.first?.userID, userID)
    }

    func test_ResolveOneOnOneConversation_ProteusSupported() async throws {
        // Given
        let userID: QualifiedID = .random()

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.proteus)

        // When
        try await sut.resolveOneOnOneConversation(with: userID, in: viewContext)

        // Then
        let count = await mockMigrator.migrateToMLSUserIDIn_Invocations.count
        XCTAssertEqual(count, 0)
    }

    func test_ResolveOneOnOneConversation_NoCommonProtocols() async throws {
        // Given
        let userID: QualifiedID = .random()

        let conversation = await viewContext.perform { [self] in
            let user = createUser(in: viewContext)
            user.remoteIdentifier = userID.uuid
            user.domain = userID.domain

            let (_, conversation) = createConnection(
                status: .pending,
                to: user,
                in: viewContext
            )

            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertFalse(conversation.isForcedReadOnly)

            return conversation
        }

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.some(nil))

        // When
        try await sut.resolveOneOnOneConversation(with: userID, in: viewContext)

        // Then
        await viewContext.perform {
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertTrue(conversation.isForcedReadOnly)
        }
    }

    // MARK: - Helpers

    @discardableResult
    private func createUser(in context: NSManagedObjectContext) -> ZMUser {
        let user = ZMUser.insertNewObject(in: context)
        user.remoteIdentifier = UUID()
        user.domain = "local@domain.com"
        return user
    }

    @discardableResult
    private func createConnection(
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
        conversation.remoteIdentifier = UUID()
        conversation.domain = "local@domain.com"
        user.oneOnOneConversation = conversation

        return (connection, conversation)
    }
}

// MARK: - Mock Error

enum MockOneOnOneResolverError: Error {
    case failed
}
