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
import XCTest
@testable import WireDomain

final class ConnectionsLocalStoreTests: XCTestCase {

    private var sut: ConnectionsLocalStore!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        sut = ConnectionsLocalStore(context: context, isFederationEnabled: false)
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        modelHelper = nil
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testPullConnections_GivenConnectionDoesNotExist_FederationDisabled() async throws {
        try await internalTestPullConnections_GivenConnectionDoesNotExist(
            federationEnabled: false
        )
    }

    func testPullConnections_GivenConnectionDoesNotExist_FederationEnabled() async throws {
        await context.perform { [context] in
            context.isFederationEnabled = true
        }
        try await internalTestPullConnections_GivenConnectionDoesNotExist(
            federationEnabled: true
        )
    }

    // MARK: Private

    func internalTestPullConnections_GivenConnectionDoesNotExist(
        federationEnabled: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        // Mock

        let connection = Scaffolding.connection

        // When

        try await sut.storeConnection(connection)

        // Then

        try await context.perform { [context] in
            // There is a connection in the database.
            let storedConnection = try XCTUnwrap(ZMConnection.fetch(
                userID: Scaffolding.member2ID.uuid,
                domain: Scaffolding.member2ID.domain,
                in: context
            ))

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

            XCTAssertFalse(relatedConversation.needsToBeUpdatedFromBackend)
        }
    }

    func testUpdateConnection_It_Successfully_Updates_Connection_Locally() async throws {
        // Given

        let connection = Scaffolding.connection

        // When

        try await sut.storeConnection(connection)

        // Then

        try await context.perform { [context] in
            let storedConnection = try XCTUnwrap(ZMConnection.fetch(
                userID: Scaffolding.member2ID.uuid,
                domain: Scaffolding.member2ID.domain,
                in: context
            ))

            XCTAssertEqual(storedConnection.lastUpdateDateInGMT, connection.lastUpdate)

            XCTAssertEqual(storedConnection.to.remoteIdentifier, connection.receiverID)
            XCTAssertNil(storedConnection.to.domain)
            XCTAssertEqual(storedConnection.status, ZMConnectionStatus.accepted)

            let relatedConversation = try XCTUnwrap(storedConnection.to.oneOnOneConversation)
            XCTAssertEqual(relatedConversation.remoteIdentifier, connection.qualifiedConversationID?.uuid)

            XCTAssertNil(relatedConversation.domain)

            XCTAssertFalse(relatedConversation.needsToBeUpdatedFromBackend)
        }
    }

    func testMarkConversationAsNeedUpdatedFromBackend_It_Successfully_Updates_Conversation_Locally() async throws {
        // Given

        let connection = Scaffolding.connection
        try await sut.storeConnection(connection)

        // When
        try await sut.markConversationAsNeedUpdatedFromBackend(connection)

        // Then

        try await context.perform { [context] in
            let storedConnection = try XCTUnwrap(ZMConnection.fetch(
                userID: Scaffolding.member2ID.uuid,
                domain: Scaffolding.member2ID.domain,
                in: context
            ))

            let relatedConversation = try XCTUnwrap(storedConnection.to.oneOnOneConversation)

            XCTAssertTrue(relatedConversation.needsToBeUpdatedFromBackend)
        }
    }

    private enum Scaffolding {
        static let member1ID = WireDataModel.QualifiedID(
            uuid: .mockID1,
            domain: String.randomDomain()
        )
        static let conversationID = WireDataModel.QualifiedID(
            uuid: .mockID2,
            domain: String.randomDomain()
        )
        static let member2ID = WireDataModel.QualifiedID(
            uuid: .mockID3,
            domain: String.randomDomain()
        )
        static let lastUpdate = Date()
        static let connectionStatus = ZMConnectionStatus.accepted

        static let connection = ConnectionInfo(
            senderID: Scaffolding.member1ID.uuid,
            receiverID: Scaffolding.member2ID.uuid,
            receiverQualifiedID: Scaffolding.member2ID,
            conversationID: Scaffolding.conversationID.uuid,
            qualifiedConversationID: Scaffolding.conversationID,
            lastUpdate: Scaffolding.lastUpdate,
            status: Scaffolding.connectionStatus
        )
    }

}
