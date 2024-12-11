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

import WireDomainSupport
import WireTestingPackage
import XCTest
@testable import WireDomain

final class MessageRepositoryTests: XCTestCase {

    private var sut: MessageRepository!
    private var localStore: MockMessageLocalStoreProtocol!
    private var conversationRepository: MockConversationRepositoryProtocol!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        localStore = MockMessageLocalStoreProtocol()
        conversationRepository = MockConversationRepositoryProtocol()

        sut = MessageRepository(
            localStore: localStore,
            conversationRepository: conversationRepository
        )
    }

    override func tearDown() async throws {
        stack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
        sut = nil
        localStore = nil
        conversationRepository = nil
    }

    // MARK: - Tests

    func testAddSystemMessageToConversation_It_Invokes_Local_Store_Method() async {
        // Mock

        localStore.addSystemMessageMessageTypeConversationIDConversationDomain_MockMethod = { _, _, _ in }

        // When

        await sut.addSystemMessage(
            messageType: .mlsMigrationMLSNotSupportedForSelfUser,
            conversationID: Scaffolding.conversationID,
            conversationDomain: Scaffolding.domain
        )

        // Then

        XCTAssertEqual(
            localStore.addSystemMessageToConversationMessageTypeConversationIDConversationDomain_Invocations.count,
            1
        )
    }

    private enum Scaffolding {
        static let conversationID = UUID.mockID1
        static let conversationDomain = "domain.com"
    }

}
