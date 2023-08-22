//
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

import XCTest
@testable import Wire

final class MessageToolboxViewTests: CoreDataSnapshotTestCase {

    // MARK: - Properties

    var message: MockMessage!
    var sut: MessageToolboxView!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        SelfUser.setupMockSelfUser()

        message = MockMessageFactory.textMessage(withText: "Hello")
        message.deliveryState = .sent
        message.conversation = otherUserConversation

        sut = MessageToolboxView()
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 28)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        message = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItConfiguresWithFailedToSend() {
        // GIVEN
        message.deliveryState = .failedToSend

        // WHEN
        sut.configureForMessage(message, animated: false)

        // THEN
        verifyView(view: sut, width: defaultIPhoneSize.width)
    }

    func testThatItConfiguresWithFailedToSendAndReason() {
        // GIVEN
        message.deliveryState = .failedToSend
        message.conversationLike = otherUserConversation
        message.failedToSendReason = .federationRemoteError
        message.conversation?.domain = "anta.wire.link"

        // WHEN
        sut.configureForMessage(message, forceShowTimestamp: true, animated: false)

        // THEN
        verifyView(view: sut, width: defaultIPhoneSize.width)
    }

    func testThatItConfiguresWith1To1ConversationReadReceipt() {
        // GIVEN
        message.deliveryState = .read

        let readReceipt = MockReadReceipt(user: otherUser)
        readReceipt.serverTimestamp = Date(timeIntervalSince1970: 12345678564)
        message.readReceipts = [readReceipt]

        // WHEN
        sut.configureForMessage(message, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItConfiguresWithGroupConversationReadReceipt() {
        // GIVEN
        message.conversation = createGroupConversation()
        message.deliveryState = .read

        let readReceipt = MockReadReceipt(user: otherUser)
        message.readReceipts = [readReceipt]

        // WHEN
        sut.configureForMessage(message, animated: false)

        // THEN
        verify(view: sut)
    }

    // MARK: - Tap Gesture

    func testThatItOpensReceipts() {
        // WHEN
        message.conversation = createTeamGroupConversation()
        message.conversationLike = message.conversation
        sut.configureForMessage(message, animated: false)

        // THEN
        XCTAssertEqual(sut.preferredDetailsDisplayMode(), .receipts)
    }

    func testThatItDisplaysTimestamp_Countdown_OtherUser() {
        // GIVEN
        message.conversation = createGroupConversation()
        message.senderUser = MockUserType.createUser(name: "Bruno")
        message.isEphemeral = true
        message.destructionDate = Date().addingTimeInterval(10)

        // WHEN
        sut.configureForMessage(message, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItDisplaysTimestamp_ReadReceipts_Countdown_SelfUser() {
        // GIVEN
        message.conversation = createGroupConversation()
        message.senderUser = MockUserType.createSelfUser(name: "Alice")
        message.readReceipts = [MockReadReceipt(user: otherUser)]
        message.deliveryState = .read
        message.isEphemeral = true
        message.destructionDate = Date().addingTimeInterval(10)

        // WHEN
        sut.configureForMessage(message, animated: false)

        // THEN
        verify(view: sut)
    }

}
