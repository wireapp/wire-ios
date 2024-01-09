// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
@testable import WireRequestStrategy

class ConversationEventProcessorTests: MessagingTestBase {

    var sut: ConversationEventProcessor!
    var conversationService: MockConversationServiceInterface!
    var mockMLSEventProcessor: MockMLSEventProcessing!

    override func setUp() {
        super.setUp()
        conversationService = MockConversationServiceInterface()
        conversationService.syncConversationQualifiedID_MockMethod = { _ in }

        mockMLSEventProcessor = .init()
        mockMLSEventProcessor.updateConversationIfNeededConversationGroupIDContext_MockMethod = { _, _, _ in }
        mockMLSEventProcessor.processWelcomeMessageConversationIDIn_MockMethod = { _, _, _ in }
        mockMLSEventProcessor.wipeMLSGroupForConversationContext_MockMethod = { _, _ in }

        sut = ConversationEventProcessor(
            context: syncMOC,
            conversationService: conversationService,
            mlsEventProcessor: mockMLSEventProcessor
        )

        BackendInfo.storage = .random()!
        BackendInfo.apiVersion = .v0
    }

    override func tearDown() {
        sut = nil
        conversationService = nil
        mockMLSEventProcessor = nil
        super.tearDown()
    }

    // MARK: - Helpers

    func updateEvent<T: CodableEventData>(from payload: T) -> ZMUpdateEvent {
        return updateEvent(
            from: payload,
            conversationID: groupConversation.qualifiedID,
            senderID: otherUser.qualifiedID,
            timestamp: nil
        )
    }

    // MARK: - Member join

    func test_ProcessMemberJoinEvent() async throws {
        // Given
        var transportPayload: ZMTransportData!

        try await syncMOC.perform { [self] in

            let selfUser = ZMUser.selfUser(in: syncMOC)
            let selfMember = Payload.ConversationMember(qualifiedID: selfUser.qualifiedID)

            let payload = ConversationEventProcessor.MemberJoinPayload(
                id: groupConversation.remoteIdentifier,
                qualifiedID: groupConversation.qualifiedID,
                from: otherUser.remoteIdentifier,
                qualifiedFrom: otherUser.qualifiedID,
                timestamp: nil,
                type: "conversation.member-join",
                data: Payload.UpdateConverationMemberJoin(
                    userIDs: [],
                    users: [selfMember]
                )
            )

            transportPayload = try payload.toTransportDictionary()
        }

        guard let event = ZMUpdateEvent(fromEventStreamPayload: transportPayload, uuid: nil) else {
            return XCTFail("failed to create event")
        }

        // When
        await sut.processConversationEvents([event])

        // Then
        let updateConversationCalls = mockMLSEventProcessor.updateConversationIfNeededConversationGroupIDContext_Invocations
        XCTAssertEqual(updateConversationCalls.count, 1)
        XCTAssertEqual(updateConversationCalls.first?.conversation, groupConversation)

    }

    // MARK: - MLS: Welcome Message

    func testUpdateConversationMLSWelcome_AsksToProcessWelcomeMessage() async throws {
        // given
        var updateEvent: ZMUpdateEvent?
        let message = "welcome message"

        try await syncMOC.perform {

            let event = Payload.UpdateConversationMLSWelcome(
                id: self.groupConversation.remoteIdentifier!,
                qualifiedID: self.groupConversation.qualifiedID,
                from: self.otherUser.remoteIdentifier,
                qualifiedFrom: self.otherUser.qualifiedID,
                timestamp: Date(),
                type: "conversation.mls-welcome",
                data: message
            )

            let unwrappedPayload = try XCTUnwrap(event.payloadData())
            updateEvent = self.updateEvent(from: unwrappedPayload)
        }
        let unwrappedUpdateEvent = try XCTUnwrap(updateEvent)

        // when
        await sut.processConversationEvents([unwrappedUpdateEvent])

        // then
        let qualifiedID = await syncMOC.perform { self.groupConversation.qualifiedID }
        let invocations = mockMLSEventProcessor.processWelcomeMessageConversationIDIn_Invocations
        XCTAssertEqual(invocations.count, 1)
        XCTAssertEqual(invocations.first?.welcomeMessage, message)
        XCTAssertEqual(invocations.first?.conversationID, qualifiedID)
    }

    // MARK: Conversation Creation

    func testThatItProcessesConversationCreateEvents() async {
        // given
        var event: ZMUpdateEvent!
        let qualifiedID = QualifiedID(uuid: UUID(), domain: self.owningDomain)

        await syncMOC.perform {

            let selfUserID = ZMUser.selfUser(in: self.syncMOC).remoteIdentifier!
            let payload = Payload.Conversation.stub(
                qualifiedID: qualifiedID,
                type: .group,
                name: "Hello World",
                members: .init(selfMember: Payload.ConversationMember(id: selfUserID),
                               others: [])
            )
            event = self.updateEvent(from: payload,
                                     conversationID: .init(uuid: UUID(), domain: self.owningDomain),
                                     senderID: self.otherUser.qualifiedID!,
                                     timestamp: Date())
        }
        // when
        await self.sut.processConversationEvents([event])

        await syncMOC.perform {
            // then
            let conversation = ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: self.syncMOC)
            XCTAssertNotNil(conversation)
        }
    }

    // MARK: Conversation Deletion

    func testThatItHandlesConversationDeletedUpdateEvent() async throws {
        var event: ZMUpdateEvent!

        try await syncMOC.perform {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID.create()

            // GIVEN
            let payload: [String: Any] = [
                "from": selfUser.remoteIdentifier!.transportString(),
                "conversation": self.groupConversation!.remoteIdentifier!.transportString(),
                "time": NSDate(timeIntervalSinceNow: 100).transportString(),
                "data": NSNull(),
                "type": "conversation.delete"
            ]

            // WHEN
            event = try XCTUnwrap(ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil))
        }

        await self.sut.processConversationEvents([event])

        await syncMOC.perform {
            // THEN
            XCTAssertTrue(self.groupConversation.isDeletedRemotely)
        }
    }

    // MARK: Conversation renaming

    func testThatItHandlesConverationNameUpdateEvent() async {
        // given
        var event: ZMUpdateEvent!
        let newName = "Hello World"

        await syncMOC.perform {
            let payload = Payload.UpdateConversationName(name: newName)
            event = self.updateEvent(from: payload,
                                     conversationID: self.groupConversation.qualifiedID,
                                     senderID: self.otherUser.qualifiedID!,
                                     timestamp: Date())
        }

        // when
        await self.sut.processConversationEvents([event])

        // then
        await syncMOC.perform {
            XCTAssertEqual(self.groupConversation.userDefinedName, newName)
        }
    }

    // MARK: Receipt Mode

    func receiptModeUpdateEvent(enabled: Bool) -> ZMUpdateEvent {
        let payload = [
            "from": self.otherUser.remoteIdentifier!.transportString(),
            "conversation": self.groupConversation.remoteIdentifier!.transportString(),
            "time": NSDate().transportString(),
            "data": ["receipt_mode": enabled ? 1 : 0],
            "type": "conversation.receipt-mode-update"
        ] as [String: Any]
        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!
    }

    func testThatItUpdatesHasReadReceiptsEnabled_WhenReceivingReceiptModeUpdateEvent() async {
        var event: ZMUpdateEvent!
        await self.syncMOC.perform {
            // GIVEN
            event = self.receiptModeUpdateEvent(enabled: true)
        }

        // WHEN
        await self.sut.processConversationEvents([event])

        // THEN
        await self.syncMOC.perform {
            XCTAssertEqual(self.groupConversation.hasReadReceiptsEnabled, true)
        }
    }

    func testThatItInsertsSystemMessageEnabled_WhenReceivingReceiptModeUpdateEvent() async {
        var event: ZMUpdateEvent!

        await self.syncMOC.perform {
            // GIVEN
            event = self.receiptModeUpdateEvent(enabled: true)
        }

        // WHEN
        await self.sut.processConversationEvents([event])

        await self.syncMOC.perform {
            // THEN
            guard let message = self.groupConversation?.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }

            XCTAssertEqual(message.systemMessageType, .readReceiptsEnabled)
        }
    }

    func testThatItInsertsSystemMessageDisabled_WhenReceivingReceiptModeUpdateEvent() async {
        var event: ZMUpdateEvent!

        await self.syncMOC.perform {
            // GIVEN
            event = self.receiptModeUpdateEvent(enabled: false)
        }

        // WHEN
        await self.sut.processConversationEvents([event])

        await self.syncMOC.perform {
            // THEN
            guard let message = self.groupConversation?.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(message.systemMessageType, .readReceiptsDisabled)
        }
    }

    func testThatItDoesntInsertsSystemMessage_WhenReceivingReceiptModeUpdateEventWhichHasAlreadybeenApplied() async {
        var event: ZMUpdateEvent!

        await self.syncMOC.perform { [self] in
            // GIVEN
            event = receiptModeUpdateEvent(enabled: true)
            groupConversation.lastServerTimeStamp = event.timestamp
        }
        // WHEN
        self.disableZMLogError(true)
        await self.sut.processConversationEvents([event])
        self.disableZMLogError(false)

        await self.syncMOC.perform {
            // THEN
            XCTAssertEqual(self.groupConversation?.allMessages.count, 0)
        }
    }

    // MARK: Access Mode

    func testThatItHandlesAccessModeUpdateEvent() async {
        // GIVEN
        var event: ZMUpdateEvent!
        let newAccessMode = ConversationAccessMode(values: ["code", "invite"])
        let newAccessRole: Set<ConversationAccessRoleV2> = [.teamMember, .guest]

        await self.syncMOC.perform { [self] in

            XCTAssertNotEqual(self.groupConversation.accessMode, newAccessMode)
            XCTAssertNotEqual(self.groupConversation.accessRoles, newAccessRole)

            event = self.updateEvent(type: "conversation.access-update",
                                     senderID: self.otherUser.remoteIdentifier!,
                                     conversationID: self.groupConversation.remoteIdentifier!,
                                     timestamp: Date(),
                                     dataPayload: [
                                        "access": newAccessMode.stringValue,
                                        "access_role_v2": newAccessRole.map(\.rawValue)
                                     ])
        }
        // WHEN
        await self.sut.processConversationEvents([event])

        await self.syncMOC.perform { [self] in
            // THEN
            XCTAssertEqual(self.groupConversation.accessMode, newAccessMode)
            XCTAssertEqual(self.groupConversation.accessRoles, newAccessRole)
        }
    }

    // MARK: Access Role

    func testThatItHandlesAccessRoleUpdateEventWhenMappingFromLegacyAccessRoleToAccessRoleV2() async {
        // GIVEN
        var event: ZMUpdateEvent!
        let legacyAccessRole: ConversationAccessRole = .team

        await self.syncMOC.perform {
            let newAccessMode = ConversationAccessMode(values: ["code", "invite"])

            event = self.updateEvent(
                type: "conversation.access-update",
                senderID: self.otherUser.remoteIdentifier!,
                conversationID: self.groupConversation.remoteIdentifier!,
                timestamp: Date(),
                dataPayload: [
                    "access": newAccessMode.stringValue,
                    "access_role": legacyAccessRole.rawValue
                ])
        }

        // WHEN
        await self.sut.processConversationEvents([event])

        await self.syncMOC.perform { [self] in
            let newAccessRole = ConversationAccessRoleV2.fromLegacyAccessRole(legacyAccessRole)
            XCTAssertEqual(self.groupConversation.accessRoles, newAccessRole)
        }
    }

    // MARK: Message Timer

    func testThatItHandlesMessageTimerUpdateEvent_Value() async {
        var event: ZMUpdateEvent!

        await syncMOC.perform {
            XCTAssertNil(self.groupConversation.activeMessageDestructionTimeoutValue)

            // GIVEN
            event = self.updateEvent(type: "conversation.message-timer-update",
                                     senderID: self.otherUser.remoteIdentifier!,
                                     conversationID: self.groupConversation.remoteIdentifier!,
                                     timestamp: Date(),
                                     dataPayload: ["message_timer": 31536000000])
        }

        // WHEN
        await self.sut.processConversationEvents([event])

        await self.syncMOC.perform { [self] in
            // THEN
            XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutValue!, .init(rawValue: 31536000))
            XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutType!, .groupConversation)
            guard let message = self.groupConversation?.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(message.systemMessageType, .messageTimerUpdate)
        }
    }

    func testThatItHandlesMessageTimerUpdateEvent_NoValue() async {
        var event: ZMUpdateEvent!

        await syncMOC.perform {
            self.groupConversation.setMessageDestructionTimeoutValue(.init(rawValue: 300), for: .groupConversation)
            XCTAssertEqual(self.groupConversation.activeMessageDestructionTimeoutValue!, .fiveMinutes)
            XCTAssertEqual(self.groupConversation.activeMessageDestructionTimeoutType!, .groupConversation)

            // Given
            event = self.updateEvent(type: "conversation.message-timer-update",
                                     senderID: self.otherUser.remoteIdentifier!,
                                     conversationID: self.groupConversation.remoteIdentifier!,
                                     timestamp: Date(),
                                     dataPayload: ["message_timer": NSNull()])
        }

        // WHEN
        await self.sut.processConversationEvents([event])

        await self.syncMOC.perform { [self] in
            // THEN
            XCTAssertNil(self.groupConversation.activeMessageDestructionTimeoutValue)
            guard let message = self.groupConversation.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(message.systemMessageType, .messageTimerUpdate)
        }
    }

    func testThatItGeneratesCorrectSystemMessageWhenSyncedTimeoutTurnedOff() async {
        var event: ZMUpdateEvent!

        // GIVEN: local & synced timeouts exist
        syncMOC.performGroupedBlockAndWait {
            self.groupConversation.setMessageDestructionTimeoutValue(.fiveMinutes, for: .selfUser)
        }

        syncMOC.performGroupedBlockAndWait {
            self.groupConversation.setMessageDestructionTimeoutValue(.oneHour, for: .groupConversation)
        }

        syncMOC.performGroupedBlockAndWait {
            XCTAssertNotNil(self.groupConversation.activeMessageDestructionTimeoutValue)

            // "turn off" synced timeout
            event = self.updateEvent(type: "conversation.message-timer-update",
                                     senderID: self.otherUser.remoteIdentifier!,
                                     conversationID: self.groupConversation.remoteIdentifier!,
                                     timestamp: Date(),
                                     dataPayload: ["message_timer": 0])
        }

        // WHEN
        await self.sut.processConversationEvents([event])

        await self.syncMOC.perform { [self] in

            // THEN: the local timeout still exists
            XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutValue!, .fiveMinutes)
            XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutType!, .selfUser)
            guard let message = self.groupConversation?.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(message.systemMessageType, .messageTimerUpdate)

            // but the system message timer reflects the update to the synced timeout
            XCTAssertEqual(0, message.messageTimer)
        }
    }

    func testThatItDiscardsDoubleSystemMessageWhenSyncedTimeoutChanges_Value() async {
        // Given
        let messageTimerMillis = 31536000000
        let messageTimer = MessageDestructionTimeoutValue(rawValue: TimeInterval(messageTimerMillis / 1000))

        var event: ZMUpdateEvent!

        syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.groupConversation.activeMessageDestructionTimeoutValue)

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID.create()

            event = self.updateEvent(type: "conversation.message-timer-update",
                                     senderID: selfUser.remoteIdentifier!,
                                     conversationID: self.groupConversation.remoteIdentifier!,
                                     timestamp: Date(),
                                     dataPayload: ["message_timer": messageTimerMillis])
        }

        // WHEN
        await self.sut.processConversationEvents([event])
        var firstMessage: ZMSystemMessage?
        await self.syncMOC.perform { [self] in
            XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutValue!, messageTimer)
            XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutType!, .groupConversation)
            firstMessage = self.groupConversation?.lastMessage as? ZMSystemMessage
            guard let firstMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(firstMessage.systemMessageType, .messageTimerUpdate)
        }

        // WHEN
        await self.sut.processConversationEvents([event]) // Second duplicated event

        await self.syncMOC.perform { [self] in
            // THEN
            XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutValue!, messageTimer)
            XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutType!, .groupConversation)
            guard let secondMessage = self.groupConversation?.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(firstMessage, secondMessage) // Check that no other messages are appended in the conversation
        }
    }

    func testThatItDiscardsDoubleSystemMessageWhenSyncedTimeoutChanges_NoValue() async {
        // Given
        let valuedMessageTimerMillis = 31536000000
        let valuedMessageTimer = MessageDestructionTimeoutValue(rawValue: TimeInterval(valuedMessageTimerMillis / 1000))

        var event: ZMUpdateEvent!
        var valuedEvent: ZMUpdateEvent!

        await syncMOC.perform {
            XCTAssertNil(self.groupConversation.activeMessageDestructionTimeoutValue)

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID.create()

            valuedEvent = self.updateEvent(type: "conversation.message-timer-update",
                                               senderID: selfUser.remoteIdentifier!,
                                               conversationID: self.groupConversation.remoteIdentifier!,
                                               timestamp: Date(),
                                               dataPayload: ["message_timer": valuedMessageTimerMillis])

            event = self.updateEvent(type: "conversation.message-timer-update",
                                     senderID: selfUser.remoteIdentifier!,
                                     conversationID: self.groupConversation.remoteIdentifier!,
                                     timestamp: Date(timeIntervalSinceNow: 100),
                                     dataPayload: ["message_timer": 0])
        }

        // WHEN

        // First event with valued timer
        await self.sut.processConversationEvents([valuedEvent])

        await self.syncMOC.perform {
            XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutType!, .groupConversation)
            XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutValue!, valuedMessageTimer)
        }
        // Second event with timer = nil
        await self.sut.processConversationEvents([event])

        var firstMessage: ZMSystemMessage?
        await self.syncMOC.perform {
            XCTAssertNil(self.groupConversation?.activeMessageDestructionTimeoutValue)
            firstMessage = self.groupConversation?.lastMessage as? ZMSystemMessage
            guard let firstMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(firstMessage.systemMessageType, .messageTimerUpdate)
        }

        // Third event with timer = nil
        await self.sut.processConversationEvents([event])

        await self.syncMOC.perform {
            // THEN
            XCTAssertNil(self.groupConversation?.activeMessageDestructionTimeoutValue)
            guard let secondMessage = self.groupConversation?.lastMessage as? ZMSystemMessage else { return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(firstMessage, secondMessage) // Check that no other messages are appended in the conversation
        }
    }

    func testThatItChangesRoleAfterMemberUpdate() async {
        var event: ZMUpdateEvent!
        var user: ZMUser!
        var newRole: Role!

        await syncMOC.perform {

            let userId = UUID.create()

            user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = userId

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID.create()

            let oldRole = Role.insertNewObject(in: self.syncMOC)
            oldRole.name = "old"
            oldRole.conversation = self.groupConversation

            self.groupConversation.addParticipantAndUpdateConversationState(user: user, role: oldRole)

            newRole = Role.insertNewObject(in: self.syncMOC)
            newRole.name = "new"
            newRole.conversation = self.groupConversation
            self.syncMOC.saveOrRollback()

            // GIVEN
            event = self.updateEvent(type: "conversation.member-update",
                                     senderID: selfUser.remoteIdentifier!,
                                     conversationID: self.groupConversation.remoteIdentifier!,
                                     timestamp: Date(timeIntervalSinceNow: 100),
                                     dataPayload: [
                                        "target": userId.transportString(),
                                        "conversation_role": "new"
                                     ])
        }
        // WHEN
        await self.sut.processConversationEvents([event])

        await syncMOC.perform {
            // THEN
            guard let participant = self.groupConversation.participantRoles
                .first(where: {$0.user == user}) else {
                return XCTFail("No user in convo")
            }
            XCTAssertEqual(participant.role, newRole)
        }
    }

    func testThatItChangesSelfRoleAfterMemberUpdate() async {
        var event: ZMUpdateEvent!
        var newRole: Role!
        var selfUser: ZMUser!

        await syncMOC.perform {

            selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID.create()

            let oldRole = Role.insertNewObject(in: self.syncMOC)
            oldRole.name = "old"
            oldRole.conversation = self.groupConversation

            self.groupConversation.addParticipantAndUpdateConversationState(user: selfUser, role: oldRole)

            newRole = Role.insertNewObject(in: self.syncMOC)
            newRole.name = "new"
            newRole.conversation = self.groupConversation
            self.syncMOC.saveOrRollback()

            // GIVEN
            event = self.updateEvent(type: "conversation.member-update",
                                     senderID: selfUser.remoteIdentifier!,
                                     conversationID: self.groupConversation.remoteIdentifier!,
                                     timestamp: Date(timeIntervalSinceNow: 100),
                                     dataPayload: [
                                        "target": selfUser.remoteIdentifier.transportString(),
                                        "conversation_role": "new"
                                     ])
        }
        // WHEN
        await self.sut.processConversationEvents([event])

        await syncMOC.perform {
            // THEN
            guard let participant = self.groupConversation.participantRoles
                .first(where: {$0.user == selfUser}) else {
                return XCTFail("No user in convo")
            }
            XCTAssertEqual(participant.role, newRole)
        }
    }

    func updateEvent(type: String,
                     senderID: UUID,
                     conversationID: UUID,
                     timestamp: Date,
                     dataPayload: [String: Any]) -> ZMUpdateEvent {
        let payload: [String: Any] = [
            "from": senderID.transportString(),
            "conversation": conversationID.transportString(),
            "time": timestamp.transportString(),
            "data": dataPayload,
            "type": type
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!
    }

}

private extension Encodable {

    func toTransportDictionary() throws -> ZMTransportData {
        return try toDictionary() as ZMTransportData
    }

    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let json = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return json as! [String: Any]
    }

}
