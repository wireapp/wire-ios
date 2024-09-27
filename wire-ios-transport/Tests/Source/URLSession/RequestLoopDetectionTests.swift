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
@testable import WireTransport

final class RequestLoopDetectionTests: XCTestCase {
    func testThatItDetectsALoopWithOneRepeatedRequest() {
        // given
        var triggered = false
        let path = "foo.com"
        let hash = "13"

        let sut = RequestLoopDetection {
            XCTAssertEqual(path, $0)
            triggered = true
        }

        // when
        for _ in 0 ..< RequestLoopDetection.repetitionTriggerThreshold {
            sut.recordRequest(path: path, contentHint: hash, date: nil)
        }

        // then
        XCTAssertTrue(triggered)
    }

    func testThatItDoesNotDetectsALoopWithOneRepeatedRequestIfMoreThan5MinutesApart() {
        // given
        let path = "foo.com"
        let hash = "13"
        var startDate = Date(timeIntervalSince1970: 100)

        let sut = RequestLoopDetection { _ in
            XCTFail()
        }

        // when
        for _ in 0 ..< RequestLoopDetection.repetitionTriggerThreshold {
            sut.recordRequest(path: path, contentHint: hash, date: startDate)
            startDate.addTimeInterval(10 * 60)
        }
    }

    func testThatItDoesNotDetectsALoopWithOneRepeatedRequesInsertedAtWrongTime() {
        // given
        let path = "foo.com"
        let hash = "12"
        var startDate = Date()

        let sut = RequestLoopDetection { _ in
            XCTFail()
        }

        // when
        for _ in 0 ..< RequestLoopDetection.repetitionTriggerThreshold {
            sut.recordRequest(path: path, contentHint: hash, date: startDate)
            startDate.addTimeInterval(-4 * 60)
        }
    }

    func testThatItDoesNotDetectsALoopIfPathIsNotSame() {
        // given
        let hash = "14"
        let sut = RequestLoopDetection { _ in
            XCTFail()
        }

        // when
        for item in 0 ..< RequestLoopDetection.repetitionTriggerThreshold {
            sut.recordRequest(path: "foo.com/\(item)", contentHint: hash, date: nil)
        }
    }

    func testThatItDoesNotDetectsALoopIfHashIsNotSame() {
        // given
        let sut = RequestLoopDetection { _ in
            XCTFail()
        }

        // when
        for item in 0 ..< RequestLoopDetection.repetitionTriggerThreshold {
            sut.recordRequest(path: "foo.com", contentHint: "\(item)", date: nil)
        }
    }

    func testThatItDetectsALoopWithOneRepeatedRequestOnlyOnceEveryThreshold() {
        // given
        let path = "foo.com"
        var triggerCount = 0
        let hash = "14"

        let sut = RequestLoopDetection {
            triggerCount += 1
            XCTAssertEqual(path, $0)
        }

        // when
        for _ in 0 ..< RequestLoopDetection.repetitionTriggerThreshold * 3 {
            sut.recordRequest(path: path, contentHint: hash, date: nil)
        }

        // then
        XCTAssertEqual(triggerCount, 3)
    }

    func testThatItDetectsMultipleLoopsFromDifferentURLs() {
        // given
        let paths = ["foo.com", "bar.de", "baz.org"]
        var triggeredURLs: [String] = []
        let hash = "14"

        let sut = RequestLoopDetection {
            triggeredURLs.append($0)
        }

        // when
        for item in 0 ..< RequestLoopDetection.repetitionTriggerThreshold * 4 {
            let path = paths[item % paths.count] // this will insert them in interleaved order
            sut.recordRequest(path: path, contentHint: hash, date: nil)
        }

        // then
        XCTAssertEqual(triggeredURLs, paths)
    }

    func testThatItDetectsMultipleLoopsFromDifferentHashes() {
        // given
        let path = "foo.com"
        var triggered = 0

        let sut = RequestLoopDetection {
            XCTAssertEqual($0, path)
            triggered += 1
        }

        // when
        for item in 0 ..< RequestLoopDetection.repetitionTriggerThreshold * 4 {
            sut.recordRequest(path: path, contentHint: "\(item % 3)", date: nil)
        }

        // then
        XCTAssertEqual(triggered, 3)
    }

    func testThatItDoesNotStoreMoreThan2000URLs() {
        // given
        let path = "MyURL.com"
        var triggered = false
        let hash = "14"

        let sut = RequestLoopDetection { _ in
            triggered = true
        }

        // when
        sut.recordRequest(path: path, contentHint: hash, date: nil)
        for item in 0 ..< 2500 {
            sut.recordRequest(path: "url.com", contentHint: "\(item)", date: nil)
        }
        sut.recordRequest(path: path, contentHint: hash, date: nil)

        // then
        XCTAssertFalse(triggered)
    }

    // MARK: Excluded URLs

    func testRecordRequest_givenExcludedPathTyping() {
        // given
        let mockPath = "/v1/typing"
        let sut = RequestLoopDetection { _ in }

        // when
        sut.recordRequest(
            path: mockPath,
            contentHint: String(),
            date: nil
        )

        // then
        XCTAssert(sut.recordedRequests.isEmpty)
    }

    func testRecordRequest_givenExcludedPathTypingWithMoreParameters() {
        // given
        let mockPath = "/v1/typing?test=1"
        let sut = RequestLoopDetection { _ in }

        // when
        sut.recordRequest(
            path: mockPath,
            contentHint: String(),
            date: nil
        )

        // then
        XCTAssert(sut.recordedRequests.isEmpty)
    }

    func testRecordRequest_givenExcludedPathEmptySearch() {
        // given
        let mockPath = "/v1/search/contacts?q="
        let sut = RequestLoopDetection { _ in }

        // when
        sut.recordRequest(
            path: mockPath,
            contentHint: String(),
            date: nil
        )

        // then
        XCTAssert(sut.recordedRequests.isEmpty)
    }

    func testRecordRequest_givenExcludedPathEmptySearchAndMoreParameters() {
        // given
        let mockPath = "/v1/search/contacts?q=&size=10"
        let sut = RequestLoopDetection { _ in }

        // when
        sut.recordRequest(
            path: mockPath,
            contentHint: String(),
            date: nil
        )

        // then
        XCTAssert(sut.recordedRequests.isEmpty)
    }

    func testRecordRequest_givenExcludedPathNonEmptySearch() {
        // given
        let mockPath = "/v1/search/contacts?q=abc"
        let sut = RequestLoopDetection { _ in }

        // when
        sut.recordRequest(
            path: mockPath,
            contentHint: String(),
            date: nil
        )

        // then
        XCTAssertEqual(sut.recordedRequests.first?.path, mockPath)
    }
}
