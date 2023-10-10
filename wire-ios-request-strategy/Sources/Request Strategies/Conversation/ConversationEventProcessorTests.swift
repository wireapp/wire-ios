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
    var mockMLSEventProcessor: MockMLSEventProcessor!
    var conversationService: MockConversationService!

    override func setUp() {
        super.setUp()
        conversationService = MockConversationService()
        mockMLSEventProcessor = MockMLSEventProcessor()
        sut = ConversationEventProcessor(
            context: syncMOC,
            conversationService: conversationService,
            mlsEventProcessor: mockMLSEventProcessor
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

    func test_ProcessMemberJoinEvent() throws {
        syncMOC.performAndWait {
            // Given
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
            let message = "welcome message"
            let event = Payload.UpdateConversationMLSWelcome(
                id: self.groupConversation.remoteIdentifier!,
                qualifiedID: self.groupConversation.qualifiedID,
                from: self.otherUser.remoteIdentifier,
                qualifiedFrom: self.otherUser.qualifiedID,
                timestamp: Date(),
                type: "conversation.mls-welcome",
                data: message
            )
            let updateEvent = self.updateEvent(from: event.payloadData()!)

            // when
            self.sut.processConversationEvents([updateEvent])

            // then
            let invocation = self.mockMLSEventProcessor.calls.processWelcomeMessage.first
            XCTAssertEqual(invocation?.0, message)
            XCTAssertEqual(invocation?.1, self.groupConversation.qualifiedID)
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
