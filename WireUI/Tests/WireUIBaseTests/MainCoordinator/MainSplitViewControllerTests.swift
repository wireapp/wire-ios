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

@testable import WireUIBase

final class MainSplitViewControllerTests: XCTestCase {

    private var sut: MainSplitViewController<UIViewController, UIViewController, UIViewController, UIViewController>!
    private var sidebar: UIViewController!
    private var conversationList: UIViewController!
    private var conversation: UIViewController!
    private var noConversationPlaceholder: UIViewController!
    private var tabContainer: UIViewController!

    @MainActor
    override func setUp() async throws {
        sidebar = .init()
        conversationList = .init()
        conversation = .init()
        noConversationPlaceholder = .init()
        tabContainer = .init()
        sut = .init(
            sidebar: sidebar,
            noConversationPlaceholder: noConversationPlaceholder,
            tabContainer: tabContainer
        )
        sut.conversationList = conversationList
        sut.conversation = conversation
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

        // Then
        XCTAssertNil(sut.conversation)
        let secondaryNavigationController = sut.viewController(for: .secondary) as! UINavigationController
        XCTAssert(secondaryNavigationController.viewControllers[0] === noConversationPlaceholder)
    }

    @MainActor
    func testConversationListIsReleased() {

        // When
        weak var conversationList = self.conversationList
        self.conversationList = nil
        sut.conversationList = nil

        // Then
        XCTAssertEqual(conversationList, nil)
    }

    @MainActor
    func testConversationIsReleased() async {

        // When
        weak var conversation = self.conversation
        self.conversation = nil
        sut.conversation = nil

        // Then
        await Task.yield()
        XCTAssertEqual(conversation, nil)
    }
}
