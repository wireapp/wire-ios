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

import WireFoundation
import XCTest
@testable import WireUtilities

final class ZMAccentColorTests: XCTestCase {
    func testTwoInstancesAreEqual() {
        let amber0: ZMAccentColor = .amber
        let amber1: ZMAccentColor? = .from(rawValue: AccentColor.amber.rawValue)
        XCTAssertEqual(amber0, amber1)
    }

    func testTwoInstancesAreNotEqual() {
        let blue: ZMAccentColor = .blue
        let amber: ZMAccentColor = .amber
        XCTAssertNotEqual(blue, amber)
    }
}
