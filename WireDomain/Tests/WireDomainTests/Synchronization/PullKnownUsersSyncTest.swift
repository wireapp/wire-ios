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

final class PullKnownUsersSyncTests: XCTestCase {

    private var sut: PullKnownUsersSync!
    private var api: MockUsersAPI!
    private var store: MockUserLocalStoreProtocol!

    override func setUp() async throws {
        api = MockUsersAPI()
        store = MockUserLocalStoreProtocol()
        sut = PullKnownUsersSync(api: api, store: store)
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        api.getUsersUserIDs_MockValue = WireNetwork.UserList(
            found: [Scaffolding.user1],
            failed: [Scaffolding.user2.id]
        )

        store.fetchUsersQualifiedIDs_MockValue = [
            Scaffolding.user1.id.toDomainModel(),
            Scaffolding.user2.id.toDomainModel()
        ]

        store.persistUserUserInfo_MockMethod = { _ in }

        // When
        try await sut.pull()

        // Then
        XCTAssertEqual(store.fetchUsersQualifiedIDs_Invocations.count, 1)

        let apiInvocations = api.getUsersUserIDs_Invocations
        try XCTAssertCount(apiInvocations, count: 1)
        XCTAssertEqual(apiInvocations[0], [Scaffolding.user1.id, Scaffolding.user2.id])

        let storeInvocations = store.persistUserUserInfo_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0], Scaffolding.localUser1)
    }

}

private enum Scaffolding {

    static let user1 = User(
        id: QualifiedID(id: UUID(), domain: "wire.com"),
        name: "user1",
        handle: "handle1",
        teamID: nil,
        type: .regular,
        accentID: 1,
        assets: [],
        deleted: false,
        email: "john.doe@wire.com",
        expiresAt: nil,
        service: nil,
        supportedProtocols: [.mls],
        legalholdStatus: .disabled
    )

    static let user2 = User(
        id: QualifiedID(id: UUID(), domain: "wire.com"),
        name: "user2",
        handle: "handle2",
        teamID: nil,
        type: .regular,
        accentID: 1,
        assets: [],
        deleted: false,
        email: "jane.doe@wire.com",
        expiresAt: nil,
        service: nil,
        supportedProtocols: [.mls],
        legalholdStatus: .disabled
    )

    static var localUser1: NewUserInfo {
        user1.toDomainModel()
    }

}
