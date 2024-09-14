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

final class MediaBarSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var sut: MediaBar!
    private var snapshotHelper: SnapshotHelper_!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = .init()
        setupMediaBar()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Method

    func setupMediaBar() {
        sut = MediaBar()
        sut.overrideUserInterfaceStyle = .dark
        sut.titleLabel.text = "demo media"

        sut.backgroundColor = .black
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: sut.intrinsicContentSize.height)
        sut.setNeedsUpdateConstraints()
        sut.layoutIfNeeded()
    }

    // MARK: - Snapshot Tests

    func testForInitState() {
        snapshotHelper.verify(matching: sut)
    }
}
