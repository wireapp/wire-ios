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

@testable import WireMainNavigationUI

final class MainCoordinatorTests: XCTestCase {

    typealias SUT = MainCoordinator<MockMainCoordinatorDependencies>

    private var sut: SUT!

    private var splitViewController: MockSplitViewController!
    private var tabBarController: SUT.TabBarController!
    private var sidebar: MockSidebarViewController!
    private var conversationListUI: SUT.ConversationListUI!

    @MainActor
    override func setUp() async throws {
        sidebar = .init()
        conversationListUI = .init("")

        splitViewController = .init(style: .tripleColumn)
        splitViewController.sidebar = sidebar
        splitViewController.conversationListUI = conversationListUI

        tabBarController = .init()
        tabBarController.archiveUI = .init()
        tabBarController.settingsUI = .init()

        sut = .init(
            mainSplitViewController: splitViewController,
            mainTabBarController: tabBarController,
            conversationUIBuilder: .init(),
            settingsContentUIBuilder: .init(),
            connectUIBuilder: .init(),
            createGroupConversationUIBuilder: .init(),
            selfProfileUIBuilder: .init(),
            userProfileUIBuilder: .init()
        )
    }

    override func tearDown() {
        sut = nil
        tabBarController = nil
        splitViewController = nil
        conversationListUI = nil
        sidebar = nil
    }

    @MainActor
    func testShowingGroupConversations() async {
        // When
        let conversationFilter: SUT.ConversationListUI.ConversationFilter = .groups
        await sut.showConversationList(conversationFilter: conversationFilter)

        // Then
        XCTAssertNotNil(splitViewController.conversationListUI)
        XCTAssertNil(tabBarController.conversationListUI)
        XCTAssertEqual(conversationListUI.conversationFilter, .groups)
        XCTAssertEqual(sidebar.selectedMenuItem, .groups)
    }

    @MainActor
    func testShowingGroupConversationsFromArchive() async {
        // When
        await sut.showArchive()

        // Then
        await testShowingGroupConversations()
    }

    @MainActor
    func testCollapsingConversationList() {
        // When
        sut.splitViewControllerDidCollapse(splitViewController)

        // Then
        XCTAssertNil(splitViewController.conversationListUI)
        XCTAssertNotNil(tabBarController.conversationListUI)
    }

    @MainActor
    func testShowingArchivedConversations() async {
        // When
        await sut.showArchive()

        // Then
        XCTAssertNil(splitViewController.conversationListUI)
        XCTAssertNotNil(tabBarController.conversationListUI)
        XCTAssertNotNil(splitViewController.archiveUI)
        XCTAssertNil(tabBarController.archiveUI)
    }

    // TODO: [WPB-10903] consider increasing test coverage, e.g.
    // - collapsing archive, connect, settings, selfProfile
    // - expanding archive, connect, settings, selfProfile
    // - dismissing conversationList, archive, connect, connect, settings, selfProfile
    // - tabBarController(_:didSelect:)
}
