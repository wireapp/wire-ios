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
import WireDataModelSupport
import WireDomainSupport
import WireNetworkSupport
import XCTest

@testable import WireDomain
@testable import WireNetwork

final class ConnectionsRepositoryTests: XCTestCase {

    private var sut: ConnectionsRepository!
    private var connectionsAPI: MockConnectionsAPI!
    private var connectionsLocalStore: MockConnectionsLocalStoreProtocol!

    override func setUp() async throws {
        connectionsAPI = MockConnectionsAPI()
        connectionsLocalStore = MockConnectionsLocalStoreProtocol()

        sut = ConnectionsRepository(
            connectionsAPI: connectionsAPI,
            connectionsLocalStore: connectionsLocalStore
        )
    }

    override func tearDown() async throws {
        connectionsAPI = nil
        connectionsLocalStore = nil
        sut = nil
    }

    // MARK: - Tests

    func testPullConnections_It_Invokes_Local_Store_Method() async throws {
        // Mock

        let connection = Scaffolding.connection

        connectionsAPI.getConnections_MockValue = .init(fetchPage: { _ in

            WireNetwork.PayloadPager.Page(
                element: [connection],
                hasMore: false,
                nextStart: "first"
            )
        })

        connectionsLocalStore.storeConnection_MockMethod = { _ in }

        // When

        try await sut.pullConnections()

        // Then

        XCTAssertEqual(connectionsLocalStore.storeConnection_Invocations.count, 1)
    }

    func testUpdateConnection_It_Invokes_Local_Store_Method() async throws {
        // Mock

        let connection = Scaffolding.connection
        connectionsLocalStore.storeConnection_MockMethod = { _ in }

        // When

        try await sut.updateConnection(connection)

        // Then

        XCTAssertEqual(connectionsLocalStore.storeConnection_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let member1ID = WireNetwork.QualifiedID(id: .mockID1, domain: String.randomDomain())
        static let conversationID = WireNetwork.QualifiedID(id: .mockID2, domain: String.randomDomain())
        static let member2ID = WireNetwork.QualifiedID(id: .mockID3, domain: String.randomDomain())
        static let lastUpdate = Date()
        static let connectionStatus = ConnectionStatus.accepted

        static let connection = WireNetwork.Connection(
            senderID: Scaffolding.member1ID.id,
            receiverID: Scaffolding.member2ID.id,
            receiverQualifiedID: Scaffolding.member2ID,
            conversationID: Scaffolding.conversationID.id,
            qualifiedConversationID: Scaffolding.conversationID,
            lastUpdate: Scaffolding.lastUpdate,
            status: Scaffolding.connectionStatus
        )
    }

}
