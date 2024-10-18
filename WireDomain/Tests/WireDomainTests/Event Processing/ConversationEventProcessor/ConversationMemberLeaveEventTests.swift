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

final class ConversationMemberLeaveEventProcessorTests: XCTestCase {

    private var sut: ConversationMemberLeaveEventProcessor!
    private var repository: MockConversationRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockConversationRepositoryProtocol()
        sut = ConversationMemberLeaveEventProcessor(
            repository: repository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        repository = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Remove_Members_Repo_Method() async throws {
        // Mock

        repository.removeMembersFromInitiatedByAtReason_MockMethod = { _, _, _, _, _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(repository.removeMembersFromInitiatedByAtReason_Invocations.count, 1)
    }
    
    func testProcessEvent_It_Throws_Error() async throws {
        // Mock
        
        enum MockError: Error {
            case failed
        }

        repository.removeMembersFromInitiatedByAtReason_MockError = MockError.failed
        
        do {
            // When
            try await sut.processEvent(Scaffolding.event)
        } catch {
            // Then
            XCTAssertTrue(error is ConversationMemberLeaveEventProcessor.Error)
        }
    }

    private enum Scaffolding {
        static let event = ConversationMemberLeaveEvent(
            conversationID: ConversationID(uuid: UUID(), domain: "domain.com"),
            senderID: UserID(uuid: UUID(), domain: "domain.com"),
            timestamp: .now,
            removedUserIDs: [],
            reason: .userDeleted
        )
    }
}

