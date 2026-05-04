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

import WireDataModel
import WireNetwork
import WireNetworkSupport
import XCTest
@testable import WireDomain
@testable import WireDomainSupport

final class PullSelfLegalholdInfoSyncTests: XCTestCase {

    private var sut: PullSelfLegalholdInfoSync!
    private var api: MockTeamsAPI!
    private var store: MockUserLocalStoreProtocol!

    override func setUp() async throws {
        api = MockTeamsAPI()
        store = MockUserLocalStoreProtocol()
        sut = PullSelfLegalholdInfoSync(
            selfUserID: Scaffolding.selfUserID,
            api: api,
            store: store
        )
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull_Legalhold_Pending() async throws {
        // Mock
        api.getLegalholdInfoForUserID_MockValue = Scaffolding.remoteLegalholdInfo(status: .pending)
        store.addSelfLegalHoldRequestUserIDClientIDLastPrekey_MockMethod = { _, _, _ in }

        // When
        try await sut.pull(selfTeamID: Scaffolding.selfTeamID)

        // Then
        let apiInvocations = api.getLegalholdInfoForUserID_Invocations
        try XCTAssertCount(apiInvocations, count: 1)
        XCTAssertEqual(apiInvocations[0].teamID, Scaffolding.selfTeamID)
        XCTAssertEqual(apiInvocations[0].userID, Scaffolding.selfUserID)

        let storeInvocations = store.addSelfLegalHoldRequestUserIDClientIDLastPrekey_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0].userID, Scaffolding.selfUserID)
        XCTAssertEqual(storeInvocations[0].clientID, Scaffolding.clientID)
        XCTAssertEqual(storeInvocations[0].lastPrekey, Scaffolding.localPrekey)
    }

    func testPull_Legalhold_Disabled() async throws {
        // Mock
        api.getLegalholdInfoForUserID_MockValue = Scaffolding.remoteLegalholdInfo(status: .disabled)
        store.cancelSelfUserLegalholdRequest_MockMethod = {}

        // When
        try await sut.pull(selfTeamID: Scaffolding.selfTeamID)

        // Then
        let apiInvocations = api.getLegalholdInfoForUserID_Invocations
        try XCTAssertCount(apiInvocations, count: 1)
        XCTAssertEqual(apiInvocations[0].teamID, Scaffolding.selfTeamID)
        XCTAssertEqual(apiInvocations[0].userID, Scaffolding.selfUserID)

        XCTAssertEqual(store.cancelSelfUserLegalholdRequest_Invocations.count, 1)
    }

    func testPull_Legalhold_Enabled() async throws {
        // Mock
        api.getLegalholdInfoForUserID_MockValue = Scaffolding.remoteLegalholdInfo(status: .enabled)

        // When
        try await sut.pull(selfTeamID: Scaffolding.selfTeamID)

        // Then
        let apiInvocations = api.getLegalholdInfoForUserID_Invocations
        try XCTAssertCount(apiInvocations, count: 1)
        XCTAssertEqual(apiInvocations[0].teamID, Scaffolding.selfTeamID)
        XCTAssertEqual(apiInvocations[0].userID, Scaffolding.selfUserID)
    }

    func testPull_Legalhold_No_Consent() async throws {
        // Mock
        api.getLegalholdInfoForUserID_MockValue = Scaffolding.remoteLegalholdInfo(status: .noConsent)

        // When
        try await sut.pull(selfTeamID: Scaffolding.selfTeamID)

        // Then
        let apiInvocations = api.getLegalholdInfoForUserID_Invocations
        try XCTAssertCount(apiInvocations, count: 1)
        XCTAssertEqual(apiInvocations[0].teamID, Scaffolding.selfTeamID)
        XCTAssertEqual(apiInvocations[0].userID, Scaffolding.selfUserID)
    }

}

private enum Scaffolding {

    static let selfUserID = UUID()
    static let selfTeamID = UUID()
    static let clientID = "abc123"
    static let prekeyData = Data.random()
    static let prekey = LegalholdPrekey(
        id: 0,
        base64EncodedKey: prekeyData.base64String()
    )

    static func remoteLegalholdInfo(status: LegalholdStatus) -> TeamMemberLegalholdInfo {
        .init(
            status: status,
            clientID: clientID,
            prekey: prekey
        )
    }

    static var localPrekey: WireDataModel.LegalHoldRequest.Prekey? {
        prekey.toDomainModel()
    }

}
