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

import WireDesign
import WireMessagingDomainSupport
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

final class GroupParticipantsDetailViewControllerSnapshotTests: XCTestCase {

    // MARK: Properties

    private var mockMainCoordinator: AnyMainCoordinator!
    private var userSession: UserSessionMock!
    private var snapshotHelper: SnapshotHelper!

    // MARK: setUp

    @MainActor
    override func setUp() async throws {
        mockMainCoordinator = .init(mainCoordinator: MockMainCoordinator())
        snapshotHelper = SnapshotHelper()
        SelfUser.setupMockSelfUser()
        userSession = UserSessionMock()
    }

    // MARK: tearDown

    override func tearDown() {
        snapshotHelper = nil
        SelfUser.provider = nil
        userSession = nil
        mockMainCoordinator = nil
    }

    // MARK: Helper Method

    private func makeNavigationController(for sut: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: sut)
        navigationController.view.backgroundColor = SemanticColors.View.backgroundDefault
        return navigationController
    }

    // MARK: Snapshot Tests

    func testThatItRendersALotOfUsers() {
        // GIVEN
        let users: [MockUserType] = (0 ..< 20).map {
            let user = MockUserType.createUser(name: "User #\($0)")
            user.handle = nil
            return user
        }

        let selected = Array(users.dropLast(15))
        let conversation = MockConversation()
        conversation.sortedOtherParticipants = users

        // WHEN & THEN
        let sut = GroupParticipantsDetailViewController(
            selectedParticipants: selected,
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            conversationCreationRepository: MockConversationCreationRepositoryProtocol()
        )

        let navigationController = makeNavigationController(for: sut)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: navigationController,
                named: "LightTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: navigationController,
                named: "DarkTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )
    }

    func testThatItRendersALotOfUsers_WithoutNames() {
        // GIVEN
        let users: [MockUserType] = (0 ..< 20).map {
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

        // WHEN & THEN
        let sut = GroupParticipantsDetailViewController(
            selectedParticipants: selected,
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            conversationCreationRepository: MockConversationCreationRepositoryProtocol()
        )

        let navigationController = makeNavigationController(for: sut)

        snapshotHelper.verify(matching: navigationController)
    }

    func testEmptyState() {
        // GIVEN
        let conversation = MockConversation()

        // WHEN & THEN
        let sut = GroupParticipantsDetailViewController(
            selectedParticipants: [],
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            conversationCreationRepository: MockConversationCreationRepositoryProtocol()
        )
        sut.viewModel.admins = []
        sut.viewModel.members = []
        sut.setupViews()
        sut.handleParticipantsChange()

        let navigationController = makeNavigationController(for: sut)

        snapshotHelper.verify(matching: navigationController)
    }
}
