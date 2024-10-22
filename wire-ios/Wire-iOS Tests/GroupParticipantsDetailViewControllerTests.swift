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

import WireMainNavigationUI
import WireTestingPackage
import XCTest

@testable import Wire

private final class MockConversation: MockStableRandomParticipantsConversation, GroupDetailsConversation {

    var userDefinedName: String?

    var hasReadReceiptsEnabled: Bool = false

    var freeParticipantSlots: Int = 1

    var syncedMessageDestructionTimeout: TimeInterval = 0

    var messageProtocol: MessageProtocol = .proteus

    var mlsGroupID: WireDataModel.MLSGroupID?

    var mlsVerificationStatus: WireDataModel.MLSVerificationStatus?

}

final class GroupParticipantsDetailViewControllerTests: XCTestCase {

    private var mockMainCoordinator: AnyMainCoordinator<Wire.MainCoordinatorDependencies>!
    private var userSession: UserSessionMock!
    private var snapshotHelper: SnapshotHelper!

    @MainActor
    override func setUp() async throws {
        mockMainCoordinator = .init(mainCoordinator: MockMainCoordinator())
        snapshotHelper = SnapshotHelper()
        SelfUser.setupMockSelfUser()
        userSession = UserSessionMock()
    }

    override func tearDown() {
        snapshotHelper = nil
        SelfUser.provider = nil
        userSession = nil
        mockMainCoordinator = nil
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
        let sut = GroupParticipantsDetailViewController(
            selectedParticipants: selected,
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol()
        ).wrapInNavigationController()

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #file,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #file,
                testName: #function,
                line: #line
            )
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
        let sut = GroupParticipantsDetailViewController(
            selectedParticipants: selected,
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol()
        )

        snapshotHelper.verify(matching: sut.wrapInNavigationController())
    }

    func testEmptyState() {
        // given
        let conversation = MockConversation()

        // when
        let sut = GroupParticipantsDetailViewController(
            selectedParticipants: [],
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol()
        )
        sut.viewModel.admins = []
        sut.viewModel.members = []
        sut.setupViews()
        sut.participantsDidChange()

        // then
        let wrapped = sut.wrapInNavigationController()
        snapshotHelper.verify(matching: wrapped)
    }
}
