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

import WireTestingPackage
import XCTest

@testable import Wire

final class MessageDetailsViewControllerTests: XCTestCase {

    // MARK: - Properties

    private var conversation: SwiftMockConversation!
    private var mockSelfUser: MockUserType!
    private var otherUser: MockUserType!
    private var userSession: UserSessionMock!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp method

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        mockSelfUser = MockUserType.createSelfUser(name: "Alice")
        otherUser = MockUserType.createDefaultOtherUser()
        SelfUser.provider = SelfProvider(providedSelfUser: mockSelfUser)
        userSession = UserSessionMock()
    }

    // MARK: - tearDown method

    override func tearDown() {
        snapshotHelper = nil
        SelfUser.provider = nil
        conversation = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    // MARK: - Seen
    func testThatItShowsReceipts_ShortList_11() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.provider?.providedSelfUser
        message.conversationLike = conversation
        message.deliveryState = .read
        message.needsReadConfirmation = true

        let users = MockUserType.usernames.prefix(upTo: 5).map({
            MockUserType.createUser(name: $0)
        })

        message.readReceipts = createReceipts(users: users)
        message.backingUsersReaction = [Emoji.ID.like: Array(users.prefix(upTo: 4))]

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)
        detailsViewController.container.selectIndex(0, animated: false)

        // THEN
        verify(detailsViewController)
    }

    func testThatItShowsReceipts_ShortList_Edited_11() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.provider?.providedSelfUser
        message.conversationLike = conversation
        message.updatedAt = Date(timeIntervalSince1970: 69)
        message.deliveryState = .read
        message.needsReadConfirmation = true

        let users = MockUserType.usernames.prefix(upTo: 5).map({
            MockUserType.createUser(name: $0)
        })

        message.readReceipts = createReceipts(users: users)

        message.backingUsersReaction = [Emoji.ID.like: Array(users.prefix(upTo: 4))]

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)
        detailsViewController.container.selectIndex(0, animated: false)

        // THEN
        verify(detailsViewController)
    }

    func testThatItShowsReceipts_LongList_12() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.provider?.providedSelfUser
        message.conversationLike = conversation
        message.updatedAt = Date(timeIntervalSince1970: 69)
        message.deliveryState = .read
        message.needsReadConfirmation = true

        let users = MockUserType.usernames.prefix(upTo: 20).map({
            MockUserType.createUser(name: $0)
        })

        message.readReceipts = createReceipts(users: users)
        message.backingUsersReaction = [Emoji.ID.like: Array(users.prefix(upTo: 4))]

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)
        detailsViewController.container.selectIndex(0, animated: false)

        // THEN
        verify(detailsViewController)
    }

    func testThatItShowsLikes_13() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.provider?.providedSelfUser
        message.conversationLike = conversation
        message.deliveryState = .read
        message.needsReadConfirmation = true

        let users: [UserType] = MockUserType.usernames.prefix(upTo: 6).map({
            let user = MockUserType.createUser(name: $0)
            user.handle = nil
            return user
        })

        message.readReceipts = createReceipts(users: users)
        message.backingUsersReaction = [Emoji.ID.like: Array(users.prefix(upTo: 4))]

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)
        detailsViewController.container.selectIndex(1, animated: false)

        // THEN
        verify(detailsViewController)
    }

    func testThatItShowsDifferentReactions() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.provider?.providedSelfUser
        message.conversationLike = conversation
        message.deliveryState = .read
        message.needsReadConfirmation = true

        let users: [UserType] = MockUserType.usernames.prefix(upTo: 22).map({
            let user = MockUserType.createUser(name: $0)
            user.handle = nil
            return user
        })

        message.readReceipts = createReceipts(users: users)
        message.backingUsersReaction = [
            Emoji.ID.thumbsUp: Array(users.prefix(upTo: 6)),
            Emoji.ID.like: Array(users.prefix(upTo: 4)),
            Emoji.ID.frown: Array(users.prefix(upTo: 1))
        ]

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)
        detailsViewController.container.selectIndex(1, animated: false)

        // THEN
        verify(detailsViewController)
    }

    // MARK: - Empty State

    func testThatItShowsNoLikesEmptyState_14() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.provider?.providedSelfUser
        message.conversationLike = conversation
        message.deliveryState = .sent
        message.needsReadConfirmation = true

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)
        detailsViewController.container.selectIndex(1, animated: false)

        // THEN
        verify(detailsViewController)
    }

    func testThatItShowsNoReceiptsEmptyState_DisabledInConversation_15() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.provider?.providedSelfUser
        message.conversationLike = conversation
        message.readReceipts = []
        message.deliveryState = .sent
        message.needsReadConfirmation = false

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)
        detailsViewController.container.selectIndex(0, animated: false)

        // THEN
        verify(detailsViewController)
    }

    func testThatItShowsNoReceiptsEmptyState_EnabledInConversation_16() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.provider?.providedSelfUser
        message.conversationLike = conversation
        message.readReceipts = []
        message.deliveryState = .sent
        message.needsReadConfirmation = true

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)
        detailsViewController.container.selectIndex(0, animated: false)

        // THEN
        verify(detailsViewController)
    }

    func testThatItShowsBothTabs_WhenMessageIsSeenButNotLiked() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.provider?.providedSelfUser
        message.conversationLike = conversation
        let mockReadReceipt = MockReadReceipt(user: ZMUser())
        mockReadReceipt.userType = otherUser
        message.readReceipts = [mockReadReceipt]
        message.deliveryState = .read
        message.needsReadConfirmation = true

        // WHEN: creating the controller
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)
        detailsViewController.container.selectIndex(0, animated: false)

        // THEN
        verify(detailsViewController)
    }

    // MARK: - Non-Combined Scenarios

    func testThatItShowsReceiptsOnly_Ephemeral() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = SelfUser.provider?.providedSelfUser
        message.conversationLike = conversation
        message.isEphemeral = true
        message.backingUsersReaction = [Emoji.ID.like: [otherUser]]
        message.needsReadConfirmation = true

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)

        // THEN
        verify(detailsViewController)
    }

    func testThatItShowsLikesOnly_FromSelf_Consumer_17() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = MockUserType.createUser(name: "Bruno")
        message.conversationLike = conversation
        message.needsReadConfirmation = false

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)

        // THEN
        verify(detailsViewController)
    }

    func testThatItShowsLikesOnly_FromOther_Team_17() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.textMessage(withText: "Message")
        message.senderUser = MockUserType.createUser(name: "Bruno")
        message.conversationLike = conversation
        message.needsReadConfirmation = false

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)

        // THEN
        verify(detailsViewController)
    }

    func testThatItShowsReceiptsOnly_Pings() {
        // GIVEN
        conversation = createGroupConversation()

        let message = MockMessageFactory.pingMessage()
        message.senderUser = SelfUser.provider?.providedSelfUser
        message.conversationLike = conversation
        message.needsReadConfirmation = true

        // WHEN
        let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)

        // THEN
        verify(detailsViewController)
    }

    // MARK: - Deallocation

    func testThatItDeallocates() {
        verifyDeallocation { () -> MessageDetailsViewController in
            // GIVEN
            conversation = createGroupConversation()

            let message = MockMessageFactory.textMessage(withText: "Message")
            message.senderUser = SelfUser.provider?.providedSelfUser
            message.conversationLike = conversation

            let users = MockUserType.usernames.prefix(upTo: 5).map({
                MockUserType.createUser(name: $0)
            })

            message.readReceipts = createReceipts(users: users)
            message.backingUsersReaction = [Emoji.ID.like: Array(users.prefix(upTo: 4))]

            // WHEN
            let detailsViewController = MessageDetailsViewController(message: message, userSession: userSession, mainCoordinator: .mock)
            detailsViewController.container.selectIndex(0, animated: false)
            return detailsViewController
        }
    }

    // MARK: - Helpers

    private func createGroupConversation() -> SwiftMockConversation {
        let conversation = SwiftMockConversation()
        conversation.teamRemoteIdentifier = UUID()
        conversation.mockLocalParticipantsContain = true

        return conversation
    }

    private func createReceipts(users: [UserType]) -> [MockReadReceipt] {
        let receipts: [MockReadReceipt] = users.map({ user in
            let receipt = MockReadReceipt(user: ZMUser())
            receipt.userType = user
            return receipt
        })

        return receipts
    }

    private func verify(
        _ detailsViewController: MessageDetailsViewController,
        configuration: ((MessageDetailsViewController) -> Void)? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        detailsViewController.reloadData()
        configuration?(detailsViewController)
        snapshotHelper.verify(
            matching: detailsViewController,
            file: file,
            testName: testName,
            line: line
        )
    }

}
