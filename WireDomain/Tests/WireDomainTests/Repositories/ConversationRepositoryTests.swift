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

import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import WireNetworkSupport
import XCTest
@testable import WireDomain
@testable import WireNetwork

final class ConversationRepositoryTests: XCTestCase {

    private var sut: ConversationRepository!
    private var conversationsAPI: MockConversationsAPI!
    private var conversationsLocalStore: MockConversationLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var teamRepository: MockTeamRepositoryProtocol!
    private var messageRepository: MockMessageRepositoryProtocol!
    private var mlsService: MockMLSServiceInterface!
    private var mlsProvider: MLSProvider!
    private var modelHelper: ModelHelper!

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        mlsService = MockMLSServiceInterface()
        mlsProvider = MLSProvider(service: mlsService, isMLSEnabled: true)
        userLocalStore = MockUserLocalStoreProtocol()
        teamRepository = MockTeamRepositoryProtocol()
        modelHelper = ModelHelper()
        conversationsLocalStore = MockConversationLocalStoreProtocol()
        conversationsAPI = MockConversationsAPI()
        messageRepository = MockMessageRepositoryProtocol()

        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()

        sut = ConversationRepository(
            conversationsAPI: conversationsAPI,
            conversationsLocalStore: conversationsLocalStore,
            userLocalStore: userLocalStore,
            teamRepository: teamRepository,
            messageRepository: messageRepository,
            localDomain: "example.com",
            isFederationEnabled: false,
            isMLSEnabled: true,
            mlsProvider: mlsProvider
        )
    }

    override func tearDown() async throws {
        userLocalStore = nil
        teamRepository = nil
        mlsProvider = nil
        mlsService = nil
        conversationsLocalStore = nil
        messageRepository = nil
        conversationsAPI = nil
        sut = nil
        modelHelper = nil
        stack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testPullMLSOneToOneConversation_It_Invokes_Local_Store_And_API_Methods() async throws {
        // Mock

        conversationsAPI.getMLSOneToOneConversationUserIDIn_MockValue = (
            Scaffolding.conversation,
            Scaffolding.mlsPublicKeys
        )
        conversationsLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }

        // When

        let (mlsGroupID, pubKeys) = try await sut.pullMLSOneToOneConversation(
            userID: Scaffolding.id.uuidString,
            userDomain: Scaffolding.domain
        )

        // Then

        XCTAssertEqual(mlsGroupID, Scaffolding.conversation.mlsGroupID)
        XCTAssertEqual(pubKeys, Scaffolding.mlsPublicKeys)
        XCTAssertEqual(conversationsAPI.getMLSOneToOneConversationUserIDIn_Invocations.count, 1)
        XCTAssertEqual(
            conversationsLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.count,
            1
        )
    }

    func testRemoveParticipantFromAllGroupConversations_It_Invokes_Local_Store_And_User_Repo_Methods() async throws {
        // Mock

        conversationsLocalStore
            .removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainDate_MockMethod = { _, _, _ in }

        // When

        try await sut.removeParticipantFromAllGroupConversations(
            participantID: Scaffolding.id,
            participantDomain: Scaffolding.domain,
            removedAt: .distantPast
        )

        // Then

        XCTAssertEqual(
            conversationsLocalStore
                .removeParticipantFromAllGroupConversationsParticipantIDParticipantDomainDate_Invocations.count,
            1
        )
    }

    func testPullConversation_It_Invokes_Local_Store_And_Conversation_API_Methods() async throws {
        // Mock

        conversationsAPI.getConversationsFor_MockValue = ConversationList(
            found: [Scaffolding.conversation],
            notFound: [],
            failed: []
        )

        conversationsLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }

        // When

        try await sut.pullConversation(
            id: Scaffolding.id,
            domain: Scaffolding.domain
        )

        // Then

        XCTAssertEqual(conversationsAPI.getConversationsFor_Invocations.count, 1)
        XCTAssertEqual(
            conversationsLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.count,
            1
        )
    }

    func testPullConversation_It_Throws_Error() async throws {
        // Mock

        conversationsAPI.getConversationsFor_MockValue = ConversationList(
            found: [],
            notFound: [],
            failed: []
        )

        do {
            // When
            try await sut.pullConversation(
                id: Scaffolding.id,
                domain: Scaffolding.domain
            )

            XCTFail("It should have failed")
        } catch {
            // Then
            XCTAssertTrue(error is ConversationRepositoryError)
        }
    }

    func testFetchConversation_It_Invokes_Local_Store_Method() async {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.id,
                domain: Scaffolding.domain,
                in: context
            )
        }

        conversationsLocalStore.fetchConversationIdDomain_MockValue = conversation

        // When

        let localConversation = await sut.fetchConversation(
            id: Scaffolding.id,
            domain: Scaffolding.domain
        )

        // Then

        XCTAssertEqual(conversation, localConversation)
        XCTAssertEqual(conversationsLocalStore.fetchConversationIdDomain_Invocations.count, 1)
    }

    func testDeleteMLSConversation_It_Invokes_Local_Store_Methods() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createMLSConversation(
                id: Scaffolding.id,
                domain: Scaffolding.domain,
                mlsGroupID: MLSGroupID(base64Encoded: Scaffolding.base64EncodedString),
                mlsStatus: .ready,
                conversationType: .group,
                epoch: 0,
                in: context
            )
        }

        conversationsLocalStore.mlsConversationInfoConversation_MockValue = (
            try XCTUnwrap(MLSGroupID(base64Encoded: Scaffolding.base64EncodedString)),
            true
        )
        conversationsLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationsLocalStore.wipeMLSGroupGroupID_MockMethod = { _ in }
        conversationsLocalStore.deleteConversation_MockMethod = { _ in }

        // When

        try await sut.deleteConversation(
            id: Scaffolding.id,
            domain: Scaffolding.domain
        )

        // Then

        XCTAssertEqual(conversationsLocalStore.mlsConversationInfoConversation_Invocations.count, 1)
        XCTAssertEqual(conversationsLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationsLocalStore.wipeMLSGroupGroupID_Invocations.count, 1)
        XCTAssertEqual(conversationsLocalStore.deleteConversation_Invocations.count, 1)
    }

    func testDeleteProteusConversation_It_Invokes_Local_Store_Methods() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.id,
                in: context
            )
        }

        conversationsLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationsLocalStore.mlsConversationInfoConversation_MockValue = (
            try XCTUnwrap(MLSGroupID(base64Encoded: Scaffolding.base64EncodedString)),
            false
        )
        conversationsLocalStore.deleteConversation_MockMethod = { _ in }
        conversationsLocalStore.wipeMLSGroupGroupID_MockMethod = { _ in }

        // When

        try await sut.deleteConversation(
            id: Scaffolding.id,
            domain: Scaffolding.domain
        )

        // Then

        XCTAssertEqual(conversationsLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationsLocalStore.mlsConversationInfoConversation_Invocations.count, 1)
        XCTAssertEqual(conversationsLocalStore.deleteConversation_Invocations.count, 1)
        XCTAssertEqual(conversationsLocalStore.wipeMLSGroupGroupID_Invocations.count, 1)
    }

    func testStoreConversation_It_Invokes_Local_Store_Method() async {
        // Mock

        conversationsLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }

        // When

        await sut.storeConversation(
            Scaffolding.conversation.toDomainModel(),
            timestamp: .now
        )

        // Then

        XCTAssertEqual(
            conversationsLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.count,
            1
        )
    }

    func testRemoveMembers_It_Invokes_Local_Store_User_Repo_Team_Repo_And_MLS_Service_Methods() async throws {
        // Mock

        let (conversation, selfUser, senderUser, removedUser) = await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(id: Scaffolding.id, in: context)
            let senderUser = modelHelper.createUser(id: Scaffolding.id, in: context)
            let removedUser = modelHelper.createUser(id: Scaffolding.id, in: context)
            let mlsGroupID = MLSGroupID(base64Encoded: Scaffolding.base64EncodedString)

            let mlsConversation = modelHelper.createMLSConversation(
                id: Scaffolding.id,
                mlsGroupID: mlsGroupID,
                with: [senderUser, selfUser, removedUser],
                in: context
            )

            return (mlsConversation, selfUser, senderUser, removedUser)
        }

        conversationsLocalStore.messageProtocolFor_MockValue = .mls
        messageRepository
            .addSystemMessageMessageTypeConversationIDConversationDomain_MockMethod = { _, _, _ in }
        conversationsLocalStore.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationsLocalStore.localParticipantsIn_MockValue = [selfUser, senderUser, removedUser]
        conversationsLocalStore
            .removeParticipantsAndUpdateConversationStateConversationUsersInitiatingUser_MockMethod = { _, _, _ in }
        conversationsLocalStore.mlsConversationInfoConversation_MockValue = (
            try XCTUnwrap(MLSGroupID(base64Encoded: Scaffolding.base64EncodedString)),
            true
        )
        userLocalStore.fetchOrCreateUserIdDomain_MockValue = removedUser
        userLocalStore.fetchUserIdDomain_MockValue = senderUser
        userLocalStore.isSelfUserIdDomain_MockValue = (user: selfUser, isSelfUser: true)
        mlsService.wipeGroup_MockMethod = { _ in }
        messageRepository
            .addSystemMessageMessageTypeConversationIDConversationDomain_MockMethod = { _, _, _ in }
        teamRepository.deleteMembershipUserIDDomainDate_MockMethod = { _, _, _ in }

        // When

        try await sut.removeMembers(
            Set([.init(id: Scaffolding.id, domain: Scaffolding.domain)]),
            from: .init(id: Scaffolding.id, domain: Scaffolding.domain),
            initiatedBy: .init(id: Scaffolding.id, domain: Scaffolding.domain),
            at: .now,
            reason: .userDeleted
        )

        // Then

        XCTAssertEqual(conversationsLocalStore.messageProtocolFor_Invocations.count, 1)
        XCTAssertEqual(
            messageRepository.addSystemMessageMessageTypeConversationIDConversationDomain_Invocations.count,
            1
        )
        XCTAssertEqual(conversationsLocalStore.fetchOrCreateConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationsLocalStore.localParticipantsIn_Invocations.count, 1)
        XCTAssertEqual(
            conversationsLocalStore
                .removeParticipantsAndUpdateConversationStateConversationUsersInitiatingUser_Invocations.count,
            1
        )
        XCTAssertEqual(conversationsLocalStore.mlsConversationInfoConversation_Invocations.count, 1)
        XCTAssertEqual(mlsService.wipeGroup_Invocations.count, 1)
        XCTAssertEqual(userLocalStore.fetchOrCreateUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(userLocalStore.fetchUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(userLocalStore.isSelfUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(teamRepository.deleteMembershipUserIDDomainDate_Invocations.count, 1)
    }

    func testAddOrUpdateParticipant_It_Invokes_Local_Store_And_User_Repo_Methods() async {
        // Mock

        let (updatedUser, conversation) = await context.perform { [self] in
            let updatedUser = modelHelper.createUser(id: Scaffolding.id, in: context)

            let conversation = modelHelper.createGroupConversation(
                id: Scaffolding.id,
                with: [updatedUser],
                in: context
            )

            return (updatedUser, conversation)
        }

        conversationsLocalStore.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationsLocalStore.addOrUpdateParticipantWithRoleIn_MockMethod = { _, _, _ in }
        userLocalStore.fetchOrCreateUserIdDomain_MockValue = updatedUser

        // When

        await sut.addOrUpdateParticipant(
            participantID: UUID(),
            participantDomain: nil,
            participantRole: ZMConversation.defaultAdminRoleName,
            conversationID: Scaffolding.id,
            conversationDomain: nil
        )

        // Then

        XCTAssertEqual(conversationsLocalStore.fetchOrCreateConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationsLocalStore.addOrUpdateParticipantWithRoleIn_Invocations.count, 1)
        XCTAssertEqual(userLocalStore.fetchOrCreateUserIdDomain_Invocations.count, 1)
    }

    func testAddParticipants_It_Invokes_Local_Store_Methods() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            return modelHelper.createGroupConversation(
                id: Scaffolding.id,
                domain: Scaffolding.domain,
                in: context
            )
        }

        conversationsLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationsLocalStore.addParticipantsAddedByAtDateConversation_MockMethod = { _, _, _, _ in }

        // When

        try await sut.addParticipants(
            [(
                Scaffolding.id,
                Scaffolding.domain,
                ZMConversation.defaultMemberRoleName
            )],
            sender: (Scaffolding.id, Scaffolding.domain),
            date: .distantPast,
            conversationID: Scaffolding.id,
            conversationDomain: Scaffolding.domain
        )

        // Then

        XCTAssertEqual(conversationsLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationsLocalStore.addParticipantsAddedByAtDateConversation_Invocations.count, 1)
    }

    func testFetchConversationGuestLink_It_Invokes_Conversation_API_Method() async throws {

        // Mock

        conversationsAPI.getConversationGuestLinkConversationID_MockValue = Scaffolding.guestLink

        // When

        let guestLink = try await sut.fetchConversationGuestLink(
            conversationID: Scaffolding.id.uuidString
        )

        // Then

        XCTAssertEqual(conversationsAPI.getConversationGuestLinkConversationID_Invocations.count, 1)
        XCTAssertEqual(guestLink, Scaffolding.guestLink)

    }

    func testFetchConversationGuestLink_It_Throws_Error() async throws {

        // Mock

        enum MockAPIError: Error {
            case error
        }

        conversationsAPI.getConversationGuestLinkConversationID_MockError = MockAPIError.error

        // Then
        await XCTAssertThrowsErrorAsync {
            // When
            try await sut.fetchConversationGuestLink(
                conversationID: Scaffolding.id.uuidString
            )
        }
    }

    private enum Scaffolding {

        static let id = UUID.mockID1

        static let domain = "domain.com"
        static let guestLink = "https://www.example.com"

        static let conversation = Conversation(
            id: id,
            qualifiedID: .init(id: id, domain: domain),
            teamID: id,
            type: .group,
            messageProtocol: .proteus,
            mlsGroupID: "",
            cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
            epoch: 0,
            epochTimestamp: nil,
            creator: id,
            members: nil,
            name: nil,
            messageTimer: 0,
            readReceiptMode: 0,
            access: [.invite],
            accessRoles: [.teamMember],
            legacyAccessRole: .team,
            lastEvent: "",
            lastEventTime: nil
        )

        static let base64EncodedString =
            "pQABARn//wKhAFggHsa0CszLXYLFcOzg8AA//E1+Dl1rDHQ5iuk44X0/PNYDoQChAFgg309rkhG6SglemG6kWae81P1HtQPx9lyb6wExTovhU4cE9g=="

        static let mlsPublicKeys = WireNetwork.MLSPublicKeys(
            ed25519: .randomAlphanumerical(length: 5),
            p256: .randomAlphanumerical(length: 5),
            p384: .randomAlphanumerical(length: 5),
            p521: .randomAlphanumerical(length: 5)
        )
    }

}
