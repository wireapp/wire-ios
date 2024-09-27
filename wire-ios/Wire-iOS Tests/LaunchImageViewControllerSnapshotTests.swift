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
import WireTestingPackage
import XCTest
@testable import Wire

final class LaunchImageViewControllerSnapshotTests: XCTestCase {
    // MARK: Internal

    var sut: LaunchImageViewController!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        sut = LaunchImageViewController()
        sut.loadViewIfNeeded()
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    func testForInitState() {
        snapshotHelper.verify(matching: sut)
    }

    func testForShowingSpinner() {
        sut.showLoadingScreen()

        snapshotHelper.verify(matching: sut)
    }

    // MARK: Private

    private var snapshotHelper: SnapshotHelper!
}
