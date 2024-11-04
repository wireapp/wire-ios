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
        // GIVEN
        let filter: ConversationFilter? = nil

        // WHEN
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .collapsed,
            isEmptyPlaceholderVisible: false
        )

        // THEN
        XCTAssertEqual(searchController.searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.placeholder)
        XCTAssertTrue(searchController.hidesNavigationBarDuringPresentation)
        XCTAssertFalse(searchController.obscuresBackgroundDuringPresentation)
        XCTAssertFalse(searchController.searchBar.isTranslucent)
    }

    func test_makeSearchController_withFavoritesFilter() {
        // GIVEN
        let filter: ConversationFilter = .favorites

        // WHEN
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .collapsed,
            isEmptyPlaceholderVisible: false
        )

        // THEN
        XCTAssertEqual(searchController.searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.favoritesPlaceholder)
    }

    func test_makeSearchController_withGroupsFilter() {
        // GIVEN
        let filter: ConversationFilter = .groups

        // WHEN
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .collapsed,
            isEmptyPlaceholderVisible: false
        )

        // THEN
        XCTAssertEqual(searchController.searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.groupsPlaceholder)
    }

    func test_makeSearchController_withOneOnOneFilter() {
        // GIVEN
        let filter: ConversationFilter = .oneOnOne

        // WHEN
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .collapsed,
            isEmptyPlaceholderVisible: false
        )

        // THEN
        XCTAssertEqual(searchController.searchBar.placeholder, L10n.Localizable.ConversationList.SearchBar.oneOnOnePlaceholder)
    }

    func test_makeSearchController_expandedState() {
        // GIVEN
        let filter: ConversationFilter? = nil

        // WHEN
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .expanded,
            isEmptyPlaceholderVisible: false
        )

        // THEN
        XCTAssertFalse(searchController.hidesNavigationBarDuringPresentation)
    }

    func test_makeSearchController_withEmptyPlaceholder() {
        // GIVEN
        let filter: ConversationFilter? = nil

        // WHEN
        let searchController = ConversationListViewController.makeSearchController(
            filter: filter,
            mainSplitViewState: .collapsed,
            isEmptyPlaceholderVisible: true
        )

        // THEN
        XCTAssertFalse(searchController.obscuresBackgroundDuringPresentation)
        XCTAssertFalse(searchController.searchBar.isTranslucent)
    }

}
