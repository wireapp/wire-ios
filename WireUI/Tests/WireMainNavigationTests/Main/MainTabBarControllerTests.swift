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

    private var sut: MainTabBarController<MockConversationListViewController, UIViewController, UIViewController, UIViewController, MockSettingsViewController>!
    private var snapshotHelper: SnapshotHelper!

    @MainActor
    override func setUp() async throws {
        sut = .init()
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
    }

    @MainActor
    func testConversationListIsInstalled() throws {
        // Given
        let conversationList = MockConversationListViewController()

        // When
        sut.conversationList = conversationList

        // Then
        let navigationController = try XCTUnwrap(sut.viewControllers?[0] as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers, [conversationList])
    }

    @MainActor
    func testConversationIsReleased() async throws {
        // Given
        weak var weakConversationList: MockConversationListViewController?
        sut.conversationList = {
            let conversationList = MockConversationListViewController()
            weakConversationList = conversationList
            return conversationList
        }()

        // When
        sut.conversationList = nil

        // Then
        await Task.yield()
        XCTAssertNil(weakConversationList)
    }

    @MainActor
    func testArchiveIsInstalled() throws {
        // Given
        let archive = UIViewController()

        // When
        sut.archive = archive

        // Then
        let navigationController = try XCTUnwrap(sut.viewControllers?[1] as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers, [archive])
    }

    @MainActor
    func testArchiveIsReleased() async throws {
        // Given
        weak var weakArchive: UIViewController?
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
        // Given
        let settings = MockSettingsViewController()

        // When
        sut.settings = settings

        // Then
        let navigationController = try XCTUnwrap(sut.viewControllers?[2] as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers, [settings])
    }

    @MainActor
    func testSettingsIsReleased() async throws {
        // Given
        weak var weakSettings: UIViewController?
        sut.settings = {
            let settings = MockSettingsViewController()
            weakSettings = settings
            return settings
        }()

        // When
        sut.settings = nil
        await Task.yield()

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
