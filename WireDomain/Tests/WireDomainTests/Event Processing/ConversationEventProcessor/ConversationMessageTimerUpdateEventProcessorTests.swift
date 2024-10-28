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
import WireDataModel
import WireDataModelSupport
@testable import WireDomain
import WireDomainSupport
import XCTest

final class ConversationMessageTimerUpdateEventProcessorTests: XCTestCase {

    private var sut: ConversationMessageTimerUpdateEventProcessor!
    private var userRepository: MockUserRepositoryProtocol!
    private var conversationRepository: MockConversationRepositoryProtocol!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
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

        userRepository = MockUserRepositoryProtocol()
        conversationRepository = MockConversationRepositoryProtocol()
        conversationLocalStore = MockConversationLocalStoreProtocol()

        sut = ConversationMessageTimerUpdateEventProcessor(
            userRepository: userRepository,
            conversationRepository: conversationRepository,
            conversationLocalStore: conversationLocalStore
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sut = nil
        userRepository = nil
        conversationRepository = nil
        conversationLocalStore = nil
        modelHelper = nil
        coreDataStack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Repo_Methods() async {
        // Mock

        let (user, conversation) = await context.perform { [self] in
            let user = modelHelper.createUser(in: context)
            let conversation = modelHelper.createGroupConversation(in: context)

            return (user, conversation)
        }

        userRepository.fetchOrCreateUserWithDomain_MockValue = user
        conversationRepository.fetchOrCreateConversationWithDomain_MockValue = conversation
        conversationRepository.addSystemMessageTo_MockMethod = { _, _ in }
        conversationLocalStore.conversationMessageDestructionTimeout_MockValue = .fiveMinutes
        conversationLocalStore.storeConversationTimeoutValueFor_MockMethod = { _, _ in }

        // When

        await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(userRepository.fetchOrCreateUserWithDomain_Invocations.count, 1)
        XCTAssertEqual(conversationRepository.fetchOrCreateConversationWithDomain_Invocations.count, 1)
        XCTAssertEqual(conversationRepository.addSystemMessageTo_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.conversationMessageDestructionTimeout_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.storeConversationTimeoutValueFor_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let id = UUID()
        static let domain = "domain.com"
        static let event = ConversationMessageTimerUpdateEvent(
            conversationID: ConversationID(uuid: id, domain: domain),
            senderID: UserID(uuid: id, domain: domain),
            timestamp: .now,
            newTimer: 10_000
        )

    }

}
