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

import SnapshotTesting
import WireTestingPackage
import XCTest

@testable import Wire

final class ContactsViewControllerSnapshotTests: XCTestCase {

    // MARK: - Properties

    var sut: ContactsViewController!
    var snapshotHelper: SnapshotHelper!
    let imageConfig = ViewImageConfig.iPhone14(.portrait)

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
            .withUserInterfaceStyle(imageConfig.traits.userInterfaceStyle)
            .withPreferredContentSizeCategory(imageConfig.traits.preferredContentSizeCategory)

        XCTestCase.accentColor = .blue
        sut = ContactsViewController()
        sut.searchHeaderViewController.overrideUserInterfaceStyle = .dark
        sut.overrideUserInterfaceStyle = .dark
        sut.view.backgroundColor = .black
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForNoContacts() {
        // Given
        sut.dataSource.ungroupedSearchResults = []

        // When
        simulateSearch(withResults: false)

        // Then
        wrapInNavigationController()
        // see issue with KeyboardLayoudGuide: https://github.com/pointfreeco/swift-snapshot-testing/issues/859
        snapshotHelper.verify(
            matching: sut,
            size: imageConfig.size,
            safeArea: imageConfig.safeArea
        )
    }

    func testForNoSearchResult() {
        // Given
        sut.dataSource.searchQuery = "!!!"

        // When
        simulateSearch(withResults: false)

        // Then
        wrapInNavigationController()
        // workaround for snapshot
        // see issue with KeyboardLayoudGuide: https://github.com/pointfreeco/swift-snapshot-testing/issues/859
        snapshotHelper.verify(
            matching: sut,
            size: imageConfig.size,
            safeArea: imageConfig.safeArea
        )
    }

    func testForContactsWithoutSections() {
        // Given
        sut.dataSource.ungroupedSearchResults = SwiftMockLoader.mockUsers()

        // When
        simulateSearch(withResults: true)

        // Then
        wrapInNavigationController()
        // workaround for snapshot
        // see issue with KeyboardLayoudGuide: https://github.com/pointfreeco/swift-snapshot-testing/issues/859
        snapshotHelper.verify(
            matching: sut,
            size: imageConfig.size,
            safeArea: imageConfig.safeArea
        )
    }

    func testForContactsAndIndexSectionBarAreShown() {
        // Given
        let mockUsers = SwiftMockLoader.mockUsers(fromResource: "people-15Sections.json")
        sut.dataSource.ungroupedSearchResults = mockUsers

        // When
        simulateSearch(withResults: true)

        // Then
        wrapInNavigationController()
        // workaround for snapshot
        // see issue with KeyboardLayoudGuide: https://github.com/pointfreeco/swift-snapshot-testing/issues/859
        snapshotHelper.verify(
            matching: sut,
            size: imageConfig.size,
            safeArea: imageConfig.safeArea
        )
    }

    // MARK: - Helper Methods

    private func simulateSearch(withResults: Bool) {
        sut.updateEmptyResults(hasResults: withResults)
    }

    private func wrapInNavigationController() {
        let navigationController = UIViewController().wrapInNavigationController()
        navigationController.pushViewController(sut, animated: false)
        sut.tableView.reloadData()
    }
}
