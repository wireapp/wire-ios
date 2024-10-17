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

import SwiftUI
import WireTestingPackage
import XCTest

@testable import WireMainNavigationUI

final class MainSplitViewControllerTests: XCTestCase {

    private var sut: MainSplitViewController<PreviewSidebarViewController, PreviewTabBarController>!
    private var sidebar: PreviewSidebarViewController!
    private var conversationListUI: PreviewConversationListViewController!
    private var conversationUI: PreviewConversationViewController!
    private var noConversationPlaceholder: UIViewController!
    private var tabController: PreviewTabBarController!

    private var snapshotHelper: SnapshotHelper!

    @MainActor
    override func setUp() async throws {
        sidebar = .init("Sidebar", .gray)
        conversationListUI = .init("Conversation List", .purple)
        conversationUI = .init()
        noConversationPlaceholder = PreviewSidebarViewController("No Conversation Selected", .brown)
        tabController = .init()
        sut = .init(
            sidebar: sidebar,
            noConversationPlaceholder: noConversationPlaceholder,
            tabController: tabController
        )
        sut.conversationListUI = conversationListUI
        sut.conversationUI = conversationUI

        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() async throws {
        snapshotHelper = nil
        sut = nil
        tabController = nil
        noConversationPlaceholder = nil
        conversationUI = nil
        conversationListUI = nil
        sidebar = nil
    }

    @MainActor
    func testInitializationWithConversation() {
        XCTAssert(sut.sidebar === sidebar)
        XCTAssert(sut.conversationListUI === conversationListUI)
        XCTAssert(sut.conversationUI === conversationUI)
        XCTAssert(sut.tabController === tabController)
    }

    @MainActor
    func testPlaceholderIsNotReturnedAsConversation() {
        // Given
        sut = .init(
            sidebar: sidebar,
            noConversationPlaceholder: noConversationPlaceholder,
            tabController: tabController
        )
        sut.conversationListUI = conversationListUI

        // When
        let conversationUI = sut.conversationUI

        // Then
        XCTAssertNil(conversationUI)
        let container = sut.viewController(for: .secondary) as! DoubleColumnContainerViewController
        let secondaryNavigationController = container.secondaryNavigationController
        XCTAssert(secondaryNavigationController.viewControllers[0] === noConversationPlaceholder)
    }

    @MainActor
    func testConversationListIsReleased() {
        // Given
        weak var conversationListUI = conversationListUI
        self.conversationListUI = nil

        // When
        sut.conversationListUI = nil

        // Then
        XCTAssertEqual(conversationListUI, nil)
    }

    @MainActor
    func testConversationIsReleasedWhenSetToNil() async {
        // Given
        weak var conversationUI = conversationUI
        self.conversationUI = nil

        // When
        sut.conversationUI = nil

        // Then
        await Task.yield()
        XCTAssertEqual(conversationUI, nil)
    }

    @MainActor
    func testConversationListIsReleasedWhenArchiveIsSet() async {
        // Given
        weak var conversationListUI = conversationListUI
        self.conversationListUI = nil

        // When
        sut.archiveUI = .init()

        // Then
        await Task.yield()
        XCTAssertEqual(conversationListUI, nil)
    }

    @MainActor
    func testConversationIsReleasedWhenSettingsIsSet() async {
        // Given
        weak var conversationListUI = conversationListUI
        self.conversationListUI = nil

        // When
        sut.settingsUI = .init()

        // Then
        await Task.yield()
        XCTAssertEqual(conversationListUI, nil)
    }

    // MARK: - Snapshot Tests

    @available(iOS 17.0, *) @MainActor
    func testSidebarAppearanceLandscape() {
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 1_024, height: 768))
        window.rootViewController = sut
        window.makeKeyAndVisible()
        sut.traitOverrides.horizontalSizeClass = .regular
        sut.preferredDisplayMode = .twoBesideSecondary

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: sut.view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.view, named: "dark")

        window.isHidden = true
    }

    @available(iOS 17.0, *) @MainActor
    func testSidebarAppearancePortrait() {
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 768, height: 1_024))
        window.rootViewController = sut
        window.makeKeyAndVisible()
        sut.traitOverrides.horizontalSizeClass = .regular
        sut.preferredDisplayMode = .twoBesideSecondary

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: sut.view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.view, named: "dark")

        window.isHidden = true
    }

    @MainActor
    func testCompactAppearance() {
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: sut, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, named: "dark")
    }
}
