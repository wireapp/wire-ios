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

import WireAPI
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import XCTest

@testable import WireDomain

final class OneOnOneResolverTests: XCTestCase {
    var sut: WireDomain.OneOnOneResolver!

    var coreDataStack: CoreDataStack!
    var coreDataStackHelper: CoreDataStackHelper!
    var modelHelper: ModelHelper!
    var userRepository: MockUserRepositoryProtocol!
    var conversationsRepository: MockConversationRepositoryProtocol!
    var mlsService: MockMLSServiceInterface!

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        userRepository = MockUserRepositoryProtocol()
        conversationsRepository = MockConversationRepositoryProtocol()
        mlsService = MockMLSServiceInterface()
        sut = WireDomain.OneOnOneResolver(
            context: context,
            userRepository: userRepository,
            conversationsRepository: conversationsRepository,
            mlsService: mlsService,
            isMLSEnabled: true,
            target: .user(id: Scaffolding.receiverQualifiedID)
        )

        DeveloperFlag.storage = UserDefaults(suiteName: Scaffolding.defaultsSuiteName)!
        var flag = DeveloperFlag.enableMLSSupport
        flag.isOn = true
    }

    override func tearDown() async throws {
        try await super.tearDown()
        coreDataStack = nil
        sut = nil
        modelHelper = nil
        try coreDataStackHelper.cleanupDirectory()
        DeveloperFlag.storage.removePersistentDomain(forName: Scaffolding.defaultsSuiteName)
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Does_Not_Migrate_MLS_Conversation() async throws {
        // Given

        let commonProtocol = WireDataModel.MessageProtocol.mls
        let (selfUser, user, mlsOneOnOneConversation) = try setupManagedObjects(
            selfUserProtocol: commonProtocol,
            userProtocol: commonProtocol
        )

        let mlsConversationExists = true /// should not migrate MLS conversation

        // Mock

        setupMock(
            selfUser: selfUser,
            user: user,
            mlsOneOnOneConversation: mlsOneOnOneConversation,
            mlsConversationExists: mlsConversationExists
        )

        // When

        try await sut.invoke()

        // Then

        XCTAssert(mlsService.establishGroupForWithRemovalKeys_Invocations.isEmpty)
        XCTAssert(mlsService.joinGroupWith_Invocations.isEmpty)
    }

    func testProcessEvent_It_Resolves_MLS_Conversation_Epoch_Zero() async throws {
        // Given

        let commonProtocol = WireDataModel.MessageProtocol.mls
        let mlsEpoch: UInt64 = 0

        let (selfUser, user, mlsOneOnOneConversation) = try setupManagedObjects(
            selfUserProtocol: commonProtocol,
            userProtocol: commonProtocol,
            mlsEpoch: mlsEpoch
        )

        // Mock

        setupMock(
            selfUser: selfUser,
            user: user,
            mlsOneOnOneConversation: mlsOneOnOneConversation
        )

        // When

        try await sut.invoke()

        // Then

        XCTAssertEqual(mlsService.establishGroupForWithRemovalKeys_Invocations.count, 1)
        let createGroupInvocation = try XCTUnwrap(
            mlsService.establishGroupForWithRemovalKeys_Invocations.first
        )

        XCTAssertEqual(createGroupInvocation.groupID, Scaffolding.mlsGroupID)
        XCTAssertEqual(
            createGroupInvocation.users,
            [MLSUser(Scaffolding.receiverQualifiedID.toDomainModel())]
        )
        XCTAssertEqual(mlsOneOnOneConversation.ciphersuite, Scaffolding.ciphersuite)
        XCTAssertEqual(mlsOneOnOneConversation.mlsStatus, .ready)
        XCTAssertEqual(mlsOneOnOneConversation.isForcedReadOnly, false)
        XCTAssertEqual(mlsOneOnOneConversation.needsToBeUpdatedFromBackend, true)
        XCTAssertEqual(user.oneOnOneConversation, mlsOneOnOneConversation)
        XCTAssertEqual(mlsOneOnOneConversation.oneOnOneUser, user)
    }

    func testProcessEvent_It_Resolves_MLS_Conversation_Epoch_Not_Zero() async throws {
        // Given

        let commonProtocol = WireDataModel.MessageProtocol.mls
        let mlsEpoch: UInt64 = 1

        let (selfUser, user, mlsOneOnOneConversation) = try setupManagedObjects(
            selfUserProtocol: commonProtocol,
            userProtocol: commonProtocol,
            mlsEpoch: mlsEpoch
        )

        // Mock

        setupMock(
            selfUser: selfUser,
            user: user,
            mlsOneOnOneConversation: mlsOneOnOneConversation
        )

        // When

        try await sut.invoke()

        // Then

        XCTAssertEqual(mlsService.joinGroupWith_Invocations.count, 1)
        let invokedMLSGroupID = try XCTUnwrap(mlsService.joinGroupWith_Invocations.first)
        XCTAssertEqual(invokedMLSGroupID, Scaffolding.mlsGroupID)
        XCTAssertEqual(user.oneOnOneConversation, mlsOneOnOneConversation)
        XCTAssertEqual(mlsOneOnOneConversation.oneOnOneUser, user)
    }

    func testProcessEvent_It_Migrates_Proteus_Messages_To_MLS_Conversation() async throws {
        // Given

        let commonProtocol = WireDataModel.MessageProtocol.mls

        let (selfUser, user, mlsOneOnOneConversation) = try setupManagedObjects(
            selfUserProtocol: commonProtocol,
            userProtocol: commonProtocol
        )

        // Mock

        setupMock(
            selfUser: selfUser,
            user: user,
            mlsOneOnOneConversation: mlsOneOnOneConversation
        )

        // When

        try await sut.invoke()

        // Then

        let migratedMessagesTexts = mlsOneOnOneConversation.allMessages
            .compactMap(\.textMessageData)
            .compactMap(\.messageText)
            .sorted()

        /// Ensuring proteus messages were migrated to MLS conversation.
        XCTAssertEqual(migratedMessagesTexts.first, "Hello")
        XCTAssertEqual(migratedMessagesTexts.last, "World!")
    }

    func testProcessEvent_It_Resolves_Proteus_Conversation() async throws {
        // Given

        let commonProtocol = WireDataModel.MessageProtocol.proteus
        let (selfUser, user, mlsOneOnOneConversation) = try setupManagedObjects(
            selfUserProtocol: commonProtocol,
            userProtocol: commonProtocol
        )

        XCTAssertEqual(user.oneOnOneConversation?.isForcedReadOnly, true)

        // Mock

        setupMock(
            selfUser: selfUser,
            user: user,
            mlsOneOnOneConversation: mlsOneOnOneConversation
        )

        // When

        try await sut.invoke()

        // Then

        XCTAssertEqual(user.oneOnOneConversation?.isForcedReadOnly, false)
    }

    func testProcessEvent_It_Resolves_Conversation_With_No_Common_Protocol() async throws {
        // Given

        let forcedReadOnly = false

        let (selfUser, user, mlsOneOnOneConversation) = try setupManagedObjects(
            selfUserProtocol: .mls,
            userProtocol: .proteus,
            forcedReadOnly: forcedReadOnly
        )

        XCTAssertEqual(user.oneOnOneConversation?.isForcedReadOnly, false)

        // Mock

        setupMock(
            selfUser: selfUser,
            user: user,
            mlsOneOnOneConversation: mlsOneOnOneConversation
        )

        // When

        try await sut.invoke()

        // Then

        let lastMessage = try XCTUnwrap(user.oneOnOneConversation?.lastMessage as? ZMSystemMessage)
        XCTAssertEqual(lastMessage.systemMessageType, .mlsNotSupportedOtherUser)
        XCTAssertEqual(user.oneOnOneConversation?.isForcedReadOnly, true)
    }

    // MARK: - Setup

    private func setupManagedObjects(
        selfUserProtocol: WireDataModel.MessageProtocol,
        userProtocol: WireDataModel.MessageProtocol,
        forcedReadOnly: Bool = true,
        mlsEpoch: UInt64 = 0
    ) throws -> (selfUser: ZMUser,
                 user: ZMUser,
                 mlsConversation: ZMConversation) {
        let user = modelHelper.createUser(
            id: Scaffolding.receiverQualifiedID.uuid,
            domain: Scaffolding.receiverQualifiedID.domain,
            in: context
        )

        user.supportedProtocols = [userProtocol]

        let selfUser = modelHelper.createSelfUser(
            id: UUID(),
            domain: nil,
            in: context
        )

        selfUser.supportedProtocols = [selfUserProtocol]

        let proteusConversation = modelHelper.createOneOnOne(
            with: selfUser,
            in: context
        )

        proteusConversation.isForcedReadOnly = forcedReadOnly
        user.oneOnOneConversation = proteusConversation

        try proteusConversation.appendText(content: "Hello")
        try proteusConversation.appendText(content: "World!")

        let mlsOneOnOneConversation = modelHelper.createMLSConversation(
            mlsGroupID: Scaffolding.mlsGroupID,
            mlsStatus: .pendingJoin,
            conversationType: .oneOnOne,
            epoch: mlsEpoch,
            in: context
        )

        return (selfUser, user, mlsOneOnOneConversation)
    }

    private func setupMock(
        selfUser: ZMUser,
        user: ZMUser,
        mlsOneOnOneConversation: ZMConversation,
        mlsConversationExists: Bool = false
    ) {
        userRepository.fetchUserWithDomain_MockValue = user
        userRepository.fetchSelfUser_MockValue = selfUser

        conversationsRepository.pullMLSOneToOneConversationUserIDDomain_MockValue = Scaffolding.conversationID.uuidString
        conversationsRepository.fetchMLSConversationWith_MockValue = mlsOneOnOneConversation

        mlsService.establishGroupForWithRemovalKeys_MockValue = Scaffolding.ciphersuite
        mlsService.conversationExistsGroupID_MockValue = mlsConversationExists
        mlsService.joinGroupWith_MockMethod = { _ in }
    }

    private enum Scaffolding {
        static let receiverID = UUID()
        static let receiverQualifiedID = WireAPI.QualifiedID(
            uuid: receiverID,
            domain: "domain.com"
        )
        static let conversationID = UUID()

        static let base64EncodedString = "pQABARn//wKhAFggHsa0CszLXYLFcOzg8AA//E1+Dl1rDHQ5iuk44X0/PNYDoQChAFgg309rkhG6SglemG6kWae81P1HtQPx9lyb6wExTovhU4cE9g=="

        static let ciphersuite = WireDataModel.MLSCipherSuite.MLS_256_DHKEMP521_AES256GCM_SHA512_P521

        static let mlsGroupID = WireDataModel.MLSGroupID(
            base64Encoded: base64EncodedString
        )!

        static let defaultsSuiteName = UUID().uuidString
    }
}
