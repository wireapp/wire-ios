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

@testable import WireAPI
@testable import WireDomain
import WireDomainSupport
import XCTest

final class ConversationMLSMessageAddEventProcessorTests: XCTestCase {

    private var sut: ConversationMLSMessageAddEventProcessor!
    private var repository: MockMessageRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockMessageRepositoryProtocol()
        sut = ConversationMLSMessageAddEventProcessor(
            repository: repository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        repository = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Add_Message_Repo_Method() async throws {
        // Mock

        repository.addMessage_MockMethod = { _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(repository.addMessage_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let event = ConversationMLSMessageAddEvent(
            conversationID: ConversationID(uuid: UUID(), domain: "domain.com"),
            senderID: UserID(uuid: UUID(), domain: "domain.com"),
            subconversation: "",
            message: "",
            timestamp: .now
        )
    }
}
