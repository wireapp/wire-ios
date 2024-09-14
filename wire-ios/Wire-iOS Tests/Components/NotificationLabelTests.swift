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

final class NotificationLabelTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper_!
    private var sut: NotificationLabel!
    private let message = "Double Tap on a tile for fullscreen"

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_()
        sut = NotificationLabel(shouldAnimate: false)
        sut.frame = CGRect(x: 0, y: 0, width: 220, height: 24)
        sut.backgroundColor = .black
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Test

    func testMessageAppearence() {
        // GIVEN && WHEN
        sut.show(message: message)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: - Unit Tests

    // show(message:hideAfter:)

    func testThat_ItDoesNotCreateTimer_When_NoTimeIntervalIsGiven() {
        // GIVEN && WHEN
        sut.show(message: message)

        // THEN
        XCTAssertNil(sut.timer)
    }

    func testThat_ItCreatesTimer_When_TimeIntervalIsGiven() {
        // GIVEN && WHEN
        sut.show(message: message, hideAfter: 5)

        // THEN
        XCTAssertNotNil(sut.timer)
        XCTAssert(sut.timer?.isValid == true)
    }

    // hideAndStopTimer()

    func testThat_ItHidesMessageAndStopsTimer() {
        // GIVEN
        sut.show(message: message, hideAfter: 5)

        // WHEN
        sut.hideAndStopTimer()

        // THEN
        XCTAssertTrue(sut.isHidden)
        XCTAssertEqual(sut.alpha, 0)
        XCTAssert(sut.timer?.isValid == false)
    }

    // setMessage(hidden:)

    func testThat_ItHidesMessage() {
        // GIVEN
        sut.show(message: message)

        // WHEN
        sut.setMessageHidden(true)

        // THEN
        XCTAssertEqual(sut.alpha, 0)
        XCTAssertTrue(sut.isHidden)
    }

    func testThat_ItShowsMessage() {
        // GIVEN
        sut.alpha = 0
        sut.isHidden = true

        // WHEN
        sut.setMessageHidden(false)

        // THEN
        XCTAssertEqual(sut.alpha, 1)
        XCTAssertFalse(sut.isHidden)
    }

    func testThat_ItDoesNotShow_IfTimerIsNotValid() {
        // GIVEN
        sut.show(message: message, hideAfter: 5)

        sut.timer?.fire()
        sut.timer?.invalidate()

        // WHEN
        sut.setMessageHidden(false)

        // THEN
        XCTAssertEqual(sut.alpha, 0)
        XCTAssertTrue(sut.isHidden)
    }
}
