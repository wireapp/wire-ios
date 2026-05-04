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

import WireDomainSupport
import WireNetwork
import XCTest
@testable import WireDomain

class SyncEventUseCaseTests: XCTestCase {

    var sut: SyncEventsUseCase!
    var sync: MockPullPendingUpdateEventsSyncV2Protocol!

    override func setUp() async throws {
        sync = MockPullPendingUpdateEventsSyncV2Protocol()
        sut = SyncEventsUseCase(
            pendingEventsSync: sync,
            timeout: .seconds(0.5)
        )
    }

    func test_invoke_ItFailsWithError() async throws {
        let error = TestError(message: "any")
        sync.pull_MockError = error

        await XCTAssertThrowsErrorAsync(SyncEventsUseCase.Failure.pendingEventsSyncFailed(error)) {
            try await self.sut.invoke()
        }
    }

    func test_invoke_ItFailsWithCancellableError() async throws {
        sync.pull_MockMethod = {
            try await Task.sleep(for: .seconds(0.75))
        }

        await XCTAssertThrowsErrorAsync(SyncEventsUseCase.Failure.timedOut) {
            try await self.sut.invoke()
        }
    }

}

extension SyncEventsUseCase.Failure: @retroactive Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.timedOut, .timedOut):
            true
        case (.pendingEventsSyncFailed, .pendingEventsSyncFailed):
            true
        default:
            false
        }
    }
}
