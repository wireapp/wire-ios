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
    var mockMLSEventProcessor: MockMLSEventProcessing!

    override func setUp() {
        super.setUp()
        mockRemoveLocalConversation = MockLocalConversationRemovalUseCase()
        mockMLSService = MockMLSServiceInterface()
        mockMLSEventProcessor = .init()
        mockMLSEventProcessor.updateConversationIfNeededConversationGroupIDContext_MockMethod = { _, _, _ in }
        mockMLSEventProcessor.wipeMLSGroupForConversationContext_MockMethod = { _, _ in }

        sut = ConversationEventPayloadProcessor(
            mlsEventProcessor: mockMLSEventProcessor,
            removeLocalConversation: mockRemoveLocalConversation
        )

        syncMOC.performAndWait {
            syncMOC.mlsService = mockMLSService
        }
    }

    override func tearDown() {
        sut = nil
        mockMLSService = nil
        mockMLSEventProcessor = nil
        mockRemoveLocalConversation = nil
        mockMLSEventProcessor = nil
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

    func testUpdateOrCreateConversation_Group_Updates_MessageProtocol_DoNotRevertToProteus() async {
        // given
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.messageProtocol = .proteus
            return self.groupConversation.qualifiedID!
        }
        let payloadProteus = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            messageProtocol: MessageProtocol.mixed.rawValue
        )
        let payloadMixed = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            messageProtocol: MessageProtocol.mixed.rawValue
        )

        // when
        await sut.updateOrCreateConversation(
            from: payloadMixed,
            in: syncMOC
        )
        // try to reset the protocol to 'proteus'
        await sut.updateOrCreateConversation(
            from: payloadProteus,
            in: syncMOC
        )

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.messageProtocol, .mixed)
        }
    }

    func testUpdateOrCreateConversation_Group_Updates_MessageProtocol_DoNotRevertToMixed() async {
        // given
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.messageProtocol = .mixed
            return self.groupConversation.qualifiedID!
        }
        let payloadMixed = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            messageProtocol: MessageProtocol.mixed.rawValue
        )
        let payloadMLS = Payload.Conversation.stub(
            qualifiedID: qualifiedID,
            type: .group,
            messageProtocol: MessageProtocol.mls.rawValue
        )

        // when
        await sut.updateOrCreateConversation(
            from: payloadMLS,
            in: syncMOC
        )
        // try to reset the protocol to 'mixed'
        await sut.updateOrCreateConversation(
            from: payloadMixed,
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
        let qualifiedID =  QualifiedID(uuid: .create(), domain: owningDomain)

        let (payload, selfUser) = await syncMOC.perform { [self] in
            let selfUser = ZMUser.selfUser(in: syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])

            let payload = Payload.Conversation(
                qualifiedID: qualifiedID,
                type: BackendConversationType.oneOnOne.rawValue,
                members: members
            )

            return (payload, selfUser)
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        try await syncMOC.perform { [self] in
            let conversation = try XCTUnwrap(ZMConversation.fetch(with: qualifiedID, in: syncMOC))
            XCTAssertEqual(conversation.remoteIdentifier, qualifiedID.uuid)
            XCTAssertEqual(conversation.domain, owningDomain)
            XCTAssertEqual(conversation.conversationType, ZMConversationType.oneOnOne)
            XCTAssertEqual(conversation.localParticipants, [selfUser, otherUser])
        }
    }

    func testUpdateOrCreateConversation_OneToOne_DoesntAssignDomain_WhenFederationIsDisabled() async throws {
        // given
        BackendInfo.isFederationEnabled = false
        let qualifiedID =  QualifiedID(uuid: .create(), domain: owningDomain)

        let (payload, selfUser) = await syncMOC.perform { [self] in
            let selfUser = ZMUser.selfUser(in: syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID!)
            let otherMember = Payload.ConversationMember(qualifiedID: otherUser.qualifiedID!)
            let members = Payload.ConversationMembers(selfMember: selfMember, others: [otherMember])

            let payload = Payload.Conversation(
                qualifiedID: qualifiedID,
                type: BackendConversationType.oneOnOne.rawValue,
                members: members
            )

            return (payload, selfUser)
        }

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        try await syncMOC.perform { [self] in
            let conversation = try XCTUnwrap(ZMConversation.fetch(with: qualifiedID, in: syncMOC))
            XCTAssertEqual(conversation.remoteIdentifier, qualifiedID.uuid)
            XCTAssertNil(conversation.domain)
            XCTAssertEqual(conversation.conversationType, .oneOnOne)
            XCTAssertEqual(conversation.localParticipants, [selfUser, otherUser])
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
        let qualifiedID = await syncMOC.perform {
            self.groupConversation.qualifiedID!
        }
        let payload = Payload.Conversation(
            qualifiedID: qualifiedID,
            type: BackendConversationType.group.rawValue,
            messageProtocol: "mls"
        )

        // when
        await sut.updateOrCreateConversation(
            from: payload,
            in: syncMOC
        )

        // then
        await syncMOC.perform { [self] in
            let updateConversationCalls = mockMLSEventProcessor.updateConversationIfNeededConversationGroupIDContext_Invocations
            XCTAssertEqual(updateConversationCalls.count, 1)
            XCTAssertEqual(updateConversationCalls.first?.conversation, groupConversation)
        }
    }

    func testUpdateOrCreateConversation_Group_UpdatesEpoch() async {
        // given
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
                data: conversationDeleted,
                from: nil,
                qualifiedID: self.groupConversation.qualifiedID,
                qualifiedFrom: nil,
                timestamp: nil,
                type: nil
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

    // MARK: - MLS conversation member leave

    func test_UpdateConversationMemberLeave_WipesMLSGroup() {
        syncMOC.performAndWait {
            // Given
            let wipeGroupExpectation = XCTestExpectation(description: "it wipes group")
            mockMLSEventProcessor.wipeMLSGroupForConversationContext_MockMethod = { _, _ in
                wipeGroupExpectation.fulfill()
            }

            // Create self user
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID.create()
            selfUser.domain = groupConversation.domain

            // Set message protocol
            groupConversation.messageProtocol = .mls

            // Create the event
            let memberLeaveEvent = Payload.UpdateConverationMemberLeave(
                userIDs: [selfUser.remoteIdentifier],
                qualifiedUserIDs: [selfUser.qualifiedID!]
            )

            let payload = self.conversationEventPayload(
                from: memberLeaveEvent,
                conversationID: groupConversation.qualifiedID,
                senderID: selfUser.qualifiedID,
                timestamp: nil
            )

            let updateEvent = self.updateEvent(from: payload.payloadData()!)

            // When
            self.sut.processPayload(
                payload,
                originalEvent: updateEvent,
                in: syncMOC
            )

            // Then
            wait(for: [wipeGroupExpectation], timeout: 0.5)
            let wipeGroupInvocations = mockMLSEventProcessor.wipeMLSGroupForConversationContext_Invocations
            XCTAssertEqual(wipeGroupInvocations.count, 1)
            XCTAssertEqual(wipeGroupInvocations.first?.conversation, groupConversation)
        }
    }

    func test_UpdateConversationMemberLeave_DoesntWipeMLSGroup_WhenSelfUserIsNotRemoved() {
        syncMOC.performAndWait {
            // Given
            // create user
            let user = ZMUser.insertNewObject(in: syncMOC)
            user.remoteIdentifier = UUID.create()
            user.domain = groupConversation.domain

            // set message protocol
            groupConversation.messageProtocol = .mls

            // create the event
            let memberLeaveEvent = Payload.UpdateConverationMemberLeave(
                userIDs: [user.remoteIdentifier],
                qualifiedUserIDs: [user.qualifiedID!]
            )

            let payload = self.conversationEventPayload(
                from: memberLeaveEvent,
                conversationID: groupConversation.qualifiedID,
                senderID: user.qualifiedID,
                timestamp: nil
            )

            let updateEvent = self.updateEvent(from: payload.payloadData()!)

            // When
            self.sut.processPayload(
                payload,
                originalEvent: updateEvent,
                in: syncMOC
            )

            // Then
            XCTAssertEqual(mockMLSEventProcessor.wipeMLSGroupForConversationContext_Invocations.count, 0)
        }
    }

    func test_UpdateConversationMemberLeave_DoesntWipeMLSGroup_WhenProtocolIsNotMLS() {
        syncMOC.performAndWait {
            // Given
            // create self user
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID.create()
            selfUser.domain = groupConversation.domain

            // set message protocol
            groupConversation.messageProtocol = .proteus

            // create the event
            let memberLeaveEvent = Payload.UpdateConverationMemberLeave(
                userIDs: [selfUser.remoteIdentifier],
                qualifiedUserIDs: [selfUser.qualifiedID!]
            )

            let payload = self.conversationEventPayload(
                from: memberLeaveEvent,
                conversationID: groupConversation.qualifiedID,
                senderID: selfUser.qualifiedID,
                timestamp: nil
            )

            let updateEvent = self.updateEvent(from: payload.payloadData()!)

            // When
            self.sut.processPayload(
                payload,
                originalEvent: updateEvent,
                in: syncMOC
            )

            // Then
            XCTAssertEqual(mockMLSEventProcessor.wipeMLSGroupForConversationContext_Invocations.count, 0)
        }
    }

}
