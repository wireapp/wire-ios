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
@testable import WireDataModel

class UserClientTests_ResetSession: DiskDatabaseTest {
    func testThatDecryptionFailedSystemMessageIsUpdated_WhenSessionIsReset() throws {
        // given
        let selfUser = ZMUser.selfUser(in: moc)
        let otherUser = createUser()
        _ = createClient(user: selfUser)
        let otherClient = createClient(user: otherUser)

        let connection = ZMConnection.insertNewSentConnection(to: otherUser)
        connection.status = .accepted
        otherUser.oneOnOneConversation?.appendDecryptionFailedSystemMessage(
            at: Date(),
            sender: otherUser,
            client: otherClient,
            errorCode: Int(CBOX_TOO_DISTANT_FUTURE.rawValue)
        )
        let systemMessage: ZMSystemMessage = (otherUser.oneOnOneConversation?.lastMessage as! ZMSystemMessage)
        moc.saveOrRollback()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        otherClient.resolveDecryptionFailedSystemMessages()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageType.decryptionFailedResolved)
    }

    func testThatDecryptionFailedSystemMessageIsNotUpdated_WhenOfTypeIdentityChanged() throws {
        // given
        let selfUser = ZMUser.selfUser(in: moc)
        let otherUser = createUser()
        _ = createClient(user: selfUser)
        let otherClient = createClient(user: otherUser)

        let connection = ZMConnection.insertNewSentConnection(to: otherUser)
        connection.status = .accepted
        otherUser.oneOnOneConversation?.appendDecryptionFailedSystemMessage(
            at: Date(),
            sender: otherUser,
            client: otherClient,
            errorCode: Int(CBOX_REMOTE_IDENTITY_CHANGED.rawValue)
        )
        let systemMessage: ZMSystemMessage = (otherUser.oneOnOneConversation?.lastMessage as! ZMSystemMessage)
        moc.saveOrRollback()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        otherClient.resolveDecryptionFailedSystemMessages()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageType.decryptionFailed_RemoteIdentityChanged)
    }

    func testThatDecryptionFailedSystemMessageIsNotUpdated_WhenUnrelatedSessionIsReset() throws {
        // given
        let selfUser = ZMUser.selfUser(in: moc)
        let otherUser = createUser()

        _ = createClient(user: selfUser)
        let otherUserClient1 = createClient(user: otherUser)
        let otherUserClient2 = createClient(user: otherUser)

        let connection = ZMConnection.insertNewSentConnection(to: otherUser)
        connection.status = .accepted
        otherUser.oneOnOneConversation?.appendDecryptionFailedSystemMessage(
            at: Date(),
            sender: otherUser,
            client: otherUserClient1,
            errorCode: Int(CBOX_TOO_DISTANT_FUTURE.rawValue)
        )
        let systemMessage: ZMSystemMessage = (otherUser.oneOnOneConversation?.lastMessage as! ZMSystemMessage)
        moc.saveOrRollback()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        otherUserClient2.resolveDecryptionFailedSystemMessages()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageType.decryptionFailed)
    }
}
