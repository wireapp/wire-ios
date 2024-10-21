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

import XCTest

@testable import Wire
@testable import WireDataModelSupport

final class ConversationListViewControllerViewModelSnapshotTests: XCTestCase {

    private var sut: ConversationListViewController.ViewModel!
    private var mockView: UIView!
    private var mockViewController: MockConversationListContainer!
    private var userSession: UserSessionMock!
    private var mockIsSelfUserE2EICertifiedUseCase: MockIsSelfUserE2EICertifiedUseCaseProtocol!
    private var mockGetUserAccountImageUseCase: MockGetUserAccountImageUseCase!
    private var window: UIWindow!

    private var coreDataFixture: CoreDataFixture!

    override func setUp() {
        coreDataFixture = CoreDataFixture()

        userSession = UserSessionMock()

        mockIsSelfUserE2EICertifiedUseCase = .init()
        mockIsSelfUserE2EICertifiedUseCase.invoke_MockValue = false

        mockGetUserAccountImageUseCase = .init()
        mockGetUserAccountImageUseCase.invoke_MockValue = .init()

        let account = Account.mockAccount(imageData: Data())
        let selfUser = MockUserType.createSelfUser(name: "Bob")
        sut = ConversationListViewController.ViewModel(
            account: account,
            selfUserLegalHoldSubject: selfUser,
            userSession: userSession,
            isSelfUserE2EICertifiedUseCase: mockIsSelfUserE2EICertifiedUseCase,
            mainCoordinator: .mock,
            getUserAccountImageUseCase: mockGetUserAccountImageUseCase
        )

        mockViewController = MockConversationListContainer(viewModel: sut)
        window = .init()
        window.rootViewController = mockViewController
        window.isHidden = false

        sut.viewController = mockViewController
    }

    override func tearDown() {
        window.isHidden = true
        window = nil
        sut = nil
        mockView = nil
        mockViewController = nil
        coreDataFixture = nil
        userSession = nil
        mockIsSelfUserE2EICertifiedUseCase = nil
        mockGetUserAccountImageUseCase = nil
    }

    // MARK: - Action menu
    func testForActionMenu() throws {
        try coreDataFixture.teamTest {
            sut.showActionMenu(for: coreDataFixture.otherUserConversation, from: mockViewController.view)
            try verify(matching: (sut?.actionsController?.alertController)!)
        }
    }

    func testForActionMenu_archive() throws {
        try coreDataFixture.teamTest {
            coreDataFixture.otherUserConversation.isArchived = true
            sut.showActionMenu(for: coreDataFixture.otherUserConversation, from: mockViewController.view)
            try verify(matching: (sut?.actionsController?.alertController)!)
        }
    }

    func testForActionMenu_NoTeam() throws {
        try coreDataFixture.nonTeamTest {
            sut.showActionMenu(for: coreDataFixture.otherUserConversation, from: mockViewController.view)
            try verify(matching: (sut?.actionsController?.alertController)!)
        }
    }
}
