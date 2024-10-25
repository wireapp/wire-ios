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

final class ConversationCreateEventProcessorTests: XCTestCase {

    private var sut: ConversationCreateEventProcessor!
    private var repository: MockConversationRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockConversationRepositoryProtocol()

        sut = ConversationCreateEventProcessor(
            repository: repository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sut = nil
        repository = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Repo_Methods() async {
        // Mock

        repository.fetchConversationWithDomain_MockMethod = { _, _ in nil }
        repository.storeConversationTimestamp_MockMethod = { _, _ in }

        // When

        await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(repository.fetchConversationWithDomain_Invocations.count, 1)
        XCTAssertEqual(repository.storeConversationTimestamp_Invocations.count, 1)
    }

    private enum Scaffolding {

        static let conversationID = ConversationID(uuid: UUID(), domain: "domain.com")

        static let senderID = UserID(uuid: UUID(), domain: "domain.com")

        static let conversation = WireAPI.Conversation(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!,
            qualifiedID: .init(uuid: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!, domain: "example.com"),
            teamID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!,
            type: .group,
            messageProtocol: .proteus,
            mlsGroupID: "",
            cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
            epoch: 0,
            epochTimestamp: nil,
            creator: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!,
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

        static let event = ConversationCreateEvent(
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.senderID,
            timestamp: .now,
            conversation: conversation
        )

    }

}
