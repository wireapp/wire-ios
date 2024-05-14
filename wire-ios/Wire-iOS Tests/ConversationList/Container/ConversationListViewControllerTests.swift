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
    var tabBarController: UITabBarController!
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
            isFolderStatePersistenceEnabled: false,
            selfProfileViewControllerBuilder: .mock
        )
        viewModel.viewController = sut
        sut.onboardingHint.arrowPointToView = sut.tabBarController?.tabBar
        sut.overrideUserInterfaceStyle = .dark
        sut.view.backgroundColor = .black
        let navigationController = UINavigationController(rootViewController: sut)
        tabBarController = UITabBarController()
        tabBarController.viewControllers = [.init(), navigationController, .init()]
        for (index, viewController) in tabBarController.viewControllers!.enumerated() {
            viewController.tabBarItem = .init(
                title: ["Lorem", "Ipsum", "Dolor"][index],
                image: .init(systemName: "pencil.slash"),
                selectedImage: .init(systemName: "pencil.slash")
            )
        }
        tabBarController.selectedIndex = 1
    }

    // MARK: - tearDown

    override func tearDown() {
        tabBarController = nil
        sut = nil
        mockIsSelfUserE2EICertifiedUseCase = nil
        userSession = nil

        super.tearDown()
    }

    // MARK: - View controller

    func testForNoConversations() throws {
        let tabBarController = try XCTUnwrap(sut.tabBarController)
        verify(matching: tabBarController)
    }

    func testForEverythingArchived() throws {
        let tabBarController = try XCTUnwrap(sut.tabBarController)
        #warning("TODO: fix test/snapshot image")
        sut.showNoContactLabel(animated: false)

        verify(matching: tabBarController)
    }

    // MARK: - PermissionDeniedViewController

    func testForPremissionDeniedViewController() throws {
        let tabBarController = try XCTUnwrap(sut.tabBarController)
        sut.showPermissionDeniedViewController()

        verify(matching: tabBarController)
    }
}
