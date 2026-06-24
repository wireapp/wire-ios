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

import Combine
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import WireNetworkSupport
import WireTestingPackage
import XCTest

@testable import WireDomain
@testable import WireNetwork

final class ConversationLocalStoreTests: XCTestCase {

    private var sut: ConversationLocalStore!
    private var messageLocalStore: MockMessageLocalStoreProtocol!
    private var mlsService: MockMLSServiceInterface!

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    private var subscription: AnyCancellable?

    override func setUp() async throws {
        mlsService = MockMLSServiceInterface()
        coreDataStackHelper = CoreDataStackHelper()
        messageLocalStore = MockMessageLocalStoreProtocol()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        sut = ConversationLocalStore(
            context: context,
            mlsService: mlsService,
            messageLocalStore: messageLocalStore,
            localDomain: "wire.com",
            isFederationEnabled: false
        )
    }

    override func tearDown() async throws {
        mlsService = nil
        stack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
        messageLocalStore = nil
        subscription = nil
    }

    // MARK: - Tests

    func testStoreConversation_It_Stores_Conversation_Locally() async throws {
        // Mock

        let groupConversation = Scaffolding.groupConversation
        let qualifiedID = try XCTUnwrap(groupConversation.qualifiedID)
        let id = qualifiedID.id
        let domain = qualifiedID.domain

        // When

        await sut.storeConversation(
            groupConversation.toDomainModel(),
            timestamp: .distantPast,
            isFederationEnabled: false,
            isMLSEnabled: true
        )

        // Then

        let localConversation = await sut.fetchConversation(
            id: id,
            domain: domain
        )

        await context.perform {
            XCTAssertNotNil(localConversation)
            XCTAssertEqual(localConversation?.remoteIdentifier, id)
        }
    }

    func testStoreFailedConversation_It_Sets_Pending_Metadata_Refresh_And_Backend_Update_Flags_To_True() async throws {
        // Given

        let groupConversation = Scaffolding.groupConversation
        let qualifiedID = try XCTUnwrap(groupConversation.qualifiedID)
        let id = qualifiedID.id
        let domain = qualifiedID.domain

        // When

        await sut.storeFailedConversation(
            conversationID: id,
            conversationDomain: domain
        )

        // Then

        let localConversation = await sut.fetchConversation(
            id: id,
            domain: domain
        )

        await context.perform {
            XCTAssertEqual(localConversation?.isPendingMetadataRefresh, true)
            XCTAssertEqual(localConversation?.needsToBeUpdatedFromBackend, true)
        }
    }

    func testStoreConversation_It_Needs_Backend_Update() async throws {
        // Mock

        let groupConversation = Scaffolding.groupConversation
        let qualifiedID = try XCTUnwrap(groupConversation.qualifiedID)
        let id = qualifiedID.id
        let domain = qualifiedID.domain

        await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(id: id, in: context)
            XCTAssertEqual(conversation.needsToBeUpdatedFromBackend, false)
        }

        // When

        await sut.storeConversation(
            needsBackendUpdate: true,
            conversationID: id,
            conversationDomain: domain
        )

        // Then

        let localConversation = await sut.fetchConversation(
            id: id,
            domain: domain
        )

        await context.perform {
            XCTAssertEqual(localConversation?.needsToBeUpdatedFromBackend, true)
        }
    }

    func testFetchMLSConversation_It_Retrieves_Conversation_Locally() async throws {
        // Mock

        let mlsGroupID = try XCTUnwrap(
            MLSGroupID(base64Encoded: Scaffolding.base64EncodedString)
        )

        let mlsConversation = await context.perform { [self] in
            modelHelper.createMLSConversation(
                mlsGroupID: mlsGroupID,
                in: context
            )
        }

        // When

        let localConversation = await sut.fetchMLSConversation(
            groupID: mlsGroupID
        )

        // Then

        await context.perform {
            XCTAssertEqual(localConversation, mlsConversation)
        }
    }

    func testRemoveParticipantFromConversation_It_Removes_Participant() async throws {
        // Mock

        let (removedUser, removedUserID, removedUserDomain, remainingUsers, conversation) = await context
            .perform { [self] in
                let user1 = modelHelper.createUser(in: context)
                let user2 = modelHelper.createUser(in: context)
                let user3 = modelHelper.createUser(in: context)
                let removedUser = modelHelper.createUser(id: Scaffolding.userID, in: context)

                let conversation = modelHelper.createGroupConversation(
                    id: Scaffolding.conversationID,
                    with: [removedUser, user1, user2, user3],
                    in: context
                )

                return (
                    removedUser,
                    removedUser.remoteIdentifier as UUID,
                    removedUser.domain,
                    [user1, user2, user3],
                    conversation
                )
            }

        messageLocalStore
            .addSystemMessageMessageTypeConversationIDConversationDomain_MockMethod = { _, _, _ in }

        // When

        try await sut.removeParticipantFromAllGroupConversations(
            participantID: removedUserID,
            participantDomain: removedUserDomain,
            date: .now
        )

        // Then

        XCTAssertEqual(
            messageLocalStore.addSystemMessageMessageTypeConversationIDConversationDomain_Invocations
                .count,
            1
        )

        await context.perform {
            XCTAssertEqual(conversation.localParticipants, Set(remainingUsers))
            XCTAssertEqual(conversation.localParticipants.contains(removedUser), false)
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

        // When

        await sut.addOrUpdateParticipant(
            addedUser,
            withRole: ZMConversation.defaultMemberRoleName,
            in: conversation
        )

        // Then

        await context.perform {
            XCTAssertEqual(conversation.localParticipants.contains(addedUser), true)
        }
    }

    func testFetchConversation_It_Retrieves_Conversation_Locally() async {
        // Mock

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

    func testDeleteConversation_It_Marks_Conversation_As_Deleted_Locally() async {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        // When

        await sut.deleteConversation(conversation)

        // Then

        await context.perform {
            XCTAssertEqual(conversation.isDeletedRemotely, true)
        }
    }

    func testRemoveParticipants_It_Removes_Participant_From_A_Given_Conversation() async {
        // Mock

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

        // When

        await sut.removeParticipantsAndUpdateConversationState(
            conversation: conversation,
            users: [removedUser],
            initiatingUser: senderUser
        )

        // Then

        await context.perform {
            let newParticipants = conversation.localParticipants
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

        // When

        await sut.addOrUpdateParticipant(
            updatedUser,
            withRole: ZMConversation.defaultAdminRoleName,
            in: conversation
        )

        // Then

        try await context.perform {
            let role = try XCTUnwrap(updatedUser.role(in: conversation))
            XCTAssertEqual(role.name, ZMConversation.defaultAdminRoleName)
        }
    }

    func testAddParticipants_It_Adds_Participants_To_Conversation() async throws {
        // Mock

        let (conversation, _, addedUser) = await context.perform { [self] in
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

        messageLocalStore
            .addSystemMessageMessageTypeConversationIDConversationDomain_MockMethod = { _, _, _ in }

        // When

        try await sut.addParticipants(
            [(
                Scaffolding.otherUserID,
                Scaffolding.domain,
                ZMConversation.defaultMemberRoleName
            )],
            addedBy: (Scaffolding.userID, Scaffolding.domain),
            atDate: .distantPast,
            conversation: (Scaffolding.conversationID, Scaffolding.domain)
        )

        // Then

        XCTAssertEqual(
            messageLocalStore.addSystemMessageMessageTypeConversationIDConversationDomain_Invocations
                .count,
            1
        )

        await context.perform {
            XCTAssertTrue(conversation.localParticipants.contains(addedUser))
        }
    }

    func testStoreMLSConversationEstablished_It_Sets_MLS_Status_Ready_And_Updates_MLS_Group_ID() async throws {

        // Mock

        let conversation = await context.perform { [modelHelper, context] in
            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                domain: Scaffolding.domain,
                in: context
            )
        }

        let mlsGroupID = try XCTUnwrap(MLSGroupID(base64Encoded: Scaffolding.base64EncodedString))
        let newEpoch = UInt64(100)
        // When

        await sut.storeMLSConversationEstablished(
            mlsGroupID: mlsGroupID,
            epoch: newEpoch,
            conversation: conversation
        )

        // Then

        try await context.unpack(conversation) { conversation in
            XCTAssertEqual(conversation.mlsStatus, .ready)
            XCTAssertEqual(conversation.mlsGroupID, mlsGroupID)
            XCTAssertEqual(conversation.epoch, newEpoch)
        }
    }

    func testUpdateOrCreateMLSGroup_It_Creates_MLS_Group_Locally() async throws {

        // Mock

        let mlsGroupID = try XCTUnwrap(MLSGroupID(base64Encoded: Scaffolding.base64EncodedString))

        // When

        await sut.updateOrCreateMLSGroup(groupID: mlsGroupID)

        // Then

        try await context.perform { [context] in
            let mlsGroupRequest = MLSGroup.fetchRequest()
            let mlsGroup = try context.fetch(mlsGroupRequest)
                .compactMap { $0 as? MLSGroup }.first

            XCTAssertEqual(mlsGroup?.id, mlsGroupID)
        }
    }

    func testFetchOtherUserIDInOneOnOneConversation_It_Returns_The_Other_User_Qualified_ID() async {

        // Mock

        let conversation = await context.perform { [self] in
            let conversation = modelHelper.createMLSConversation(
                conversationType: .oneOnOne,
                in: context
            )

            let selfUser = modelHelper.createSelfUser(in: context)
            let otherUser = modelHelper.createUser(id: Scaffolding.otherUserID, domain: Scaffolding.domain, in: context)
            conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, otherUser]))

            return conversation
        }

        // When

        let qualifiedID = await sut.fetchOtherUserIDInOneOnOneConversation(
            conversation: conversation
        )

        // Then

        XCTAssertEqual(qualifiedID?.uuid, Scaffolding.otherUserID)
        XCTAssertEqual(qualifiedID?.domain, Scaffolding.domain)
    }

    func testStoreConversationPermission_It_Updates_The_Permission_Locally() async {
        // Mock

        let conversation = await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(
                in: context
            )

            conversation.groupType = .channel

            XCTAssertEqual(conversation.privateChannelPermission, .unset)

            return conversation
        }

        // When

        let channelPermission = Conversation.ChannelPermission.admins

        await sut.storeConversation(
            permission: channelPermission,
            conversation: conversation
        )

        // Then

        await context.perform {
            XCTAssertEqual(conversation.privateChannelPermission, .admins)
        }
    }

    private enum Scaffolding {

        static let selfUserId = UUID.mockID1

        static let domain = "domain.com"

        static let teamID = UUID.mockID2

        static let userID = UUID.mockID3

        static let otherUserID = UUID.mockID4

        static let time = "2021-05-12T10:52:02.671Z"

        static let teamConversationID = UUID.mockID5

        static let anotherTeamConversationID = UUID.mockID6

        static let conversationID = UUID.mockID7

        static let base64EncodedString =
            "pQABARn//wKhAFggHsa0CszLXYLFcOzg8AA//E1+Dl1rDHQ5iuk44X0/PNYDoQChAFgg309rkhG6SglemG6kWae81P1HtQPx9lyb6wExTovhU4cE9g=="

        static func date(from string: String) -> Date {
            ISO8601DateFormatter.fractionalInternetDateTime.date(from: string)!
        }

        static let groupConversation = Conversation(
            id: .mockID1,
            qualifiedID: .init(id: .mockID1, domain: domain),
            teamID: .mockID2,
            type: .group,
            messageProtocol: .proteus,
            mlsGroupID: "",
            cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
            epoch: 0,
            epochTimestamp: nil,
            creator: .mockID3,
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

    }

}
