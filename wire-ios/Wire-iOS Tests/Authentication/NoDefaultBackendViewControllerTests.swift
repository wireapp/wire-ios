//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class NoDefaultBackendViewControllerTests: XCTestCase {

    // MARK: - Properties

    private var sut: NoDefaultBackendViewController!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        accentColor = .blue
    }

    override func tearDown() {
        sut = nil
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    @MainActor
    func testForAllScreenSizes() {
        sut = NoDefaultBackendViewController()
        snapshotHelper.verifyInAllDeviceSizes(matching: sut)
    }

    @MainActor
    func testThatItShowsAnErrorMessage() {
        sut = NoDefaultBackendViewController()
        sut.loadViewIfNeeded()
        sut.noDefaultBackendViewModel(
            NoDefaultBackendViewModel(),
            didFailWithMessage: "This configuration link is not valid."
        )
        snapshotHelper.verify(matching: sut)
    }
}
