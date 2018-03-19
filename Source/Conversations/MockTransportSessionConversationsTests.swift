////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

@testable import WireMockTransport

class MockTransportSessionConversationsTests_Swift: MockTransportSessionTests {

    var selfUser: MockUser!
    var team: MockTeam!

    override func setUp() {
        super.setUp()
        sut.performRemoteChanges { session in
            self.team = session.insertTeam(withName: "Name", isBound: true)
            self.selfUser = session.insertSelfUser(withName: "me")
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    override func tearDown() {
        self.team = nil
        self.selfUser = nil
        super.tearDown()
    }

    func testThatDefaultAccessModeForOneToOneConversationIsCorrect() {
        // when
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertOneOnOneConversation(withSelfUser: self.selfUser, otherUser: session.insertUser(withName: "friend"))
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation.accessMode, ["private"])
        XCTAssertEqual(conversation.accessRole, "private")
    }

    func testThatDefaultAccessModeForGroupConversationIsCorrect() {
        // when
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertGroupConversation(withSelfUser: self.selfUser, otherUsers: [session.insertUser(withName: "friend"), session.insertUser(withName: "other friend")])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation.accessMode, ["invite"])
        XCTAssertEqual(conversation.accessRole, "activated")
    }

    func testThatDefaultAccessModeForTeamGroupConversationIsCorrect() {
        // when
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertTeamConversation(to: self.team, with: [session.insertUser(withName: "friend"), session.insertUser(withName: "other friend")], creator: self.selfUser)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation.accessMode, ["invite"])
        XCTAssertEqual(conversation.accessRole, "activated")
    }

    func testThatPushPayloadIsNilWhenThereAreNoChanges() {
        // given
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertTeamConversation(to: self.team, with: [], creator: self.selfUser)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(conversation.changePushPayload)
    }

    func testThatPushPayloadIsPresentWhenChangingAccessMode() {
        // given
        let newAccessMode = ["invite", "code"]
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertTeamConversation(to: self.team, with: [], creator: self.selfUser)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotEqual(conversation.accessMode, newAccessMode)

        // when
        conversation.accessMode = newAccessMode

        // then
        XCTAssertNotNil(conversation.changePushPayload)
        guard let access = conversation.changePushPayload?["access"] as? [String] else { XCTFail(); return }
        XCTAssertEqual(access, newAccessMode)
    }

    func testThatPushPayloadIsPresentWhenChangingAccessRole() {
        // given
        let newAccessRole = "non_activated"
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertTeamConversation(to: self.team, with: [], creator: self.selfUser)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotEqual(conversation.accessRole, newAccessRole)

        // when
        conversation.accessRole = newAccessRole

        // then
        XCTAssertNotNil(conversation.changePushPayload)
        guard let accessRole = conversation.changePushPayload?["access_role"] as? String else { XCTFail(); return }
        XCTAssertEqual(accessRole, newAccessRole)
    }

    func testThatUpdateEventIsGeneratedWhenChangingAccessRoles() {
        // given
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertTeamConversation(to: self.team, with: [self.selfUser], creator: session.insertUser(withName: "some"))
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        sut.saveAndCreatePushChannelEventForSelfUser()
        let eventsCount = sut.generatedPushEvents.count

        // when
        sut.performRemoteChanges { session in
            conversation.accessRole = "non_activated"
            conversation.accessMode = ["invite", "code"]
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.generatedPushEvents.count, eventsCount + 1)
        guard let lastEvent = sut.generatedPushEvents.lastObject as? MockPushEvent else { XCTFail(); return }
        guard let payloadData = lastEvent.payload as? [String : Any] else { XCTFail(); return }
        guard let data = payloadData["data"] as? [String : Any] else { XCTFail(); return }

        XCTAssertNotNil(data["access"])
        XCTAssertNotNil(data["access_role"])

    }
}
