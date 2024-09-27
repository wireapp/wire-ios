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

import WireTesting
import XCTest
@testable import WireSyncEngine

final class SessionManagerMessageRetentionTests: IntegrationTest {
    override var useInMemoryStore: Bool {
        false
    }

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    func testThatItDeletesMessagesOlderThanTheRetentionLimit() {
        // given
        XCTAssertTrue(login())
        establishSession(with: user2)

        remotelyInsert(text: "Hello 1", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 2", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 3", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 4) // text messages + system messages

        // when
        sessionManager?.configuration.messageRetentionInterval = 1
        spinMainQueue(withTimeout: 1)
        sessionManager?.logoutCurrentSession()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(login())

        // then
        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 0)
    }

    func testThatItKeepsMessagesNewerThanTheRetentionLimit() {
        // given
        XCTAssertTrue(login())
        establishSession(with: user2)

        remotelyInsert(text: "Hello 1", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 2", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 3", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 4) // text messages + system message

        // when
        sessionManager?.configuration.messageRetentionInterval = 100
        sessionManager?.logoutCurrentSession()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(login())

        // then

        // only text messages
        // system message is ignored due to `messageRetentionInterval`.
        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 3)
    }

    func testThatItKeepsMessagesIfThereIsNoRetentionLimit() {
        // given
        XCTAssertTrue(login())
        establishSession(with: user2)

        remotelyInsert(text: "Hello 1", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 2", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        remotelyInsert(text: "Hello 3", from: user2.clients.anyObject() as! MockUserClient, into: groupConversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 4) // text messages + system messages

        // when
        sessionManager?.configuration.messageRetentionInterval = nil
        sessionManager?.logoutCurrentSession()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(login())

        // then
        XCTAssertEqual(conversation(for: groupConversation)?.allMessages.count, 4)
    }
}
