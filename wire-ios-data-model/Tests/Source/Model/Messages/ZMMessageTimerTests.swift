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

@testable import WireDataModel
import WireTransport
import XCTest

class ZMMessageTimerTests: BaseZMMessageTests {

    var sut: ZMMessageTimer!

    override func setUp() {
        super.setUp()
        sut = ZMMessageTimer(managedObjectContext: uiMOC)!
    }

    override func tearDown() {
        sut.tearDown()
        sut = nil
        super.tearDown()
    }

    func testThatItDoesNotCreateBackgroundActivityWhenTimerStarted() throws {
        // given
        XCTAssertFalse(BackgroundActivityFactory.shared.isActive)
        let message = try XCTUnwrap(createClientTextMessage(withText: "hello"))

        // when
        sut.startTimerIfNeeded(for: message, fireDate: Date(timeIntervalSinceNow: 1.0), userInfo: [:])

        // then
        let timer = sut.timer(for: message)
        XCTAssertNotNil(timer)

        XCTAssertFalse(BackgroundActivityFactory.shared.isActive)
    }

    func testThatItRemovesTheInternalTimerAfterTimerFired() throws {
        // given
        let message = try XCTUnwrap(createClientTextMessage(withText: "hello"))
        let expectation = self.customExpectation(description: "timer fired")
        sut.timerCompletionBlock = { _, _ in expectation.fulfill() }

        // when
        sut.startTimerIfNeeded(for: message, fireDate: Date(), userInfo: [:])
        _ = waitForCustomExpectations(withTimeout: 0.5)

        // then
        XCTAssertNil(sut.timer(for: message))
    }

    func testThatItRemovesTheInternalTimerWhenTimerStopped() throws {
        // given
        let message = try XCTUnwrap(createClientTextMessage(withText: "hello"))
        sut.startTimerIfNeeded(for: message, fireDate: Date(), userInfo: [:])

        // when
        sut.stop(for: message)

        // then
        XCTAssertNil(sut.timer(for: message))
    }
}
