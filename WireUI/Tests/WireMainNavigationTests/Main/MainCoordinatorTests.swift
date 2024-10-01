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

@testable import WireMainNavigation

final class MainCoordinatorTests: XCTestCase {

    typealias SUT = MainCoordinator<
        MockSplitViewController,
        MockConversationBuilder<MockConversationID>,
        MockSettingsViewControllerBuilder,
        MockViewControllerBuilder,
        MockViewControllerBuilder
    >

    private var sut: SUT!

    private var splitViewController: MockSplitViewController!
    private var tabBarController: MockTabBarController!
    private var sidebar: MockSidebarViewController!
    private var conversationList: MockConversationListViewController!

    @MainActor
    override func setUp() async throws {
        sidebar = .init()
        conversationList = .init()

        splitViewController = .init(style: .tripleColumn)
        splitViewController.sidebar = sidebar
        splitViewController.conversationList = conversationList

        tabBarController = .init()
        tabBarController.archive = .init()
        tabBarController.settings = .init()

        sut = .init(
            mainSplitViewController: splitViewController,
            mainTabBarController: tabBarController,
            conversationBuilder: .init(),
            settingsContentBuilder: .init(),
            connectBuilder: .init(),
            selfProfileBuilder: .init()
        )
    }

    override func tearDown() {
        sut = nil
        tabBarController = nil
        splitViewController = nil
        conversationList = nil
        sidebar = nil
    }

    @MainActor
    func testShowingGroupConversations() {
        // When
        let conversationFilter: MockConversationListViewController.ConversationFilter = .groups
        sut.showConversationList(conversationFilter: conversationFilter)

        // Then
        XCTAssertNotNil(splitViewController.conversationList)
        XCTAssertNil(tabBarController.conversationList)
        XCTAssertEqual(conversationList.conversationFilter, .groups)
        XCTAssertEqual(sidebar.selectedMenuItem, .groups)
    }

    @MainActor
    func testShowingGroupConversationsFromArchive() {
        // When
        sut.showArchive()

        // Then
        testShowingGroupConversations()
    }

    @MainActor
    func testCollapsingConversationList() {
        // When
        sut.splitViewControllerDidCollapse(splitViewController)

        // Then
        XCTAssertNil(splitViewController.conversationList)
        XCTAssertNotNil(tabBarController.conversationList)
    }

    @MainActor
    func testShowingArchivedConversations() {
        // When
        sut.showArchive()

        // Then
        XCTAssertNil(splitViewController.conversationList)
        XCTAssertNotNil(tabBarController.conversationList)
        XCTAssertNotNil(splitViewController.archive)
        XCTAssertNil(tabBarController.archive)
    }

    // TODO: [WPB-10903] add many more tests, e.g.
    // - collapsing archive, connect, settings, selfProfile
    // - expanding archive, connect, settings, selfProfile
    // - dismissing conversationList, archive, connect, connect, settings, selfProfile
    // - tabBarController(_:didSelect:)
}
