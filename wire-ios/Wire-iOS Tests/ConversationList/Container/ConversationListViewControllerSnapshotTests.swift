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
import WireDesign

@testable import Wire

// MARK: - ConversationListViewControllerSnapshotTests

final class ConversationListViewControllerSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var mockMainCoordinator: MockMainCoordinator!
    private var sut: ConversationListViewController!
    private var window: UIWindow!
    private var tabBarController: MainTabBarController<ConversationListViewController, ConversationRootViewController>!
    private var userSession: UserSessionMock!
    private var coreDataFixture: CoreDataFixture!
    private var mockIsSelfUserE2EICertifiedUseCase: MockIsSelfUserE2EICertifiedUseCaseProtocol!
    private var mockGetUserAccountImageUseCase: MockGetUserAccountImageUseCase!
    private var modelHelper: ModelHelper!
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

        mockGetUserAccountImageUseCase = .init()
        mockGetUserAccountImageUseCase.invoke_MockValue = .init()

        modelHelper = ModelHelper()

        let selfUser = modelHelper.createSelfUser(in: coreDataFixture.coreDataStack.viewContext)
        selfUser.name = "Johannes Chrysostomus Wolfgangus Theophilus Mozart"
        selfUser.accentColor = .red

        let account = Account.mockAccount(imageData: mockImageData)
        let viewModel = ConversationListViewController.ViewModel(
            account: account,
            selfUserLegalHoldSubject: selfUser,
            userSession: userSession,
            isSelfUserE2EICertifiedUseCase: mockIsSelfUserE2EICertifiedUseCase,
            mainCoordinator: .mock,
            getUserAccountImageUseCase: mockGetUserAccountImageUseCase
        )

        sut = ConversationListViewController(
            viewModel: viewModel,
            zClientViewController: .init(account: account, userSession: userSession),
            mainCoordinator: .init(mainCoordinator: mockMainCoordinator),
            selfProfileViewControllerBuilder: .mock
        )
        sut.mainSplitViewState = .collapsed
        // sut.navigationController?.navigationBar.barTintColor = SemanticColors.View.backgroundDefaultWhite

        // Set the navigation bar color here
           let navBarAppearance = UINavigationBarAppearance()
           navBarAppearance.backgroundColor = SemanticColors.View.backgroundDefaultWhite
           UINavigationBar.appearance().standardAppearance = navBarAppearance
           UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance


        tabBarController = MainTabBarController()
        tabBarController.conversationListUI = sut

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
        modelHelper = nil
        mockMainCoordinator = nil
        mockGetUserAccountImageUseCase = nil

        super.tearDown()
    }

    // MARK: - View Controller

    func testForNoConversations() {
        window.rootViewController = nil
        snapshotHelper.verify(matching: tabBarController)
    }

    func testForEverythingArchived() {
        let conversation = modelHelper.createGroupConversation(in: coreDataFixture.coreDataStack.viewContext)
        conversation.isArchived = true
        coreDataFixture.coreDataStack.viewContext.conversationListDirectory().refetchAllLists(in: coreDataFixture.coreDataStack.viewContext)
        sut.showNoContactLabel(animated: false)
        window.rootViewController = nil
        snapshotHelper.verify(matching: tabBarController)
    }

    // MARK: - Snapshot Tests for Filter View

    func testForShowingConversationsWithoutAnyFilterApplied() {
        // GIVEN
        let conversationData = [
            (name: "iOS Team", isFavorite: false),
            (name: "Web Team", isFavorite: false),
            (name: "QA Team", isFavorite: false),
            (name: "Design Team", isFavorite: false),
            (name: "iOS Bugs & Questions", isFavorite: false)
        ]

        let conversations = createConversations(conversationsData: conversationData)
        userSession.mockConversationDirectory.mockUnarchivedConversations = conversations

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.none)

        // THEN
        snapshotHelper.verify(matching: tabBarController)
    }

    func testForShowingConversationsFilteredByGroups() {
        // GIVEN
        let conversationData = [
            (name: "iOS Team", isFavorite: false),
            (name: "Web Team", isFavorite: false)
        ]
        let conversations = createConversations(conversationsData: conversationData)
        userSession.mockConversationDirectory.mockGroupConversations = conversations

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.groups)

        // THEN
        snapshotHelper.verify(matching: tabBarController)
    }

    func testForShowingNoConversationsFilteredByGroups() {
        // GIVEN
        let conversationData = [
            (name: "iOS Team", isFavorite: false),
            (name: "Web Team", isFavorite: false)
        ]
        userSession.mockConversationDirectory.mockGroupConversations = []

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.groups)

        // THEN
        snapshotHelper.verify(matching: tabBarController)
    }

    func testForShowingConversationsFilteredByFavourites() {
        // GIVEN
        let conversationData = [
            (name: "iOS Team", isFavorite: false),
            (name: "Web Team", isFavorite: true)
        ]
        let conversations = createConversations(conversationsData: conversationData)
        userSession.mockConversationDirectory.mockFavoritesConversations = conversations.filter { $0.isFavorite }

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.favorites)

        // THEN
        snapshotHelper.verify(matching: tabBarController)
    }

    func testForShowingNoConversationsFilteredByFavourites() {
        // GIVEN
        let conversationData = [
            (name: "iOS Team", isFavorite: false),
            (name: "Web Team", isFavorite: true)
        ]
        userSession.mockConversationDirectory.mockFavoritesConversations = []

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.favorites)

        // THEN
        snapshotHelper.verify(matching: tabBarController)
    }

    func testForShowingConversationsFilteredByOneOnOne() throws {
        // GIVEN
        let user1 = modelHelper.createUser(in: coreDataFixture.coreDataStack.viewContext)
        user1.name = "Alice"

        let user2 = modelHelper.createUser(in: coreDataFixture.coreDataStack.viewContext)
        user2.name = "Bob"

        let oneOnOneConversation1 = modelHelper.createOneOnOne(with: user1, in: coreDataFixture.coreDataStack.viewContext)
        let oneOnOneConversation2 = modelHelper.createOneOnOne(with: user2, in: coreDataFixture.coreDataStack.viewContext)

        userSession.mockConversationDirectory.mockContactsConversations = [oneOnOneConversation1, oneOnOneConversation2]

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.oneOnOne)

        // THEN
        snapshotHelper.verify(matching: tabBarController)
    }

    func testForShowingNoConversationsFilteredByOneOnOne() throws {
        // GIVEN
        let user1 = modelHelper.createUser(in: coreDataFixture.coreDataStack.viewContext)
        user1.name = "Alice"

        let user2 = modelHelper.createUser(in: coreDataFixture.coreDataStack.viewContext)
        user2.name = "Bob"

        userSession.mockConversationDirectory.mockContactsConversations = []

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.oneOnOne)

        // THEN
        snapshotHelper.verify(matching: tabBarController)
    }

    // MARK: - Helper Methods

    private func createConversations(conversationsData: [(name: String, isFavorite: Bool)]) -> [ZMConversation] {
        var conversations: [ZMConversation] = []

        for (name, isFavorite) in conversationsData {
            let conversation = modelHelper.createGroupConversation(
                in: coreDataFixture.coreDataStack.viewContext
            )

            conversation.userDefinedName = name
            conversation.isFavorite = isFavorite
            conversations.append(conversation)
        }
        return conversations
    }

    private func viewIfLoadedExpectation(for viewController: UIViewController) -> XCTNSPredicateExpectation {
        let predicate = NSPredicate { _, _ in
            viewController.viewIfLoaded != nil
        }
        return XCTNSPredicateExpectation(predicate: predicate, object: nil)
    }
}

// MARK: MainCoordinatorInjectingViewControllerBuilder + mock

private extension MainCoordinatorInjectingViewControllerBuilder where Self == MockMainCoordinatorInjectingViewControllerBuilder {
    static var mock: Self { .init() }
}

private struct MockMainCoordinatorInjectingViewControllerBuilder: MainCoordinatorInjectingViewControllerBuilder {

    typealias Dependencies = Wire.MainCoordinatorDependencies

    func build<MainCoordinator: MainCoordinatorProtocol>(
        mainCoordinator: MainCoordinator
    ) -> UIViewController where
    MainCoordinator.Dependencies == Dependencies {
        .init()
    }
}
