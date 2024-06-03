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

final class ConversationListViewControllerTests: XCTestCase {

    // MARK: - Properties

    private var sut: ConversationListViewController!
    private var window: UIWindow!
    private var tabBarController: UITabBarController!
    private var userSession: UserSessionMock!
    private var coreDataFixture: CoreDataFixture!
    private var mockIsSelfUserE2EICertifiedUseCase: MockIsSelfUserE2EICertifiedUseCaseProtocol!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        accentColor = .blue

        coreDataFixture = .init()

        userSession = .init()
        userSession.contextProvider = coreDataFixture.coreDataStack

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

        tabBarController = MainTabBarController(
            conversations: UINavigationController(rootViewController: sut),
            archive: .init(),
            settings: .init()
        )

        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        wait(for: [viewIfLoadedExpectation(for: sut)], timeout: 5)
        tabBarController.overrideUserInterfaceStyle = .dark

        UIView.setAnimationsEnabled(false)
    }

    // MARK: - tearDown

    override func tearDown() {
        window.isHidden = true
        window.rootViewController = nil
        window = nil
        tabBarController = nil
        sut = nil
        mockIsSelfUserE2EICertifiedUseCase = nil
        userSession = nil
        coreDataFixture = nil

        super.tearDown()
    }

    // MARK: - View controller

    func testForNoConversations() {
        window.rootViewController = nil
        verify(matching: tabBarController)
    }

    func testForEverythingArchived() {
        let modelHelper = ModelHelper()
        let conversation = modelHelper.createGroupConversation(in: coreDataFixture.coreDataStack.viewContext)
        conversation.isArchived = true
        coreDataFixture.coreDataStack.viewContext.conversationListDirectory().refetchAllLists(in: coreDataFixture.coreDataStack.viewContext)
        sut.showNoContactLabel(animated: false)
        window.rootViewController = nil
        verify(matching: tabBarController)
    }

    // MARK: - Snapshot Tests for Filter View

    func testForShowingConversationsWithoutAnyFilterApplied() {
        // GIVEN
        let modelHelper = ModelHelper()
        let fixture = CoreDataFixture()

        let iOSGroupConversation = modelHelper.createGroupConversation(in: fixture.coreDataStack.viewContext)
        iOSGroupConversation.userDefinedName = "iOS Team"
        let webGroupConversation = modelHelper.createGroupConversation(in: fixture.coreDataStack.viewContext)
        webGroupConversation.userDefinedName = "Web Team"
        let qaGroupConversation = modelHelper.createGroupConversation(in: fixture.coreDataStack.viewContext)
        qaGroupConversation.userDefinedName = "QA Team"
        let designGroupConversation = modelHelper.createGroupConversation(in: fixture.coreDataStack.viewContext)
        designGroupConversation.userDefinedName = "QA Team"
        let iOSBugsAndQuestionsGroupConversation = modelHelper.createGroupConversation(in: fixture.coreDataStack.viewContext)
        iOSBugsAndQuestionsGroupConversation.userDefinedName = "iOS Bugs & Questions"

        userSession.mockConversationDirectory.mockUnarchivedConversations = [
            iOSGroupConversation,
            webGroupConversation,
            qaGroupConversation,
            designGroupConversation,
            iOSBugsAndQuestionsGroupConversation
        ]

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(nil)

        // THEN
        verify(matching: tabBarController)
    }

    func testForShowingConversationsFilteredByGroups() {
        // GIVEN
        let modelHelper = ModelHelper()
        let fixture = CoreDataFixture()

        let iOSGroupConversation = modelHelper.createGroupConversation(in: fixture.coreDataStack.viewContext)
        iOSGroupConversation.userDefinedName = "iOS Team"
        let webGroupConversation = modelHelper.createGroupConversation(in: fixture.coreDataStack.viewContext)
        webGroupConversation.userDefinedName = "Web Team"

        userSession.mockConversationDirectory.mockGroupConversations = [iOSGroupConversation, webGroupConversation]

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.groups)

        // THEN
        verify(matching: tabBarController)
    }

    func testForShowingConversationsFilteredByFavourites() {
        // GIVEN
        let modelHelper = ModelHelper()
        let fixture = CoreDataFixture()

        let iOSGroupConversation = modelHelper.createGroupConversation(in: fixture.coreDataStack.viewContext)
        iOSGroupConversation.userDefinedName = "iOS Team"
        iOSGroupConversation.isFavorite = true
        let webGroupConversation = modelHelper.createGroupConversation(in: fixture.coreDataStack.viewContext)
        webGroupConversation.userDefinedName = "Web Team"

        coreDataFixture.coreDataStack.viewContext.conversationListDirectory().refetchAllLists(in: coreDataFixture.coreDataStack.viewContext)
        userSession.mockConversationDirectory.mockFavoritesConversations = [iOSGroupConversation]

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.favorites)

        // THEN
        verify(matching: tabBarController)
    }

    // MARK: - Helpers

    private func viewIfLoadedExpectation(for viewController: UIViewController) -> XCTNSPredicateExpectation {
        let predicate = NSPredicate { _, _ in
            viewController.viewIfLoaded != nil
        }
        return XCTNSPredicateExpectation(predicate: predicate, object: nil)
    }
}
