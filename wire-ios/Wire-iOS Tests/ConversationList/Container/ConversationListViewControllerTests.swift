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

import WireDataModelSupport
import WireSyncEngineSupport
import XCTest

@testable import Wire

// MARK: - ConversationListViewControllerTests

final class ConversationListViewControllerTests: BaseSnapshotTestCase {

    // MARK: - Properties

    var sut: ConversationListViewController!
    var navigationController: UINavigationController!
    var userSession: UserSessionMock!
    private var mockIsSelfUserE2EICertifiedUseCase: MockIsSelfUserE2EICertifiedUseCaseProtocol!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        accentColor = .blue

        userSession = UserSessionMock()

        mockIsSelfUserE2EICertifiedUseCase = .init()
        mockIsSelfUserE2EICertifiedUseCase.invoke_MockValue = false

        let selfUser = MockUserType.createSelfUser(name: "Johannes Chrysostomus Wolfgangus Theophilus Mozart", inTeam: UUID())
        let account = Account.mockAccount(imageData: mockImageData)
        let viewModel = ConversationListViewController.ViewModel(
            account: account,
            selfUser: selfUser,
            userSession: userSession,
            isSelfUserE2EICertifiedUseCase: mockIsSelfUserE2EICertifiedUseCase
        )

        sut = ConversationListViewController(
            viewModel: viewModel,
            selfProfileViewControllerBuilder: .mock
        )
        viewModel.viewController = sut
        sut.onboardingHint.arrowPointToView = sut.tabBarController?.tabBar
        sut.overrideUserInterfaceStyle = .dark
        sut.view.backgroundColor = .black
        navigationController = .init(rootViewController: sut)
    }

    // MARK: - tearDown

    override func tearDown() {
        navigationController = nil
        sut = nil
        mockIsSelfUserE2EICertifiedUseCase = nil
        userSession = nil

        super.tearDown()
    }

    // MARK: - View controller

    func testForNoConversations() {
        verify(matching: navigationController)
    }

    func testForEverythingArchived() {
        #warning("TODO: fix test/snapshot image")
        sut.showNoContactLabel(animated: false)

        verify(matching: navigationController)
    }

    // MARK: - PermissionDeniedViewController

    func testForPremissionDeniedViewController() {
        sut.showPermissionDeniedViewController()

        verify(matching: navigationController)
    }
}
