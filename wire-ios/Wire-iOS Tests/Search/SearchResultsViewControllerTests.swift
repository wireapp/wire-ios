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

@testable import Wire
import XCTest

final class SearchResultsViewControllerTests: XCTestCase {
    weak var sut: SearchResultsViewController!

    func testThatSearchResultsViewControllerIsNotRetained() {
        autoreleasepool {
            // GIVEN
            let selfUser = MockUserType.createSelfUser(name: "Bobby McFerrin")
            let mockUserSession = UserSessionMock(mockUser: selfUser)
            var searchResultsViewController: SearchResultsViewController! = .init(
                userSelection: UserSelection(),
                userSession: mockUserSession,
                isAddingParticipants: false,
                shouldIncludeGuests: true,
                isFederationEnabled: false
            )
            sut = searchResultsViewController

            // WHEN
            searchResultsViewController.viewDidLoad()

            searchResultsViewController = nil
        }

        // THEN
        XCTAssertNil(sut)
    }
}
