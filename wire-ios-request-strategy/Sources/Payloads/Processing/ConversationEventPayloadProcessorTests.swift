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

import WireDataModelSupport
import XCTest

@testable import WireRequestStrategy

final class ConversationEventPayloadProcessorTests: MessagingTestBase {

    var sut: ConversationEventPayloadProcessor!
    var mockMLSService: MockMLSServiceInterface!
    var mockRemoveLocalConversation: MockLocalConversationRemovalUseCase!

    override func setUp() {
        super.setUp()

        mockMLSService = .init()
        mockRemoveLocalConversation = MockLocalConversationRemovalUseCase()

        sut = ConversationEventPayloadProcessor(
            removeLocalConversation: mockRemoveLocalConversation
        )

        syncMOC.performAndWait {
            syncMOC.mlsService = mockMLSService
        }
    }

    override func tearDown() {
        sut = nil
        mockMLSService = nil
        mockRemoveLocalConversation = nil
        BackendInfo.isFederationEnabled = false
        super.tearDown()
    }

    // MARK: - Group conversations

    func testUpdateOrCreateConversation_Group_UpdatesQualifiedID() async throws {
        // Given
        let qualifiedID = await syncMOC.perform {
            BackendInfo.isFederationEnabled = true
            return self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group
        )

        // When
        await sut.updateOrCreateConversation(
            from: payload,
            in: self.syncMOC
        )

        // Then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.remoteIdentifier, qualifiedID.uuid)
            XCTAssertEqual(self.groupConversation.domain, qualifiedID.domain)
        }
    }

    func testUpdateOrCreateConversation_Group_DoesntUpdatesQualifiedID_WhenFederationIsDisabled() async throws {
        // given
        let qualifiedID = await syncMOC.perform {
            BackendInfo.isFederationEnabled = false
            return self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            id: qualifiedID.uuid,
            type: .group
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: self.syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.remoteIdentifier, qualifiedID.uuid)
            XCTAssertNil(self.groupConversation.domain)
        }
    }

    func testUpdateOrCreateConversation_Group_SetsNeedsToBeUpdatedFromBackend() async throws {
        // given
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.needsToBeUpdatedFromBackend = true
            return self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: self.syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertFalse(self.groupConversation.needsToBeUpdatedFromBackend)
        }
    }

    func testUpdateOrCreateConversation_Group_CreatesConversation() async throws {
        // given
        let qualifiedID = await syncMOC.perform {
            QualifiedID(uuid: UUID(), domain: self.owningDomain)
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: self.syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertNotNil(ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: self.syncMOC))
        }
    }

    func testUpdateOrCreateConversation_Group_AddSystemMessageWhenCreatingGroup() async throws {
        // given
        let qualifiedID = await syncMOC.perform {
            QualifiedID(uuid: UUID(), domain: self.owningDomain)
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            let conversation = ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: self.syncMOC)
            XCTAssertEqual(conversation?.lastMessage?.systemMessageData?.systemMessageType, .newConversation)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesLastServerTimestamp() async throws {
        // given
        let serverTimestamp = Date()
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            serverTimestamp: serverTimestamp,
            in: self.syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.lastServerTimeStamp, serverTimestamp)
        }
    }

    func testUpdateOrCreateConversation_Group_ResetsIsPendingMetadataRefresh() async throws {
        // given
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.isPendingMetadataRefresh = true
            return self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation(
            qualifiedID: qualifiedID,
            type: BackendConversationType.group.rawValue
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: self.syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertFalse(self.groupConversation.isPendingMetadataRefresh)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesUserDefinedName() async throws {
        // given
        let name = "Example name"
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            name: name
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.userDefinedName, name)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesTeamID() async throws {
        // given
        let teamID = UUID()
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            teamID: teamID
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.teamRemoteIdentifier, teamID)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesCreator() async throws {
        let (creator, qualifiedID) = await syncMOC.perform {
            // given
            let creator = self.otherUser.remoteIdentifier
            let qualifiedID = self.groupConversation.qualifiedID!
            return (creator, qualifiedID)
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            creator: creator
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.creator, self.otherUser)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesMembers() async throws {
        let (qualifiedID, selfUser, members) = await syncMOC.perform {
            // given
            let qualifiedID = self.groupConversation.qualifiedID!
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            return (qualifiedID, selfUser, members)
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            members: members
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            let otherUserSet: Set<ZMUser?> = [self.otherUser, selfUser]
            XCTAssertEqual(self.groupConversation.localParticipants, otherUserSet)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesReadReceiptMode() async throws {
        // given
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            readReceiptMode: 1
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertTrue(self.groupConversation.hasReadReceiptsEnabled)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesAccessStatus() async throws {
        // given
        let accessMode: ConversationAccessMode = .allowGuests
        let accessRole: Set<ConversationAccessRoleV2> = [.teamMember]
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            access: accessMode.stringValue,
            accessRoles: accessRole.map(\.rawValue)
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.accessMode, accessMode)
            XCTAssertEqual(self.groupConversation.accessRoles, accessRole)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdateAccessRoleV2() async throws {
        // GIVEN
        let accessMode: ConversationAccessMode = .allowGuests
        let accessRoleV2: Set<ConversationAccessRoleV2> = [.teamMember, .nonTeamMember, .guest]
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            access: accessMode.stringValue,
            accessRoles: accessRoleV2.map(\.rawValue)
        )

        // WHEN
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // THEN
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.accessRoles, accessRoleV2)
        }
    }

    func testThatItMapsFromLegacyAccessRoleToAccessRoleV2() async throws {
        // GIVEN
        let accessRole: ConversationAccessRole = .team
        let accessMode: ConversationAccessMode = .teamOnly
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation(
            qualifiedID: qualifiedID,
            type: BackendConversationType.group.rawValue,
            access: accessMode.stringValue,
            legacyAccessRole: accessRole.rawValue
        )

        // WHEN
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // THEN
        await syncMOC.perform {
            let accessRoleV2 = ConversationAccessRoleV2.fromLegacyAccessRole(accessRole)
            XCTAssertEqual(self.groupConversation.accessRoles, accessRoleV2)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesMessageTimer() async throws {
        // given
        let messageTimer = MessageDestructionTimeoutValue.fiveMinutes
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            messageTimer: messageTimer.rawValue * 1000
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.activeMessageDestructionTimeoutValue, messageTimer)
            XCTAssertEqual(self.groupConversation.activeMessageDestructionTimeoutType, .groupConversation)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesMutedStatus() async throws {
        let (payload, mutedMessageTypes) = await syncMOC.perform {
            let qualifiedID = self.groupConversation.qualifiedID!
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let mutedMessageTypes: MutedMessageTypes = .all
            let selfMember = Payload.ConversationMember(
                qualifiedID: selfUser.qualifiedID!,
                mutedStatus: Int(mutedMessageTypes.rawValue),
                mutedReference: Date()
            )
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [])
            let payload = Payload.Conversation.stub(
                qualifiedID: qualifiedID,
                type: .group,
                members: members
            )
            return (payload, mutedMessageTypes)
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.mutedMessageTypes, mutedMessageTypes)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesArchivedStatus() async throws {
        // given
        let payload = await syncMOC.perform {
            let qualifiedID = self.groupConversation.qualifiedID!
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!,
                                                        archived: true,
                                                        archivedReference: Date())
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [])
            return Payload.Conversation.stub(
                qualifiedID: qualifiedID,
                type: .group,
                members: members
            )
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertTrue(self.groupConversation.isArchived)
        }
    }

    func testUpdateOrCreateConversation_Group_Updates_MessageProtocol() async {
        // given
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.messageProtocol = .proteus
            return self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            messageProtocol: "mls"
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.messageProtocol, .mls)
        }
    }

    // MARK: 1:1 / Connection Conversations

    func testUpdateOrCreateConversation_OneToOne_CreatesConversation() async throws {
        // given
        BackendInfo.isFederationEnabled = true
        let conversationID = UUID()
        let (payload, otherUserSet) = await syncMOC.perform {
            self.otherUser.connection?.conversation = nil

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let qualifiedID = QualifiedID(uuid: conversationID, domain: self.owningDomain)
            let payload = Payload.Conversation(qualifiedID: qualifiedID,
                                               type: BackendConversationType.oneOnOne.rawValue,
                                               members: members)
            let otherUserSet: Set<ZMUser> = [selfUser, self.otherUser]
            return (payload, otherUserSet)
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.otherUser.connection?.conversation?.remoteIdentifier, conversationID)
            XCTAssertEqual(self.otherUser.connection?.conversation?.domain, self.owningDomain)
            XCTAssertEqual(self.otherUser.connection?.conversation?.conversationType, .oneOnOne)
            XCTAssertEqual(self.otherUser.connection?.conversation?.localParticipants, otherUserSet)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_DoesntAssignDomain_WhenFederationIsDisabled() async throws {
        // given
        BackendInfo.isFederationEnabled = false
        let conversationID = UUID()
        let payload = await syncMOC.perform {
            self.otherUser.connection?.conversation = nil

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let qualifiedID = QualifiedID(uuid: conversationID, domain: self.owningDomain)
            let payload = Payload.Conversation(qualifiedID: qualifiedID,
                                               type: BackendConversationType.oneOnOne.rawValue,
                                               members: members)
            return payload
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.otherUser.connection?.conversation?.remoteIdentifier, conversationID)
            XCTAssertNil(self.otherUser.connection?.conversation?.domain)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_UpdatesConversationType() async throws {
        // given
        let (conversation, payload) = await syncMOC.perform {
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID()
            conversation.domain = self.owningDomain
            let qualifiedID = conversation.qualifiedID!
            let payload = Payload.Conversation(qualifiedID: qualifiedID, type: BackendConversationType.connection.rawValue)
            return (conversation, payload)
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(conversation.conversationType, .connection)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_UpdatesLastServerTimestamp() async throws {
        // given
        let serverTimestamp = Date()
        let payload = await syncMOC.perform {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let qualifiedID = self.oneToOneConversation.qualifiedID!
            return Payload.Conversation(qualifiedID: qualifiedID,
                                        type: BackendConversationType.oneOnOne.rawValue,
                                        members: members)
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            serverTimestamp: serverTimestamp,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.oneToOneConversation.lastServerTimeStamp, serverTimestamp)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_ResetsIsPendingMetadataRefresh() async throws {
        let payload = await syncMOC.perform {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            self.otherUser.isPendingMetadataRefresh = true
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let qualifiedID = self.oneToOneConversation.qualifiedID!
            return Payload.Conversation(qualifiedID: qualifiedID,
                                               type: BackendConversationType.oneOnOne.rawValue,
                                               members: members)
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.oneToOneConversation.isPendingMetadataRefresh, self.otherUser.isPendingMetadataRefresh)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_MergesWithExistingConversation() async throws {
        // given
        let existingTextMessage = "Hello World"
        let (existingConversation, payload) = try await syncMOC.perform {

            // We already have a local 1:1 conversation
            self.otherUser.connection?.conversation.remoteIdentifier = nil
            self.otherUser.connection?.conversation.domain = nil

            // The remote 1:1 conversation also exists but it's not linked to the connection
            let existingConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            existingConversation.remoteIdentifier = UUID()
            existingConversation.domain = self.owningDomain
            try existingConversation.appendText(content: existingTextMessage)

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let payload = Payload.Conversation(qualifiedID: existingConversation.qualifiedID!,
                                        type: BackendConversationType.connection.rawValue,
                                        members: members)
            return (existingConversation, payload)
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertTrue(existingConversation.isZombieObject)
            XCTAssertEqual(self.otherUser.connection?.conversation?.lastMessage?.textMessageData?.messageText, existingTextMessage)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_UpdatesMutedStatus() async throws {
        // given
        let mutedMessageTypes: MutedMessageTypes = .all
        let payload = await syncMOC.perform {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!,
                                                        mutedStatus: Int(mutedMessageTypes.rawValue),
                                                        mutedReference: Date())
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let qualifiedID = self.oneToOneConversation.qualifiedID!
            return Payload.Conversation(qualifiedID: qualifiedID,
                                        type: BackendConversationType.oneOnOne.rawValue,
                                        members: members)
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.oneToOneConversation.mutedMessageTypes, mutedMessageTypes)
        }
    }

    func testUpdateOrCreateConversation_OneToOne_UpdatesArchivedStatus() async throws {
        // given
        let payload = await syncMOC.perform {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!,
                                                        archived: true,
                                                        archivedReference: Date())
            let otherMember = Payload.ConversationMember(qualifiedID: self.otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])
            let qualifiedID = self.oneToOneConversation.qualifiedID!
            let payload = Payload.Conversation(qualifiedID: qualifiedID,
                                               type: BackendConversationType.oneOnOne.rawValue,
                                               members: members)
            return payload
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertTrue(self.oneToOneConversation.isArchived)
        }
    }

    // MARK: Self conversation

    func testUpdateOrCreateConversation_Self_CreatesConversation() async throws {
        // given
        BackendInfo.isFederationEnabled = true
        let qualifiedID = QualifiedID(uuid: UUID(), domain: self.owningDomain)
        let payload = Payload.Conversation(qualifiedID: qualifiedID, type: BackendConversationType.`self`.rawValue)

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        try await syncMOC.perform {
            let conversation = try XCTUnwrap(ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: self.syncMOC))
            XCTAssertEqual(conversation.conversationType, .`self`)
        }
    }

    func testUpdateOrCreateConversation_Self_DoesntAssignDomain_WhenFederationIsDisabled() async throws {
        // given
        BackendInfo.isFederationEnabled = false
        let qualifiedID = QualifiedID(uuid: UUID(), domain: self.owningDomain)
        let payload = Payload.Conversation(qualifiedID: qualifiedID, type: BackendConversationType.`self`.rawValue)

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        try await syncMOC.perform {
            let conversation = try XCTUnwrap(ZMConversation.fetch(with: qualifiedID.uuid, domain: nil, in: self.syncMOC))
            XCTAssertEqual(conversation.conversationType, .`self`)
            XCTAssertNil(conversation.domain)
        }
    }

    func testUpdateOrCreateConversation_Self_ResetsNeedsToBeUpdatedFromBackend() async throws {
        let (conversation, qualifiedID) = await syncMOC.perform {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.needsToBeUpdatedFromBackend = true
            conversation.remoteIdentifier = UUID()
            conversation.domain = self.owningDomain
            let qualifiedID = conversation.qualifiedID!
            return (conversation, qualifiedID)
        }
        let payload = Payload.Conversation(qualifiedID: qualifiedID, type: BackendConversationType.`self`.rawValue)

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertFalse(conversation.needsToBeUpdatedFromBackend)
        }
    }

    func testUpdateOrCreateConversation_Self_UpdatesLastServerTimestamp() async throws {
        // given
        let serverTimestamp = Date()
        let (selfConversation, payload) = await syncMOC.perform {
            let selfConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            selfConversation.remoteIdentifier = ZMConversation.selfConversationIdentifier(in: self.syncMOC)
            selfConversation.domain = self.owningDomain
            let payload = Payload.Conversation(qualifiedID: selfConversation.qualifiedID!,
                                               type: BackendConversationType.`self`.rawValue)
            return (selfConversation, payload)
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            serverTimestamp: serverTimestamp,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(selfConversation.lastServerTimeStamp, serverTimestamp)
        }
    }

    func testUpdateOrCreateConversation_Self_ResetsIsPendingMetadataRefresh() async throws {
        // given
        let (selfConversation, payload) = await syncMOC.perform {
            let selfConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            selfConversation.remoteIdentifier = ZMConversation.selfConversationIdentifier(in: self.syncMOC)
            selfConversation.domain = self.owningDomain
            selfConversation.isPendingMetadataRefresh = true
            let payload = Payload.Conversation(
                qualifiedID: selfConversation.qualifiedID!,
                type: BackendConversationType.`self`.rawValue
            )
            return (selfConversation, payload)
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertFalse(selfConversation.isPendingMetadataRefresh)
        }
    }

    // MARK: - MLS: Conversation Create

    func testUpdateOrCreateConversation_Group_MLS_AsksToUpdateConversationIfNeeded() async {
        // given
        let mockEventProcessor = MockMLSEventProcessor()
        MLSEventProcessor.setMock(mockEventProcessor)
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation(qualifiedID: qualifiedID,
                                           type: BackendConversationType.group.rawValue,
                                           messageProtocol: "mls")
        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            let updateConversationCalls = mockEventProcessor.calls.updateConversationIfNeeded
            XCTAssertEqual(updateConversationCalls.count, 1)
            XCTAssertEqual(updateConversationCalls.first?.conversation, self.groupConversation)
        }
    }

    func testUpdateOrCreateConversation_Group_MLS_AsksToJoinGroupWhenReady_DuringSlowSync() async {
        // given
        let mockEventProcessor = MockMLSEventProcessor()
        MLSEventProcessor.setMock(mockEventProcessor)
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation(qualifiedID: qualifiedID,
                                           type: BackendConversationType.group.rawValue,
                                           messageProtocol: "mls")

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            source: .slowSync,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            let joinMLSGroupWhenReadyCalls = mockEventProcessor.calls.joinMLSGroupWhenReady
            XCTAssertEqual(joinMLSGroupWhenReadyCalls.count, 1)
            XCTAssertEqual(joinMLSGroupWhenReadyCalls.first, self.groupConversation)
        }
    }

    func testUpdateOrCreateConversation_Group_MLS_DoesntAskToJoinGroupWhenReady_DuringQuickSync() async {
        // given
        let mockEventProcessor = MockMLSEventProcessor()
        MLSEventProcessor.setMock(mockEventProcessor)
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation(qualifiedID: qualifiedID,
                                           type: BackendConversationType.group.rawValue,
                                           messageProtocol: "mls")

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            source: .eventStream,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(mockEventProcessor.calls.joinMLSGroupWhenReady.count, 0)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesEpoch() async {
        // given
        MLSEventProcessor.setMock(MockMLSEventProcessor())
        let payload = await syncMOC.perform {
            self.groupConversation.epoch = 0
            return Payload.Conversation(
                qualifiedID: self.groupConversation.qualifiedID!,
                type: BackendConversationType.group.rawValue,
                epoch: 1
            )
        }

        // when
        let conversation = await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(conversation?.epoch, 1)
        }
    }

    // MARK: - MLS Self Group

    func testUpdateOrCreate_withMLSSelfGroupEpoch0_callsMLSServiceCreateGroup() async {
        let didCallCreateGroup = XCTestExpectation(description: "didCallCreateGroup")
        mockMLSService.createSelfGroupFor_MockMethod = { _ in
            didCallCreateGroup.fulfill()
        }

        await internalTest_UpdateOrCreate_withMLSSelfGroupEpoch(epoch: 0)
        await fulfillment(of: [didCallCreateGroup], timeout: 0.5)

        // then
        XCTAssertFalse(mockMLSService.createSelfGroupFor_Invocations.isEmpty)
    }

    func testUpdateOrCreate_withMLSSelfGroupEpoch1_callsMLSServiceJoinGroup() async {
        let didJoinGroup = XCTestExpectation(description: "didJoinGroup")
        mockMLSService.joinGroupWith_MockMethod = { _ in
            didJoinGroup.fulfill()
        }
        mockMLSService.conversationExistsGroupID_MockValue = false

        await internalTest_UpdateOrCreate_withMLSSelfGroupEpoch(epoch: 1)
        await fulfillment(of: [didJoinGroup], timeout: 0.5)

        // then
        XCTAssertFalse(mockMLSService.joinGroupWith_Invocations.isEmpty)
    }

    func internalTest_UpdateOrCreate_withMLSSelfGroupEpoch(epoch: UInt?) async {
        // given
        let conversation = await syncMOC.perform {
            MLSEventProcessor.setMock(MockMLSEventProcessor())
            let domain = "example.com"
            let id = QualifiedID(uuid: UUID(), domain: domain)
            return Payload.Conversation(
                qualifiedID: id,
                type: BackendConversationType.`self`.rawValue,
                messageProtocol: "mls",
                mlsGroupID: "test",
                epoch: epoch
            )
        }

        // when
        await sut.updateOrCreateConversation(from: conversation, in: syncMOC)
    }

    // MARK: - Conversation Delete

    func testProcessingConversationDelete_CallsLocalConversationRemovalUseCase() async {
        // Given
        let payload = await syncMOC.perform {
            let conversationDeleted = Payload.UpdateConversationDeleted()
            return Payload.ConversationEvent(
                id: nil,
                qualifiedID: self.groupConversation.qualifiedID,
                from: nil,
                qualifiedFrom: nil,
                timestamp: nil,
                type: nil,
                data: conversationDeleted
            )
        }

        // When
        await sut.processPayload(payload, in: syncMOC)

        // Then
        await syncMOC.perform {
            XCTAssertEqual(
                self.mockRemoveLocalConversation.invokeCalls,
                [self.groupConversation]
            )
        }
    }

    // MARK: - Handle User Removed

    func testProcessingConverationMemberLeave_SelfUserTriggersAccountDeletedNotification() {
        // Given
        let (_, _, conversationEvent, originalEvent) = setupForProcessingConverationMemberLeaveTests(
            selfUserLeaves: true
        )
        let expectation = XCTNSNotificationExpectation(name: AccountDeletedNotification.notificationName, object: nil, notificationCenter: .default)
        expectation.handler = { notification in
            notification.userInfo?[AccountDeletedNotification.userInfoKey] as? AccountDeletedNotification != nil
        }

        // When
        syncMOC.performAndWait {
            sut.processPayload(
                conversationEvent,
                originalEvent: originalEvent,
                in: syncMOC
            )
        }

        // Then
        wait(for: [expectation], timeout: 1)
    }

    func testProcessingConverationMemberLeave_MarksOtherUserAsDeleted() {
        // Given
        let (conversation, users, conversationEvent, originalEvent) = setupForProcessingConverationMemberLeaveTests(
            selfUserLeaves: false
        )

        // When
        syncMOC.performAndWait {
            sut.processPayload(
                conversationEvent,
                originalEvent: originalEvent,
                in: syncMOC
            )
        }

        // Then
        syncMOC.performAndWait {
            XCTAssertTrue(users[1].isAccountDeleted)
            XCTAssertFalse(conversation.localParticipants.contains(users[1]))
        }
    }

    private func setupForProcessingConverationMemberLeaveTests(
        selfUserLeaves: Bool
    ) -> (
        conversation: ZMConversation,
        users: [ZMUser],
        conversationEvent: Payload.ConversationEvent<Payload.UpdateConverationMemberLeave>,
        originalEvent: ZMUpdateEvent
    ) {
        syncMOC.performAndWait {
            let team = Team.fetchOrCreate(with: .init(), create: true, in: syncMOC, created: .none)

            let users: [ZMUser] = [.selfUser(in: syncMOC), .insertNewObject(in: syncMOC)]
            users.forEach { user in
                user.remoteIdentifier = .init()
                user.domain = owningDomain
                let membership = Member.insertNewObject(in: syncMOC)
                membership.user = user
                membership.team = team
            }
            let userIndex = selfUserLeaves ? 0 : 1

            let conversation = ZMConversation.insertGroupConversation(moc: syncMOC, participants: users)!
            conversation.remoteIdentifier = .init(uuidString: "ee8824c5-95d0-4e59-9862-e9bb0fc6e921")
            conversation.conversationType = .group
            conversation.domain = owningDomain

            let memberLeavePayload = Payload.UpdateConverationMemberLeave(
                qualifiedUserIDs: [users[userIndex].qualifiedID].compactMap { $0 },
                reason: .userDeleted
            )
            let conversationEvent = Payload.ConversationEvent(
                id: nil,
                qualifiedID: groupConversation.qualifiedID,
                from: nil,
                qualifiedFrom: nil,
                timestamp: nil,
                type: nil,
                data: memberLeavePayload
            )
            let originalEvent = ZMUpdateEvent(
                uuid: .init(),
                payload: [
                    "id": "cf51e6b1-39a6-11ed-8005-520924331b82",
                    "time": "2022-09-21T12:13:32.173Z",
                    "type": "conversation.member-leave",
                    "from": "f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
                    "conversation": "ee8824c5-95d0-4e59-9862-e9bb0fc6e921",
                    "data": [
                        "qualified_user_ids": [
                            ["id": users[userIndex].remoteIdentifier.transportString(), "domain": owningDomain]
                        ],
                        "reason": "user-delete"
                    ]
                ],
                transient: false,
                decrypted: true,
                source: .webSocket
            )!

            return (conversation, users, conversationEvent, originalEvent)
        }
    }

}

extension Payload.Conversation {

    static func stub(
        qualifiedID: QualifiedID? = nil,
        id: UUID?  = nil,
        type: BackendConversationType? = nil,
        creator: UUID? = nil,
        access: [String]? = nil,
        accessRole: String? = nil,
        accessRoles: [String]? = nil,
        name: String? = nil,
        members: Payload.ConversationMembers? = nil,
        lastEvent: String? = nil,
        lastEventTime: String? = nil,
        teamID: UUID? = nil,
        messageTimer: TimeInterval? = nil,
        readReceiptMode: Int? = nil,
        messageProtocol: String? = "proteus",
        mlsGroupID: String? = "id".data(using: .utf8)?.base64EncodedString()
    ) -> Self {

        self.init(
            qualifiedID: qualifiedID,
            id: id,
            type: type?.rawValue,
            creator: creator,
            access: access,
            legacyAccessRole: accessRole,
            accessRoles: accessRoles,
            name: name,
            members: members,
            lastEvent: lastEvent,
            lastEventTime: lastEventTime,
            teamID: teamID,
            messageTimer: messageTimer,
            readReceiptMode: readReceiptMode,
            messageProtocol: messageProtocol,
            mlsGroupID: mlsGroupID
        )

    }
}
