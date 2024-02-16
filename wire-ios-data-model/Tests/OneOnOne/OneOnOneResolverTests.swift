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
    private var mockProtocolSelector: MockActorOneOnOneProtocolSelectorInterface!
    private var mockMigrator: MockActorOneOnOneMigratorInterface!

    private var viewContext: NSManagedObjectContext { mockCoreDataStack.viewContext }

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        coreDataStackHelper = CoreDataStackHelper()

        mockCoreDataStack = try await coreDataStackHelper.createStack()
        mockProtocolSelector = MockActorOneOnOneProtocolSelectorInterface()
        mockMigrator = MockActorOneOnOneMigratorInterface()
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

    @MainActor
    func test_resolveAllOneOnOneConversations_givenZeroUsers() async throws {
        // Given

        // When
        try await sut.resolveAllOneOnOneConversations(in: viewContext)

        // Then
        XCTAssertTrue(mockProtocolSelector.getProtocolForUserWithIn_Invocations.isEmpty)
        XCTAssertTrue(mockMigrator.migrateToMLSUserIDIn_Invocations.isEmpty)
    }

    @MainActor
    func test_resolveAllOneOnOneConversations_givenMultipleUsers_thenMigrateAll() async throws {
        // Given
        mockProtocolSelector.getProtocolForUserWithIn_MockValue = .mls
        mockMigrator.migrateToMLSUserIDIn_MockValue = .random()

        await viewContext.perform { [self] in
            let userA = createUser(in: viewContext)
            createConnection(status: .accepted, to: userA, in: viewContext)

            let userB = createUser(in: viewContext)
            createConnection(status: .accepted, to: userB, in: viewContext)
        }

        // When
        try await sut.resolveAllOneOnOneConversations(in: viewContext)

        // Then
        XCTAssertEqual(mockProtocolSelector.getProtocolForUserWithIn_Invocations.count, 2)
        XCTAssertEqual(mockMigrator.migrateToMLSUserIDIn_Invocations.count, 2)
    }

    @MainActor
    func test_resolveAllOneOnOneConversations_givenUserWithoutConnection_thenSkipOneMigration() async throws {
        // Given
        mockProtocolSelector.getProtocolForUserWithIn_MockValue = .mls
        mockMigrator.migrateToMLSUserIDIn_MockValue = .random()

        await viewContext.perform { [self] in
            _ = createUser(in: viewContext)

            let userB = createUser(in: viewContext)
            createConnection(status: .accepted, to: userB, in: viewContext)
        }

        // When
        try await sut.resolveAllOneOnOneConversations(in: viewContext)

        // Then
        XCTAssertEqual(mockProtocolSelector.getProtocolForUserWithIn_Invocations.count, 1)
        XCTAssertEqual(mockMigrator.migrateToMLSUserIDIn_Invocations.count, 1)
    }

    @MainActor
    func test_resolveAllOneOnOneConversations_givenUserWithoutDomain_thenSkipOneMigration() async throws {
        // Given
        mockProtocolSelector.getProtocolForUserWithIn_MockValue = .mls
        mockMigrator.migrateToMLSUserIDIn_MockValue = .random()

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
        XCTAssertEqual(mockProtocolSelector.getProtocolForUserWithIn_Invocations.count, 1)
        XCTAssertEqual(mockMigrator.migrateToMLSUserIDIn_Invocations.count, 1)
    }

    @MainActor
    func test_resolveAllOneOnOneConversations_givenMigrationFailure() async throws {
        // Given
        mockProtocolSelector.getProtocolForUserWithIn_MockValue = .mls
        mockMigrator.migrateToMLSUserIDIn_MockError = MockOneOnOneResolverError.failed

        await viewContext.perform { [self] in
            let userA = createUser(in: viewContext)
            createConnection(status: .accepted, to: userA, in: viewContext)

            let userB = createUser(in: viewContext)
            createConnection(status: .accepted, to: userB, in: viewContext)
        }

        // When
        try await sut.resolveAllOneOnOneConversations(in: viewContext)

        // Then
        XCTAssertEqual(mockProtocolSelector.getProtocolForUserWithIn_Invocations.count, 2)
        XCTAssertEqual(mockMigrator.migrateToMLSUserIDIn_Invocations.count, 2)
    }

    @MainActor
    func test_ResolveOneOnOneConversation_MLSSupported() async throws {
        // Given
        let userID: QualifiedID = .random()

        // Mock
        mockProtocolSelector.getProtocolForUserWithIn_MockValue = .mls
        mockMigrator.migrateToMLSUserIDIn_MockValue = .random()

        // When
        try await sut.resolveOneOnOneConversation(with: userID, in: viewContext)

        // Then
        XCTAssertEqual(mockMigrator.migrateToMLSUserIDIn_Invocations.count, 1)
        let invocation = try XCTUnwrap(mockMigrator.migrateToMLSUserIDIn_Invocations.first)
        XCTAssertEqual(invocation.userID, userID)
    }

    @MainActor
    func test_ResolveOneOnOneConversation_ProteusSupported() async throws {
        // Given
        let userID: QualifiedID = .random()

        // Mock
        mockProtocolSelector.getProtocolForUserWithIn_MockValue = .proteus

        // When
        try await sut.resolveOneOnOneConversation(with: userID, in: viewContext)

        // Then
        XCTAssertEqual(mockMigrator.migrateToMLSUserIDIn_Invocations.count, 0)
    }

    @MainActor
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
        mockProtocolSelector.getProtocolForUserWithIn_MockValue = .some(nil)

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

@MainActor
public class MockActorOneOnOneMigratorInterface: OneOnOneMigratorInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - migrateToMLS

    public var migrateToMLSUserIDIn_Invocations: [(userID: QualifiedID, context: NSManagedObjectContext)] = []
    public var migrateToMLSUserIDIn_MockError: Error?
    public var migrateToMLSUserIDIn_MockMethod: ((QualifiedID, NSManagedObjectContext) async throws -> MLSGroupID)?
    public var migrateToMLSUserIDIn_MockValue: MLSGroupID?

    @discardableResult
    public func migrateToMLS(userID: QualifiedID, in context: NSManagedObjectContext) async throws -> MLSGroupID {
        migrateToMLSUserIDIn_Invocations.append((userID: userID, context: context))

        if let error = migrateToMLSUserIDIn_MockError {
            throw error
        }

        if let mock = migrateToMLSUserIDIn_MockMethod {
            return try await mock(userID, context)
        } else if let mock = migrateToMLSUserIDIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `migrateToMLSUserIDIn`")
        }
    }

}

@MainActor
public class MockActorOneOnOneProtocolSelectorInterface: OneOnOneProtocolSelectorInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - getProtocolForUser

    public var getProtocolForUserWithIn_Invocations: [(id: QualifiedID, context: NSManagedObjectContext)] = []
    public var getProtocolForUserWithIn_MockMethod: ((QualifiedID, NSManagedObjectContext) async -> MessageProtocol?)?
    public var getProtocolForUserWithIn_MockValue: MessageProtocol??

    public func getProtocolForUser(with id: QualifiedID, in context: NSManagedObjectContext) async -> MessageProtocol? {
        getProtocolForUserWithIn_Invocations.append((id: id, context: context))

        if let mock = getProtocolForUserWithIn_MockMethod {
            return await mock(id, context)
        } else if let mock = getProtocolForUserWithIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `getProtocolForUserWithIn`")
        }
    }

}
