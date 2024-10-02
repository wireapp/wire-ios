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

@testable import WireDataModel
@testable import WireDataModelSupport
import XCTest

final class OneOnOneResolverTests: XCTestCase {

    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var mockCoreDataStack: CoreDataStack!
    private var mockMigrator: MockActorOneOnOneMigrator!
    private var mockProtocolSelector: MockActorOneOnOneProtocolSelector!

    private var syncContext: NSManagedObjectContext { mockCoreDataStack.syncContext }
    private var oldDeveloperFlagStorage: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()

        oldDeveloperFlagStorage = DeveloperFlag.storage
        DeveloperFlag.enableMLSSupport.enable(true, storage: .temporary())

        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()

        mockCoreDataStack = try await coreDataStackHelper.createStack()

        mockProtocolSelector = MockActorOneOnOneProtocolSelector()
        mockMigrator = MockActorOneOnOneMigrator()
    }

    override func tearDown() async throws {
        mockProtocolSelector = nil
        mockCoreDataStack = nil

        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
        DeveloperFlag.storage = oldDeveloperFlagStorage

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

        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.some(.none))

        await syncContext.perform { [self] in
            makeOneOnOneConversation(in: syncContext)
            makeOneOnOneConversation(in: syncContext)
        }

        // When
        try await resolver.resolveAllOneOnOneConversations(in: syncContext)

        // Then
        let selectorInvocationsCount = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.count
        XCTAssertEqual(selectorInvocationsCount, 2)
    }

    func test_resolveAllOneOnOneConversations_givenUserWithoutDomain_thenSkipOneMigration() async throws {
        // Given
        let resolver = makeResolver()

        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockMethod { _, _ in .random() }

        // mockHandler must be retained to catch notifications
        await syncContext.perform { [self] in
            makeOneOnOneConversation(
                domain: nil,
                in: syncContext
            )
            makeOneOnOneConversation(
                domain: "local@domain.com",
                in: syncContext
            )
        }

        // When
        try await resolver.resolveAllOneOnOneConversations(in: syncContext)

        // Then
        let selectorInvocationsCount = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.count
        XCTAssertEqual(selectorInvocationsCount, 1)

        let migratorInvocationsCount = await mockMigrator.migrateToMLSUserIDIn_Invocations.count
        XCTAssertEqual(migratorInvocationsCount, 1)
    }

    func test_resolveAllOneOnOneConversations_givenMigrationFailure() async throws {
        // Given
        let resolver = makeResolver()

        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockError(MockOneOnOneResolverError.failed)

        await syncContext.perform { [self] in
            makeOneOnOneConversation(in: syncContext)
            makeOneOnOneConversation(in: syncContext)
        }

        // When
        try await resolver.resolveAllOneOnOneConversations(in: syncContext)

        // Then
        let selectorCount = await mockProtocolSelector.getProtocolForUserWithIn_Invocations.count
        XCTAssertEqual(selectorCount, 2)

        let migratorCount = await mockMigrator.migrateToMLSUserIDIn_Invocations.count
        XCTAssertEqual(migratorCount, 2)
    }

    func test_ResolveOneOnOneConversation_GivenMLS() async throws {
        // Given
        let userID: QualifiedID = .random()
        let resolver = makeResolver()

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockValue(.random())

        await syncContext.perform { [self] in
            let conversation = makeOneOnOneConversation(qualifiedID: userID, in: syncContext)
            conversation.messageProtocol = .proteus
        }

        // When
        let result = try await resolver.resolveOneOnOneConversation(with: userID, in: syncContext)

        // Then
        guard case .migratedToMLSGroup = result else {
            XCTFail("expected result '.noAction'")
            return
        }

        let invocations = await mockMigrator.migrateToMLSUserIDIn_Invocations
        XCTAssertEqual(invocations.count, 1)
        XCTAssertEqual(invocations.first?.userID, userID)
    }

    func test_ResolveOneOnOneConversation_GivenMLS_SetsReadOnlyToFalse_WhenItSucceeds() async throws {
        // Given
        let userID: QualifiedID = .random()
        let resolver = makeResolver()

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockValue(.random())

        let conversation = await syncContext.perform { [self] in
            let conversation = makeOneOnOneConversation(qualifiedID: userID, in: syncContext)
            conversation.isForcedReadOnly = true
            return conversation
        }

        // When
        try await resolver.resolveOneOnOneConversation(with: userID, in: syncContext)

        // Then
        let isReadOnly = await syncContext.perform { conversation.isForcedReadOnly }
        XCTAssertFalse(isReadOnly)
    }

    func test_ResolveOneOnOneConversation_GivenMLS_SetsReadOnlyToTrue_WhenItFailsToEstablishGroup() async throws {
        // Given
        let userID: QualifiedID = .random()
        let resolver = makeResolver()

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.mls)
        await mockMigrator.setMigrateToMLSUserIDIn_MockError(
            MigrateMLSOneOnOneConversationError.failedToEstablishGroup(MockOneOnOneResolverError.failed)
        )

        let conversation = await syncContext.perform { [self] in
            let conversation = makeOneOnOneConversation(qualifiedID: userID, in: syncContext)
            return conversation
        }

        do {
            // When
            try await resolver.resolveOneOnOneConversation(with: userID, in: syncContext)
        } catch MigrateMLSOneOnOneConversationError.failedToEstablishGroup {
            // Then
            let isReadOnly = await syncContext.perform { conversation.isReadOnly }
            XCTAssertTrue(isReadOnly)
        } catch {
            XCTFail("unexpected error")
        }
    }

    func test_ResolveOneOnOneConversation_GivenProteus_SetsReadOnlyToFalse() async throws {
        // Given
        let resolver = makeResolver()
        let userID: QualifiedID = .random()

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.proteus)

        let conversation = await syncContext.perform { [self] in
            let conversation = makeOneOnOneConversation(qualifiedID: userID, in: syncContext)
            conversation.isForcedReadOnly = true
            return conversation
        }

        // When
        let result = try await resolver.resolveOneOnOneConversation(with: userID, in: syncContext)

        // Then
        let isReadOnly = await syncContext.perform { conversation.isForcedReadOnly }
        XCTAssertFalse(isReadOnly)

        guard case .noAction = result else {
            XCTFail("expected result '.noAction'")
            return
        }
    }

    func test_ResolveOneOnOneConversation_GivenProteus_DoesntAttemptMLSMigration() async throws {
        // Given
        let resolver = makeResolver()
        let userID: QualifiedID = .random()

        // Mock
        await mockProtocolSelector.setGetProtocolForUserWithIn_MockValue(.proteus)

        _ = await syncContext.perform { [self] in
            let conversation = makeOneOnOneConversation(qualifiedID: userID, in: syncContext)
            conversation.isForcedReadOnly = true
            return conversation
        }

        // When
        _ = try await resolver.resolveOneOnOneConversation(with: userID, in: syncContext)

        // Then
        let invocations = await mockMigrator.migrateToMLSUserIDIn_Invocations
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
        let result = try await resolver.resolveOneOnOneConversation(with: userID, in: syncContext)

        // Then
        guard case .archivedAsReadOnly = result else {
            XCTFail("expected result '.noAction'")
            return
        }

        await syncContext.perform {
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertTrue(conversation.isForcedReadOnly)
            XCTAssertEqual(conversation.lastMessage?.systemMessageData?.systemMessageType, .mlsNotSupportedSelfUser)
        }
    }

    // MARK: Helpers

    private func makeResolver() -> OneOnOneResolver {
        OneOnOneResolver(
            protocolSelector: mockProtocolSelector,
            migrator: mockMigrator
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
