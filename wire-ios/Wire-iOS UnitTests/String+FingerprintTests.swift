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

import XCTest
@testable import Wire

final class String_FingerprintTests: XCTestCase {

    func testGivenEmptyStringAndUsingFingerPrintSpacesWhenSplitStringIntoLinesThenValidIsReturned() {
        let testText = ""
        XCTAssertEqual(testText, testText.splitStringIntoLines(charactersPerLine: 10))
    }
    func testGivenValidStringAndUsingFingerPrintSpacesWhenSplitStringIntoLinesThenValidIsReturned() {
        let testText = "ABCDEFGHIJKLMNOPQRST"
        let validText = "AB CD\nEF GH\nIJ KL\nMN OP\nQR ST"
        XCTAssertEqual(validText, testText.splitStringIntoLines(charactersPerLine: 4))
    }
    func testGivenValidStringAndNotUsingFingerPrintSpacesWhenSplitStringIntoLinesThenValidIsReturned() {
        let testText = "ABCDEFGHIJKLMNOPQRST"
        let validText = "ABCD\nEFGH\nIJKL\nMNOP\nQRST"
        XCTAssertEqual(validText, testText.splitStringIntoLines(charactersPerLine: 4, withFingerprintStringWithSpaces: false))
    }
}
