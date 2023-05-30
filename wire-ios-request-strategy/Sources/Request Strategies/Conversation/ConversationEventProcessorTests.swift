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

    // MARK: - Member join

    func test_ProcessMemberJoinEvent() throws {
        syncMOC.performAndWait {
            // Given
            let sut = ConversationEventProcessor(
                context: syncMOC,
                conversationService: MockConversationService()
            )

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
