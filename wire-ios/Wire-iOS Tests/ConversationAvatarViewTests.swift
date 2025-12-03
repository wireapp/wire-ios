//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class ConversationAvatarViewTests: XCTestCase {

    // MARK: - Properties

    private var sut: ConversationAvatarView!
    private var snapshotHelper: SnapshotHelper!

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

    func testThatItRendersGroup() {
        // GIVEN
        let conversation = MockStableRandomParticipantsConversation()
        let mockConversations = [QualifiedID.mockID1, .mockID2, .mockID3].map { id in
            let conversation = MockStableRandomParticipantsConversation()
            conversation.qualifiedID = id
            return conversation
        }

        mockConversations.enumerated().forEach { index, conversation in
            sut.configure(context: .conversation(conversation: conversation))
            snapshotHelper.verify(matching: sut.prepareForSnapshots(), named: "\(index)")
        }
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
        XCTAssert(otherUser.isApp)

        otherUser.zmAccentColor = .green
        let otherUserConversation = MockStableRandomParticipantsConversation()
        otherUserConversation.conversationType = .oneOnOne
        otherUserConversation.stableRandomParticipants = [otherUser]

        // WHEN
        sut.configure(context: .conversation(conversation: otherUserConversation))

        // THEN
        snapshotHelper.verify(matching: sut.prepareForSnapshots())
    }
}

// MARK: - Helper method

private extension UIView {

    func prepareForSnapshots() -> UIView {
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
            container.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        return container
    }
}
