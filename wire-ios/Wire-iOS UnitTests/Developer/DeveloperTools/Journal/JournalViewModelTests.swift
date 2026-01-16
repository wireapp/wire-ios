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

final class JournalViewModelTests: XCTestCase {

    let sectionsCount = 2

    func testJournalSectionsCount() throws {
        // given
        let sut = JournalViewModel(userId: UUID())

        // when
        // then
        guard sut.sections.count == sectionsCount else {
            XCTFail("wrong number of sections")
            return
        }
        let boolSection = try XCTUnwrap(sut.sections[0])
        XCTAssertEqual(boolSection.items.count, 9)

        XCTAssertNotNil(sut.sections.last, "broken MLS Groups section is missing")
    }
}
