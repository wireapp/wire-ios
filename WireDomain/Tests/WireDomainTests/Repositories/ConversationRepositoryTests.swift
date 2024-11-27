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

import WireAPISupport
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import XCTest
@testable import WireAPI
@testable import WireDomain

final class ConversationRepositoryTests: XCTestCase {

    private var sut: ConversationRepository!
    private var conversationsAPI: MockConversationsAPI!
    private var conversationsLocalStore: ConversationLocalStoreProtocol!
    private var userRepository: MockUserRepositoryProtocol!
    private let backendInfo: ConversationRepository.BackendInfo = .init(
        domain: "example.com",
        isFederationEnabled: false,
        isMLSEnabled: true
    )

    private var teamRepository: MockTeamRepositoryProtocol!
    private var messageRepository: MockMessageRepositoryProtocol!
    private var mlsService: MockMLSServiceInterface!
    private var mlsProvider: MLSProvider!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var messageLocalStore: MockMessageLocalStoreProtocol!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        mlsService = MockMLSServiceInterface()
        mlsProvider = MLSProvider(service: mlsService, isMLSEnabled: true)
        userRepository = MockUserRepositoryProtocol()
        teamRepository = MockTeamRepositoryProtocol()
        messageRepository = MockMessageRepositoryProtocol()
        coreDataStackHelper = CoreDataStackHelper()
        userLocalStore = MockUserLocalStoreProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        conversationsLocalStore = ConversationLocalStore(
            context: context,
            mlsService: mlsService,
            userLocalStore: userLocalStore,
            messageLocalStore: messageLocalStore
        )
        conversationsAPI = MockConversationsAPI()
        userRepository = MockUserRepositoryProtocol()

        sut = ConversationRepository(
            conversationsAPI: conversationsAPI,
            conversationsLocalStore: conversationsLocalStore,
            userRepository: userRepository,
            teamRepository: teamRepository,
            messageRepository: messageRepository,
            backendInfo: backendInfo,
            mlsProvider: mlsProvider
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        userRepository = nil
        teamRepository = nil
        mlsProvider = nil
        mlsService = nil
        conversationsLocalStore = nil
        stack = nil
        conversationsAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
        userLocalStore = nil
        messageRepository = nil
        messageLocalStore = nil
    }

    // MARK: - Tests

    func testPullConversations_Found_And_Failed_Conversations_Are_Stored_Locally() async throws {
        // Given
        let uuids = Scaffolding.conversationList.found.compactMap(\.id) + Scaffolding.conversationList.failed
            .map(\.uuid)

        await context.perform { [context] in
            // There are no conversations in the database.

            let conversations = ZMConversation.fetchObjects(
                withRemoteIdentifiers: Set(uuids),
                in: context
            ) as! Set<ZMConversation>

            XCTAssertEqual(conversations.count, 0)
        }

        // Mock

        mockConversationsAPI()

        // When
        try await sut.pullConversations()

        // Then
        await context.perform { [context] in

            let conversations = ZMConversation.fetchObjects(
                withRemoteIdentifiers: Set(uuids),
                in: context
            ) as! Set<ZMConversation>

            XCTAssertEqual(conversations.count, uuids.count)

            for conversation in conversations {
                XCTAssert(uuids.contains(conversation.remoteIdentifier))
            }
        }
    }

    func testPullConversations_Found_Conversations_Pending_MetadataRefresh_And_Initial_Fetch_Are_False() async throws {
        // Given
        let uuids = Scaffolding.conversationList.found.compactMap(\.id)

        await context.perform { [context] in
            // There are no conversations in the database.

            let conversations = ZMConversation.fetchObjects(
                withRemoteIdentifiers: Set(uuids),
                in: context
            ) as! Set<ZMConversation>

            XCTAssertEqual(conversations.count, 0)
        }

        // Mock

        mockConversationsAPI()

        // When
        try await sut.pullConversations()

        // Then
        await context.perform { [context] in
            let conversations = ZMConversation.fetchObjects(
                withRemoteIdentifiers: Set(uuids),
                in: context
            ) as! Set<ZMConversation>

            XCTAssertEqual(conversations.count, uuids.count)

            for conversation in conversations {
                XCTAssertEqual(conversation.isPendingMetadataRefresh, false)
                XCTAssertEqual(conversation.isPendingInitialFetch, false)
            }
        }
    }

    func testPullConversations_Failed_Conversations_Needs_To_Be_Updated_From_Backend_And_Pending_MetataRefresh_Are_True(
    ) async throws {
        // Given
        let failedUuids = Scaffolding.conversationList.failed.map(\.uuid)

        await context.perform {
            // There are no conversations in the database.
            let uuids = Scaffolding.conversationList.found.compactMap(\.id) + failedUuids

            let conversations = self.fetchConversations(withIds: uuids)

            XCTAssertEqual(conversations.count, 0)

            for conversation in conversations {
                XCTAssertEqual(conversation.isPendingMetadataRefresh, false)
                XCTAssertEqual(conversation.needsToBeUpdatedFromBackend, false)
            }
        }

        // Mock

        mockConversationsAPI()

        // When
        try await sut.pullConversations()

        // Then
        await context.perform {
            let conversations = self.fetchConversations(withIds: failedUuids)
            XCTAssertEqual(conversations.count, failedUuids.count)

            for conversation in conversations {
                XCTAssertEqual(conversation.isPendingMetadataRefresh, true)
                XCTAssertEqual(conversation.needsToBeUpdatedFromBackend, true)
            }
        }
    }

    func testPullConversations_Not_Found_Conversations_Needs_To_Be_Updated_From_Backend_Is_True() async throws {
        // Given

        let uuids = Scaffolding.conversationList.notFound.map(\.uuid)

        await context.perform { [context] in
            // We already have conversations in the database.

            for uuid in uuids {
                _ = ZMConversation.fetchOrCreate(
                    with: uuid,
                    domain: self.backendInfo.domain,
                    in: context
                )
            }

            let conversations = self.fetchConversations(withIds: uuids)

            for conversation in conversations {
                XCTAssertEqual(conversation.needsToBeUpdatedFromBackend, false)
            }
        }

        // Mock

        mockConversationsAPI()

        // When
        try await sut.pullConversations()

        // Then
        await context.perform { [self] in
            let conversations = fetchConversations(withIds: uuids)

            for conversation in conversations {
                XCTAssertEqual(conversation.needsToBeUpdatedFromBackend, true)
            }
        }
    }

    func testGetMLSOneToOneConversation() async throws {
        // Mock

        mockConversationsAPI()

        // When

        let mlsGroupID = try await sut.pullMLSOneToOneConversation(
            userID: Scaffolding.userID.uuidString,
            userDomain: Scaffolding.domain
        )

        let mlsConversation = await sut.fetchMLSConversation(groupID: mlsGroupID)

        // Then

        await context.perform {
            XCTAssertEqual(mlsConversation?.remoteIdentifier, Scaffolding.conversationOneOnOneType.id)
        }
    }

    func testRemoveParticipantFromConversation_It_Removes_Participant() async throws {
        // Mock

        let (removedUser, remainingUsers, conversation) = await context.perform { [self] in
            let user1 = modelHelper.createUser(in: context)
            let user2 = modelHelper.createUser(in: context)
            let user3 = modelHelper.createUser(in: context)
            let removedUser = modelHelper.createUser(id: Scaffolding.userID, in: context)

            let conversation = modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                with: [removedUser, user1, user2, user3],
                in: context
            )

            return (removedUser, [user1, user2, user3], conversation)
        }

        userLocalStore.fetchUserIdDomain_MockValue = removedUser
        messageLocalStore
            .addSystemMessageToConversationMessageTypeConversationIDConversationDomain_MockMethod = { _, _, _ in }

        // When

        try await sut.removeParticipantFromAllGroupConversations(
            participantID: Scaffolding.userID,
            participantDomain: nil,
            removedAt: .now
        )

        // Then

        await context.perform {
            XCTAssertEqual(conversation.localParticipants, Set(remainingUsers))
            XCTAssertEqual(conversation.localParticipants.contains(removedUser), false)
        }
    }

    func testPullConversation_It_Retrieves_Conversation_Locally() async throws {
        // Mock

        let conversationID = try XCTUnwrap(Scaffolding.conversationGroupType.qualifiedID)

        conversationsAPI.getConversationsFor_MockValue = ConversationList(
            found: [Scaffolding.conversationGroupType],
            notFound: [],
            failed: []
        )

        // When

        try await sut.pullConversation(
            id: conversationID.uuid,
            domain: conversationID.domain
        )

        // Then

        await context.perform { [context] in
            let localConversation = ZMConversation.fetch(
                with: conversationID.uuid,
                domain: conversationID.domain,
                in: context
            )

            XCTAssertNotNil(localConversation)
            XCTAssertEqual(localConversation?.remoteIdentifier, conversationID.uuid)
        }
    }

    func testPullConversation_It_Throws_Error() async throws {
        // Mock

        let conversationID = try XCTUnwrap(Scaffolding.conversationGroupType.qualifiedID)

        conversationsAPI.getConversationsFor_MockValue = ConversationList(
            found: [],
            notFound: [],
            failed: []
        )

        do {
            // When
            try await sut.pullConversation(
                id: conversationID.uuid,
                domain: conversationID.domain
            )

            XCTFail("it should have failed")
        } catch {
            // Then
            XCTAssertTrue(error is ConversationRepositoryError)
        }
    }

    func testAddOrUpdateParticipant_It_Adds_Participant_To_Conversation() async {
        // Mock

        let (addedUser, conversation) = await context.perform { [self] in
            let user1 = modelHelper.createUser(in: context)
            let user2 = modelHelper.createUser(in: context)
            let user3 = modelHelper.createUser(in: context)
            let addedUser = modelHelper.createUser(id: Scaffolding.userID, in: context)

            let conversation = modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                with: [user1, user2, user3],
                in: context
            )

            return (addedUser, conversation)
        }

        userRepository.fetchOrCreateUserIdDomain_MockValue = addedUser

        // When

        await sut.addOrUpdateParticipant(
            participantID: UUID(),
            participantDomain: nil,
            participantRole: "",
            conversationID: Scaffolding.conversationID,
            conversationDomain: nil
        )

        // Then

        await context.perform {
            XCTAssertEqual(conversation.localParticipants.contains(addedUser), true)
        }
    }

    func testFetchConversation_It_Retrieves_Conversation_Locally() async {
        // Given

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                domain: Scaffolding.domain,
                in: context
            )
        }

        // When

        let localConversation = await sut.fetchConversation(
            id: Scaffolding.conversationID,
            domain: Scaffolding.domain
        )

        // Then

        XCTAssertEqual(conversation, localConversation)
    }

    func testDeleteMLSConversation_It_Wipes_MLS_Group_And_Marks_MLS_Conversation_As_Deleted_Locally() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createMLSConversation(
                id: Scaffolding.conversationID,
                domain: Scaffolding.domain,
                mlsGroupID: MLSGroupID(base64Encoded: Scaffolding.base64EncodedString),
                mlsStatus: .ready,
                conversationType: .group,
                epoch: 0,
                in: context
            )
        }

        mlsService.wipeGroup_MockMethod = { _ in }

        // When

        try await sut.deleteConversation(
            id: Scaffolding.conversationID,
            domain: Scaffolding.domain
        )

        // Then

        let isDeletedRemotely = await context.perform {
            conversation.isDeletedRemotely
        }

        XCTAssertEqual(mlsService.wipeGroup_Invocations.count, 1)
        XCTAssertEqual(isDeletedRemotely, true)
    }

    func testDeleteProteusConversation_It_Marks_Conversation_As_Deleted_Remotely() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                in: context
            )
        }

        // When

        try await sut.deleteConversation(
            id: Scaffolding.conversationID,
            domain: Scaffolding.domain
        )

        // Then

        let isDeletedRemotely = await context.perform {
            conversation.isDeletedRemotely
        }

        XCTAssertEqual(isDeletedRemotely, true)
    }

    func testStoreConversation_It_Stores_Conversation_Locally() async throws {
        // Given

        let groupConversation = Scaffolding.conversationGroupType
        let id = try XCTUnwrap(groupConversation.qualifiedID?.uuid)
        let domain = try XCTUnwrap(groupConversation.qualifiedID?.domain)

        // When

        await sut.storeConversation(Scaffolding.conversationGroupType, timestamp: .now)

        // Then

        let localConversation = await sut.fetchConversation(
            id: id,
            domain: domain
        )

        await context.perform {
            XCTAssertEqual(localConversation?.remoteIdentifier, id)
            XCTAssertEqual(localConversation?.teamRemoteIdentifier, groupConversation.teamID)
            XCTAssertEqual(localConversation?.conversationType, .group)
            XCTAssertEqual(localConversation?.messageProtocol, .proteus)
            XCTAssertEqual(localConversation?.epoch, 0)
            XCTAssertEqual(localConversation?.hasReadReceiptsEnabled, false)
            XCTAssertEqual(localConversation?.accessMode, [.invite])
            XCTAssertEqual(localConversation?.accessRoles, [.teamMember])
        }
    }

    func testRemoveMembers() async throws {
        // Mock

        let removedMembersIDs = [UserID(uuid: Scaffolding.otherUserID, domain: Scaffolding.domain)]
        let conversationID = ConversationID(uuid: Scaffolding.conversationID, domain: Scaffolding.domain)
        let sender = UserID(uuid: Scaffolding.userID, domain: Scaffolding.domain)

        let (conversation, selfUser, senderUser, removedUser) = await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(id: Scaffolding.selfUserId, in: context)
            let senderUser = modelHelper.createUser(id: Scaffolding.userID, in: context)
            let removedUser = modelHelper.createUser(id: Scaffolding.otherUserID, in: context)
            let mlsGroupID = MLSGroupID(base64Encoded: Scaffolding.base64EncodedString)

            let mlsConversation = modelHelper.createMLSConversation(
                id: Scaffolding.conversationID,
                mlsGroupID: mlsGroupID,
                with: [senderUser, selfUser, removedUser],
                in: context
            )

            return (mlsConversation, selfUser, senderUser, removedUser)
        }

        userRepository.fetchOrCreateUserIdDomain_MockValue = removedUser
        userRepository.fetchUserIdDomain_MockValue = senderUser
        userRepository.isSelfUserIdDomain_MockValue = true
        mlsService.wipeGroup_MockMethod = { _ in }
        messageRepository
            .addMessageToConversationMessageTypeConversationIDConversationDomain_MockMethod = { _, _, _ in }
        teamRepository.deleteMembershipUserIDDomainDate_MockMethod = { _, _, _ in }

        // When

        try await sut.removeMembers(
            Set(removedMembersIDs),
            from: conversationID,
            initiatedBy: sender,
            at: .now,
            reason: .userDeleted
        )

        // Then

        XCTAssertEqual(mlsService.wipeGroup_Invocations.count, 1)
        XCTAssertEqual(userRepository.fetchOrCreateUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(userRepository.fetchUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(userRepository.isSelfUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(
            messageRepository.addMessageToConversationMessageTypeConversationIDConversationDomain_Invocations.count,
            1
        )
        XCTAssertEqual(teamRepository.deleteMembershipUserIDDomainDate_Invocations.count, 1)

        let newParticipants = await context.perform {
            conversation.localParticipants
        }

        await context.perform {
            XCTAssertEqual(newParticipants, [selfUser, senderUser])
            XCTAssertFalse(newParticipants.contains(removedUser)) // user was successfuly removed from conversation
        }
    }

    func testAddOrUpdateParticipant_It_Updates_Participant_Role_In_Conversation() async throws {
        // Mock

        let (updatedUser, conversation) = await context.perform { [self] in
            let updatedUser = modelHelper.createUser(id: Scaffolding.userID, in: context)

            let conversation = modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                with: [updatedUser],
                in: context
            )

            return (updatedUser, conversation)
        }

        userRepository.fetchOrCreateUserIdDomain_MockValue = updatedUser

        // When

        await sut.addOrUpdateParticipant(
            participantID: UUID(),
            participantDomain: nil,
            participantRole: ZMConversation.defaultAdminRoleName,
            conversationID: Scaffolding.conversationID,
            conversationDomain: nil
        )

        // Then

        try await context.perform {
            let role = try XCTUnwrap(updatedUser.role(in: conversation))
            XCTAssertEqual(role.name, ZMConversation.defaultAdminRoleName)
        }
    }

    func testAddParticipants_It_Adds_Participants_To_Conversation() async throws {
        // Mock

        let (conversation, sender, addedUser) = await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                domain: Scaffolding.domain,
                in: context
            )

            let addedUser = modelHelper.createUser(
                qualifiedID: .init(uuid: Scaffolding.otherUserID, domain: Scaffolding.domain),
                in: context
            )

            let sender = modelHelper.createUser(
                qualifiedID: .init(uuid: Scaffolding.userID, domain: Scaffolding.domain),
                in: context
            )

            return (conversation, sender, addedUser)
        }

        userLocalStore.fetchOrCreateUserIdDomain_MockValue = addedUser
        messageLocalStore
            .addSystemMessageToConversationMessageTypeConversationIDConversationDomain_MockMethod = { _, _, _ in }

        // When

        try await sut.addParticipants(
            [(
                Scaffolding.otherUserID,
                Scaffolding.domain,
                ZMConversation.defaultMemberRoleName
            )],
            sender: (Scaffolding.userID, Scaffolding.domain),
            date: .distantPast,
            conversationID: Scaffolding.conversationID,
            conversationDomain: Scaffolding.domain
        )

        // Then

        XCTAssertEqual(userLocalStore.fetchOrCreateUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(
            messageLocalStore.addSystemMessageToConversationMessageTypeConversationIDConversationDomain_Invocations
                .count,
            1
        )

        await context.perform {
            XCTAssertTrue(conversation.localParticipants.contains(addedUser))
        }
    }

    func testUpdateConversationName() async {

        // Mock

        let newConversationName = "new"

        let conversation = await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                domain: Scaffolding.domain,
                in: context
            )
            conversation.userDefinedName = "old"

            return conversation
        }

        messageRepository
            .addMessageToConversationMessageTypeConversationIDConversationDomain_MockMethod = { _, _, _ in }

        // When

        await sut.updateConversationName(
            newName: newConversationName,
            conversationID: Scaffolding.conversationID,
            conversationDomain: Scaffolding.domain,
            senderID: Scaffolding.userID,
            senderDomain: Scaffolding.domain,
            date: .now
        )

        // Then

        XCTAssertEqual(
            messageRepository.addMessageToConversationMessageTypeConversationIDConversationDomain_Invocations.count,
            1
        )

        await context.perform {
            XCTAssertEqual(conversation.userDefinedName, newConversationName)
        }
    }

    func testFetchConversationGuestLink_It_Invokes_Conversation_API_Method() async throws {

        // Mock

        conversationsAPI.getConversationGuestLinkConversationID_MockValue = Scaffolding.guestLink

        // When

        let guestLink = try await sut.fetchConversationGuestLink(
            conversationID: Scaffolding.conversationID.uuidString
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
                conversationID: Scaffolding.conversationID.uuidString
            )
        }
    }

    private enum Scaffolding {
        static let teamID = UUID()
        static let userID = UUID()
        static let otherUserID = UUID()
        static let time = "2021-05-12T10:52:02.671Z"
        static let teamConversationID = UUID()
        static let anotherTeamConversationID = UUID()
        static let conversationID = UUID()
        static let domain = "domain.com"
        static let guestLink = "https://www.example.com"

        static func date(from string: String) -> Date {
            ISO8601DateFormatter.fractionalInternetDateTime.date(from: string)!
        }

        static let conversationList = ConversationList(
            found: [
                conversationSelfType,
                conversationGroupType,
                conversationConnectionType,
                conversationOneOnOneType
            ],
            notFound: [conversationNotFound],
            failed: [conversationFailed]
        )

        static let conversationListError = ConversationList(
            found: [
                conversationSelfTypeMissingId,
                conversationGroupType,
                conversationConnectionType,
                conversationOneOnOneType
            ],
            notFound: [conversationNotFound],
            failed: [conversationFailed]
        )

        static let conversationSelfType = Conversation(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            qualifiedID: .init(uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!, domain: "example.com"),
            teamID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            type: .`self`,
            messageProtocol: .proteus,
            mlsGroupID: "",
            cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
            epoch: 0,
            epochTimestamp: nil,
            creator: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            members: nil,
            name: "Test",
            messageTimer: 0,
            readReceiptMode: 0,
            access: [.invite],
            accessRoles: [.teamMember],
            legacyAccessRole: .team,
            lastEvent: "",
            lastEventTime: nil
        )

        static let conversationSelfTypeMissingId = Conversation(
            id: nil,
            qualifiedID: nil,
            teamID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            type: .`self`,
            messageProtocol: .proteus,
            mlsGroupID: "",
            cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
            epoch: 0,
            epochTimestamp: nil,
            creator: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
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

        static let conversationConnectionType = Conversation(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ac")!,
            qualifiedID: .init(uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ac")!, domain: "example.com"),
            teamID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ac")!,
            type: .connection,
            messageProtocol: .proteus,
            mlsGroupID: "",
            cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
            epoch: 0,
            epochTimestamp: nil,
            creator: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ac")!,
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

        static let conversationGroupType = Conversation(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!,
            qualifiedID: .init(uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!, domain: "example.com"),
            teamID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!,
            type: .group,
            messageProtocol: .proteus,
            mlsGroupID: "",
            cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
            epoch: 0,
            epochTimestamp: nil,
            creator: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!,
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

        static let conversationOneOnOneType = Conversation(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ae")!,
            qualifiedID: .init(uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ae")!, domain: "example.com"),
            teamID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ae")!,
            type: .oneOnOne,
            messageProtocol: .proteus,
            mlsGroupID: base64EncodedString,
            cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
            epoch: 0,
            epochTimestamp: nil,
            creator: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ae")!,
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

        static let conversationNotFound = WireAPI.QualifiedID(
            uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4aa")!,
            domain: "example.com"
        )

        static let conversationFailed = WireAPI.QualifiedID(
            uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4af")!,
            domain: "example.com"
        )

        static let selfUserId = UUID()
    }

}

extension ConversationRepositoryTests {

    private func fetchConversations(withIds ids: [UUID]) -> Set<ZMConversation> {
        ZMConversation.fetchObjects(
            withRemoteIdentifiers: Set(ids),
            in: context
        ) as! Set<ZMConversation>
    }

    private func mockSelfUser() -> ZMUser {
        let selfUser = ZMUser.selfUser(in: context)
        selfUser.remoteIdentifier = Scaffolding.selfUserId
        selfUser.domain = backendInfo.domain

        let client = UserClient.insertNewObject(in: context)
        client.remoteIdentifier = UUID().uuidString
        client.user = selfUser
        context.saveOrRollback()

        return selfUser
    }

    private func mockConversationsAPI(conversationList: WireAPI.ConversationList = Scaffolding.conversationList) {
        conversationsAPI.getLegacyConversationIdentifiers_MockValue = .init(fetchPage: { _ in
            .init(
                element: [Scaffolding.conversationSelfType.id!],
                hasMore: false,
                nextStart: .init()
            )
        })

        conversationsAPI.getConversationIdentifiers_MockValue = .init(fetchPage: { _ in
            .init(
                element: [Scaffolding.conversationSelfType.qualifiedID!],
                hasMore: false,
                nextStart: .init()
            )
        })

        conversationsAPI.getConversationsFor_MockValue = .init(
            found: conversationList.found,
            notFound: conversationList.notFound,
            failed: conversationList.failed
        )

        conversationsAPI.getMLSOneToOneConversationUserIDIn_MockValue = Scaffolding.conversationOneOnOneType
    }

}
