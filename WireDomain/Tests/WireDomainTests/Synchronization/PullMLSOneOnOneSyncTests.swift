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
import WireFoundation
import WireNetworkSupport
import XCTest

@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class PullMLSOneOnOneSyncTests: XCTestCase {

    private var sut: PullMLSOneOnOneSync!
    private var api: MockConversationsAPI!
    private var store: MockConversationLocalStoreProtocol!

    override func setUp() async throws {
        api = MockConversationsAPI()
        store = MockConversationLocalStoreProtocol()
        sut = PullMLSOneOnOneSync(
            api: api,
            store: store,
            isFederationEnabled: Scaffolding.isFederationEnabled,
            isMLSEnabled: Scaffolding.isMLSEnabled
        )
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        api.getMLSOneToOneConversationUserIDIn_MockValue = (Scaffolding.conversation, Scaffolding.mlsPublicKeys)
        store.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }

        // When
        let (mlsGroupID, publicKeys) = try await sut.pull(
            userID: Scaffolding.userID,
            userDomain: Scaffolding.userDomain
        )

        // Then
        let apiInvocations = api.getMLSOneToOneConversationUserIDIn_Invocations
        try XCTAssertCount(apiInvocations, count: 1)
        XCTAssertEqual(apiInvocations[0].userID, Scaffolding.userID.uuidString.lowercased())
        XCTAssertEqual(apiInvocations[0].domain, Scaffolding.userDomain)

        let storeInvocations = store.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0].conversation, Scaffolding.conversation.toDomainModel())
        XCTAssertEqual(storeInvocations[0].isFederationEnabled, Scaffolding.isFederationEnabled)
        XCTAssertEqual(storeInvocations[0].isMLSEnabled, Scaffolding.isMLSEnabled)

        XCTAssertEqual(mlsGroupID, MLSGroupID(base64Encoded: Scaffolding.mlsGroupID))
        XCTAssertEqual(publicKeys, Scaffolding.mlsPublicKeys)
    }

}

private enum Scaffolding {

    static let userID = UUID()
    static let userDomain = "wire.com"
    static let isFederationEnabled = true
    static let isMLSEnabled = true

    static let conversation = Conversation(
        id: userID,
        qualifiedID: .init(id: userID, domain: userDomain),
        teamID: userID,
        type: .group,
        messageProtocol: .proteus,
        mlsGroupID: mlsGroupID,
        cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
        epoch: 0,
        epochTimestamp: nil,
        creator: userID,
        members: nil,
        name: nil,
        messageTimer: 0,
        readReceiptMode: 0,
        access: [.invite],
        accessRoles: [.teamMember],
        legacyAccessRole: .team,
        lastEvent: "",
        lastEventTime: nil
    )

    static let mlsPublicKeys = WireNetwork.MLSPublicKeys(
        ed25519: .randomAlphanumerical(length: 5),
        p256: .randomAlphanumerical(length: 5),
        p384: .randomAlphanumerical(length: 5),
        p521: .randomAlphanumerical(length: 5)
    )
    static let mlsGroupID =
        "pQABARn//wKhAFggHsa0CszLXYLFcOzg8AA//E1+Dl1rDHQ5iuk44X0/PNYDoQChAFgg309rkhG6SglemG6kWae81P1HtQPx9lyb6wExTovhU4cE9g=="

}
