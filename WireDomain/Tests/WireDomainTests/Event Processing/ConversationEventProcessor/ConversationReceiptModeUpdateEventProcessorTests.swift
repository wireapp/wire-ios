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
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import XCTest

final class ConversationReceiptModeUpdateEventProcessorTests: XCTestCase {

    private var sut: ConversationReceiptModeUpdateEventProcessor!
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
        sut = ConversationReceiptModeUpdateEventProcessor(
            userRepository: userRepository,
            conversationRepository: conversationRepository,
            conversationLocalStore: conversationLocalStore
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        modelHelper = nil
        coreDataStack = nil
        userRepository = nil
        conversationRepository = nil
        conversationLocalStore = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Repo_And_Local_Store_Methods() async throws {
        // Mock
        
        let (user, conversation) = await context.perform { [self] in
            let user = modelHelper.createUser(in: context)
            let conversation = modelHelper.createGroupConversation(in: context)
            
            return (user, conversation)
        }
    
        userRepository.fetchUserWithDomain_MockValue = user
        conversationRepository.fetchConversationWithDomain_MockValue = conversation
        conversationRepository.addSystemMessageTo_MockMethod = { _, _ in }
        conversationLocalStore.storeConversationHasReadReceiptsEnabledFor_MockMethod = { _, _ in }
        conversationLocalStore.isConversationArchived_MockValue = true
        conversationLocalStore.conversationMutedMessageTypes_MockValue = MutedMessageTypes.none
        conversationLocalStore.storeConversationIsArchivedFor_MockMethod = { _, _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(userRepository.fetchUserWithDomain_Invocations.count, 1)
        XCTAssertEqual(conversationRepository.fetchConversationWithDomain_Invocations.count, 1)
        XCTAssertEqual(conversationRepository.addSystemMessageTo_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.storeConversationHasReadReceiptsEnabledFor_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.isConversationArchived_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.conversationMutedMessageTypes_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.storeConversationIsArchivedFor_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let id = UUID()
        static let domain = "domain.com"
        static let event = ConversationReceiptModeUpdateEvent(
            conversationID: ConversationID(uuid: id, domain: domain),
            senderID: UserID(uuid: id, domain: domain),
            newRecieptMode: 1
        )
    }
}

