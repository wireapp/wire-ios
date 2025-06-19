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

@testable import WireDomain

final class AsyncStreamExtensionTests: XCTestCase {

    func testCollectFlushesOnMaxCount() async throws {
        let elements = Array(1...100)
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

        XCTAssertEqual(collected.count, 4)
        XCTAssertTrue(collected.allSatisfy { $0.count == 25 })
        for i in 0..<4 {
            XCTAssertEqual(collected[i], Array(elements[i * 25..<(i + 1) * 25]))
        }
    }

    func testCollectFlushesOnTimeout() async throws {
        let stream = AsyncThrowingStream<Int, Error> { continuation in
            continuation.yield(1)
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                continuation.yield(2)
                continuation.finish()
            }
        }

        let batches = stream.collect(maxCount: 10, timeout: 0.5)
        var result: [[Int]] = []

        for try await batch in batches {
            result.append(batch)
        }

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0], [1])
        XCTAssertEqual(result[1], [2])
    }
//
////    func testCollectHandlesStreamEndGracefully() async throws {
////        let stream = AsyncThrowingStream<Int, Error> { continuation in
////            continuation.yield(42)
////            continuation.finish()
////        }
////
////        let batches = stream.collect(maxCount: 5, timeout: 1.0)
////        let allBatches = try await Array(batches)
////
////        XCTAssertEqual(allBatches.count, 1)
////        XCTAssertEqual(allBatches.first, [42])
////    }
//
//    func testCollectMultipleSmallBatches() async throws {
//        let stream = AsyncThrowingStream<Int, Error> { continuation in
//            for i in 1...10 {
//                continuation.yield(i)
//                usleep(200_000) // 0.2s
//            }
//            continuation.finish()
//        }
//
//        let batches = stream.collect(maxCount: 3, timeout: 0.5)
//        var allBatches: [[Int]] = []
//
//        for try await batch in batches {
//            allBatches.append(batch)
//        }
//
//        XCTAssertGreaterThanOrEqual(allBatches.count, 3)
//        XCTAssertLessThanOrEqual(allBatches.count, 5)
//        XCTAssertEqual(allBatches.flatMap { $0 }, Array(1...10))
//    }
}
