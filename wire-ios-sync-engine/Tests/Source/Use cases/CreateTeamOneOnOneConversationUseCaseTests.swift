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

import XCTest
import WireDataModelSupport
import WireSyncEngineSupport
@testable import WireSyncEngine

final class CreateTeamOneOnOneConversationUseCaseTests: XCTestCase {

    private let coreDataStackHelper = CoreDataStackHelper()
    private var stack: CoreDataStack!
    private let modelHelper = ModelHelper()

    private var sut: CreateTeamOneOnOneConversationUseCase!
    private var protocolSelector: MockOneOnOneProtocolSelectorInterface!
    private var migrator: MockOneOnOneMigratorInterface!
    private var service: MockConversationServiceInterface!

    private var syncContext: NSManagedObjectContext {
        return stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()

        protocolSelector = MockOneOnOneProtocolSelectorInterface()
        migrator = MockOneOnOneMigratorInterface()
        service = MockConversationServiceInterface()

        sut = CreateTeamOneOnOneConversationUseCase(
            protocolSelector: protocolSelector,
            migrator: migrator,
            service: service
        )
    }

    override func tearDown() async throws {
        stack = nil
        protocolSelector = nil
        migrator = nil
        service = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func createTeamWithAnotherUser() async throws -> ZMUser {
        return try await syncContext.perform {
            let (_, _, otherUsers) = self.modelHelper.createSelfTeam(
                numberOfUsers: 1,
                in: self.syncContext
            )

            return try XCTUnwrap(otherUsers.first)
        }
    }

    // MARK: - Tests

    func testItFailsIfOtherUserIsNotInTheSameTeam() async throws {
        // Given
        let otherUser = await syncContext.perform {
            let selfUser = ZMUser.selfUser(in: self.syncContext)
            selfUser.remoteIdentifier = .init()

            let team = self.modelHelper.createTeam(in: self.syncContext)
            self.modelHelper.addUser(selfUser, to: team, in: self.syncContext)
            XCTAssertNotNil(selfUser.team)

            let otherUser = self.modelHelper.createUser(in: self.syncContext)
            XCTAssertNil(otherUser.team)

            return otherUser
        }

        do {
            // When
            _ = try await sut.invoke(with: otherUser, syncContext: syncContext)
        } catch CreateTeamOneOnOneConversationError.userIsNotOnSameTeam {
            // Then
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testItFailsIfThereAreNoCommonProtocols() async throws {
        // Given
        let otherUser = try await createTeamWithAnotherUser()

        // Mock: no common protocol.
        protocolSelector.getProtocolForUserWithIn_MockValue = .some(.none)

        do {
            // When
            _ = try await sut.invoke(with: otherUser, syncContext: syncContext)
        } catch CreateTeamOneOnOneConversationError.noCommonProtocols {
            // Then
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testItCreatesMLSConversation() async throws {
        // Given
        let otherUser = try await createTeamWithAnotherUser()

        // Mock: common protocol is mls.
        protocolSelector.getProtocolForUserWithIn_MockValue = .mls

        // Mock: the mls one on one that would have been created.
        let groupID = MLSGroupID.random()
        let objectID = await syncContext.perform {
            let conversation = self.modelHelper.createOneOnOne(with: otherUser, in: self.syncContext)
            conversation.mlsGroupID = groupID
            conversation.messageProtocol = .mls
            return conversation.objectID
        }

        // Mock: migrator returns id of the created mls one on one.
        migrator.migrateToMLSUserIDIn_MockMethod = { _, _ in
            return groupID
        }

        // When
        let result = try await sut.invoke(with: otherUser, syncContext: syncContext)

        // Then
        XCTAssertEqual(result, objectID)
    }

    func testItCreatesProteusConversation() async throws {
        // Given
        let otherUser = try await createTeamWithAnotherUser()

        // Mock: common protocol is proteus.
        protocolSelector.getProtocolForUserWithIn_MockValue = .proteus

        // Mock: the proteus one on one that would have been created.
        let conversation = await syncContext.perform {
            let conversation = self.modelHelper.createOneOnOne(with: otherUser, in: self.syncContext)
            conversation.messageProtocol = .proteus
            return conversation
        }

        // Mock: service created one on one.
        service.createFakeOneOnOneProteusConversationUserCompletion_MockMethod = { _, completion in
            completion(.success(conversation))
        }

        // When
        let result = try await sut.invoke(with: otherUser, syncContext: syncContext)

        // Then
        XCTAssertEqual(result, conversation.objectID)
    }

}

// TODO: deduplicate
private class MockConversationServiceInterface: ConversationServiceInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - createGroupConversation

    public var createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_Invocations: [(name: String?, users: Set<ZMUser>, allowGuests: Bool, allowServices: Bool, enableReceipts: Bool, messageProtocol: MessageProtocol, completion: (Result<ZMConversation, ConversationCreationFailure>) -> Void)] = []
    public var createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_MockMethod: ((String?, Set<ZMUser>, Bool, Bool, Bool, MessageProtocol, @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void) -> Void)?

    public func createGroupConversation(name: String?, users: Set<ZMUser>, allowGuests: Bool, allowServices: Bool, enableReceipts: Bool, messageProtocol: MessageProtocol, completion: @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void) {
        createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_Invocations.append((name: name, users: users, allowGuests: allowGuests, allowServices: allowServices, enableReceipts: enableReceipts, messageProtocol: messageProtocol, completion: completion))

        guard let mock = createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion_MockMethod else {
            fatalError("no mock for `createGroupConversationNameUsersAllowGuestsAllowServicesEnableReceiptsMessageProtocolCompletion`")
        }

        mock(name, users, allowGuests, allowServices, enableReceipts, messageProtocol, completion)
    }

    // MARK: - createFakeOneOnOneProteusConversation

    public var createFakeOneOnOneProteusConversationUserCompletion_Invocations: [(user: ZMUser, completion: (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void)] = []
    public var createFakeOneOnOneProteusConversationUserCompletion_MockMethod: ((ZMUser, @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void) -> Void)?

    public func createFakeOneOnOneProteusConversation(user: ZMUser, completion: @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void) {
        createFakeOneOnOneProteusConversationUserCompletion_Invocations.append((user: user, completion: completion))

        guard let mock = createFakeOneOnOneProteusConversationUserCompletion_MockMethod else {
            fatalError("no mock for `createFakeOneOnOneProteusConversationUserCompletion`")
        }

        mock(user, completion)
    }

    // MARK: - syncConversation

    public var syncConversationQualifiedIDCompletion_Invocations: [(qualifiedID: QualifiedID, completion: () -> Void)] = []
    public var syncConversationQualifiedIDCompletion_MockMethod: ((QualifiedID, @escaping () -> Void) -> Void)?

    public func syncConversation(qualifiedID: QualifiedID, completion: @escaping () -> Void) {
        syncConversationQualifiedIDCompletion_Invocations.append((qualifiedID: qualifiedID, completion: completion))

        guard let mock = syncConversationQualifiedIDCompletion_MockMethod else {
            fatalError("no mock for `syncConversationQualifiedIDCompletion`")
        }

        mock(qualifiedID, completion)
    }

    // MARK: - syncConversation

    public var syncConversationQualifiedID_Invocations: [QualifiedID] = []
    public var syncConversationQualifiedID_MockMethod: ((QualifiedID) async -> Void)?

    public func syncConversation(qualifiedID: QualifiedID) async {
        syncConversationQualifiedID_Invocations.append(qualifiedID)

        guard let mock = syncConversationQualifiedID_MockMethod else {
            fatalError("no mock for `syncConversationQualifiedID`")
        }

        await mock(qualifiedID)
    }

}
