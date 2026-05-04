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

final class ConversationTypingEventProcessorTests: XCTestCase {

    private var sut: ConversationTypingEventProcessor!
    private var userRepository: MockUserRepositoryProtocol!
    private var conversationRepository: MockConversationRepositoryProtocol!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!
    private var didProcessTypingUsers = false

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        userRepository = MockUserRepositoryProtocol()
        conversationRepository = MockConversationRepositoryProtocol()
        conversationLocalStore = MockConversationLocalStoreProtocol()

        sut = ConversationTypingEventProcessor(
            conversationRepository: conversationRepository,
            conversationLocalStore: conversationLocalStore,
            userRepository: userRepository,
            onProcessedTypingUsers: { _ in self.didProcessTypingUsers = true }
        )
    }

    override func tearDown() async throws {
        modelHelper = nil
        coreDataStack = nil
        userRepository = nil
        conversationRepository = nil
        conversationLocalStore = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        didProcessTypingUsers = false
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Repo_And_Local_Store_Methods() async throws {

        // Mock

        let (user, conversation) = await context.perform { [self] in
            let user = modelHelper.createUser(in: context)
            let conversation = modelHelper.createGroupConversation(in: context)

            return (user, conversation)
        }

        userRepository.fetchOrCreateUserIdDomain_MockValue = user
        conversationRepository.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationLocalStore.obtainPermanentIDsUserConversation_MockMethod = { _, _ in }

        // When

        await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(conversationLocalStore.obtainPermanentIDsUserConversation_Invocations.count, 1)
        XCTAssertEqual(userRepository.fetchOrCreateUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationRepository.fetchOrCreateConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(didProcessTypingUsers, true)
    }

    private enum Scaffolding {
        static let id = UUID()
        static let domain = "domain.com"
        static let event = ConversationTypingEvent(
            conversationID: ConversationID(id: id, domain: domain),
            senderID: UserID(id: id, domain: domain),
            isTyping: true
        )
    }
}
