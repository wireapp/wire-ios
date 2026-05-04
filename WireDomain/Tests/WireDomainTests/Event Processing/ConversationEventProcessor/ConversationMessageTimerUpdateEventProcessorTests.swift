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
import XCTest
@testable import WireDomain
@testable import WireNetwork

final class ConversationMessageTimerUpdateEventProcessorTests: XCTestCase {

    private var sut: ConversationMessageTimerUpdateEventProcessor!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var messageLocalStore: MockMessageLocalStoreProtocol!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()

        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()

        conversationLocalStore = MockConversationLocalStoreProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()

        sut = ConversationMessageTimerUpdateEventProcessor(
            conversationLocalStore: conversationLocalStore,
            messageLocalStore: messageLocalStore
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sut = nil
        conversationLocalStore = nil
        messageLocalStore = nil
        modelHelper = nil
        coreDataStack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Repo_Methods() async {
        // Mock

        let conversation = await context.perform { [self] in
            return modelHelper.createGroupConversation(in: context)
        }

        conversationLocalStore.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationLocalStore.conversationMessageDestructionTimeout_MockValue = .fiveMinutes
        conversationLocalStore.storeConversationTimeoutValueFor_MockMethod = { _, _ in }
        messageLocalStore
            .addSystemMessageMessageTypeConversationIDConversationDomain_MockMethod = { _, _, _ in }

        // When

        await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(conversationLocalStore.fetchOrCreateConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.conversationMessageDestructionTimeout_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.storeConversationTimeoutValueFor_Invocations.count, 1)
        XCTAssertEqual(
            messageLocalStore.addSystemMessageMessageTypeConversationIDConversationDomain_Invocations
                .count,
            1
        )
    }

    private enum Scaffolding {
        static let id = UUID()
        static let domain = "domain.com"
        static let event = ConversationMessageTimerUpdateEvent(
            conversationID: ConversationID(id: id, domain: domain),
            senderID: UserID(id: id, domain: domain),
            timestamp: .now,
            newTimer: 10_000
        )

    }

}
