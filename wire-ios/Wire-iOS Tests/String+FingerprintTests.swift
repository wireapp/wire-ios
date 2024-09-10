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

final class String_FingerprintTests: XCTestCase {
    let fingerprintString = "05 1c f4 ca 74 4b 80"

    func testFingerprintAttributes() {
        // GIVEN
        let regularAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]
        let boldAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]

        // WHEN
        let attributedString = fingerprintString.fingerprintString(attributes: regularAttributes, boldAttributes: boldAttributes)

        // THEN
        for item in stride(from: 0, to: 20, by: 6) {
            let boldRange = NSRange(location: item, length: 2)

            let substring = attributedString.attributedSubstring(from: boldRange)
            let attrs = substring.attributes(at: 0, effectiveRange: nil)

            XCTAssertEqual(attrs as? [NSAttributedString.Key: UIFont], boldAttributes)
        }

        for item in stride(from: 3, to: 20, by: 6) {
            let regularRange = NSRange(location: item, length: 2)

            let substring = attributedString.attributedSubstring(from: regularRange)
            let attrs = substring.attributes(at: 0, effectiveRange: nil)

            XCTAssertEqual(attrs as? [NSAttributedString.Key: UIFont], regularAttributes)
        }
    }
}
