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

@testable import WireUIFoundation

final class MainSplitViewControllerTests: XCTestCase {

    private var sut: MainSplitViewController<PreviewSidebarViewController, PreviewConversationListViewController>!
    private var sidebar: PreviewSidebarViewController!
    private var conversationList: PreviewConversationListViewController!
    private var conversation: UIViewController!
    private var noConversationPlaceholder: UIViewController!
    private var tabContainer: UIViewController!

    private var snapshotHelper: SnapshotHelper!

    @MainActor
    override func setUp() async throws {
        sidebar = .init("Sidebar", .gray)
        conversationList = .init("Conversation List", .purple)
        conversation = PreviewSidebarViewController("Conversation", .blue)
        noConversationPlaceholder = PreviewSidebarViewController("No Conversation Selected", .brown)
        tabContainer = PreviewSidebarViewController("Tab Container", .cyan)
        sut = .init(
            sidebar: sidebar,
            noConversationPlaceholder: noConversationPlaceholder,
            tabContainer: tabContainer
        )
        sut.conversationList = conversationList
        sut.conversation = conversation

        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() async throws {
        snapshotHelper = nil
        sut = nil
        tabContainer = nil
        noConversationPlaceholder = nil
        conversation = nil
        conversationList = nil
        sidebar = nil
    }

    @MainActor
    func testInitializationWithConversation() {
        XCTAssert(sut.sidebar === sidebar)
        XCTAssert(sut.conversationList === conversationList)
        XCTAssert(sut.conversation === conversation)
        XCTAssert(sut.tabContainer === tabContainer)
    }

    @MainActor
    func testPlaceholderIsNotReturnedAsConversation() {
        // Given
        sut = .init(
            sidebar: sidebar,
            noConversationPlaceholder: noConversationPlaceholder,
            tabContainer: tabContainer
        )
        sut.conversationList = conversationList

        // When
        let conversation = sut.conversation

        // Then
        XCTAssertNil(conversation)
        let secondaryNavigationController = sut.viewController(for: .secondary) as! UINavigationController
        XCTAssert(secondaryNavigationController.viewControllers[0] === noConversationPlaceholder)
    }

    @MainActor
    func testConversationListIsReleased() {
        // Given
        weak var conversationList = conversationList
        self.conversationList = nil

        // When
        sut.conversationList = nil

        // Then
        XCTAssertEqual(conversationList, nil)
    }

    @MainActor
    func testConversationIsReleasedWhenSetToNil() async {
        // Given
        weak var conversation = conversation
        self.conversation = nil

        // When
        sut.conversation = nil

        // Then
        await Task.yield()
        XCTAssertEqual(conversation, nil)
    }

    @MainActor
    func testConversationListIsReleasedWhenArchiveIsSet() async {
        // Given
        weak var conversationList = conversationList
        self.conversationList = nil

        // When
        sut.archive = .init()

        // Then
        await Task.yield()
        XCTAssertEqual(conversationList, nil)
    }

    @MainActor
    func testConversationIsReleasedWhenNewConversationIsSet() async {
        // Given
        weak var conversationList = conversationList
        self.conversationList = nil

        // When
        sut.newConversation = .init()

        // Then
        await Task.yield()
        XCTAssertEqual(conversationList, nil)
    }

    @MainActor
    func testConversationIsReleasedWhenSettingsIsSet() async {
        // Given
        weak var conversationList = conversationList
        self.conversationList = nil

        // When
        sut.settings = .init()

        // Then
        await Task.yield()
        XCTAssertEqual(conversationList, nil)
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
