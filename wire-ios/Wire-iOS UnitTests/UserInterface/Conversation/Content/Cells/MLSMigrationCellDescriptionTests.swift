//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import Foundation

import XCTest
import WireCommonComponents
@testable import Wire

final class MLSMigrationCellDescriptionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        FontScheme.configure(with: .large)
    }

    func testProperties() throws {
        // given
        let cellDescription = MLSMigrationCellDescription(messageType: .mlsMigrationStarted)

        // when
        // then
        XCTAssertEqual(cellDescription.topMargin, .zero)
        XCTAssertTrue(cellDescription.isFullWidth)
        XCTAssertFalse(cellDescription.supportsActions)
        XCTAssertFalse(cellDescription.showEphemeralTimer)
        XCTAssertFalse(cellDescription.containsHighlightableContent)
        XCTAssertNil(cellDescription.message)
        XCTAssertNil(cellDescription.delegate)
        XCTAssertNil(cellDescription.actionController)
        XCTAssertNotNil(cellDescription.configuration)
        XCTAssertNil(cellDescription.accessibilityIdentifier)
        XCTAssertEqual(cellDescription.accessibilityLabel?.isEmpty, false)
    }
}
