//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

@testable import WireMainNavigationUI

final class MainTabBarControllerTests: XCTestCase {

    private var sut: MainTabBarController<
        MockConversationListViewController,
        MockConversationViewController<PreviewConversationModel>
    >!
    private var snapshotHelper: SnapshotHelper!

    @MainActor
    override func setUp() async throws {
        sut = MainTabBarController(showMeetings: false, showFiles: false)
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
        let conversationListUI = MockConversationListViewController()

        // When
        sut.conversationListUI = conversationListUI

        // Then
        let navigationController = try XCTUnwrap(sut.viewControllers?[0] as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers, [conversationListUI])
    }

    @MainActor
    func testConversationIsReleased() async throws {
        // Given
        weak var weakConversationListUI: MockConversationListViewController?
        sut.conversationListUI = {
            let conversationListUI = MockConversationListViewController()
            weakConversationListUI = conversationListUI
            return conversationListUI
        }()

        // When
        sut.conversationListUI = nil

        // Then
        await Task.yield()
        XCTAssertNil(weakConversationListUI)
    }

    @MainActor
    func testArchiveIsInstalled() throws {
        // Given
        let archiveUI = UIViewController()

        // When
        sut.archiveUI = archiveUI

        // Then
        let navigationController = try XCTUnwrap(sut.viewControllers?[1] as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers, [archiveUI])
    }

    @MainActor
    func testArchiveIsReleased() async throws {
        // Given
        weak var weakArchiveUI: UIViewController?
        sut.archiveUI = {
            let archiveUI = UIViewController()
            weakArchiveUI = archiveUI
            return archiveUI
        }()

        // When
        sut.archiveUI = nil

        // Then
        await Task.yield()
        XCTAssertNil(weakArchiveUI)
    }

    @MainActor
    func testSettingsIsInstalled() throws {
        // Given
        let settingsUI = UIViewController()

        // When
        sut.settingsUI = settingsUI

        // Then
        let navigationController = try XCTUnwrap(sut.viewControllers?[2] as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers, [settingsUI])
    }

    @MainActor
    func testSettingsIsReleased() async throws {
        // Given
        weak var weakSettings: UIViewController?
        sut.settingsUI = {
            let settings = UIViewController()
            weakSettings = settings
            return settings
        }()

        // When
        sut.settingsUI = nil
        await Task.yield()

        // Then
        XCTAssertNil(weakSettings)
    }

    @MainActor
    func testFilesIsInstalled() throws {
        // Given
        sut = MainTabBarController(showMeetings: false, showFiles: true)
        let filesUI = UIViewController()

        // When
        sut.filesUI = filesUI

        // Then
        let navigationController = try XCTUnwrap(sut.viewControllers?[1] as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers, [filesUI])
    }

    @MainActor
    func testFilesIsReleased() async throws {
        // Given
        sut = MainTabBarController(showMeetings: false, showFiles: true)
        weak var weakSettings: UIViewController?
        sut.filesUI = {
            let settings = UIViewController()
            weakSettings = settings
            return settings
        }()

        // When
        sut.filesUI = nil
        await Task.yield()

        // Then
        XCTAssertNil(weakSettings)
    }

    @MainActor
    func testMeetingsIsInstalled() throws {
        // Given
        sut = MainTabBarController(showMeetings: true, showFiles: false)
        let meetingsUI = UIViewController()

        // When
        sut.meetingsUI = meetingsUI

        // Then
        let navigationController = try XCTUnwrap(sut.viewControllers?[2] as? UINavigationController)
        XCTAssertEqual(navigationController.viewControllers, [meetingsUI])
    }

    @MainActor
    func testMeetingsIsReleased() async throws {
        // Given
        sut = MainTabBarController(showMeetings: true, showFiles: false)
        weak var weakMeetings: UIViewController?
        sut.meetingsUI = {
            let meetings = UIViewController()
            weakMeetings = meetings
            return meetings
        }()

        // When
        sut.meetingsUI = nil
        await Task.yield()

        // Then
        XCTAssertNil(weakMeetings)
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

    @MainActor
    func testAppearanceWithFilesTab() {
        let sut = MainTabBarControllerPreview(showFiles: true)
        snapshotHelper
            .verify(matching: sut, named: "light", testName: "tabBarWithFilesTabItem")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, named: "dark", testName: "tabBarWithFilesTabItem")
    }

    @MainActor
    func testAppearanceWithMeetingsTab() {
        let sut = MainTabBarControllerPreview(showMeetings: true)
        snapshotHelper
            .verify(matching: sut, named: "light", testName: "tabBarWithMeetingsTabItem")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, named: "dark", testName: "tabBarWithMeetingsTabItem")
    }

}
