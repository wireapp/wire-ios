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

@testable import Wire

final class ConversationListViewControllerSearchTests: XCTestCase {

    func test_makeSearchController_withNoFilter() {
        // Given
        let filter: ConversationFilter? = nil

        // When
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .collapsed,
            isEmptyPlaceholderVisible: false
        )

        // Then
        XCTAssertEqual(searchController.searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.placeholder)
        XCTAssertTrue(searchController.hidesNavigationBarDuringPresentation)
        XCTAssertFalse(searchController.obscuresBackgroundDuringPresentation)
        XCTAssertFalse(searchController.searchBar.isTranslucent)
    }

    func test_makeSearchController_withFavoritesFilter() {
        // Given
        let filter: ConversationFilter = .favorites

        // When
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .collapsed,
            isEmptyPlaceholderVisible: false
        )

        // Then
        XCTAssertEqual(searchController.searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.favoritesPlaceholder)
    }

    func test_makeSearchController_withGroupsFilter() {
        // Given
        let filter: ConversationFilter = .groups

        // When
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .collapsed,
            isEmptyPlaceholderVisible: false
        )

        // Then
        XCTAssertEqual(searchController.searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.groupsPlaceholder)
    }

    func test_makeSearchController_withOneOnOneFilter() {
        // Given
        let filter: ConversationFilter = .oneOnOne

        // When
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .collapsed,
            isEmptyPlaceholderVisible: false
        )

        // Then
        XCTAssertEqual(searchController.searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.oneOnOnePlaceholder)
    }

    func test_makeSearchController_expandedState() {
        // Given
        let filter: ConversationFilter? = nil

        // When
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .expanded,
            isEmptyPlaceholderVisible: false
        )

        // Then
        XCTAssertFalse(searchController.hidesNavigationBarDuringPresentation)
    }

    func test_makeSearchController_withEmptyPlaceholder() {
        // Given
        let filter: ConversationFilter? = nil

        // When
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .collapsed,
            isEmptyPlaceholderVisible: true
        )

        // Then
        XCTAssertFalse(searchController.obscuresBackgroundDuringPresentation)
        XCTAssertFalse(searchController.searchBar.isTranslucent)
    }

}
