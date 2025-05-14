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

import WireTestingPackage
import XCTest

@testable import WireFoundation

final class BackoffRetrierTests: XCTestCase {

    private var sut: BackoffRetrier!

    override func setUp() {
        sut = BackoffRetrier()
    }

    override func tearDown() {
        sut = nil
    }

    // TODO: [WPB-17645] Assert sleep durations exponentially increased
    func testBackOffRetrier_It_Eventually_Succeeds() async throws {
        // Given
        var callCount = 0

        let policy = BackoffRetryPolicy(
            maxRetries: 3,
            baseTime: 1.0,
            maxTime: 100.0,
            exponentMultiplier: 2.0,
            jitter: false // Disable jitter for deterministic testing
        )

        let retrier = BackoffRetrier(policy: policy, sleep: { _ in })

        // When, simulating 3 calls, first 2 fail, third succeeds
        let result = try await retrier.retry {
            callCount += 1
            if callCount < 3 {
                throw NSError(domain: "Test", code: -1)
            }
            return "Success"
        }

        // Then
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(callCount, 3)
    }

    func testBackoffRetrier_It_Fails_After_Max_Retries() async {
        // Given
        let policy = BackoffRetryPolicy()
        let retrier = BackoffRetrier(policy: policy, sleep: { _ in })

        do {
            // When
            _ = try await retrier.retry {
                throw NSError(domain: "Test", code: -1)
            }
            XCTFail("Expected retry to fail after max retries")
        } catch let BackoffRetrier.Failure.exceededMaxAttempts(error as NSError) {
            // Then
            XCTAssertEqual(error.domain, "Test")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
