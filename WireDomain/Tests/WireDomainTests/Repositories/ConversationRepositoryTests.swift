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

@testable import WireAPI
import WireAPISupport
import WireDataModel
import WireDataModelSupport
@testable import WireDomain
import XCTest

final class ConversationRepositoryTests: XCTestCase {

    private var sut: ConversationRepository!
    private var conversationsAPI: MockConversationsAPI!
    private var conversationsLocalStore: ConversationLocalStoreProtocol!
    private let backendInfo: ConversationRepository.BackendInfo = .init(
        domain: "example.com",
        isFederationEnabled: false
    )
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        conversationsLocalStore = ConversationLocalStore(
            context: context,
            mlsService: MockMLSServiceInterface()
        )
        conversationsAPI = MockConversationsAPI()

        sut = ConversationRepository(
            conversationsAPI: conversationsAPI,
            conversationsLocalStore: conversationsLocalStore,
            backendInfo: backendInfo
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        conversationsLocalStore = nil
        stack = nil
        conversationsAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testPullConversations_Found_And_Failed_Conversations_Are_Stored_Locally() async throws {
        // Given
        let uuids = Scaffolding.conversationList.found.compactMap(\.id) + Scaffolding.conversationList.failed.map(\.uuid)

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

    func testPullConversations_Failed_Conversations_Needs_To_Be_Updated_From_Backend_And_Pending_MetataRefresh_Are_True() async throws {
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
            domain: Scaffolding.domain
        )

        let mlsConversation = await sut.fetchMLSConversation(with: mlsGroupID)

        // Then

        XCTAssertEqual(mlsConversation?.remoteIdentifier, Scaffolding.conversationOneOnOneType.id)
    }

    func testRemoveFromConversations_It_Appends_A_System_Message_To_All_Team_Conversations_When_A_Member_Leave() async throws {
        // Given

        let user = try await context.perform { [self] in
            let (team, users, _) = modelHelper.createTeam(
                id: Scaffolding.teamID,
                withMembers: [Scaffolding.userID],
                inGroupConversation: Scaffolding.teamConversationID,
                context: context
            )

            modelHelper.createGroupConversation(
                id: Scaffolding.anotherTeamConversationID,
                with: users,
                team: team,
                domain: nil,
                in: context
            )

            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                with: Set(users),
                domain: nil,
                in: context
            )

            let user = try XCTUnwrap(users.first)
            let member = try XCTUnwrap(team.members.first)
            XCTAssertEqual(user.membership, member)

            return user
        }

        let timestamp = Scaffolding.date(from: Scaffolding.time)

        // When

        await sut.removeFromConversations(user: user, removalDate: timestamp)

        // Then

        try await context.perform { [self] in

            let user = try XCTUnwrap(ZMUser.fetch(with: Scaffolding.userID, in: context), "No User")
            XCTAssertNotNil(Team.fetch(with: Scaffolding.teamID, in: context))

            let teamConversation = try XCTUnwrap(ZMConversation.fetch(with: Scaffolding.teamConversationID, in: context), "No Team Conversation")

            let teamAnotherConversation = try XCTUnwrap(ZMConversation.fetch(with: Scaffolding.anotherTeamConversationID, in: context), "No Team Conversation")

            let conversation = try XCTUnwrap(ZMConversation.fetch(with: Scaffolding.conversationID, in: context), "No Conversation")

            try internalTest_checkLastMessage(
                in: teamConversation,
                messageType: .teamMemberLeave,
                at: timestamp
            )

            try internalTest_checkLastMessage(
                in: teamAnotherConversation,
                messageType: .teamMemberLeave,
                at: timestamp
            )

            let lastMessage = try XCTUnwrap(conversation.lastMessage as? ZMSystemMessage)
            XCTAssertNotEqual(lastMessage.systemMessageType, .teamMemberLeave, "Should not append leave message to regular conversation")
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
            with: Scaffolding.conversationID,
            domain: Scaffolding.domain
        )

        // Then

        XCTAssertEqual(conversation, localConversation)
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

        try await sut.pullConversation(with: conversationID)

        // Then

        let storedConversation = await sut.fetchConversation(
            with: conversationID.uuid,
            domain: conversationID.domain
        )

        XCTAssertEqual(storedConversation?.remoteIdentifier, conversationID.uuid)
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
            try await sut.pullConversation(with: conversationID)
        } catch {
            // Then
            XCTAssertTrue(error is ConversationRepositoryError)
        }
    }

    func testAddSystemMessage_It_Adds_System_Message_To_Conversation() async throws {
        // Mock

        let (conversation, user) = await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                domain: Scaffolding.domain,
                in: context
            )

            let user = modelHelper.createUser(in: context)

            return (conversation, user)
        }

        let timestamp = Scaffolding.date(from: Scaffolding.time)

        let systemMessage = SystemMessage(
            type: .participantsAdded,
            sender: user,
            timestamp: timestamp
        )

        // When

        await sut.addSystemMessage(systemMessage, to: conversation)

        // Then

        try internalTest_checkLastMessage(
            in: conversation,
            messageType: .participantsAdded,
            at: timestamp
        )
    }

    private func internalTest_checkLastMessage(
        in conversation: ZMConversation,
        messageType: ZMSystemMessageType,
        at timestamp: Date
    ) throws {
        let lastMessage = try XCTUnwrap(
            conversation.lastMessage as? ZMSystemMessage,
            "Last message is not system message"
        )

        XCTAssertEqual(
            lastMessage.systemMessageType,
            messageType, "System message is not \(messageType.rawValue): but '\(lastMessage.systemMessageType.rawValue)"
        )

        let serverTimeStamp = try XCTUnwrap(
            lastMessage.serverTimestamp, "System message should have timestamp"
        )

        XCTAssertEqual(
            serverTimeStamp.timeIntervalSince1970,
            timestamp.timeIntervalSince1970,
            accuracy: 0.1
        )
    }

    private enum Scaffolding {
        static let teamID = UUID()
        static let userID = UUID()
        static let time = "2021-05-12T10:52:02.671Z"
        static let teamConversationID = UUID()
        static let anotherTeamConversationID = UUID()
        static let conversationID = UUID()

        static func date(from string: String) -> Date {
            ISO8601DateFormatter.fractionalInternetDateTime.date(from: string)!
        }

        static let conversationList = ConversationList(
            found: [conversationSelfType,
                    conversationGroupType,
                    conversationConnectionType,
                    conversationOneOnOneType],
            notFound: [conversationNotFound],
            failed: [conversationFailed]
        )

        static let conversationListError = ConversationList(
            found: [conversationSelfTypeMissingId,
                    conversationGroupType,
                    conversationConnectionType,
                    conversationOneOnOneType],
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

        static let base64EncodedString = "pQABARn//wKhAFggHsa0CszLXYLFcOzg8AA//E1+Dl1rDHQ5iuk44X0/PNYDoQChAFgg309rkhG6SglemG6kWae81P1HtQPx9lyb6wExTovhU4cE9g=="

        static let conversationNotFound = WireAPI.QualifiedID(
            uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4aa")!,
            domain: "example.com"
        )

        static let conversationFailed = WireAPI.QualifiedID(
            uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4af")!,
            domain: "example.com"
        )

        static let selfUserId = UUID()

        static let domain = "domain.com"
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
