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

@testable import WireMessagingData

/// `shouldForward` is `mutating`, and `#expect` captures its operand immutably, so every call is
/// hoisted into a local before being asserted on.
struct WireDriveDirectUploadSessionProgressThrottleTests {

    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    @Test
    func forwardsTheFirstSample() {
        // Given
        var sut = WireDriveDirectUploadSession.ProgressThrottle()

        // When
        let didForward = sut.shouldForward(bytesSent: 1, totalBytes: 10_000_000, now: start)

        // Then
        #expect(didForward)
    }

    @Test
    func withholdsSamplesThatAreTooCloseTogether() {
        // Given
        var sut = WireDriveDirectUploadSession.ProgressThrottle()
        _ = sut.shouldForward(bytesSent: 0, totalBytes: 10_000_000, now: start)

        // When
        let didForward = sut.shouldForward(bytesSent: 1024, totalBytes: 10_000_000, now: start)

        // Then
        #expect(!didForward)
    }

    @Test
    func forwardsOnceEnoughTimeHasPassed() {
        // Given
        var sut = WireDriveDirectUploadSession.ProgressThrottle(minimumInterval: 0.25)
        _ = sut.shouldForward(bytesSent: 0, totalBytes: 10_000_000, now: start)

        // When
        let didForward = sut.shouldForward(
            bytesSent: 1,
            totalBytes: 10_000_000,
            now: start.addingTimeInterval(0.25)
        )

        // Then
        #expect(didForward)
    }

    @Test
    func forwardsOnceEnoughBytesHaveAccumulated() {
        // Given
        var sut = WireDriveDirectUploadSession.ProgressThrottle(minimumByteDelta: 64 * 1024)
        _ = sut.shouldForward(bytesSent: 0, totalBytes: 1_000_000, now: start)

        // When
        let didForward = sut.shouldForward(bytesSent: 64 * 1024, totalBytes: 1_000_000, now: start)

        // Then
        #expect(didForward)
    }

    /// The byte threshold scales with file size, so a large upload emits roughly 100 updates rather
    /// than one every 64 KiB.
    @Test
    func scalesTheByteThresholdWithFileSize() {
        // Given
        let totalBytes: Int64 = 1_000_000_000
        var sut = WireDriveDirectUploadSession.ProgressThrottle(minimumByteDelta: 64 * 1024)
        _ = sut.shouldForward(bytesSent: 0, totalBytes: totalBytes, now: start)

        // When
        let didForwardSmallDelta = sut.shouldForward(
            bytesSent: 64 * 1024,
            totalBytes: totalBytes,
            now: start
        )
        let didForwardScaledDelta = sut.shouldForward(
            bytesSent: totalBytes / 100,
            totalBytes: totalBytes,
            now: start
        )

        // Then
        #expect(!didForwardSmallDelta)
        #expect(didForwardScaledDelta)
    }

    @Test
    func alwaysForwardsTheFinalSample() {
        // Given — no time has passed and only one byte was added, but the body is complete.
        var sut = WireDriveDirectUploadSession.ProgressThrottle()
        _ = sut.shouldForward(bytesSent: 0, totalBytes: 10_000_000, now: start)

        // When
        let didForward = sut.shouldForward(bytesSent: 10_000_000, totalBytes: 10_000_000, now: start)

        // Then
        #expect(didForward)
    }

    @Test
    func emitsABoundedNumberOfSamplesForALargeUpload() {
        // Given
        let totalBytes: Int64 = 500 * 1024 * 1024
        var sut = WireDriveDirectUploadSession.ProgressThrottle()
        var forwarded = 0

        // When — one callback per 64 KiB, all at the same instant, which is the worst case.
        var chunk: Int64 = 0
        while chunk <= totalBytes {
            if sut.shouldForward(bytesSent: chunk, totalBytes: totalBytes, now: start) {
                forwarded += 1
            }
            chunk += 64 * 1024
        }

        // Then
        #expect(forwarded <= 110, "expected roughly 100 updates, got \(forwarded)")
    }
}
