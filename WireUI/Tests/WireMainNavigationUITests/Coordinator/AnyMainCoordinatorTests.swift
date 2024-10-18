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

@MainActor
final class AnyMainCoordinatorTests: XCTestCase {

    private var mockMainCoordinator: MockMainCoordinatorProtocol!
    private var sut: AnyMainCoordinator<MockMainCoordinatorDependencies>!

    override func setUp() async throws {
        mockMainCoordinator = .init()
        sut = .init(mainCoordinator: mockMainCoordinator)
    }

    override func tearDown() async throws {
        sut = nil
        mockMainCoordinator = nil
    }

    func testShowConversationListIsInvoked() async {
        // When
        await sut.showConversationList(conversationFilter: .groups)

        // Then
        XCTAssertEqual(mockMainCoordinator.showConversationList_Invocations.count, 1)
        XCTAssertEqual(mockMainCoordinator.showConversationList_Invocations.first, .groups)
    }

    func testShowArchiveIsInvoked() async {
        // When
        await sut.showArchive()

        // Then
        XCTAssertEqual(mockMainCoordinator.showArchive_Invocations.count, 1)
    }

    func testShowSettingsIsInvoked() async {
        // When
        await sut.showSettings()

        // Then
        XCTAssertEqual(mockMainCoordinator.showSettings_Invocations.count, 1)
    }

    func testShowConversationIsInvokedWithoutMessage() async {
        // Given
        let conversation = PreviewConversationModel()

        // When
        await sut.showConversation(conversation: conversation, message: nil)

        // Then
        XCTAssertEqual(mockMainCoordinator.showConversation_Invocations.count, 1)
        XCTAssertEqual(mockMainCoordinator.showConversation_Invocations.first?.conversation, conversation)
        XCTAssertNil(mockMainCoordinator.showConversation_Invocations.first?.message)
    }

    func testShowConversationIsInvokedWithMessage() async {
        // Given
        let conversation = PreviewConversationModel()
        let message: Void = ()

        // When
        await sut.showConversation(conversation: conversation, message: message)

        // Then
        XCTAssertEqual(mockMainCoordinator.showConversation_Invocations.count, 1)
        XCTAssertEqual(mockMainCoordinator.showConversation_Invocations.first?.conversation, conversation)
        XCTAssertNotNil(mockMainCoordinator.showConversation_Invocations.first?.message)
    }

    func testHideConversationIsInvoked() {
        // When
        sut.hideConversation()

        // Then
        XCTAssertEqual(mockMainCoordinator.hideConversation_Invocations.count, 1)
    }

    func testShowSettingsContentIsInvoked() {
        // When
        sut.showSettingsContent(.advanced)

        // Then
        XCTAssertEqual(mockMainCoordinator.showSettingsContent_Invocations.count, 1)
        XCTAssertEqual(mockMainCoordinator.showSettingsContent_Invocations.first, .advanced)
    }

    func testHideSettingsContentIsInvoked() {
        // When
        sut.hideSettingsContent()

        // Then
        XCTAssertEqual(mockMainCoordinator.hideSettingsContent_Invocations.count, 1)
    }

    func testShowSelfProfileIsInvoked() async {
        // When
        await sut.showSelfProfile()

        // Then
        XCTAssertEqual(mockMainCoordinator.showSelfProfile_Invocations.count, 1)
    }

    func testShowConnectIsInvoked() async {
        // When
        await sut.showConnect()

        // Then
        XCTAssertEqual(mockMainCoordinator.showConnect_Invocations.count, 1)
    }

    func testShowCreateGroupConversationIsInvoked() async {
        // When
        await sut.showCreateGroupConversation()

        // Then
        XCTAssertEqual(mockMainCoordinator.showCreateGroupConversation_Invocations.count, 1)
    }

    func testPresentViewControllerIsInvoked() async {
        // Given
        let viewController = UIViewController()

        // When
        await sut.presentViewController(viewController)

        // Then
        XCTAssertEqual(mockMainCoordinator.presentViewController_Invocations.count, 1)
        XCTAssertEqual(mockMainCoordinator.presentViewController_Invocations.first, viewController)
    }

    func testDismissPresentedViewControllerIsInvoked() async {
        // When
        await sut.dismissPresentedViewController()

        // Then
        XCTAssertEqual(mockMainCoordinator.dismissPresentedViewController_Invocations.count, 1)
    }
}
