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

final class RoundedPageIndicatorTests: XCTestCase {
    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: RoundedPageIndicator!
    private let frame = CGRect(x: 0, y: 0, width: 120, height: 24)

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        accentColor = .blue
        sut = RoundedPageIndicator()
        sut.frame = frame
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Unit Test

    func testThatPageIndicator_IsHidden_When_ThereIsOneOrLessPages() {
        // When
        sut.numberOfPages = 1

        // Then
        XCTAssertTrue(sut.isHidden)
    }

    // MARK: - Snapshot Test

    func testWithFivePages() {
        // When
        sut.numberOfPages = 5
        sut.currentPage = 0

        let view = UIView(frame: frame)
        view.backgroundColor = .black
        view.addSubview(sut)

        // Then
        snapshotHelper.verify(matching: view)
    }
}
