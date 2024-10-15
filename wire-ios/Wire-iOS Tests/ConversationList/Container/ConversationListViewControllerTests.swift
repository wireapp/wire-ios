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
import WireMainNavigationUI
import WireSyncEngineSupport
import WireTestingPackage
import XCTest

@testable import Wire

// MARK: - ConversationListViewControllerTests

final class ConversationListViewControllerTests: XCTestCase {

    // MARK: - Properties

    private var mockMainCoordinator: MockMainCoordinator!
    private var sut: ConversationListViewController!
    private var window: UIWindow!
    private var tabBarController: MainTabBarController<ConversationListViewController>!
    private var userSession: UserSessionMock!
    private var coreDataFixture: CoreDataFixture!
    private var mockIsSelfUserE2EICertifiedUseCase: MockIsSelfUserE2EICertifiedUseCaseProtocol!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    @MainActor
    override func setUp() async throws {

        mockMainCoordinator = .init()
        snapshotHelper = SnapshotHelper()
        accentColor = .blue

        coreDataFixture = .init()

        userSession = .init()
        userSession.coreDataStack = coreDataFixture.coreDataStack

        mockIsSelfUserE2EICertifiedUseCase = .init()
        mockIsSelfUserE2EICertifiedUseCase.invoke_MockValue = false

        let selfUser = MockUserType.createSelfUser(name: "Johannes Chrysostomus Wolfgangus Theophilus Mozart", inTeam: UUID())
        let account = Account.mockAccount(imageData: mockImageData)
        let viewModel = ConversationListViewController.ViewModel(
            account: account,
            selfUserLegalHoldSubject: selfUser,
            userSession: userSession,
            isSelfUserE2EICertifiedUseCase: mockIsSelfUserE2EICertifiedUseCase,
            mainCoordinator: .mock
        )

        sut = ConversationListViewController(
            viewModel: viewModel,
            isFolderStatePersistenceEnabled: false,
            zClientViewController: .init(account: account, userSession: userSession),
            mainCoordinator: mockMainCoordinator,
            selfProfileViewControllerBuilder: .mock
        )
        tabBarController = .init()
        tabBarController.conversations = (sut, nil)

        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

        await fulfillment(of: [viewIfLoadedExpectation(for: sut)], timeout: 5)
        tabBarController.overrideUserInterfaceStyle = .dark
        UIView.setAnimationsEnabled(false)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        window.isHidden = true
        window.rootViewController = nil
        window = nil
        tabBarController = nil
        sut = nil
        mockIsSelfUserE2EICertifiedUseCase = nil
        userSession = nil
        coreDataFixture = nil
        mockMainCoordinator = nil

        super.tearDown()
    }

    // MARK: - View Controller

    func testForNoConversations() {
        window.rootViewController = nil
        snapshotHelper.verify(matching: tabBarController)
    }

    func testForEverythingArchived() {
        let modelHelper = ModelHelper()
        let conversation = modelHelper.createGroupConversation(in: coreDataFixture.coreDataStack.viewContext)
        conversation.isArchived = true
        coreDataFixture.coreDataStack.viewContext.conversationListDirectory().refetchAllLists(in: coreDataFixture.coreDataStack.viewContext)
        sut.showNoContactLabel(animated: false)
        window.rootViewController = nil
        snapshotHelper.verify(matching: tabBarController)
    }

    // MARK: - Helpers

    private func viewIfLoadedExpectation(for viewController: UIViewController) -> XCTNSPredicateExpectation {
        let predicate = NSPredicate { _, _ in
            viewController.viewIfLoaded != nil
        }
        return XCTNSPredicateExpectation(predicate: predicate, object: nil)
    }
}
