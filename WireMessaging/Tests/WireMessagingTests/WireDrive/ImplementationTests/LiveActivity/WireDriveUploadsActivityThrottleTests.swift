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

@testable import WireMessagingAssembly

struct WireDriveUploadsActivityThrottleTests {

    private let start = Date(timeIntervalSince1970: 1000)

    @Test
    func sendsTheFirstState() {
        var sut = WireDriveUploadsActivityThrottle()
        let sent1 = sut.shouldSend(makeState(), at: start)
        #expect(sent1)
    }

    @Test
    func dropsAStateIdenticalToTheLastOne() {
        var sut = WireDriveUploadsActivityThrottle()
        _ = sut.shouldSend(makeState(progress: 0.1), at: start)

        let sent2 = sut.shouldSend(makeState(progress: 0.1), at: start.addingTimeInterval(5))
        #expect(!sent2)
    }

    @Test
    func limitsProgressOnlyChangesToOnePerInterval() {
        var sut = WireDriveUploadsActivityThrottle(minimumProgressInterval: 1)
        _ = sut.shouldSend(makeState(progress: 0.10), at: start)

        let sent3 = sut.shouldSend(makeState(progress: 0.11), at: start.addingTimeInterval(0.2))
        #expect(!sent3)
        let sent4 = sut.shouldSend(makeState(progress: 0.12), at: start.addingTimeInterval(1.1))
        #expect(sent4)
    }

    @Test
    func sendsACountChangeAtOnce() {
        var sut = WireDriveUploadsActivityThrottle(minimumProgressInterval: 60)
        _ = sut.shouldSend(makeState(uploaded: 1, progress: 0.1), at: start)

        let sent5 = sut.shouldSend(makeState(uploaded: 2, progress: 0.2), at: start.addingTimeInterval(0.1))
        #expect(sent5)
    }

    @Test
    func sendsAFailureAtOnce() {
        var sut = WireDriveUploadsActivityThrottle(minimumProgressInterval: 60)
        _ = sut.shouldSend(makeState(progress: 0.1), at: start)

        let failing = makeState(.uploadingWithFailures, failed: 1, progress: 0.1)
        let sent6 = sut.shouldSend(failing, at: start.addingTimeInterval(0.1))
        #expect(sent6)
    }

    @Test
    func sendsTheFinalStateAtOnce() {
        var sut = WireDriveUploadsActivityThrottle(minimumProgressInterval: 60)
        _ = sut.shouldSend(makeState(uploaded: 7, progress: 0.99), at: start)

        let finished = makeState(.completed, uploaded: 8, progress: 1)
        let sent7 = sut.shouldSend(finished, at: start.addingTimeInterval(0.1))
        #expect(sent7)
    }

    @Test
    func sendsTheNextStateAfterAReset() {
        var sut = WireDriveUploadsActivityThrottle(minimumProgressInterval: 60)
        _ = sut.shouldSend(makeState(progress: 0.1), at: start)
        sut.reset()

        let sent8 = sut.shouldSend(makeState(progress: 0.1), at: start.addingTimeInterval(0.1))
        #expect(sent8)
    }
}
