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
import WireDataModel
import WireDataModelSupport
@testable import WireDomain
import WireDomainSupport
import XCTest

final class ConversationAccessUpdateEventProcessorTests: XCTestCase {

    private var sut: ConversationAccessUpdateEventProcessor!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!
    private var repository: MockConversationRepositoryProtocol!
    private var localStore: MockConversationLocalStoreProtocol!

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        repository = MockConversationRepositoryProtocol()
        localStore = MockConversationLocalStoreProtocol()

        sut = ConversationAccessUpdateEventProcessor(
            repository: repository,
            localStore: localStore
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        coreDataStack = nil
        sut = nil
        repository = nil
        modelHelper = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        localStore = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Local_Store_And_Repo_Methods() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.id,
                domain: Scaffolding.domain,
                in: context
            )
        }

        repository.fetchOrCreateConversationWithDomain_MockValue = conversation
        localStore.updateAccessesForAccessModesAccessRoles_MockMethod = { _, _, _ in }

        // When

        await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(repository.fetchOrCreateConversationWithDomain_Invocations.count, 1)
        XCTAssertEqual(localStore.updateAccessesForAccessModesAccessRoles_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let id = UUID()
        static let domain = "domain.com"
        static let conversationID = ConversationID(uuid: id, domain: domain)
        static let senderID = UserID(uuid: id, domain: domain)

        static let event = ConversationAccessUpdateEvent(
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.senderID,
            accessModes: [.invite, .link],
            accessRoles: [.teamMember],
            legacyAccessRole: .team
        )
    }

}
