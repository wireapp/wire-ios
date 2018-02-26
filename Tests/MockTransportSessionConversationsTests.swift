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

class MockTransportSessionConversationsTests_Swift: MockTransportSessionTests {
    func testThatDefaultAccessModeForOneToOneConversationIsCorrect() {
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "me")
            conversation = session.insertOneOnOneConversation(withSelfUser: selfUser, otherUser: session.insertUser(withName: "friend"))
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(conversation.accessMode, ["private"])
        XCTAssertEqual(conversation.accessRole, "private")
    }

    func testThatDefaultAccessModeForGroupConversationIsCorrect() {
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "me")
            conversation = session.insertGroupConversation(withSelfUser: selfUser, otherUsers: [session.insertUser(withName: "friend"), session.insertUser(withName: "other friend")])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(conversation.accessMode, ["invite"])
        XCTAssertEqual(conversation.accessRole, "activated")
    }

    func testThatDefaultAccessModeForTeamGroupConversationIsCorrect() {
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            let team = session.insertTeam(withName: "Name", isBound: true)
            let selfUser = session.insertSelfUser(withName: "me")
            conversation = session.insertTeamConversation(to: team, with: [session.insertUser(withName: "friend"), session.insertUser(withName: "other friend")], creator: selfUser)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(conversation.accessMode, ["invite"])
        XCTAssertEqual(conversation.accessRole, "activated")
    }
}
