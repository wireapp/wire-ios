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

final class SearchHeaderViewModelTests: XCTestCase {

    func testClearButtonIsHiddenForEmptyQueryAndNoTokens() {
        let sut = SearchHeaderViewModel()

        XCTAssertTrue(sut.displayState(query: "", tokenCount: 0).clearButtonIsHidden)
    }

    func testClearButtonIsVisibleForQuery() {
        let sut = SearchHeaderViewModel()

        XCTAssertFalse(sut.displayState(query: "alice", tokenCount: 0).clearButtonIsHidden)
    }

    func testClearButtonIsVisibleForTokens() {
        let sut = SearchHeaderViewModel()

        XCTAssertFalse(sut.displayState(query: "", tokenCount: 1).clearButtonIsHidden)
    }

    func testRoutes() {
        let sut = SearchHeaderViewModel()

        XCTAssertEqual(sut.routeForFilterTextChanged("bob"), .updateQuery("bob"))
        XCTAssertEqual(sut.routeForResetQuery(""), .updateQuery(""))
        XCTAssertEqual(sut.routeForConfirmSelection(), .confirmSelection)
    }
}
