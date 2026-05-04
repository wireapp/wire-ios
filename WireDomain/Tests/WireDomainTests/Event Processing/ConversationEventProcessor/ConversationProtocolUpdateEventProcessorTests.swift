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

import WireDomainSupport
import XCTest
@testable import WireDomain
@testable import WireNetwork

final class ConversationProtocolUpdateEventProcessorTests: XCTestCase {

    private var sut: ConversationProtocolUpdateEventProcessor!
    private var repository: MockConversationRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockConversationRepositoryProtocol()
        sut = ConversationProtocolUpdateEventProcessor(
            repository: repository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        repository = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Pull_Conversation_Repo_Method() async throws {
        // Mock

        repository.pullConversationIdDomain_MockMethod = { _, _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(repository.pullConversationIdDomain_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let event = ConversationProtocolUpdateEvent(
            conversationID: ConversationID(id: UUID(), domain: "domain.com"),
            senderID: UserID(id: UUID(), domain: "domain.com"),
            newProtocol: .mls
        )
    }
}
