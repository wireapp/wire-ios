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

        conversationService.syncConversationQualifiedIDCompletion_MockMethod = { _, completion in
            completion()
        }

        sut = ConversationEventProcessor(
            context: syncMOC,
            conversationService: conversationService
        )
    }

    override func tearDown() {
        conversationService = nil
        sut = nil
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

    func test_ProcessMemberJoinEvent() throws {
        syncMOC.performAndWait {
            // Given
            let mockMLSEventProcessor = MockMLSEventProcessor()
            MLSEventProcessor.setMock(mockMLSEventProcessor)

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

            guard let transportPayload = try? payload.toTransportDictionary() else {
                return XCTFail("failed to encode payload")
            }

            guard let event = ZMUpdateEvent(fromEventStreamPayload: transportPayload, uuid: nil) else {
                return XCTFail("failed to create event")
            }

            // When
            sut.processConversationEvents([event])

            // Then
            let updateConversationCalls = mockMLSEventProcessor.calls.updateConversationIfNeeded
            XCTAssertEqual(updateConversationCalls.count, 1)
            XCTAssertEqual(updateConversationCalls.first?.conversation, groupConversation)
        }
    }

    // MARK: - MLS: Welcome Message

    func testUpdateConversationMLSWelcome_AsksToProcessWelcomeMessage() {
        syncMOC.performAndWait {
            // given
            let mockEventProcessor = MockMLSEventProcessor()
            MLSEventProcessor.setMock(mockEventProcessor)

            let message = "welcome message"
            let event = Payload.UpdateConversationMLSWelcome(
                id: groupConversation.remoteIdentifier!,
                qualifiedID: groupConversation.qualifiedID,
                from: otherUser.remoteIdentifier,
                qualifiedFrom: otherUser.qualifiedID,
                timestamp: Date(),
                type: "conversation.mls-welcome",
                data: message
            )
            let updateEvent = self.updateEvent(from: event.payloadData()!)

            // when
            self.sut.processConversationEvents([updateEvent])

            // then
            XCTAssertEqual(message, mockEventProcessor.calls.processWelcomeMessage.first)
        }
    }

    // MARK: - MLS conversation member leave

    func test_UpdateConversationMemberLeave_WipesMLSGroup() {
        syncMOC.performAndWait {
            // Given
            // set mock event processor
            let mockEventProcessor = MockMLSEventProcessor()
            MLSEventProcessor.setMock(mockEventProcessor)

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
            let updateEvent = self.updateEvent(from: payload)

            // When
            self.sut.processConversationEvents([updateEvent])

            // Then
            XCTAssertEqual(mockEventProcessor.calls.wipeGroup.count, 1)
            XCTAssertEqual(mockEventProcessor.calls.wipeGroup.first, groupConversation)
        }
    }

    func test_UpdateConversationMemberLeave_DoesntWipeMLSGroup_WhenSelfUserIsNotRemoved() {
        syncMOC.performAndWait {
            // Given
            // set mock event processor
            let mockEventProcessor = MockMLSEventProcessor()
            MLSEventProcessor.setMock(mockEventProcessor)

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
            let updateEvent = self.updateEvent(from: payload)

            // When
            self.sut.processConversationEvents([updateEvent])

            // Then
            XCTAssertEqual(mockEventProcessor.calls.wipeGroup.count, 0)
        }
    }

    func test_UpdateConversationMemberLeave_DoesntWipeMLSGroup_WhenProtocolIsNotMLS() {
        syncMOC.performAndWait {
            // Given
            // set mock event processor
            let mockEventProcessor = MockMLSEventProcessor()
            MLSEventProcessor.setMock(mockEventProcessor)

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
            let updateEvent = self.updateEvent(from: payload)

            // When
            self.sut.processConversationEvents([updateEvent])

            // Then
            XCTAssertEqual(mockEventProcessor.calls.wipeGroup.count, 0)
        }
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
