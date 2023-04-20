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
import SnapshotTesting

final class SketchColorPickerControllerSnapshotTests: XCTestCase {

    var sut: SketchColorPickerController!

    override func setUp() {
        super.setUp()
        sut = SketchColorPickerController()

        sut.sketchColors = [SemanticColors.SketchColors.blackColor,
                            SemanticColors.SketchColors.whiteColor,
                            SemanticColors.SketchColors.blueColor,
                            SemanticColors.SketchColors.greenColor,
                            SemanticColors.SketchColors.yellowColor,
                            SemanticColors.SketchColors.redColor,
                            SemanticColors.SketchColors.orangeColor,
                            SemanticColors.SketchColors.purpleColor,
                            SemanticColors.SketchColors.brownColor,
                            SemanticColors.SketchColors.turquoiseColor,
                            SemanticColors.SketchColors.skyColor,
                            SemanticColors.SketchColors.limeColor,
                            SemanticColors.SketchColors.cyanColor,
                            SemanticColors.SketchColors.lilacColor,
                            SemanticColors.SketchColors.coralColor,
                            SemanticColors.SketchColors.pinkColor,
                            SemanticColors.SketchColors.chocolateColor,
                            SemanticColors.SketchColors.grayColor]

        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 48)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForInitState() {
        verify(matching: sut)
    }

    func testForAllItemsAreVisible() {
        sut.view.frame = CGRect(x: 0, y: 0, width: 768, height: 48)
        verify(matching: sut)
    }

    func testForColorButtonBumpedThreeTimes() {
        // GIVEN & WHEN
        for _ in 1...3 {
            sut.collectionView(sut.colorsCollectionView, didSelectItemAt: IndexPath(item: 1, section: 0))
        }

        // THEN
        verify(matching: sut)
    }
}
