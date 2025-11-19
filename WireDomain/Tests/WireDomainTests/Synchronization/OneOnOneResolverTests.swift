//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import Foundation
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import WireNetwork
import WireNetworkSupport
import XCTest
@testable import WireDomain

final class OneOnOneResolverTests: XCTestCase {
    var sut: WireDomain.OneOnOneResolver!

    var coreDataStack: CoreDataStack!
    var coreDataStackHelper: CoreDataStackHelper!
    var modelHelper: ModelHelper!
    var userLocalStore: MockUserLocalStoreProtocol!
    var conversationLocalStore: MockConversationLocalStoreProtocol!
    var pullMLSOneOnOneSync: MockPullMLSOneOnOneSyncProtocol!
    var mlsService: MockMLSServiceInterface!

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        userLocalStore = MockUserLocalStoreProtocol()
        conversationLocalStore = MockConversationLocalStoreProtocol()
        pullMLSOneOnOneSync = MockPullMLSOneOnOneSyncProtocol()
        mlsService = MockMLSServiceInterface()
        sut = OneOnOneResolver(
            context: context,
            userLocalStore: userLocalStore,
            conversationLocalStore: conversationLocalStore,
            pullMLSOneOnOneSync: pullMLSOneOnOneSync,
            mlsProvider: MLSProvider(service: mlsService, isMLSEnabled: true)
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        coreDataStack = nil
        sut = nil
        modelHelper = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        userLocalStore = nil
        conversationLocalStore = nil
        pullMLSOneOnOneSync = nil
        mlsService = nil
    }

    func testProcessEvent_It_Resolves_MLS_Conversation_Epoch_Zero() async throws {
        // Given

        let commonProtocol = WireDataModel.MessageProtocol.mls

        let (selfUser, user, mlsOneOnOneConversation) = try await context.perform { [self] in
            try setupManagedObjects(
                selfUserProtocol: commonProtocol,
                userProtocol: commonProtocol
            )
        }

        // Mock

        setupMock(
            selfUser: selfUser,
            user: user,
            mlsOneOnOneConversation: mlsOneOnOneConversation
        )

        // When

        try await sut.resolveAllOneOnOneConversations()

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

        await context.perform {
            XCTAssertEqual(mlsOneOnOneConversation.ciphersuite, Scaffolding.ciphersuite)
            XCTAssertEqual(mlsOneOnOneConversation.mlsStatus, .ready)
            XCTAssertEqual(mlsOneOnOneConversation.isForcedReadOnly, false)
            XCTAssertEqual(mlsOneOnOneConversation.needsToBeUpdatedFromBackend, true)
            XCTAssertEqual(user.oneOnOneConversation, mlsOneOnOneConversation)
            XCTAssertEqual(mlsOneOnOneConversation.oneOnOneUser, user)
        }
    }

    func testProcessEvent_It_Resolves_MLS_Conversation_Epoch_Not_Zero() async throws {
        // Given

        let commonProtocol = WireDataModel.MessageProtocol.mls
        let mlsEpoch: UInt64 = 1

        let (selfUser, user, mlsOneOnOneConversation) = try await context.perform { [self] in
            try setupManagedObjects(
                selfUserProtocol: commonProtocol,
                userProtocol: commonProtocol,
                mlsEpoch: mlsEpoch
            )
        }

        // Mock

        setupMock(
            selfUser: selfUser,
            user: user,
            mlsOneOnOneConversation: mlsOneOnOneConversation
        )

        // When

        try await sut.resolveAllOneOnOneConversations()

        // Then

        try await context.perform { [self] in
            XCTAssertEqual(mlsService.joinGroupWith_Invocations.count, 1)
            let invokedMLSGroupID = try XCTUnwrap(mlsService.joinGroupWith_Invocations.first)
            XCTAssertEqual(invokedMLSGroupID, Scaffolding.mlsGroupID)
            XCTAssertEqual(user.oneOnOneConversation, mlsOneOnOneConversation)
            XCTAssertEqual(mlsOneOnOneConversation.oneOnOneUser, user)
        }
    }

    func testProcessEvent_It_Migrates_Proteus_Messages_To_MLS_Conversation() async throws {
        // Given

        let commonProtocol = WireDataModel.MessageProtocol.mls

        let (selfUser, user, mlsOneOnOneConversation) = try await context.perform { [self] in
            try setupManagedObjects(
                selfUserProtocol: commonProtocol,
                userProtocol: commonProtocol
            )
        }

        // Mock

        setupMock(
            selfUser: selfUser,
            user: user,
            mlsOneOnOneConversation: mlsOneOnOneConversation
        )

        // When

        try await sut.resolveAllOneOnOneConversations()

        // Then

        try await context.perform { [self] in
            let allMessages = mlsOneOnOneConversation.allMessages

            try XCTAssertCount(allMessages, count: 3)
            let mlsSystemMessage = try XCTUnwrap(mlsOneOnOneConversation.lastMessage as? ZMSystemMessage)
            XCTAssertEqual(
                mlsSystemMessage.systemMessageType.rawValue,
                ZMSystemMessageType.mlsMigrationFinalized.rawValue
            )

            XCTAssertEqual(mlsOneOnOneConversation.needsToBeUpdatedFromBackend, true)

            let migratedMessagesTexts = allMessages
                .compactMap(\.textMessageData)
                .compactMap(\.messageText)
                .sorted()

            /// Ensuring proteus messages were migrated to MLS conversation.
            XCTAssertEqual(migratedMessagesTexts.first, "Hello")
            XCTAssertEqual(migratedMessagesTexts.last, "World!")
        }
    }

    func testProcessEvent_It_Resolves_Proteus_Conversation() async throws {
        // Given

        let commonProtocol = WireDataModel.MessageProtocol.proteus

        let (selfUser, user, mlsOneOnOneConversation) = try await context.perform { [self] in
            try setupManagedObjects(
                selfUserProtocol: commonProtocol,
                userProtocol: commonProtocol
            )
        }

        await context.perform {
            XCTAssertEqual(user.oneOnOneConversation?.isForcedReadOnly, true)
        }

        // Mock

        setupMock(
            selfUser: selfUser,
            user: user,
            mlsOneOnOneConversation: mlsOneOnOneConversation
        )

        // When

        try await sut.resolveAllOneOnOneConversations()

        // Then

        await context.perform {
            XCTAssertEqual(user.oneOnOneConversation?.isForcedReadOnly, false)
        }
    }

    func testProcessEvent_It_Resolves_Conversation_With_No_Common_Protocol() async throws {
        // Given

        let forcedReadOnly = false

        let (selfUser, user, mlsOneOnOneConversation) = try await context.perform { [self] in
            try setupManagedObjects(
                selfUserProtocol: .mls,
                userProtocol: .proteus,
                forcedReadOnly: forcedReadOnly
            )
        }

        await context.perform {
            XCTAssertEqual(user.oneOnOneConversation?.isForcedReadOnly, false)
        }

        // Mock

        setupMock(
            selfUser: selfUser,
            user: user,
            mlsOneOnOneConversation: mlsOneOnOneConversation
        )

        // When

        try await sut.resolveAllOneOnOneConversations()

        // Then

        try await context.perform {
            let lastMessage = try XCTUnwrap(user.oneOnOneConversation?.lastMessage as? ZMSystemMessage)
            XCTAssertEqual(lastMessage.systemMessageType, .mlsNotSupportedOtherUser)
            XCTAssertEqual(user.oneOnOneConversation?.isForcedReadOnly, true)
        }
    }

    // MARK: - Setup

    typealias ManagedObjects = (selfUser: ZMUser, user: ZMUser, mlsConversation: ZMConversation)

    private func setupManagedObjects(
        selfUserProtocol: WireDataModel.MessageProtocol,
        userProtocol: WireDataModel.MessageProtocol,
        forcedReadOnly: Bool = true,
        mlsEpoch: UInt64 = 0
    ) throws -> ManagedObjects {
        let user = modelHelper.createUser(
            id: Scaffolding.receiverQualifiedID.id,
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
        userLocalStore.fetchUserIdDomain_MockValue = user
        userLocalStore.fetchSelfUser_MockValue = selfUser
        userLocalStore
            .fetchAllUserIDsWithOneOnOneConversation_MockValue = [Scaffolding.receiverQualifiedID.toDomainModel()]

        pullMLSOneOnOneSync.pullUserIDUserDomain_MockValue = (Scaffolding.mlsGroupID, Scaffolding.mlsPublicKeys)
        conversationLocalStore.fetchMLSConversationGroupID_MockValue = mlsOneOnOneConversation

        mlsService.establishGroupForWithRemovalKeys_MockValue = Scaffolding.ciphersuite
        mlsService.conversationExistsGroupID_MockValue = mlsConversationExists
        mlsService.joinGroupWith_MockMethod = { _ in }
    }

    private func setupConnection(status: ConnectionStatus) -> Connection {
        Connection(
            senderID: Scaffolding.senderID,
            receiverID: Scaffolding.receiverID,
            receiverQualifiedID: Scaffolding.receiverQualifiedID,
            conversationID: Scaffolding.conversationID,
            qualifiedConversationID: Scaffolding.qualifiedConversationID,
            lastUpdate: .now,
            status: status
        )
    }

    private enum Scaffolding {
        static let username = "username"
        static let senderID = UUID()
        static let receiverID = UUID()
        static let receiverQualifiedID = WireNetwork.QualifiedID(
            id: receiverID,
            domain: "domain.com"
        )
        static let conversationID = UUID()
        static let qualifiedConversationID = WireNetwork.QualifiedID(
            id: conversationID,
            domain: "domain.com"
        )

        static let base64EncodedString =
            "pQABARn//wKhAFggHsa0CszLXYLFcOzg8AA//E1+Dl1rDHQ5iuk44X0/PNYDoQChAFgg309rkhG6SglemG6kWae81P1HtQPx9lyb6wExTovhU4cE9g=="

        static let ciphersuite = WireDataModel.MLSCipherSuite.MLS_256_DHKEMP521_AES256GCM_SHA512_P521

        static let mlsGroupID = WireDataModel.MLSGroupID(
            base64Encoded: base64EncodedString
        )!

        static let mlsPublicKeys = WireNetwork.MLSPublicKeys(
            ed25519: .randomAlphanumerical(length: 5),
            p256: .randomAlphanumerical(length: 5),
            p384: .randomAlphanumerical(length: 5),
            p521: .randomAlphanumerical(length: 5)
        )

        static let defaultsSuiteName = UUID().uuidString
    }

}
