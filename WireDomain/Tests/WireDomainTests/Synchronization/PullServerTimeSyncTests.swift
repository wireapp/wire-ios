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

final class PullServerTimeSyncTests: XCTestCase {

    private var sut: PullServerTimeSync!
    private var api: MockUpdateEventsAPI!
    private var store: MockUpdateEventsLocalStoreProtocol!

    override func setUp() async throws {
        api = MockUpdateEventsAPI()
        store = MockUpdateEventsLocalStoreProtocol()
        sut = PullServerTimeSync(api: api, store: store)
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        let value = Date()
        let expectedValue = value.timeIntervalSinceNow
        api.getServerTime_MockValue = value
        store.storeServerTimeDelta_MockMethod = { _ in }

        // When
        try await sut.pull()

        // Then
        try XCTAssertCount(api.getServerTime_Invocations, count: 1)

        let storeInvocations = store.storeServerTimeDelta_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0], expectedValue, accuracy: 0.1)
    }

}
