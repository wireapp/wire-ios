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
import WireNetwork
import XCTest

@testable import WireDomain

final class UserConnectionEventProcessorTests: XCTestCase {

    private var sut: UserConnectionEventProcessor!
    private var connectionsRepository: MockConnectionsRepositoryProtocol!
    private var oneOnOneResolver: MockOneOnOneResolverProtocol!

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
        connectionsRepository = MockConnectionsRepositoryProtocol()
        oneOnOneResolver = MockOneOnOneResolverProtocol()
        sut = UserConnectionEventProcessor(
            context: context,
            connectionsRepository: connectionsRepository,
            oneOnOneResolver: oneOnOneResolver
        )
    }

    override func tearDown() async throws {
        stack = nil
        modelHelper = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        connectionsRepository = nil
        oneOnOneResolver = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_Accepted_Connection_It_Invokes_Repo_And_Resolver_Methods() async throws {
        // Given

        let expectation = expectation(description: "resolved 1:1 conversation")
        let event = UserConnectionEvent(
            userName: Scaffolding.username,
            connection: Scaffolding.acceptedConnection
        )

        // Mock

        connectionsRepository.updateConnection_MockMethod = { _ in }
        connectionsRepository.scheduleToSyncConversationWith_MockMethod = { _ in }
        oneOnOneResolver.resolveOneOnOneConversationWith_MockMethod = { _ in
            expectation.fulfill()
            return .noAction
        }

        // When

        try await sut.processEvent(event)
        await fulfillment(of: [expectation])

        // Then

        XCTAssertEqual(connectionsRepository.updateConnection_Invocations, [event.connection])
        XCTAssertEqual(connectionsRepository.scheduleToSyncConversationWith_Invocations, [event.connection])
        XCTAssertEqual(oneOnOneResolver.resolveOneOnOneConversationWith_Invocations.count, 1)
    }

    func testProcessEvent_Pending_Connection_It_Invokes_Repo_And_Resolver_Methods() async throws {
        // Given

        let event = UserConnectionEvent(
            userName: Scaffolding.username,
            connection: Scaffolding.pendingConnection
        )

        // Mock

        connectionsRepository.updateConnection_MockMethod = { _ in }
        oneOnOneResolver.resolveOneOnOneConversationWith_MockMethod = { _ in .noAction }
        _ = await context.perform { [self] in
            modelHelper.createUser(
                qualifiedID: Scaffolding.receiverQualifiedID.toDomainModel(),
                in: context
            )
        }

        // When

        try await sut.processEvent(event)

        // Then

        XCTAssertEqual(connectionsRepository.updateConnection_Invocations, [event.connection])
        XCTAssertEqual(oneOnOneResolver.resolveOneOnOneConversationWith_Invocations.count, 1)
        XCTAssertEqual(connectionsRepository.scheduleToSyncConversationWith_Invocations.count, 0)
    }

    private enum Scaffolding {
        static let username = "username"
        static let receiverQualifiedID = WireNetwork.QualifiedID(
            id: UUID(),
            domain: "domain.com"
        )
        static let acceptedConnection = Connection(
            senderID: UUID(),
            receiverID: UUID(),
            receiverQualifiedID: WireNetwork.QualifiedID(
                id: UUID(),
                domain: "domain.com"
            ),
            conversationID: UUID(),
            qualifiedConversationID: WireNetwork.QualifiedID(
                id: UUID(),
                domain: "domain.com"
            ),
            lastUpdate: .now,
            status: .accepted
        )

        static let pendingConnection = Connection(
            senderID: UUID(),
            receiverID: UUID(),
            receiverQualifiedID: receiverQualifiedID,
            conversationID: UUID(),
            qualifiedConversationID: WireNetwork.QualifiedID(
                id: UUID(),
                domain: "domain.com"
            ),
            lastUpdate: .now,
            status: .pending
        )
    }

}
