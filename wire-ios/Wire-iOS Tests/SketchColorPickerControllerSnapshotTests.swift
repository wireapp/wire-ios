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
import WireDesign
import WireTestingPackage
import XCTest
@testable import Wire

final class SketchColorPickerControllerSnapshotTests: XCTestCase {
    // MARK: - Properties

    typealias SketchColors = SemanticColors.DrawingColors
    var sut: SketchColorPickerController!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        sut = SketchColorPickerController()

        sut.sketchColors = SketchColor.getAllColors()
        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 69)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testForInitState() {
        snapshotHelper.verify(matching: sut)
    }

    func testForAllItemsAreVisible() {
        sut.view.frame = CGRect(x: 0, y: 0, width: 768, height: 48)
        snapshotHelper.verify(matching: sut)
    }

    func testForColorButtonBumpedThreeTimes() {
        // GIVEN & WHEN
        for _ in 1 ... 3 {
            sut.collectionView(sut.colorsCollectionView, didSelectItemAt: IndexPath(item: 1, section: 0))
        }

        // THEN
        snapshotHelper.verify(matching: sut)
    }
}
