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

import Foundation
import WireAPISupport
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireAPI
@testable import WireDomain

class ConversationRepositoryTests: XCTestCase {

    var sut: ConversationRepository!
    var conversationsAPI: MockConversationsAPI!
    var conversationsLocalStore: ConversationLocalStoreProtocol!
    let backendInfo: ConversationRepository.BackendInfo = .init(
        domain: "example.com",
        isFederationEnabled: false
    )
    var stack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
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
        conversationsLocalStore = nil
        stack = nil
        conversationsAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
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
    }

    private enum Scaffolding {
        nonisolated(unsafe) static let conversationList = ConversationList(
            found: [conversationSelfType,
                    conversationGroupType,
                    conversationConnectionType,
                    conversationOneOnOneType],
            notFound: [conversationNotFound],
            failed: [conversationFailed]
        )

        nonisolated(unsafe) static let conversationListError = ConversationList(
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
            mlsGroupID: "",
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
