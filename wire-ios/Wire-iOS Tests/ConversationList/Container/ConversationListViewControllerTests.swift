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

        let modelHelper = ModelHelper()

        let selfUser = modelHelper.createSelfUser(in: coreDataFixture.coreDataStack.viewContext)
        selfUser.name = "Johannes Chrysostomus Wolfgangus Theophilus Mozart"
        selfUser.accentColor = .red

        let account = Account.mockAccount(imageData: mockImageData)
        let viewModel = ConversationListViewController.ViewModel(
            account: account,
            selfUserLegalHoldSubject: selfUser,
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
        sut.applyFilter(nil)

        // THEN
        verify(matching: tabBarController)
    }

    func testForShowingConversationsFilteredByGroups() {
        // GIVEN
        let conversationData: [(String, Bool)] = [("iOS Team", false), ("Web Team", false)]
        let conversations = createConversations(conversationsData: conversationData)
        userSession.mockConversationDirectory.mockGroupConversations = conversations

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.groups)

        // THEN
        verify(matching: tabBarController)
    }

    func testForShowingConversationsFilteredByFavourites() {
        // GIVEN
        let conversationData: [(String, Bool)] = [("iOS Team", true), ("Web Team", false)]
        let conversations = createConversations(conversationsData: conversationData)
        userSession.mockConversationDirectory.mockFavoritesConversations = conversations.filter { $0.isFavorite }

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.favorites)

        // THEN
        verify(matching: tabBarController)
    }

    func testForShowingConversationsFilteredByOneOnOne() throws {
        // GIVEN
        let modelHelper = ModelHelper()
        let fixture = CoreDataFixture()

        let user1 = modelHelper.createUser(in: fixture.coreDataStack.viewContext)
        user1.name = "Alice"

        let user2 = modelHelper.createUser(in: fixture.coreDataStack.viewContext)
        user2.name = "Bob"

        let oneOnOneConversation1 = modelHelper.createOneOnOne(with: user1, in: fixture.coreDataStack.viewContext)
        let oneOnOneConversation2 = modelHelper.createOneOnOne(with: user2, in: fixture.coreDataStack.viewContext)

        userSession.mockConversationDirectory.mockContactsConversations = [oneOnOneConversation1, oneOnOneConversation2]

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.oneToOneConversations)

        // THEN
        verify(matching: tabBarController)
    }

    // MARK: - Helper Methods

    private func createConversations(conversationsData: [(name: String, isFavorite: Bool)]) -> [ZMConversation] {
        let modelHelper = ModelHelper()
        let fixture = CoreDataFixture()

        var conversations: [ZMConversation] = []

        for (name, isFavorite) in conversationsData {
            let conversation = modelHelper.createGroupConversation(
                in: fixture.coreDataStack.viewContext
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
