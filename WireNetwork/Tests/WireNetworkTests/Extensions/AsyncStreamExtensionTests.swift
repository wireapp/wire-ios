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

import XCTest

@testable import WireNetwork

final class AsyncStreamExtensionTests: XCTestCase {

    func testCollectFlushesOnMaxCount() async throws {
        let elements = Array(1 ... 100)
        let stream = AsyncThrowingStream<Int, Error> { continuation in
            for element in elements {
                continuation.yield(element)
            }
            continuation.finish()
        }

        let batches = stream.collect(maxCount: 25, timeout: 100.0)
        var collected: [[Int]] = []

        for try await batch in batches {
            collected.append(batch)
        }

        let expectedBatches = 4
        XCTAssertEqual(collected.count, expectedBatches)
        guard collected.count == expectedBatches else {
            XCTFail("wrong number of batches, got \(collected.count), expected \(expectedBatches)")
            return
        }
        XCTAssertTrue(collected.allSatisfy { $0.count == 25 })
        for i in 0 ..< 4 {
            XCTAssertEqual(collected[i], Array(elements[i * 25 ..< (i + 1) * 25]))
        }
    }

    func testCollectFlushes() async throws {
        let elements = Array(1 ... 100)
        let stream = AsyncThrowingStream<Int, Error> { continuation in
            for element in elements {
                continuation.yield(element)
            }
            continuation.finish()
        }

        let batches = stream.collect(maxCount: 18, timeout: 100.0)
        var collected: [[Int]] = []

        for try await batch in batches {
            collected.append(batch)
        }

        guard collected.count == 6 else {
            XCTFail("wrong number of batches, got \(collected.count), expected 6")
            return
        }
        XCTAssertTrue(collected.prefix(5).allSatisfy { $0.count == 18 })
        XCTAssertEqual(collected.last?.count, 10)
        for i in 0 ..< 4 {
            print(i)
            XCTAssertEqual(collected[i], Array(elements[i * 18 ..< (i + 1) * 18]))
        }
        XCTAssertEqual(collected[5], Array(elements[90 ..< 100]))
    }

    func testCollectFlushesMaxCountHigherThanElements() async throws {
        let elements = Array(1 ... 5)
        let stream = AsyncThrowingStream<Int, Error> { continuation in
            for element in elements {
                continuation.yield(element)
            }
            continuation.finish()
        }

        let batches = stream.collect(maxCount: 10, timeout: 100.0)
        var collected: [[Int]] = []

        for try await batch in batches {
            collected.append(batch)
        }

        XCTAssertEqual(collected.count, 1)
        XCTAssertTrue(collected.allSatisfy { $0.count == 5 })
        XCTAssertEqual(collected[0], Array(elements[0 ..< 5]))
    }

    func testCollectFlushesOnTimeout() async throws {
        let stream = AsyncThrowingStream<Int, Error> { continuation in
            Task {
                continuation.yield(1)
                try await Task.sleep(for: .seconds(1))
                continuation.yield(2)
                continuation.yield(3)
                continuation.finish()
            }
        }

        let batches = stream.collect(maxCount: 10, timeout: 0.5)
        var result: [[Int]] = []

        for try await batch in batches {
            result.append(batch)
        }
        let expectedBatches = 2
        XCTAssertEqual(result.count, expectedBatches)
        guard result.count == expectedBatches else {
            XCTFail("wrong number of batches, got \(result.count), expected \(expectedBatches)")
            return
        }
        XCTAssertEqual(result[0], [1])
        XCTAssertEqual(result[1], [2, 3])
    }

    func testCollectHandlesStreamEndGracefully() async throws {
        let stream = AsyncThrowingStream<Int, Error> { continuation in
            continuation.yield(42)
            continuation.finish()
        }

        let batches = stream.collect(maxCount: 5, timeout: 1.0)
        var result: [[Int]] = []

        for try await batch in batches {
            result.append(batch)
        }

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first, [42])
    }

    func testCollectMultipleSmallBatches() async throws {
        let stream = AsyncThrowingStream<Int, Error> { continuation in
            for i in 1 ... 10 {
                continuation.yield(i)
                usleep(200_000) // 0.2s
            }
            continuation.finish()
        }

        let batches = stream.collect(maxCount: 3, timeout: 0.5)
        var allBatches: [[Int]] = []

        for try await batch in batches {
            allBatches.append(batch)
        }

        XCTAssertGreaterThanOrEqual(allBatches.count, 3)
        XCTAssertLessThanOrEqual(allBatches.count, 5)
        XCTAssertEqual(allBatches.flatMap(\.self), Array(1 ... 10))
    }
}
