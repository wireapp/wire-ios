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

    override func setUp() {
        super.setUp()
        conversationService = MockConversationServiceInterface()
        conversationService.syncConversationQualifiedID_MockMethod = { _ in
        }
        sut = ConversationEventProcessor(
            context: syncMOC,
            conversationService: conversationService
        )
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
        let mockMLSEventProcessor = MockMLSEventProcessor()
        MLSEventProcessor.setMock(mockMLSEventProcessor)

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
        let updateConversationCalls = mockMLSEventProcessor.calls.updateConversationIfNeeded
        XCTAssertEqual(updateConversationCalls.count, 1)
        XCTAssertEqual(updateConversationCalls.first?.conversation, groupConversation)

    }

    // MARK: - MLS: Welcome Message

    func testUpdateConversationMLSWelcome_AsksToProcessWelcomeMessage() async throws {
        // given
        var updateEvent: ZMUpdateEvent?
        let message = "welcome message"
        let mockEventProcessor = MockMLSEventProcessor()
        MLSEventProcessor.setMock(mockEventProcessor)

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
        await self.sut.processConversationEvents([unwrappedUpdateEvent])

        // then
        XCTAssertEqual(message, mockEventProcessor.calls.processWelcomeMessage.first)

    }

    // MARK: - MLS conversation member leave

    func test_UpdateConversationMemberLeave_WipesMLSGroup() async throws {
        // Given
        var updateEvent: ZMUpdateEvent?
        // set mock event processor
        let mockEventProcessor = MockMLSEventProcessor()
        MLSEventProcessor.setMock(mockEventProcessor)

        await syncMOC.perform { [self] in
            // Create self user
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID.create()
            selfUser.domain = groupConversation.domain

            // Set message protocol
            groupConversation.messageProtocol = .mls

            // Create the event
            let payload = Payload.UpdateConverationMemberLeave(
                userIDs: [selfUser.remoteIdentifier],
                qualifiedUserIDs: [selfUser.qualifiedID!]
            )
            updateEvent = self.updateEvent(from: payload)
        }

        let event = try XCTUnwrap(updateEvent)

        // When
        await self.sut.processConversationEvents([event])

        // Then
        XCTAssertEqual(mockEventProcessor.calls.wipeGroup.count, 1)
        XCTAssertEqual(mockEventProcessor.calls.wipeGroup.first, groupConversation)

    }

    func test_UpdateConversationMemberLeave_DoesntWipeMLSGroup_WhenSelfUserIsNotRemoved() async throws {
        // Given
        var updateEvent: ZMUpdateEvent?

        // set mock event processor
        let mockEventProcessor = MockMLSEventProcessor()
        MLSEventProcessor.setMock(mockEventProcessor)

        await syncMOC.perform { [self] in

            // create user
            let user = ZMUser.insertNewObject(in: syncMOC)
            user.remoteIdentifier = UUID.create()
            user.domain = groupConversation.domain

            // set message protocol
            groupConversation.messageProtocol = .mls

            // create the event
            let payload = Payload.UpdateConverationMemberLeave(
                userIDs: [user.remoteIdentifier],
                qualifiedUserIDs: [user.qualifiedID!]
            )
            updateEvent = self.updateEvent(from: payload)
        }
        let event = try XCTUnwrap(updateEvent)
        // When
        await self.sut.processConversationEvents([event])

        // Then
        XCTAssertEqual(mockEventProcessor.calls.wipeGroup.count, 0)
    }

    func test_UpdateConversationMemberLeave_DoesntWipeMLSGroup_WhenProtocolIsNotMLS() async throws {

        // Given
        var updateEvent: ZMUpdateEvent?

        // set mock event processor
        let mockEventProcessor = MockMLSEventProcessor()
        MLSEventProcessor.setMock(mockEventProcessor)

        await syncMOC.perform { [self] in

            // create self user
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.remoteIdentifier = UUID.create()
            selfUser.domain = groupConversation.domain

            // set message protocol
            groupConversation.messageProtocol = .proteus

            // create the event
            let payload = Payload.UpdateConverationMemberLeave(
                userIDs: [selfUser.remoteIdentifier],
                qualifiedUserIDs: [selfUser.qualifiedID!]
            )
            updateEvent = self.updateEvent(from: payload)
        }
        let event = try XCTUnwrap(updateEvent)

        // When
        await self.sut.processConversationEvents([event])

        // Then
        XCTAssertEqual(mockEventProcessor.calls.wipeGroup.count, 0)
    }

    /*
     // MARK: - Event processing

     // MARK: Conversation Creation

     func testThatItProcessesConversationCreateEvents() {
         syncMOC.performAndWait {
             // given
             let selfUserID = ZMUser.selfUser(in: self.syncMOC).remoteIdentifier!
             let qualifiedID = QualifiedID(uuid: UUID(), domain: self.owningDomain)
             let payload = Payload.Conversation.stub(
                 qualifiedID: qualifiedID,
                 type: .group,
                 name: "Hello World",
                 members: .init(selfMember: Payload.ConversationMember(id: selfUserID),
                 others: [])
             )
             let event = updateEvent(from: payload,
                                     conversationID: .init(uuid: UUID(), domain: owningDomain),
                                     senderID: otherUser.qualifiedID!,
                                     timestamp: Date())

             // when
             self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

             // then
             let conversation = ZMConversation.fetch(with: qualifiedID.uuid, domain: qualifiedID.domain, in: self.syncMOC)
             XCTAssertNotNil(conversation)
         }
     }

     // MARK: Conversation deletion

     func testThatItHandlesConversationDeletedUpdateEvent() {

         syncMOC.performAndWait {
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
             let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!
             self.sut?.processEvents([event], liveEvents: true, prefetchResult: nil)

             // THEN
             XCTAssertTrue(self.groupConversation.isDeletedRemotely)
         }
     }

     // MARK: Conversation renaming

     func testThatItHandlesConverationNameUpdateEvent() {
         syncMOC.performAndWait {
             // given
             let newName = "Hello World"
             let payload = Payload.UpdateConversationName(name: newName)
             let event = updateEvent(from: payload,
                                     conversationID: self.groupConversation.qualifiedID,
                                     senderID: self.otherUser.qualifiedID!,
                                     timestamp: Date())

             // when
             self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

             // then
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

     func testThatItUpdatesHasReadReceiptsEnabled_WhenReceivingReceiptModeUpdateEvent() {
         self.syncMOC.performAndWait {
             // GIVEN
             let event = receiptModeUpdateEvent(enabled: true)

             // WHEN
             self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

             // THEN
             XCTAssertEqual(self.groupConversation.hasReadReceiptsEnabled, true)
         }
     }

     func testThatItInsertsSystemMessageEnabled_WhenReceivingReceiptModeUpdateEvent() {
         self.syncMOC.performAndWait {
             // GIVEN
             let event = receiptModeUpdateEvent(enabled: true)

             // WHEN
             self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

             // THEN
             guard let message = self.groupConversation?.lastMessage as? ZMSystemMessage else {
                 return XCTFail("Last conversation message is not a system message")
             }
             XCTAssertEqual(message.systemMessageType, .readReceiptsEnabled)
         }
     }

     func testThatItInsertsSystemMessageDisabled_WhenReceivingReceiptModeUpdateEvent() {
         self.syncMOC.performAndWait {
             // GIVEN
             let event = receiptModeUpdateEvent(enabled: false)

             // WHEN
             self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

             // THEN
             guard let message = self.groupConversation?.lastMessage as? ZMSystemMessage else {
                 return XCTFail("Last conversation message is not a system message")
             }
             XCTAssertEqual(message.systemMessageType, .readReceiptsDisabled)
         }
     }

     func testThatItDoesntInsertsSystemMessage_WhenReceivingReceiptModeUpdateEventWhichHasAlreadybeenApplied() {
         self.syncMOC.performAndWait {
             // GIVEN
             let event = receiptModeUpdateEvent(enabled: true)
             groupConversation.lastServerTimeStamp = event.timestamp

             // WHEN
             performIgnoringZMLogError {
                 self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
             }

             // THEN
             XCTAssertEqual(self.groupConversation?.allMessages.count, 0)
         }
     }

     // MARK: Access Mode

     func testThatItHandlesAccessModeUpdateEvent() {
         self.syncMOC.performAndWait {

             let newAccessMode = ConversationAccessMode(values: ["code", "invite"])
             let newAccessRole: Set<ConversationAccessRoleV2> = [.teamMember, .guest]

             XCTAssertNotEqual(self.groupConversation.accessMode, newAccessMode)
             XCTAssertNotEqual(self.groupConversation.accessRoles, newAccessRole)

             // GIVEN
             let event = self.updateEvent(type: "conversation.access-update",
                                          senderID: self.otherUser.remoteIdentifier!,
                                          conversationID: self.groupConversation.remoteIdentifier!,
                                          timestamp: Date(),
                                          dataPayload: [
                                             "access": newAccessMode.stringValue,
                                             "access_role_v2": newAccessRole.map(\.rawValue)
                                          ])

             // WHEN
             self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

             // THEN
             XCTAssertEqual(self.groupConversation.accessMode, newAccessMode)
             XCTAssertEqual(self.groupConversation.accessRoles, newAccessRole)
         }
     }

     // MARK: Access Role

     func testThatItHandlesAccessRoleUpdateEventWhenMappingFromLegacyAccessRoleToAccessRoleV2() {
         self.syncMOC.performAndWait {
             let newAccessMode = ConversationAccessMode(values: ["code", "invite"])
             let legacyAccessRole: ConversationAccessRole = .team

             // GIVEN
             let event = self.updateEvent(
                 type: "conversation.access-update",
                 senderID: self.otherUser.remoteIdentifier!,
                 conversationID: self.groupConversation.remoteIdentifier!,
                 timestamp: Date(),
                 dataPayload: [
                     "access": newAccessMode.stringValue,
                     "access_role": legacyAccessRole.rawValue
                 ])

             // WHEN
             self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

             // THEN
             let newAccessRole = ConversationAccessRoleV2.fromLegacyAccessRole(legacyAccessRole)
             XCTAssertEqual(self.groupConversation.accessRoles, newAccessRole)
         }
     }

     // MARK: Message Timer

     func testThatItHandlesMessageTimerUpdateEvent_Value() {
         syncMOC.performGroupedBlockAndWait {
             XCTAssertNil(self.groupConversation.activeMessageDestructionTimeoutValue)

             // GIVEN
             let event = self.updateEvent(type: "conversation.message-timer-update",
                                          senderID: self.otherUser.remoteIdentifier!,
                                          conversationID: self.groupConversation.remoteIdentifier!,
                                          timestamp: Date(),
                                          dataPayload: ["message_timer": 31536000000])

             // WHEN
             self.sut?.processEvents([event], liveEvents: true, prefetchResult: nil)

             // THEN
             XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutValue!, .init(rawValue: 31536000))
             XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutType!, .groupConversation)
             guard let message = self.groupConversation?.lastMessage as? ZMSystemMessage else {
                 return XCTFail("Last conversation message is not a system message")
             }
             XCTAssertEqual(message.systemMessageType, .messageTimerUpdate)
         }
     }

     func testThatItHandlesMessageTimerUpdateEvent_NoValue() {
         syncMOC.performGroupedBlockAndWait {
             self.groupConversation.setMessageDestructionTimeoutValue(.init(rawValue: 300), for: .groupConversation)
             XCTAssertEqual(self.groupConversation.activeMessageDestructionTimeoutValue!, .fiveMinutes)
             XCTAssertEqual(self.groupConversation.activeMessageDestructionTimeoutType!, .groupConversation)

             // Given
             let event = self.updateEvent(type: "conversation.message-timer-update",
                                          senderID: self.otherUser.remoteIdentifier!,
                                          conversationID: self.groupConversation.remoteIdentifier!,
                                          timestamp: Date(),
                                          dataPayload: ["message_timer": NSNull()])

             // WHEN
             self.sut?.processEvents([event], liveEvents: true, prefetchResult: nil)

             // THEN
             XCTAssertNil(self.groupConversation.activeMessageDestructionTimeoutValue)
             guard let message = self.groupConversation.lastMessage as? ZMSystemMessage else {
                 return XCTFail("Last conversation message is not a system message")
             }
             XCTAssertEqual(message.systemMessageType, .messageTimerUpdate)
         }
     }

     func testThatItGeneratesCorrectSystemMessageWhenSyncedTimeoutTurnedOff() {
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
             let event = self.updateEvent(type: "conversation.message-timer-update",
                                          senderID: self.otherUser.remoteIdentifier!,
                                          conversationID: self.groupConversation.remoteIdentifier!,
                                          timestamp: Date(),
                                          dataPayload: ["message_timer": 0])

             // WHEN
             self.sut?.processEvents([event], liveEvents: true, prefetchResult: nil)

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

     func testThatItDiscardsDoubleSystemMessageWhenSyncedTimeoutChanges_Value() {

         syncMOC.performGroupedBlockAndWait {
             XCTAssertNil(self.groupConversation.activeMessageDestructionTimeoutValue)

             // Given
             let messageTimerMillis = 31536000000
             let messageTimer = MessageDestructionTimeoutValue(rawValue: TimeInterval(messageTimerMillis / 1000))
             let selfUser = ZMUser.selfUser(in: self.syncMOC)
             selfUser.remoteIdentifier = UUID.create()

             let event = self.updateEvent(type: "conversation.message-timer-update",
                                          senderID: selfUser.remoteIdentifier!,
                                          conversationID: self.groupConversation.remoteIdentifier!,
                                          timestamp: Date(),
                                          dataPayload: ["message_timer": messageTimerMillis])

             // WHEN
             self.sut?.processEvents([event], liveEvents: true, prefetchResult: nil) // First event

             XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutValue!, messageTimer)
             XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutType!, .groupConversation)
             guard let firstMessage = self.groupConversation?.lastMessage as? ZMSystemMessage else {
                 return XCTFail("Last conversation message is not a system message")
             }
             XCTAssertEqual(firstMessage.systemMessageType, .messageTimerUpdate)

             self.sut?.processEvents([event], liveEvents: true, prefetchResult: nil) // Second duplicated event

             // THEN
             XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutValue!, messageTimer)
             XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutType!, .groupConversation)
             guard let secondMessage = self.groupConversation?.lastMessage as? ZMSystemMessage else {
                 return XCTFail("Last conversation message is not a system message")
             }
             XCTAssertEqual(firstMessage, secondMessage) // Check that no other messages are appended in the conversation
         }
     }

     func testThatItDiscardsDoubleSystemMessageWhenSyncedTimeoutChanges_NoValue() {

         syncMOC.performGroupedBlockAndWait {
             XCTAssertNil(self.groupConversation.activeMessageDestructionTimeoutValue)

             // Given
             let valuedMessageTimerMillis = 31536000000
             let valuedMessageTimer = MessageDestructionTimeoutValue(rawValue: TimeInterval(valuedMessageTimerMillis / 1000))

             let selfUser = ZMUser.selfUser(in: self.syncMOC)
             selfUser.remoteIdentifier = UUID.create()

             let valuedEvent = self.updateEvent(type: "conversation.message-timer-update",
                                                senderID: selfUser.remoteIdentifier!,
                                                conversationID: self.groupConversation.remoteIdentifier!,
                                                timestamp: Date(),
                                                dataPayload: ["message_timer": valuedMessageTimerMillis])

             let event = self.updateEvent(type: "conversation.message-timer-update",
                                          senderID: selfUser.remoteIdentifier!,
                                          conversationID: self.groupConversation.remoteIdentifier!,
                                          timestamp: Date(timeIntervalSinceNow: 100),
                                          dataPayload: ["message_timer": 0])

             // WHEN

             // First event with valued timer
             self.sut?.processEvents([valuedEvent], liveEvents: true, prefetchResult: nil)
             XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutType!, .groupConversation)
             XCTAssertEqual(self.groupConversation?.activeMessageDestructionTimeoutValue!, valuedMessageTimer)

             // Second event with timer = nil
             self.sut?.processEvents([event], liveEvents: true, prefetchResult: nil)
             XCTAssertNil(self.groupConversation?.activeMessageDestructionTimeoutValue)

             guard let firstMessage = self.groupConversation?.lastMessage as? ZMSystemMessage else {
                 return XCTFail("Last conversation message is not a system message")
             }
             XCTAssertEqual(firstMessage.systemMessageType, .messageTimerUpdate)

             // Third event with timer = nil
             self.sut?.processEvents([event], liveEvents: true, prefetchResult: nil)

             // THEN
             XCTAssertNil(self.groupConversation?.activeMessageDestructionTimeoutValue)
             guard let secondMessage = self.groupConversation?.lastMessage as? ZMSystemMessage else { return XCTFail("Last conversation message is not a system message")
             }
             XCTAssertEqual(firstMessage, secondMessage) // Check that no other messages are appended in the conversation
         }
     }


     func testThatItChangesRoleAfterMemberUpdate() {

         syncMOC.performAndWait {

             let userId = UUID.create()

             let user = ZMUser.insertNewObject(in: self.syncMOC)
             user.remoteIdentifier = userId

             let selfUser = ZMUser.selfUser(in: self.syncMOC)
             selfUser.remoteIdentifier = UUID.create()

             let oldRole = Role.insertNewObject(in: self.syncMOC)
             oldRole.name = "old"
             oldRole.conversation = self.groupConversation

             self.groupConversation.addParticipantAndUpdateConversationState(user: user, role: oldRole)

             let newRole = Role.insertNewObject(in: self.syncMOC)
             newRole.name = "new"
             newRole.conversation = self.groupConversation
             self.syncMOC.saveOrRollback()

             // GIVEN
             let event = self.updateEvent(type: "conversation.member-update",
                                          senderID: selfUser.remoteIdentifier!,
                                          conversationID: self.groupConversation.remoteIdentifier!,
                                          timestamp: Date(timeIntervalSinceNow: 100),
                                          dataPayload: [
                                             "target": userId.transportString(),
                                             "conversation_role": "new"
                                          ])

             // WHEN
             self.sut?.processEvents([event], liveEvents: true, prefetchResult: nil)

             // THEN
             guard let participant = self.groupConversation.participantRoles
                     .first(where: {$0.user == user}) else {
                         return XCTFail("No user in convo")
                     }
             XCTAssertEqual(participant.role, newRole)
         }
     }

     func testThatItChangesSelfRoleAfterMemberUpdate() {

         syncMOC.performAndWait {

             let selfUser = ZMUser.selfUser(in: self.syncMOC)
             selfUser.remoteIdentifier = UUID.create()

             let oldRole = Role.insertNewObject(in: self.syncMOC)
             oldRole.name = "old"
             oldRole.conversation = self.groupConversation

             self.groupConversation.addParticipantAndUpdateConversationState(user: selfUser, role: oldRole)

             let newRole = Role.insertNewObject(in: self.syncMOC)
             newRole.name = "new"
             newRole.conversation = self.groupConversation
             self.syncMOC.saveOrRollback()

             // GIVEN
             let event = self.updateEvent(type: "conversation.member-update",
                                          senderID: selfUser.remoteIdentifier!,
                                          conversationID: self.groupConversation.remoteIdentifier!,
                                          timestamp: Date(timeIntervalSinceNow: 100),
                                          dataPayload: [
                                             "target": selfUser.remoteIdentifier.transportString(),
                                             "conversation_role": "new"
                                          ])

             // WHEN
             self.sut?.processEvents([event], liveEvents: true, prefetchResult: nil)

             // THEN
             guard let participant = self.groupConversation.participantRoles
                     .first(where: {$0.user == selfUser}) else {
                         return XCTFail("No user in convo")
                     }
             XCTAssertEqual(participant.role, newRole)
         }
     }

     */

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
