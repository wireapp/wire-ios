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

final class AccentColorTests: XCTestCase {
    /// Ensures that the raw values haven't changed when migrating `ZMAccentColor` into Swift.
    func testRawValues() {
        XCTAssertEqual(AccentColor.blue.rawValue, 1)
        XCTAssertEqual(AccentColor.green.rawValue, 2)
        XCTAssertEqual(AccentColor.red.rawValue, 4)
        XCTAssertEqual(AccentColor.amber.rawValue, 5)
        XCTAssertEqual(AccentColor.turquoise.rawValue, 6)
        XCTAssertEqual(AccentColor.purple.rawValue, 7)

        XCTAssertEqual(ZMAccentColor.min, .from(accentColor: .blue))
        XCTAssertEqual(ZMAccentColor.max, .from(accentColor: .purple))
    }
}
