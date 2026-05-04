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

import WireNetwork
import WireNetworkSupport
import XCTest
@testable import WireDomain
@testable import WireDomainSupport

final class PullLastUpdateEventIDSyncTests: XCTestCase {

    private var sut: PullLastUpdateEventIDSync!
    private var api: MockUpdateEventsAPI!
    private var store: MockUpdateEventsLocalStoreProtocol!

    override func setUp() async throws {
        api = MockUpdateEventsAPI()
        store = MockUpdateEventsLocalStoreProtocol()
        sut = PullLastUpdateEventIDSync(
            selfClientID: Scaffolding.selfClientID,
            api: api,
            store: store
        )
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        api.getLastUpdateEventSelfClientID_MockValue = Scaffolding.envelope1
        store.storeLastEventIDId_MockMethod = { _ in }

        // When
        try await sut.pull()

        // Then
        let apiInvocations = api.getLastUpdateEventSelfClientID_Invocations
        try XCTAssertCount(apiInvocations, count: 1)
        XCTAssertEqual(apiInvocations[0], Scaffolding.selfClientID)

        let storeInvocations = store.storeLastEventIDId_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0], Scaffolding.envelope1.id)
    }

}

private enum Scaffolding {

    static let selfClientID = "abc123"

    static let envelope1 = UpdateEventEnvelope(
        id: UUID(),
        events: [.user(.pushRemove)],
        isTransient: false
    )

}
