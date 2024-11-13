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
    private var zClientViewController: ZClientViewController!
    private var window: UIWindow!
    private var snapshotHelper: SnapshotHelper!

    private var sut: ConversationListViewController! { zClientViewController.conversationListViewController }
    private var coreDataStack: CoreDataStack! { coreDataFixture.coreDataStack }
    private var windowScene: UIWindowScene! {
        UIApplication.shared.connectedScenes.first as? UIWindowScene
    }

    @MainActor
    override func setUp() async throws {

        coreDataFixture = .init()
        coreDataStack.account.imageData = mockImageData

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

        snapshotHelper = .init()

        zClientViewController = ZClientViewController(
            account: coreDataStack.account,
            userSession: userSession,
            trackingManager: nil
        )


    }

    override func tearDown() {
        snapshotHelper = nil
        zClientViewController = nil
        userSession = nil
        modelHelper = nil
        coreDataFixture = nil
        window.isHidden = true
        window = nil
    }

    @MainActor
    func testForNoConversations() async {
        window = .init(windowScene: windowScene)
        window.rootViewController = zClientViewController
        window.makeKeyAndVisible()

        await fulfillment(of: [viewIfLoadedExpectation(for: zClientViewController)], timeout: 5)
        zClientViewController.overrideUserInterfaceStyle = .dark
        UIView.setAnimationsEnabled(false)
        window.rootViewController = nil
        snapshotHelper.verify(matching: zClientViewController)
    }

    func testForEverythingArchived() {
        let conversation = modelHelper.createGroupConversation(in: coreDataFixture.coreDataStack.viewContext)
        conversation.isArchived = true
        coreDataFixture.coreDataStack.viewContext.conversationListDirectory().refetchAllLists(in: coreDataFixture.coreDataStack.viewContext)
        sut.showNoContactLabel(animated: false)
        window.rootViewController = nil
        snapshotHelper.verify(matching: zClientViewController)
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
        window.rootViewController = nil
        snapshotHelper.verify(matching: zClientViewController)
    }

    @MainActor
    func testForShowingConversationsFilteredByGroups() async {
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
        window.rootViewController = nil
        snapshotHelper.verify(matching: zClientViewController)
    }

    func testForShowingNoConversationsFilteredByGroups() {
        // GIVEN
        userSession.mockConversationDirectory.mockGroupConversations = []

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.groups)

        // THEN
        window.rootViewController = nil
        snapshotHelper.verify(matching: zClientViewController)
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
        window.rootViewController = nil
        snapshotHelper.verify(matching: zClientViewController)
    }

    func testForShowingNoConversationsFilteredByFavourites() {
        // GIVEN
        userSession.mockConversationDirectory.mockFavoritesConversations = []

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.favorites)

        // THEN
        window.rootViewController = nil
        snapshotHelper.verify(matching: zClientViewController)
    }

    @MainActor
    func testForShowingConversationsFilteredByOneOnOne() async throws {
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
        window = .init(windowScene: windowScene)
        window.rootViewController = zClientViewController
        window.makeKeyAndVisible()

        await fulfillment(of: [viewIfLoadedExpectation(for: zClientViewController)], timeout: 5)
        zClientViewController.overrideUserInterfaceStyle = .dark
        UIView.setAnimationsEnabled(false)
        snapshotHelper.verify(matching: zClientViewController)
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
        window.rootViewController = nil
        snapshotHelper.verify(matching: zClientViewController)
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
