//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireTesting

final class ColorSchemeTests: ZMTestCase {

    var sut: ColorScheme!

    override func setUp() {
        super.setUp()

        sut = ColorScheme()
    }

    override func tearDown() {
        sut = nil
    }

    func testForIsCurrentAccentColor() {
        // GIVEN
        sut.accentColor = .black
        let alphaBlack = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0)

        // THEN
        XCTAssertEqual(sut.accentColor, .black)
        XCTAssert(sut.isCurrentAccentColor(.black))

        XCTAssertNotEqual(sut.accentColor, alphaBlack)
        XCTAssertFalse(sut.isCurrentAccentColor(alphaBlack))
    }

    func testForIsStrongBlue_WhenAccentColorIsUndefinedInLightVariant() {
        // GIVEN / WHEN
        let expectedAccentColor = UIColor.white.mix(UIColor(fromZMAccentColor: .strongBlue), amount: 0.8)
        let accentColor = UIColor.nameColor(for: .undefined, variant: .light)

        // THEN
        XCTAssertEqual(accentColor, expectedAccentColor)
    }

    func testForIsStrongBlue_WhenAccentColorIsUndefinedInDarkVariant() {
        // GIVEN / WHEN
        let expectedAccentColor = UIColor.black.mix(UIColor(fromZMAccentColor: .strongBlue), amount: 0.8)
        let accentColor = UIColor.nameColor(for: .undefined, variant: .dark)

        // THEN
        XCTAssertEqual(accentColor, expectedAccentColor)
    }
}
