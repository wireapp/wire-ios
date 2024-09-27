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

// MARK: - ConversationAvatarViewTests

final class ConversationAvatarViewTests: XCTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        sut = ConversationAvatarView()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItRendersNoUserImages() {
        // GIVEN
        let conversation = MockStableRandomParticipantsConversation()

        // WHEN
        sut.configure(context: .conversation(conversation: conversation))

        // THEN
        snapshotHelper.verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersSomeAndThenNoUserImages() {
        // GIVEN
        let otherUserConversation = MockStableRandomParticipantsConversation()

        // WHEN
        sut.configure(context: .conversation(conversation: otherUserConversation))

        // AND WHEN
        _ = sut.prepareForSnapshots()

        // AND WHEN

        let conversation = MockStableRandomParticipantsConversation()

        sut.configure(context: .conversation(conversation: conversation))

        // THEN
        snapshotHelper.verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersSingleUserImage() {
        // GIVEN
        let otherUserConversation = MockStableRandomParticipantsConversation()
        let otherUser = MockUserType.createDefaultOtherUser()
        otherUser.zmAccentColor = .green
        otherUserConversation.conversationType = .oneOnOne
        otherUserConversation.stableRandomParticipants = [otherUser]

        // WHEN
        sut.configure(context: .conversation(conversation: otherUserConversation))

        // THEN
        snapshotHelper.verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersPendingConnection() {
        // GIVEN
        let otherUser = MockUserType.createDefaultOtherUser()
        otherUser.zmAccentColor = .green
        otherUser.isConnected = false
        otherUser.isPendingApprovalBySelfUser = true
        let otherUserConversation = MockStableRandomParticipantsConversation()
        otherUserConversation.conversationType = .connection
        otherUserConversation.stableRandomParticipants = [otherUser]

        // WHEN
        sut.configure(context: .connect(users: [otherUser]))

        // THEN
        snapshotHelper.verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersASingleServiceUser() {
        // GIVEN
        let otherUser = MockServiceUserType()
        otherUser.initials = "B"
        otherUser.serviceIdentifier = "serviceIdentifier"
        otherUser.providerIdentifier = "providerIdentifier"
        otherUser.isConnected = true
        XCTAssert(otherUser.isServiceUser)

        otherUser.zmAccentColor = .green
        let otherUserConversation = MockStableRandomParticipantsConversation()
        otherUserConversation.conversationType = .oneOnOne
        otherUserConversation.stableRandomParticipants = [otherUser]

        // WHEN
        sut.configure(context: .conversation(conversation: otherUserConversation))

        // THEN
        snapshotHelper.verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersTwoUserImages() {
        // GIVEN
        let conversation = MockStableRandomParticipantsConversation()
        let otherUser = MockUserType.createDefaultOtherUser()
        let thirdUser = MockUserType.createConnectedUser(name: "Anna")
        thirdUser.zmAccentColor = .red
        conversation.stableRandomParticipants = [thirdUser, otherUser]

        // WHEN
        sut.configure(context: .conversation(conversation: conversation))

        // THEN
        snapshotHelper.verify(matching: sut.prepareForSnapshots())
    }

    func testThatItRendersManyUsers() {
        // GIVEN
        let conversation = MockStableRandomParticipantsConversation()
        conversation.stableRandomParticipants = MockUserType.usernames
            .map { MockUserType.createConnectedUser(name: $0) }

        (conversation.stableRandomParticipants[0] as! MockUserType).zmAccentColor = .red
        (conversation.stableRandomParticipants[1] as! MockUserType).zmAccentColor = .amber
        (conversation.stableRandomParticipants[2] as! MockUserType).zmAccentColor = .purple
        (conversation.stableRandomParticipants[3] as! MockUserType).zmAccentColor = .blue

        // WHEN
        sut.configure(context: .conversation(conversation: conversation))

        // THEN
        snapshotHelper.verify(matching: sut.prepareForSnapshots())
    }

    // MARK: Private

    // MARK: - Properties

    private var sut: ConversationAvatarView!
    private var snapshotHelper: SnapshotHelper!
}

// MARK: - Helper method

extension UIView {
    fileprivate func prepareForSnapshots() -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 24),
            container.widthAnchor.constraint(equalToConstant: 24),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        return container
    }
}
