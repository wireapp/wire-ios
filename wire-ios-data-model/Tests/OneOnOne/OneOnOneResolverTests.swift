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
    private var mockProtocolSelector: MockOneOnOneProtocolSelectorInterface!
    private var mockMigrator: MockOneOnOneMigratorInterface!

    private var viewContext: NSManagedObjectContext { mockCoreDataStack.viewContext }

    override func setUp() async throws {
        try await super.setUp()

        coreDataStackHelper = CoreDataStackHelper()

        mockCoreDataStack = try await coreDataStackHelper.createStack()
        mockProtocolSelector = MockOneOnOneProtocolSelectorInterface()
        mockMigrator = MockOneOnOneMigratorInterface()
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

    func test_ResolveOneOnOneConversation_MLSSupported() async throws {
        // Given
        let userID = QualifiedID.random()

        // Mock
        mockProtocolSelector.getProtocolForUserWithIn_MockValue = .mls
        mockMigrator.migrateToMLSUserIDIn_MockMethod = { _, _ in .random() }

        // When
        try await sut.resolveOneOnOneConversation(with: userID, in: viewContext)

        // Then
        XCTAssertEqual(mockMigrator.migrateToMLSUserIDIn_Invocations.count, 1)
        let invocation = try XCTUnwrap(mockMigrator.migrateToMLSUserIDIn_Invocations.first)
        XCTAssertEqual(invocation.userID, userID)
    }

    func test_ResolveOneOnOneConversation_ProteusSupported() async throws {
        // Given
        let userID = QualifiedID.random()

        // Mock
        mockProtocolSelector.getProtocolForUserWithIn_MockValue = .proteus

        // When
        try await sut.resolveOneOnOneConversation(with: userID, in: viewContext)

        // Then
        XCTAssertEqual(mockMigrator.migrateToMLSUserIDIn_Invocations.count, 0)
    }

    func test_ResolveOneOnOneConversation_NoCommonProtocols() async throws {
        // Given
        let userID = QualifiedID.random()

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
        return user
    }

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
        conversation.remoteIdentifier = .create()
        conversation.domain = "local@domain.com"
        user.oneOnOneConversation = conversation

        return (connection, conversation)
    }
}
