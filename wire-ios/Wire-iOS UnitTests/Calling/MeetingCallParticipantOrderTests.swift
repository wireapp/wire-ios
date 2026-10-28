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

import WireDataModel
import WireSyncEngine
import XCTest

@testable import Wire

final class MeetingCallParticipantOrderTests: XCTestCase {

    @MainActor
    func testMeetingCallParticipantsPrioritizeHostAndSelf() async throws {
        let fixture = try await CoreDataFixture()
        let selfUser = try XCTUnwrap(fixture.selfUser)
        let host = try XCTUnwrap(fixture.otherUser)
        let bob = fixture.createUser(name: "Bob")
        let alice = fixture.createUser(name: "Alice")
        let conversation = ZMConversation.insertNewObject(in: fixture.uiMOC)
        conversation.conversationType = .group
        conversation.groupType = .meeting
        let meeting = StoredMeeting.insertNewObject(in: fixture.uiMOC)
        meeting.conversation = conversation
        meeting.creator = host
        let channel = MockVoiceChannel(conversation: conversation)
        channel.mockInitiator = bob
        let participants = [bob, selfUser, alice, host].map {
            CallParticipant(user: $0, clientId: "1", state: .connecting, activeSpeakerState: .inactive)
        }

        XCTAssertEqual(
            channel.orderedMeetingParticipants(participants),
            [participants[3], participants[1], participants[0], participants[2]]
        )

        meeting.creator = selfUser
        XCTAssertEqual(
            channel.orderedMeetingParticipants(participants),
            [participants[1], participants[0], participants[2], participants[3]]
        )

        meeting.creator = host
        let secondMeeting = StoredMeeting.insertNewObject(in: fixture.uiMOC)
        secondMeeting.conversation = conversation
        secondMeeting.creator = bob
        XCTAssertEqual(
            channel.orderedMeetingParticipants(participants),
            [participants[1], participants[0], participants[2], participants[3]]
        )

        conversation.groupType = .group
        XCTAssertEqual(channel.orderedMeetingParticipants(participants), participants)
    }

}
