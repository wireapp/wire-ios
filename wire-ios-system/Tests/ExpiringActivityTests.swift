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

import Foundation
@testable import WireSystem
import XCTest

class ExpiringActivityTests: XCTestCase {

    let concurrentQueue = DispatchQueue(label: "activity queue", attributes: [.concurrent])

    func testThatTaskIsCancelled_WhenActivityExpires() async throws {

        // given
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager(api: api)

        api.method = { _, block in
            self.concurrentQueue.async {
                block(false)
            }
            self.concurrentQueue.async {
                block(true)
            }
        }

        // when
        do {
            try await sut.withExpiringActivity(reason: "Expiring test activity") {
                while true {
                    await Task.yield()
                    try Task.checkCancellation()
                }
            }
            XCTFail("Expected a cancellation error to be thrown")
        } catch { }
    }

    func testThatTaskIsCancelled_WhenActivityIsNotAllowedToBegin() async throws {

        // given
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager(api: api)

        api.method = { _, block in
            self.concurrentQueue.async {
                block(true)
            }
        }

        // when
        do {
            try await sut.withExpiringActivity(reason: "Expiring test activity") {
                while true {
                    await Task.yield()
                    try Task.checkCancellation()
                }
            }
            XCTFail("Expected an expiring activity not allowed to run error to be thrown")
        } catch { }
    }

    func testThatTaskEndsWithoutError_WhenActivityCompletes() async throws {

        // given
        let api = MockExpiringActivityAPI()
        let sut = ExpiringActivityManager(api: api)

        api.method = { _, block in
            self.concurrentQueue.async {
                block(false)
            }
        }

        // when
        do {
            try await sut.withExpiringActivity(reason: "Expiring test activity") {
                try Task.checkCancellation()
            }
        } catch {
            XCTFail("Expected the activity to end without any error thrown")
        }
    }

}

private class MockExpiringActivityAPI: ExpiringActivityInterface {

    typealias MethodCall = (_ reason: String, _ block: @escaping @Sendable (Bool) -> Void) -> Void

    var method: MethodCall?

    func performExpiringActivity(withReason reason: String, using block: @escaping @Sendable (Bool) -> Void) {
        if let method {
            method(reason, block)
        } else {
            fatalError("no mock for `performExpiringActivity(withReason:using:)`")
        }
    }

}
