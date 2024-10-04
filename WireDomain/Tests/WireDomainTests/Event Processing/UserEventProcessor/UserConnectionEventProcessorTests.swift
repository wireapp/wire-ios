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

import WireAPI
@testable import WireDomain
import WireDomainSupport
import XCTest

final class UserConnectionEventProcessorTests: XCTestCase {
    var sut: UserConnectionEventProcessor!
    var connectionsRepository: MockConnectionsRepositoryProtocol!
    var oneOnOneResolver: MockOneOnOneResolverProtocol!

    override func setUp() async throws {
        try await super.setUp()
        connectionsRepository = MockConnectionsRepositoryProtocol()
        oneOnOneResolver = MockOneOnOneResolverProtocol()
        sut = UserConnectionEventProcessor(
            connectionsRepository: connectionsRepository,
            oneOnOneResolver: oneOnOneResolver
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        connectionsRepository = nil
        oneOnOneResolver = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Repo_And_Resolver_Methods() async throws {
        // Given

        let event = UserConnectionEvent(
            userName: Scaffolding.username,
            connection: Scaffolding.connection
        )

        // Mock

        connectionsRepository.updateConnection_MockMethod = { _ in }
        oneOnOneResolver.invoke_MockMethod = {}

        // When

        try await sut.processEvent(event)

        // Then

        XCTAssertEqual(connectionsRepository.updateConnection_Invocations, [event.connection])
        XCTAssertEqual(oneOnOneResolver.invoke_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let username = "username"
        static let connection = Connection(
            senderID: UUID(),
            receiverID: UUID(),
            receiverQualifiedID: WireAPI.QualifiedID(
                uuid: UUID(),
                domain: "domain.com"
            ),
            conversationID: UUID(),
            qualifiedConversationID: WireAPI.QualifiedID(
                uuid: UUID(),
                domain: "domain.com"
            ),
            lastUpdate: .now,
            status: .accepted
        )
    }

}
