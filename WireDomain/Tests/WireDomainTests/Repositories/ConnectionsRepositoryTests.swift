//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import WireAPISupport
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import WireTransport
import XCTest

@testable import WireAPI
@testable import WireDomain

final class ConnectionsRepositoryTests: XCTestCase {

    var sut: ConnectionsRepository!
    var connectionsAPI: MockConnectionsAPI!

    var stack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        BackendInfo.isFederationEnabled = false

        stack = try await coreDataStackHelper.createStack()
        connectionsAPI = MockConnectionsAPI()
        sut = ConnectionsRepository(
            connectionsAPI: connectionsAPI,
            connectionsLocalStore: ConnectionsLocalStore(context: context)
        )
    }

    override func tearDown() async throws {
        stack = nil
        connectionsAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Tests

    func testPullConnections_GivenOneConnectionFails_OtherConnectionsAreStored() async throws {
        // Mock
        let connection = Scaffolding.connection
        let brokenConnection = Scaffolding.brokenConnection

        connectionsAPI.getConnections_MockValue = .init(fetchPage: { _ in

            WireAPI.PayloadPager.Page(
                element: [
                    brokenConnection,
                    connection
                ],
                hasMore: false,
                nextStart: "first"
            )
        })

        // When
        try await sut.pullConnections()

        // Then
        try await context.perform { [context] in
            // There is a connection in the database.
            let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: ZMConnection.entityName())
            let a = try context.fetch(fetchRequest)
            XCTAssertEqual(a.count, 1)
        }
    }

    func testPullConnections_GivenConnectionDoesNotExist_FederationDisabled() async throws {
        try await internalTestPullConnections_GivenConnectionDoesNotExist(federationEnabled: false)
    }

    func testPullConnections_GivenConnectionDoesNotExist_FederationEnabled() async throws {
        BackendInfo.isFederationEnabled = true
        try await internalTestPullConnections_GivenConnectionDoesNotExist(federationEnabled: true)
    }

    // MARK: Private

    func internalTestPullConnections_GivenConnectionDoesNotExist(
        federationEnabled: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        // Mock
        let connection = Scaffolding.connection
        connectionsAPI.getConnections_MockValue = .init(fetchPage: { _ in
            WireAPI.PayloadPager.Page(element: [connection], hasMore: false, nextStart: "first")
        })

        // When
        try await sut.pullConnections()

        // Then
        try await context.perform { [context] in
            // There is a connection in the database.
            let storedConnection = try XCTUnwrap(ZMConnection.fetch(userID: Scaffolding.member2ID.uuid, domain: Scaffolding.member2ID.domain, in: context))

            XCTAssertEqual(storedConnection.lastUpdateDateInGMT, connection.lastUpdate)

            XCTAssertEqual(storedConnection.to.remoteIdentifier, connection.receiverID)
            if federationEnabled {
                XCTAssertEqual(storedConnection.to.domain, connection.receiverQualifiedID?.domain)
            } else {
                XCTAssertNil(storedConnection.to.domain)
            }
            XCTAssertEqual(storedConnection.status, ZMConnectionStatus.accepted)

            let relatedConversation = try XCTUnwrap(storedConnection.to.oneOnOneConversation)
            XCTAssertEqual(relatedConversation.remoteIdentifier, connection.qualifiedConversationID?.uuid)

            if federationEnabled {
                XCTAssertEqual(relatedConversation.domain, connection.qualifiedConversationID?.domain)
            } else {
                XCTAssertNil(relatedConversation.domain)
            }

            XCTAssertTrue(relatedConversation.needsToBeUpdatedFromBackend)
        }
    }
}

private enum Scaffolding {
    static let member1ID = WireAPI.QualifiedID(uuid: UUID(), domain: String.randomDomain())
    static let conversationID = WireAPI.QualifiedID(uuid: UUID(), domain: String.randomDomain())
    static let member2ID = WireAPI.QualifiedID(uuid: UUID(), domain: String.randomDomain())
    static let lastUpdate = Date()
    static let connectionStatus = ConnectionStatus.accepted

    static let connection = WireAPI.Connection(senderID: Scaffolding.member1ID.uuid,
                                               receiverID: Scaffolding.member2ID.uuid,
                                               receiverQualifiedID: Scaffolding.member2ID,
                                               conversationID: Scaffolding.conversationID.uuid,
                                               qualifiedConversationID: Scaffolding.conversationID,
                                               lastUpdate: Scaffolding.lastUpdate,
                                               status: Scaffolding.connectionStatus)

    static let brokenConnection = WireAPI.Connection(senderID: nil,
                                                     receiverID: nil,
                                                     receiverQualifiedID: nil,
                                                     conversationID: nil,
                                                     qualifiedConversationID: nil,
                                                     lastUpdate: Date(),
                                                     status: .pending)
}
