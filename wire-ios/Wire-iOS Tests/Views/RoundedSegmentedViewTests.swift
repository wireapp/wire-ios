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

import WireTestingPackage
import XCTest
@testable import Wire

final class RoundedSegmentedViewTests: XCTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testTwoItems_Unselected() {
        // GIVEN && WHEN
        sut = createView(with: ["one", "two"])

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testTwoItems_FirstSelected() {
        // GIVEN && WHEN
        sut = createView(with: ["one", "two"])
        sut.setSelected(true, forItemAt: 0)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testTwoItems_SecondSelected_AfterFirst() {
        // GIVEN && WHEN
        sut = createView(with: ["one", "two"])
        sut.setSelected(true, forItemAt: 0)
        sut.setSelected(true, forItemAt: 1)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: Private

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: RoundedSegmentedView!

    // MARK: - Helper Method

    private func createView(with items: [String]) -> RoundedSegmentedView {
        let view = RoundedSegmentedView()
        for item in items {
            view.addButton(withTitle: item, actionHandler: {})
        }
        view.frame = CGRect(x: 0, y: 0, width: 95, height: 25)
        return view
    }
}
