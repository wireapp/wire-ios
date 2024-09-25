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

import WireTestingPackage
import XCTest

@testable import WireMainNavigation

final class MainTabBarControllerTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testConversationListAndConversationIsInstalled() throws {
        // Given
        let conversationList = MockConversationListViewController()
        let conversation = UIViewController()
        let sut = MainTabBarController<MockConversationListViewController>()

        // When
        sut.conversations = (conversationList, conversation)

        // Then
        let navigationController = try XCTUnwrap(sut.viewControllers?[1] as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers, [conversationList, conversation])
    }

    @MainActor
    func testConversationIsReleased() throws {
        // Given
        let sut = MainTabBarController<MockConversationListViewController>()
        sut.conversations = (.init(), .init())
        let navigationController = try XCTUnwrap(sut.viewControllers?[1] as? UINavigationController)

        // When
        navigationController.popViewController(animated: false)

        // Then
        let (conversationList, conversation) = try XCTUnwrap(sut.conversations)
        XCTAssertNotNil(conversationList)
        XCTAssertNil(conversation)
    }

    @MainActor
    func testArchiveIsInstalled() throws {
        // Given
        let archive = UIViewController()
        let sut = MainTabBarController<MockConversationListViewController>()

        // When
        sut.archive = archive

        // Then
        let navigationController = try XCTUnwrap(sut.viewControllers?[3] as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers, [archive])
    }

    @MainActor
    func testArchiveIsReleased() async throws {
        // Given
        weak var weakArchive: UIViewController?
        let sut = MainTabBarController<MockConversationListViewController>()
        sut.archive = {
            let archive = UIViewController()
            weakArchive = archive
            return archive
        }()

        // When
        sut.archive = nil

        // Then
        await Task.yield()
        XCTAssertNil(weakArchive)
    }

    @MainActor
    func testSettingsIsInstalled() throws {
        throw XCTSkip() // test will be activated with navigation overhaul

        // Given
        let settings = UIViewController()
        let sut = MainTabBarController<MockConversationListViewController>()

        // When
        sut.settings = settings

        // Then
        let navigationController = try XCTUnwrap(sut.viewControllers?[2] as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers, [settings])
    }

    @MainActor
    func testSettingsIsReleased() throws {
        throw XCTSkip() // test will be activated with navigation overhaul

        // Given
        weak var weakSettings: UIViewController?
        let sut = MainTabBarController<MockConversationListViewController>()
        sut.settings = {
            let settings = UIViewController()
            weakSettings = settings
            return settings
        }()

        // When
        sut.settings = nil

        // Then
        XCTAssertNil(weakSettings)
    }

    // MARK: - Snapshot Tests

    @MainActor
    func testAppearance() {
        let sut = MainTabBarControllerPreview()
        snapshotHelper
            .verify(matching: sut, named: "light", testName: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, named: "dark", testName: "dark")
    }
}
