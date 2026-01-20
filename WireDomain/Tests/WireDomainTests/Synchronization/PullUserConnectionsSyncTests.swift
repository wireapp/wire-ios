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

final class PullUserConnectionsSyncTests: XCTestCase {

    private var sut: PullUserConnectionsSync!
    private var api: MockConnectionsAPI!
    private var store: MockConnectionsLocalStoreProtocol!

    override func setUp() async throws {
        api = MockConnectionsAPI()
        store = MockConnectionsLocalStoreProtocol()
        sut = PullUserConnectionsSync(api: api, store: store)
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        api.getConnections_MockValue = .init(fetchPage: { _ in
            WireNetwork.PayloadPager.Page(
                element: [Scaffolding.remoteConnection],
                hasMore: false,
                nextStart: "first"
            )
        })

        store.storeConnection_MockMethod = { _ in }

        // When
        try await sut.pull()

        // Then
        XCTAssertEqual(api.getConnections_Invocations.count, 1)

        let storeInvocations = store.storeConnection_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0], Scaffolding.localConnection)
    }

}

private enum Scaffolding {

    static let senderID = UUID()
    static let receiverID = UUID()
    static let conversationID = UUID()
    static let domain = "wire.com"

    static let remoteConnection = WireNetwork.Connection(
        senderID: senderID,
        receiverID: receiverID,
        receiverQualifiedID: .init(id: senderID, domain: domain),
        conversationID: Scaffolding.conversationID,
        qualifiedConversationID: .init(id: conversationID, domain: domain),
        lastUpdate: Date(),
        status: .accepted
    )

    static var localConnection: ConnectionInfo {
        remoteConnection.toDomainModel()
    }

}
