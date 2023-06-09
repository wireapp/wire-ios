//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import SnapshotTesting

final class ConversationReactionMessageTests: CoreDataSnapshotTestCase {

    // MARK: - Properties

    var message: MockMessage!
    var sut: MessageReactionsCell!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        SelfUser.setupMockSelfUser()

        message = MockMessageFactory.textMessage(withText: "Hello, it's me!")
        message.deliveryState = .sent
        message.conversation = otherUserConversation

        sut = MessageReactionsCell()
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 70)
    }

    // MARK: - tearDown

    override func tearDown() {
        message = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItConfiguresWithSelfReaction() {
        // GIVEN
        let configuration = MessageReactionsCell.Configuration(message: message)
        message.backingUsersReaction = [MessageReaction.like.unicodeValue: [selfUser]]

        sut.configure(with: configuration, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItConfiguresWithOtherReactions() {
        // GIVEN
        let usersWhoReactionWithBeamingFace = MockUser.mockUsers().filter { !$0.isSelfUser }
        let configuration = MessageReactionsCell.Configuration(message: message)

        message.backingUsersReaction = [MessageReaction.beamingFace.unicodeValue: usersWhoReactionWithBeamingFace]

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        verify(view: sut)
    }

}
