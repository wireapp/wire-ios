//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Foundation
import Testing

@testable import WireFoundation

struct AsyncMulticasterTests {

    @Test
    func broadcastsToAllObservers() async {
        var sut: AsyncMulticaster<Int>? = AsyncMulticaster()
        let stream1 = sut!.makeStream()
        let stream2 = sut!.makeStream()

        sut?.broadcast(1)
        sut?.broadcast(2)
        sut = nil // finishes the streams, buffered elements are still delivered

        var received1 = [Int]()
        for await element in stream1 {
            received1.append(element)
        }
        var received2 = [Int]()
        for await element in stream2 {
            received2.append(element)
        }

        #expect(received1 == [1, 2])
        #expect(received2 == [1, 2])
    }

    @Test
    func deallocationUnblocksSuspendedObserver() async throws {
        var sut: AsyncMulticaster<Int>? = AsyncMulticaster()
        let stream = sut!.makeStream()

        let consumer = Task {
            var received = [Int]()
            for await element in stream {
                received.append(element)
            }
            return received
        }

        // Give the consumer time to suspend in `for await`.
        try await Task.sleep(for: .seconds(0.1))
        sut?.broadcast(7)
        sut = nil

        // Hangs here if deinit doesn't finish the continuations.
        let received = await consumer.value
        #expect(received == [7])
    }

    @Test
    func bufferingNewestCoalescesBurstsForSlowConsumer() async {
        var sut: AsyncMulticaster<Int>? = AsyncMulticaster()
        let stream = sut!.makeStream(bufferingPolicy: .bufferingNewest(1))

        for element in 1 ... 5 {
            sut?.broadcast(element)
        }
        sut = nil

        var received = [Int]()
        for await element in stream {
            received.append(element)
        }

        #expect(received == [5])
    }

    @Test
    func voidBroadcast() async {
        var sut: AsyncMulticaster<Void>? = AsyncMulticaster()
        let stream = sut!.makeStream()

        sut?.broadcast()
        sut = nil

        var count = 0
        for await _ in stream {
            count += 1
        }

        #expect(count == 1)
    }

}
