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

final class PullSelfTeamMembersSyncTests: XCTestCase {

    private var sut: PullSelfTeamMembersSync!
    private var api: MockTeamsAPI!
    private var store: MockTeamLocalStoreProtocol!

    override func setUp() async throws {
        api = MockTeamsAPI()
        store = MockTeamLocalStoreProtocol()
        sut = PullSelfTeamMembersSync(api: api, store: store)
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        api.getTeamMembersForMaxResults_MockValue = Scaffolding.remoteMembers

        store.storeTeamMembersSelfTeamIDTeamMembersInfo_MockMethod = { _, _ in }

        // When
        try await sut.pull(selfTeamID: Scaffolding.selfTeamID)

        // Then
        let apiInvocations = api.getTeamMembersForMaxResults_Invocations
        try XCTAssertCount(apiInvocations, count: 1)
        XCTAssertEqual(apiInvocations[0].teamID, Scaffolding.selfTeamID)
        XCTAssertEqual(apiInvocations[0].maxResults, 2000)

        let storeInvocations = store.storeTeamMembersSelfTeamIDTeamMembersInfo_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0].selfTeamID, Scaffolding.selfTeamID)
        XCTAssertEqual(storeInvocations[0].teamMembersInfo, Scaffolding.localMembers)
    }

}

private enum Scaffolding {

    static let selfTeamID = UUID()

    static let member1 = TeamMember(
        userID: UUID(),
        creationDate: .now,
        creatorID: UUID(),
        legalholdStatus: .enabled,
        permissions: .init(
            copyPermissions: 1,
            selfPermissions: 1
        )
    )

    static let member2 = TeamMember(
        userID: UUID(),
        creationDate: .now,
        creatorID: UUID(),
        legalholdStatus: .noConsent,
        permissions: .init(
            copyPermissions: 2,
            selfPermissions: 2
        )
    )

    static let remoteMembers = [
        member1,
        member2
    ]

    static var localMembers: [TeamMemberInfo] {
        remoteMembers.map {
            $0.toDomainModel()
        }
    }

}
