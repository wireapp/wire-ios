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

@testable import WireDataModel

class ZMConversationCreationSystemMessageTests: ZMConversationTestsBase {

    override func setUp() {
        super.setUp()
    }

    func testSystemMessageWhenCreatingConversationWithNoName() {
        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let alice = self.createUser(onMoc: self.syncMOC)!
            alice.name = "alice"
            let bob = self.createUser(onMoc: self.syncMOC)!
            bob.name = "bob"

            let conversation = ZMConversation.insertGroupConversation(into: self.syncMOC, withParticipants: [alice, bob], name: nil, in: nil)

            XCTAssertEqual(conversation?.messages.count, 1)
            let systemMessage = conversation?.messages.firstObject as? ZMSystemMessage

            XCTAssertNotNil(systemMessage)
            XCTAssertEqual(systemMessage?.systemMessageType, .newConversation)
            XCTAssertNil(systemMessage?.text)
            XCTAssertEqual(systemMessage?.users, [selfUser, alice, bob])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testSystemMessageWhenCreatingConversationWithName() {
        syncMOC.performGroupedBlock {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let alice = self.createUser(onMoc: self.syncMOC)!
            alice.name = "alice"
            let bob = self.createUser(onMoc: self.syncMOC)!
            bob.name = "bob"

            let name = "Crypto"

            let conversation = ZMConversation.insertGroupConversation(into: self.syncMOC, withParticipants: [alice, bob], name: name, in: nil)

            XCTAssertEqual(conversation?.messages.count, 1)

            let systemMessage = conversation?.messages.lastObject as? ZMSystemMessage

            XCTAssertNotNil(systemMessage)
            XCTAssertEqual(systemMessage?.systemMessageType, .newConversation)
            XCTAssertEqual(systemMessage?.text, name)
            XCTAssertEqual(systemMessage?.users, [selfUser, alice, bob])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testSystemMessageWhenCreatingEmptyConversationWithName() {
        syncMOC.performGroupedBlock {
            let name = "Crypto"
            let selfUser = ZMUser.selfUser(in: self.syncMOC)

            let conversation = ZMConversation.insertGroupConversation(into: self.syncMOC, withParticipants: [], name: name, in: nil)

            XCTAssertEqual(conversation?.messages.count, 1)

            let nameMessage = conversation?.messages.firstObject as? ZMSystemMessage
            XCTAssertNotNil(nameMessage)
            XCTAssertEqual(nameMessage?.systemMessageType, .newConversation)
            XCTAssertEqual(nameMessage?.text, name)
            XCTAssertEqual(nameMessage?.users, [selfUser])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }
}
