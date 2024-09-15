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

import SnapshotTesting
import WireCommonComponents
import WireDesign
import WireTestingPackage
import WireFoundation
import XCTest

@testable import Wire

final class FontBookSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    override func tearDown() {
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: Helper Method

    func setupLabel(
        style: WireTextStyle,
        width: Int = 320,
        height: Int = 200
    ) -> UILabel {
        let sutLabel = DynamicFontLabel(
            text: "Welcome to Dub Dub",
            style: style,
            color: SemanticColors.Label.textDefault
        )
        sutLabel.numberOfLines = 0
        sutLabel.frame.size = .init(width: width, height: height)

        return sutLabel
    }

    // MARK: Snapshot Tests

    func testForTitle3FontStyle() {
        snapshotHelper.verifyForDynamicType(matching: setupLabel(style: .h1))
    }

    func testForHeadlineFontStyle() {
        snapshotHelper.verifyForDynamicType(matching: setupLabel(style: .h3))
    }

    func testBodyFontStyle() {
        snapshotHelper.verifyForDynamicType(matching: setupLabel(style: .body1))
    }

    func testForSubHeadLineFontStyle() {
        snapshotHelper.verifyForDynamicType(matching: setupLabel(style: .h4))
    }

    func testForCaption1FontStyle() {
        snapshotHelper.verifyForDynamicType(matching: setupLabel(style: .subline1))
    }

    func testForTitle3BoldFontStyle() {
        snapshotHelper.verifyForDynamicType(matching: setupLabel(style: .h2))
    }

    func testForCalloutBoldFontStyle() {
        snapshotHelper.verifyForDynamicType(matching: setupLabel(style: .body3))
    }

    func testForFootnoteSemiboldFontStyle() {
        snapshotHelper.verifyForDynamicType(matching: setupLabel(style: .h5))
    }

    func testForBodyTwoSemiboldFontStyle() {
        snapshotHelper.verifyForDynamicType(matching: setupLabel(style: .body2))
    }

    func testForButtonSmallSemiboldFontStyle() {
        snapshotHelper.verifyForDynamicType(matching: setupLabel(style: .buttonSmall))
    }

    func testForButtonBigSemiboldFontStyle() {
        snapshotHelper.verifyForDynamicType(matching: setupLabel(style: .buttonBig))
    }

}
