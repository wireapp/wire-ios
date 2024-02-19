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
import SnapshotTesting

private final class MockConversation: MockStableRandomParticipantsConversation, GroupDetailsConversation {

    var userDefinedName: String?

    var hasReadReceiptsEnabled: Bool = false

    var freeParticipantSlots: Int = 1

    var syncedMessageDestructionTimeout: TimeInterval = 0

    var messageProtocol: MessageProtocol = .proteus

    var mlsGroupID: WireDataModel.MLSGroupID?

    var mlsVerificationStatus: WireDataModel.MLSVerificationStatus?

}

final class GroupParticipantsDetailViewControllerTests: ZMSnapshotTestCase {

    var userSession: UserSessionMock!

    override func setUp() {
        super.setUp()

        SelfUser.setupMockSelfUser()
        userSession = UserSessionMock()
    }

    override func tearDown() {
        SelfUser.provider = nil
        userSession = nil

        super.tearDown()
    }

    func testThatItRendersALotOfUsers() {
        // given
        let users: [MockUserType] = (0..<20).map {
            let user = MockUserType.createUser(name: "User #\($0)")
            user.handle = nil

            return user
        }

        let selected = Array(users.dropLast(15))
        let conversation = MockConversation()
        conversation.sortedOtherParticipants = users

        // when & then
		let createSut: () -> UIViewController = {
            let sut = GroupParticipantsDetailViewController(
                selectedParticipants: selected,
                conversation: conversation,
                userSession: self.userSession
            )
			return sut.wrapInNavigationController()
		}

        verifyInAllColorSchemes(createSut: createSut)
    }

    func testThatItRendersALotOfUsers_WithoutNames() {
        // given
        let users: [MockUserType] = (0..<20).map {
            let user = MockUserType.createUser(name: "\($0)")
            user.name = nil
            user.handle = nil
            user.domain = "foma.wire.link"
            user.initials = ""

            return user
        }

        let selected = Array(users.dropLast(15))
        let conversation = MockConversation()
        conversation.sortedOtherParticipants = users

        // when & then
        let createSut: () -> UIViewController = {
            let sut = GroupParticipantsDetailViewController(
                selectedParticipants: selected,
                conversation: conversation,
                userSession: self.userSession
            )
            return sut.wrapInNavigationController()
        }

        verify(matching: createSut())
    }

    func testEmptyState() {
        // given
        let conversation = MockConversation()

        // when
        let sut = GroupParticipantsDetailViewController(
            selectedParticipants: [],
            conversation: conversation,
            userSession: self.userSession
        )
        sut.viewModel.admins = []
        sut.viewModel.members = []
        sut.setupViews()
        sut.participantsDidChange()

        // then
        let wrapped = sut.wrapInNavigationController()
        verify(matching: wrapped)
    }
}
