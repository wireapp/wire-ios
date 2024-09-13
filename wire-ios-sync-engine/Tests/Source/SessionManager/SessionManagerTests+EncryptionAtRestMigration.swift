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

import Foundation
import LocalAuthentication
@testable import WireSyncEngine

final class SessionManagerEncryptionAtRestMigrationTests: IntegrationTest {
    override var useInMemoryStore: Bool {
        false
    }

    override func setUp() {
        DeveloperFlag.storage = UserDefaults(suiteName: UUID().uuidString)!
        var flag = DeveloperFlag.proteusViaCoreCrypto
        flag.isOn = false

        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    override func tearDown() {
        DeveloperFlag.storage = .standard
        super.tearDown()
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseIsMigrated_WhenEncryptionAtRestIsEnabled() throws {
        // given
        XCTAssertTrue(login())
        var session = try XCTUnwrap(userSession)
        XCTAssertFalse(session.encryptMessagesAtRest)

        let expectedText = "Hello World"
        session.perform {
            let groupConversation = self.conversation(for: self.groupConversation)
            try! groupConversation?.appendText(content: expectedText)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        try session.setEncryptionAtRest(enabled: true)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        session = try XCTUnwrap(userSession)
        XCTAssertTrue(session.encryptMessagesAtRest)

        try session.unlockDatabase()
        let groupConversation = conversation(for: groupConversation)
        let clientMessage = groupConversation?.lastMessage as? ZMClientMessage
        XCTAssertEqual(clientMessage?.messageText, expectedText)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func testThatDatabaseIsMigrated_WhenEncryptionAtRestIsDisabled() throws {
        // given
        XCTAssertTrue(login())
        var session = try XCTUnwrap(userSession)

        let expectedText = "Hello World"

        try session.setEncryptionAtRest(enabled: true, skipMigration: true)
        XCTAssertTrue(session.encryptMessagesAtRest)

        session.perform {
            let groupConversation = self.conversation(for: self.groupConversation)
            try! groupConversation?.appendText(content: expectedText)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        try session.setEncryptionAtRest(enabled: false)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        session = try XCTUnwrap(userSession)
        XCTAssertFalse(session.encryptMessagesAtRest)

        let groupConversation = conversation(for: groupConversation)
        let clientMessage = groupConversation?.lastMessage as? ZMClientMessage
        XCTAssertEqual(clientMessage?.messageText, expectedText)
    }
}
