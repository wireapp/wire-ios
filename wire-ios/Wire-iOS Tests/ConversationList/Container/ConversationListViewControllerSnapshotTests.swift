//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

    private let iOSTeamID = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E50")!
    private let webTeamID = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E51")!
    private let qaTeamID = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E52")!
    private let designTeamID = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E53")!
    private let bugsAndQuestionsTeamID = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E54")!

    @MainActor
    override func setUp() async throws {
        coreDataFixture = try await CoreDataFixture()
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
            trackingManager: nil,
            wireMeetingsFactory: MockWireMeetingsFactoryProtocol(),
            wireMessagingFactory: MockWireMessagingFactoryProtocol.makeDefault()
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

        await setupTabBar()
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

    @MainActor
    private func setupTabBar(showFiles: Bool = false) async {
        let tabBarController = ZClientViewController.MainCoordinator.TabBarController(
            showMeetings: false,
            showFiles: showFiles
        )
        tabBarController.applyMainTabBarControllerAppearance()
        tabBarController.conversationListUI = sut
        if showFiles {
            tabBarController.filesUI = .init()
        }

        window = .init(windowScene: windowScene)
        window.backgroundColor = .systemBackground
        window.overrideUserInterfaceStyle = .dark
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

        await fulfillment(of: [viewIfLoadedExpectation(for: sut)], timeout: 5)
        tabBarController.overrideUserInterfaceStyle = .dark
        UIView.setAnimationsEnabled(false)
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
            (name: "iOS Team", iOSTeamID, isFavorite: false),
            (name: "Web Team", webTeamID, isFavorite: false),
            (name: "QA Team", qaTeamID, isFavorite: false),
            (name: "Design Team", designTeamID, isFavorite: false),
            (name: "iOS Bugs & Questions", bugsAndQuestionsTeamID, isFavorite: false)
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
            (name: "iOS Team", iOSTeamID, isFavorite: false),
            (name: "Web Team", webTeamID, isFavorite: false)
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
            (name: "iOS Team", iOSTeamID, isFavorite: false),
            (name: "Web Team", webTeamID, isFavorite: true)
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

    // MARK: - Unread Filter Tests

    func testForShowingConversationsFilteredByUnread() throws {
        // GIVEN
        let conversationData = [
            (name: "iOS Team", iOSTeamID, isFavorite: false),
            (name: "Web Team", webTeamID, isFavorite: false),
            (name: "QA Team", qaTeamID, isFavorite: false)
        ]
        let conversations = createConversations(conversationsData: conversationData)

        // Mark some conversations as having unread messages
        conversations[0].lastServerTimeStamp = Date()
        conversations[0].lastReadServerTimeStamp = Date(timeIntervalSinceNow: -3600)
        conversations[1].lastServerTimeStamp = Date()
        conversations[1].lastReadServerTimeStamp = Date(timeIntervalSinceNow: -7200)

        userSession.mockConversationDirectory.mockUnarchivedConversations = conversations

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.unread)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.unreadPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    func testForShowingNoConversationsFilteredByUnread() {
        // GIVEN
        userSession.mockConversationDirectory.mockUnarchivedConversations = []

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.unread)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.unreadPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    // MARK: - Mentions Filter Tests

    func testForShowingConversationsFilteredByMentions() {
        // GIVEN
        let conversationData = [
            (name: "iOS Team", iOSTeamID, isFavorite: false),
            (name: "Web Team", webTeamID, isFavorite: false)
        ]
        let conversations = createConversations(conversationsData: conversationData)

        // Add mentions to conversations
        // Add mention to first conversation
        let selfUser = coreDataFixture.selfUser!
        let otherUser = modelHelper.createUser(in: coreDataFixture.coreDataStack.viewContext)
        otherUser.name = "Alice"

        let mention = Mention(range: NSRange(location: 0, length: 5), user: selfUser)
        let message = try! conversations[0].appendText(
            content: "@self check this out",
            mentions: [mention],
            replyingTo: nil,
            fetchLinkPreview: false,
            nonce: UUID()
        ) as! ZMClientMessage
        message.sender = otherUser
        message.serverTimestamp = Date()
        conversations[0].updateTimestampsAfterUpdatingMessage(message)
        conversations[0].lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
        conversations[0].setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfMentionCountKey)
        conversations[0].needsToCalculateUnreadMessages = true

        // Add mention to second conversation
        let mention2 = Mention(range: NSRange(location: 0, length: 5), user: selfUser)
        let message2 = try! conversations[1].appendText(
            content: "@self urgent task",
            mentions: [mention2],
            replyingTo: nil,
            fetchLinkPreview: false,
            nonce: UUID()
        ) as! ZMClientMessage
        message2.sender = otherUser
        message2.serverTimestamp = Date()
        conversations[1].updateTimestampsAfterUpdatingMessage(message2)
        conversations[1].lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
        conversations[1].setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfMentionCountKey)
        conversations[1].needsToCalculateUnreadMessages = true

        ZMConversation.calculateLastUnreadMessages(in: coreDataFixture.coreDataStack.viewContext)

        userSession.mockConversationDirectory.mockUnarchivedConversations = conversations

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.mentions)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.mentionsPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    func testForShowingNoConversationsFilteredByMentions() {
        // GIVEN
        userSession.mockConversationDirectory.mockUnarchivedConversations = []

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.mentions)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.mentionsPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    // MARK: - Replies Filter Tests

    func testForShowingConversationsFilteredByReplies() {
        // GIVEN
        let conversationData = [
            (name: "Design Team", designTeamID, isFavorite: false),
            (name: "QA Team", qaTeamID, isFavorite: false)
        ]
        let conversations = createConversations(conversationsData: conversationData)

        // Add replies to conversations
        let selfUser = coreDataFixture.selfUser!
        let otherUser = modelHelper.createUser(in: coreDataFixture.coreDataStack.viewContext)
        otherUser.name = "Bob"

        // Add reply to first conversation
        // Create original message from self
        let originalMessage1 = try! conversations[0]
            .appendText(content: "What about the new design?") as! ZMClientMessage
        originalMessage1.sender = selfUser
        originalMessage1.serverTimestamp = Date(timeIntervalSinceNow: -180)

        // Create reply from other user
        let replyMessage1 = try! conversations[0].appendText(
            content: "I think it looks great!",
            mentions: [],
            replyingTo: originalMessage1,
            fetchLinkPreview: false,
            nonce: UUID()
        ) as! ZMClientMessage
        replyMessage1.sender = otherUser
        replyMessage1.serverTimestamp = Date()
        conversations[0].updateTimestampsAfterUpdatingMessage(replyMessage1)
        conversations[0].lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
        conversations[0].setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfReplyCountKey)
        conversations[0].needsToCalculateUnreadMessages = true

        // Add reply to second conversation
        let originalMessage2 = try! conversations[1]
            .appendText(content: "Can you test this feature?") as! ZMClientMessage
        originalMessage2.sender = selfUser
        originalMessage2.serverTimestamp = Date(timeIntervalSinceNow: -180)

        let replyMessage2 = try! conversations[1].appendText(
            content: "Testing it now",
            mentions: [],
            replyingTo: originalMessage2,
            fetchLinkPreview: false,
            nonce: UUID()
        ) as! ZMClientMessage
        replyMessage2.sender = otherUser
        replyMessage2.serverTimestamp = Date()
        conversations[1].updateTimestampsAfterUpdatingMessage(replyMessage2)
        conversations[1].lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
        conversations[1].setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfReplyCountKey)
        conversations[1].needsToCalculateUnreadMessages = true

        ZMConversation.calculateLastUnreadMessages(in: coreDataFixture.coreDataStack.viewContext)

        userSession.mockConversationDirectory.mockUnarchivedConversations = conversations

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.replies)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.repliesPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    func testForShowingNoConversationsFilteredByReplies() {
        // GIVEN
        userSession.mockConversationDirectory.mockUnarchivedConversations = []

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.replies)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.repliesPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    // MARK: - Drafts Filter Tests

    func testForShowingConversationsFilteredByDrafts() {
        // GIVEN
        let conversationData = [
            (name: "iOS Team", iOSTeamID, isFavorite: false),
            (name: "Design Team", designTeamID, isFavorite: false)
        ]
        let conversations = createConversations(conversationsData: conversationData)

        // Add drafts to conversations
        // Add draft to first conversation
        let draft1 = DraftMessage(
            text: "Working on the new feature...",
            mentions: [],
            quote: nil
        )
        conversations[0].draftMessage = draft1

        // Add draft to second conversation
        let draft2 = DraftMessage(
            text: "I think we should redesign the",
            mentions: [],
            quote: nil
        )
        conversations[1].draftMessage = draft2

        userSession.mockConversationDirectory.mockUnarchivedConversations = conversations

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.drafts)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.draftsPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    func testForShowingNoConversationsFilteredByDrafts() {
        // GIVEN#imageLiteral(resourceName: "testForShowingConversationsFilteredByDrafts.1.png")
        userSession.mockConversationDirectory.mockUnarchivedConversations = []

        // WHEN
        sut.hideNoContactLabel(animated: false)
        sut.applyFilter(.drafts)

        // THEN
        XCTAssertEqual(searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.draftsPlaceholder)
        snapshotHelper.verify(matching: renderedImage())
    }

    @MainActor
    func testForShowingFilesTabWhenWireCellsEnabled() async {
        // GIVEN
        userSession.mockConversationDirectory.mockUnarchivedConversations = []

        // WHEN
        await setupTabBar(showFiles: true)

        // THEN, files tab should show up
        snapshotHelper.verify(matching: renderedImage())
    }

    // MARK: - Helper Methods

    private func createConversations(conversationsData: [(name: String, id: UUID, isFavorite: Bool)])
        -> [ZMConversation] {
        var conversations: [ZMConversation] = []

        for (name, id, isFavorite) in conversationsData {
            let conversation = modelHelper.createGroupConversation(
                in: coreDataFixture.coreDataStack.viewContext
            )

            conversation.userDefinedName = name
            conversation.remoteIdentifier = id
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
