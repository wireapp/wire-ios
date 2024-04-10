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

import SnapshotTesting
import WireCommonComponents
import XCTest
@testable import Wire

final class FontBookSnapshotTests: XCTestCase {

    // MARK: Helper Method

    func setupLabel(
        style: UIFont.FontStyle,
        width: Int = 320,
        height: Int = 200
    ) -> UILabel {
        let sutLabel = DynamicFontLabel(text: "Welcome to Dub Dub",
                                        style: style,
                                        color: SemanticColors.Label.textDefault)
        sutLabel.numberOfLines = 0
        sutLabel.frame.size = .init(width: width, height: height)

        return sutLabel
    }

    // MARK: Snapshot Tests

    func testForTitle3FontStyle() {
        verifyForDynamicType(matching: setupLabel(style: .title3))
    }

    func testForHeadlineFontStyle() {
        verifyForDynamicType(matching: setupLabel(style: .headline))
    }

    func testBodyFontStyle() {
        verifyForDynamicType(matching: setupLabel(style: .body))
    }

    func testForSubHeadLineFontStyle() {
        verifyForDynamicType(matching: setupLabel(style: .subheadline))
    }

    func testForCaption1FontStyle() {
        verifyForDynamicType(matching: setupLabel(style: .caption1))
    }

    func testForTitle3BoldFontStyle() {
        verifyForDynamicType(matching: setupLabel(style: .title3Bold))
    }

    func testForCalloutBoldFontStyle() {
        verifyForDynamicType(matching: setupLabel(style: .calloutBold))
    }

    func testForFootnoteSemiboldFontStyle() {
        verifyForDynamicType(matching: setupLabel(style: .footnoteSemibold))
    }

    func testForBodyTwoSemiboldFontStyle() {
        verifyForDynamicType(matching: setupLabel(style: .bodyTwoSemibold))
    }

    func testForButtonSmallSemiboldFontStyle() {
        verifyForDynamicType(matching: setupLabel(style: .buttonSmallSemibold))
    }

    func testForButtonBigSemiboldFontStyle() {
        verifyForDynamicType(matching: setupLabel(style: .buttonBigSemibold))
    }

}
