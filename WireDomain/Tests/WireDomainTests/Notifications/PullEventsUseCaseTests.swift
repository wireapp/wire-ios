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

import WireNetworkSupport
import XCTest
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class PullEventsUseCaseTests: XCTestCase {
    private var sut: PullEventsUseCase!
    private var updateEventsLocalStore: MockUpdateEventsLocalStoreProtocol!
    private var userClientsLocalStore: MockUserClientsLocalStoreProtocol!
    private var eventsSync: MockPullPendingUpdateEventsSyncProtocol!

    override func setUp() async throws {
        updateEventsLocalStore = MockUpdateEventsLocalStoreProtocol()
        userClientsLocalStore = MockUserClientsLocalStoreProtocol()
        eventsSync = MockPullPendingUpdateEventsSyncProtocol()

        sut = PullEventsUseCase(pendingEventsSync: eventsSync)
    }

    override func tearDown() async throws {
        sut = nil
        eventsSync = nil
        updateEventsLocalStore = nil
        userClientsLocalStore = nil
    }

    func testStartsSync_It_Invokes_Methods() async throws {

        // Mock
        eventsSync.pull_MockValue = AsyncStream {
            [
                UpdateEvent.user(.pushRemove),
                UpdateEvent.user(.pushRemove)
            ]
        }

        // When
        let asyncStream = try await sut.invoke()

        // Then
        XCTAssertEqual(eventsSync.pull_Invocations.count, 1)
        let containsEvents = await asyncStream.contains(
            [.user(.pushRemove), .user(.pushRemove)]
        )
        XCTAssertTrue(containsEvents)
    }

    func testStartsSync_It_Throws_Error() async throws {
        // Mock

        enum MockError: Error {
            case someError
        }

        updateEventsLocalStore.lastEventID_MockValue = .some(nil)
        updateEventsLocalStore.storeLastEventIDId_MockMethod = { _ in }
        eventsSync.pull_MockError = MockError.someError

        do {
            // When
            _ = try await sut.invoke()

        } catch {
            // Then
            XCTAssert(error is PullEventsUseCase.Failure)
        }
    }

}
