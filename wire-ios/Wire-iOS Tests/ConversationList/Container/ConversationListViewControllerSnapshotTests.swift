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

import WireDataModelSupport
import WireDesign
import WireSyncEngineSupport
import WireTestingPackage
import XCTest

@testable import Wire

final class ConversationListViewControllerSnapshotTests: XCTestCase {

    private var coreDataFixture: CoreDataFixture!
    private var modelHelper: ModelHelper!
    private var userSession: UserSessionMock!
    private var mockIsSelfUserE2EICertifiedUseCase: MockIsSelfUserE2EICertifiedUseCaseProtocol!
    private var mockGetUserAccountImageSourceUseCase: MockGetUserAccountImageSourceUseCaseProtocol!
    private var zClientViewController: ZClientViewController!
    private var sut: ConversationListViewController!
    private var window: UIWindow!
    private var snapshotHelper: SnapshotHelper!

    private var coreDataStack: CoreDataStack! { coreDataFixture.coreDataStack }
    private var windowScene: UIWindowScene! { UIApplication.shared.connectedScenes.first as? UIWindowScene }
    private var searchBar: UISearchBar! { sut.navigationItem.searchController?.searchBar }

    @MainActor
    override func setUp() async throws {

        coreDataFixture = .init()
        modelHelper = .init()

        let selfUser = try XCTUnwrap(coreDataFixture.selfUser)
        userSession = .init(selfUser: selfUser, selfUserLegalHoldSubject: selfUser, editableSelfUser: selfUser)
        userSession.coreDataStack = coreDataFixture.coreDataStack
        userSession.mockConversationList = ConversationList(
            allConversations: [],
            filteringPredicate: NSPredicate(value: true),
            managedObjectContext: coreDataStack.viewContext,
            description: "all conversations"
        )

        mockIsSelfUserE2EICertifiedUseCase = .init()
        mockIsSelfUserE2EICertifiedUseCase.invoke_MockValue = false

        mockGetUserAccountImageSourceUseCase = .init()
        mockGetUserAccountImageSourceUseCase
            .invokeUserUserContextAccount_MockValue = .image(UIImage(data: mockImageData)!)

        snapshotHelper = .init()

        zClientViewController = ZClientViewController(
            account: coreDataStack.account,
            selfProfileViewsMonitor: SelfProfileViewsMonitorImplementation(),
            userSession: userSession,
            trackingManager: nil
        )
        sut = .init(
            account: coreDataStack.account,
            selfUserLegalHoldSubject: selfUser,
            userSession: userSession,
            zClientViewController: zClientViewController,
            mainCoordinator: .init(mainCoordinator: MockMainCoordinator()),
            isSelfUserE2EICertifiedUseCase: mockIsSelfUserE2EICertifiedUseCase,
            connectViewControllerBuilder: MockConnectViewControllerBuilderProtocol(),
            selfProfileViewControllerBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            createGroupConversationViewControllerBuilder: MockCreateGroupConversationViewControllerBuilderProtocol(),
            folderPickerViewControllerBuilder: FolderPickerViewControllerBuilder(
                conversationDirectory: userSession.conversationDirectory,
                conversationFilter: { nil }
            ),
            getUserAccountImageSourceUseCase: mockGetUserAccountImageSourceUseCase
        )
        sut.mainSplitViewState = .collapsed

        let tabBarController = ZClientViewController.MainCoordinator.TabBarController()
        tabBarController.applyMainTabBarControllerAppearance()
        tabBarController.conversationListUI = sut

        window = .init(windowScene: windowScene)
        window.backgroundColor = .systemBackground
        window.overrideUserInterfaceStyle = .dark
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

        await fulfillment(of: [viewIfLoadedExpectation(for: sut)], timeout: 5)
        tabBarController.overrideUserInterfaceStyle = .dark
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        sut = nil
        snapshotHelper = nil
        zClientViewController = nil
        userSession = nil
        mockGetUserAccountImageSourceUseCase = nil
        mockIsSelfUserE2EICertifiedUseCase = nil
        modelHelper = nil
        coreDataFixture = nil
        window.isHidden = true
        window = nil
    }

    func testForNoConversations() {
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.placeholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    func testForEverythingArchived() {
        let conversation = modelHelper.createGroupConversation(in: coreDataFixture.coreDataStack.viewContext)
        conversation.isArchived = true
        coreDataFixture.coreDataStack.viewContext.conversationListDirectory()
            .refetchAllLists(in: coreDataFixture.coreDataStack.viewContext)
        sut.showNoContactLabel(animated: false)
        snapshotHelper.verify(matching: renderedImage())
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
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.placeholder)
        snapshotHelper.verify(matching: renderedImage())
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
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.groupsPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    func testForShowingNoConversationsFilteredByGroups() {
        // GIVEN
        userSession.mockConversationDirectory.mockGroupConversations = []

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.groups)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.groupsPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    func testForShowingConversationsFilteredByFavourites() {
        // GIVEN
        let conversationData = [
            (name: "iOS Team", isFavorite: false),
            (name: "Web Team", isFavorite: true)
        ]
        let conversations = createConversations(conversationsData: conversationData)
        userSession.mockConversationDirectory.mockFavoritesConversations = conversations.filter(\.isFavorite)

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.favorites)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.favoritesPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    func testForShowingNoConversationsFilteredByFavourites() {
        // GIVEN
        userSession.mockConversationDirectory.mockFavoritesConversations = []

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.favorites)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.favoritesPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    //
    func testForShowingConversationsFilteredByOneOnOne() throws {
        // GIVEN
        let user1 = modelHelper.createUser(in: coreDataFixture.coreDataStack.viewContext)
        user1.name = "Alice"

        let user2 = modelHelper.createUser(in: coreDataFixture.coreDataStack.viewContext)
        user2.name = "Bob"

        let oneOnOneConversation1 = modelHelper.createOneOnOne(
            with: user1,
            in: coreDataFixture.coreDataStack.viewContext
        )
        let oneOnOneConversation2 = modelHelper.createOneOnOne(
            with: user2,
            in: coreDataFixture.coreDataStack.viewContext
        )

        userSession.mockConversationDirectory.mockContactsConversations = [oneOnOneConversation1, oneOnOneConversation2]

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.oneOnOne)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.oneOnOnePlaceholder)
        snapshotHelper.verify(matching: renderedImage())
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
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.oneOnOnePlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    func testForShowingNoConversationsFilteredBySearchTerm() throws {
        // GIVEN
        let user1 = modelHelper.createUser(in: coreDataFixture.coreDataStack.viewContext)
        user1.name = "Alice"

        let user2 = modelHelper.createUser(in: coreDataFixture.coreDataStack.viewContext)
        user2.name = "Bob"

        userSession.mockConversationDirectory.mockContactsConversations = []
        sut.navigationItem.searchController?.searchBar.text = "XXX"
        sut.applySearchText()

        // WHEN
        // note here the searchBar is not presented but within the app it is
        sut.hideNoContactLabel(animated: false)

        // THEN
        snapshotHelper.verify(matching: renderedImage())
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

    /// Without this helper the layout around the navigation item's search bar breaks when rendering the snapshot.
    private func renderedImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
        return renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }
}
