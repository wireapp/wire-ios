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

import XCTest
@testable import WireSystem

final class DispatchGroupTests: XCTestCase {
    // MARK: Internal

    func testThatItNotifiesWhenEnteringAndLeavingAGroupOnce() {
        // Given
        var notified = false
        let sut = ZMSDispatchGroup(label: "test group")
        let queue = DispatchQueue(label: "test queue")
        sut.enter()

        // When
        sut.notify(on: queue) {
            notified = true
        }

        // Then
        queue.sync {
            // this is here to make sure there are no previous op running on the queue
            XCTAssertFalse(notified)
        }

        // and when
        sut.leave()

        // Then
        queue.sync {
            XCTAssertTrue(notified)
        }
    }

    func testThatItNotifiesWhenEnteringAndLeavingAGroupThatWasInjected() {
        // Given
        var notified = false
        let rawGroup = DispatchGroup()
        let sut = ZMSDispatchGroup(dispatchGroup: rawGroup, label: "Test")
        let queue = DispatchQueue(label: "test queue")
        rawGroup.enter()

        // When
        sut.notify(on: queue) {
            notified = true
        }

        // Then
        queue.sync {
            XCTAssertFalse(notified)
        }

        // and when
        sut.leave()

        // Then
        queue.sync {
            XCTAssertTrue(notified)
        }
    }

    func testThatItNotifiesImmediatelyIfTheGroupWasNotEntered() {
        // Given
        var notified = false
        let sut = ZMSDispatchGroup(label: "test group")
        let queue = DispatchQueue(label: "test queue")

        // When
        sut.notify(on: queue) {
            notified = true
        }

        // Then
        queue.sync {
            XCTAssertTrue(notified)
        }
    }

    func testThatItNotifiesWhenEnteringAndLeavingAGroupMultipleTimes() {
        // Given
        var notified = false
        let sut = ZMSDispatchGroup(label: "test group")
        let queue = DispatchQueue(label: "test queue")
        sut.enter() // enterinc once
        sut.enter() // entering twice

        // When
        sut.notify(on: queue) {
            notified = true
        }
        sut.leave() // leaving once

        // Then
        queue.sync {
            // this is here to make sure there are no previous op running on the queue
            XCTAssertFalse(notified)
        }

        // and when
        sut.leave() // leaving twice

        // Then
        queue.sync {
            XCTAssertTrue(notified)
        }
    }

    func testThatItNotifiesOnTheRightQueueAfterEnteringAndLeaving() {
        // Given
        var notified = false
        let sut = ZMSDispatchGroup(label: "test group")
        sut.enter()

        let queue = DispatchQueue(label: "test queue")
        let semaphore = DispatchSemaphore(value: 0)
        queue.async {
            // this will block this queue until we signal
            // preventing the notify to be executed
            // only if it's enqueued on this queue
            semaphore.wait()
        }

        // When
        sut.notify(on: queue) {
            notified = true
        }
        sut.leave()

        sleep(for: 0.1)

        // Then
        XCTAssertFalse(notified)

        // and when
        semaphore.signal()

        queue.sync {
            XCTAssertTrue(notified)
        }
    }

    func testThatItNotifiesWhenPerformingAsync() {
        // Given
        var notified = false
        // not been fulfilled yet without making the test fail
        let sut = ZMSDispatchGroup(label: "test group")

        let queue = DispatchQueue(label: "test queue")
        let semaphore = DispatchSemaphore(value: 0)
        sut.async(on: queue) {
            semaphore.wait()
        }

        // When
        sut.notify(on: queue) {
            notified = true
        }
        sleep(for: 0.1)

        // Then
        XCTAssertFalse(notified)

        // and when
        semaphore.signal()
        sleep(for: 0.1)

        queue.sync {
            XCTAssertTrue(notified)
        }
    }

    func testThatItWaitsAfterEnteringWithATimeoutThatExpires() {
        // Given
        let sut = ZMSDispatchGroup(label: "test group")
        sut.enter()

        // When
        let result = sut.wait(deltaFromNow: 200)

        // Then
        XCTAssertNotEqual(result, 0)
        sut.leave()
    }

    func testThatItWaitsAfterEnteringWithATimeoutThatDoesNotExpire() {
        // Given
        let sut = ZMSDispatchGroup(label: "test group")
        sut.enter()

        let queue = DispatchQueue(label: "test queue", attributes: .concurrent)
        queue.asyncAfter(deadline: .now() + .milliseconds(500)) {
            sut.leave()
        }

        // When
        let result = sut.waitWithTimeoutForever()

        // then
        XCTAssertEqual(result, 0)
    }

    // MARK: Private

    // MARK: - Helper

    private func sleep(for time: TimeInterval) {
        let sleepExpectation = XCTestExpectation()
        sleepExpectation.isInverted = true
        wait(for: [sleepExpectation], timeout: time)
    }
}
