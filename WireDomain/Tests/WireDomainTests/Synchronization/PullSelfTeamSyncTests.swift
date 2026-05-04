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

final class PullSelfTeamSyncTests: XCTestCase {

    private var sut: PullSelfTeamSync!
    private var api: MockTeamsAPI!
    private var store: MockTeamLocalStoreProtocol!

    override func setUp() async throws {
        api = MockTeamsAPI()
        store = MockTeamLocalStoreProtocol()
        sut = PullSelfTeamSync(api: api, store: store)
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        api.getTeamFor_MockValue = WireNetwork.Team(
            id: Scaffolding.selfTeamID,
            name: Scaffolding.teamName,
            creatorID: Scaffolding.teamCreatorID,
            logoID: Scaffolding.logoID,
            logoKey: Scaffolding.logoKey,
            splashScreenID: Scaffolding.splashScreenID
        )

        store.storeTeamIdNameCreatorIDLogoIDLogoKey_MockMethod = { _, _, _, _, _ in }

        // When
        try await sut.pull(selfTeamID: Scaffolding.selfTeamID)

        // Then
        let apiInvocations = api.getTeamFor_Invocations
        try XCTAssertCount(apiInvocations, count: 1)
        XCTAssertEqual(apiInvocations[0], Scaffolding.selfTeamID)

        let storeInvocations = store.storeTeamIdNameCreatorIDLogoIDLogoKey_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0].id, Scaffolding.selfTeamID)
        XCTAssertEqual(storeInvocations[0].name, Scaffolding.teamName)
        XCTAssertEqual(storeInvocations[0].creatorID, Scaffolding.teamCreatorID)
        XCTAssertEqual(storeInvocations[0].logoID, Scaffolding.logoID)
        XCTAssertEqual(storeInvocations[0].logoKey, Scaffolding.logoKey)
    }

}

private enum Scaffolding {

    static let selfTeamID = UUID()
    static let teamName = "Team Foo"
    static let teamCreatorID = UUID()
    static let logoID = UUID().uuidString
    static let logoKey = UUID().uuidString
    static let splashScreenID = UUID().uuidString

}
