//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

final class TextSearchViewModelTests: XCTestCase {

    func testUpdateQuerySchedulesSearchForValidQuery() {
        var viewModel = TextSearchViewModel()

        let effects = viewModel.updateQuery("hello")

        XCTAssertEqual(effects, [.cancelSearch, .scheduleSearch])
        XCTAssertEqual(viewModel.query, "hello")
        XCTAssertFalse(viewModel.viewState.isResultsViewHidden)
        XCTAssertTrue(viewModel.viewState.isTableViewHidden)
        XCTAssertFalse(viewModel.viewState.isNoResultsViewHidden)
    }

    func testUpdateQueryClearsDisplayForInvalidQuery() {
        var viewModel = TextSearchViewModel()
        _ = viewModel.updateQuery("hello")
        viewModel.showLoading()

        let effects = viewModel.updateQuery("h")

        XCTAssertEqual(effects, [.cancelSearch])
        XCTAssertEqual(viewModel.query, "h")
        XCTAssertTrue(viewModel.viewState.isTableViewHidden)
        XCTAssertTrue(viewModel.viewState.isNoResultsViewHidden)
        XCTAssertFalse(viewModel.viewState.isLoading)
    }

    func testEmptyQueryHidesSearchResultsView() {
        var viewModel = TextSearchViewModel()

        let effects = viewModel.updateQuery("")

        XCTAssertEqual(effects, [.cancelSearch])
        XCTAssertTrue(viewModel.viewState.isResultsViewHidden)
        XCTAssertTrue(viewModel.viewState.isTableViewHidden)
        XCTAssertTrue(viewModel.viewState.isNoResultsViewHidden)
    }

    func testTextContentComesFromLocalization() {
        let viewModel = TextSearchViewModel()

        XCTAssertEqual(
            viewModel.searchPlaceholder,
            L10n.Localizable.Collections.Search.Field.placeholder
        )
        XCTAssertEqual(viewModel.noResultsText, L10n.Localizable.Collections.Search.noItems)
        XCTAssertEqual(
            viewModel.noResultsAccessibilityLabel,
            L10n.Accessibility.ConversationSearch.EmptyResult.description
        )
    }
}
