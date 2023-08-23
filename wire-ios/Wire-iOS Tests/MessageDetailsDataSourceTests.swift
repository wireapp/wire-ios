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

final class MessageDetailsDataSourceTests: BaseSnapshotTestCase {

    // MARK: - Properties

    var sut: MessageDetailsDataSource!
    var conversation: SwiftMockConversation!
    var mockSelfUser: MockUserType!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockSelfUser = MockUserType.createSelfUser(name: "Alice")
        SelfUser.provider = SelfProvider(selfUser: mockSelfUser)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        SelfUser.provider = nil
        conversation = nil
        super.tearDown()
    }

    // MARK: - Unit Tests

    func testThatReactionsAreSortedFirstByCountAndThenByName() {
        // GIVEN
        conversation = createGroupConversation()
        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.current
        message.conversationLike = conversation

        let users = MockUserType.usernames.prefix(upTo: 22).map({
            MockUserType.createUser(name: $0)
        })

        message.backingUsersReaction = [Emoji.thumbsUp.value: Array(users.prefix(upTo: 6)),
                                        Emoji.like.value: Array(users.prefix(upTo: 4)),
                                        Emoji.frown.value: Array(users.prefix(upTo: 4))
        ]

        // WHEN
        sut = MessageDetailsDataSource(message: message)

        let sectionHeaders = sut.reactions.map(\.headerText)

        XCTAssertEqual(sectionHeaders, [("👍 Thumbs up sign (6)"), ("❤️ Heavy black heart (4)"), ("☹️ White frowning face (4)")])
    }

    // MARK: - Helpers

    private func createGroupConversation() -> SwiftMockConversation {
        let conversation = SwiftMockConversation()
        conversation.teamRemoteIdentifier = UUID()
        conversation.mockLocalParticipantsContain = true

        return conversation
    }

}
