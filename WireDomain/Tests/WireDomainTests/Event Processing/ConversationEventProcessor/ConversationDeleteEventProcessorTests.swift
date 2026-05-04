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
import WireNetwork
import XCTest
@testable import WireDomain

final class ConversationDeleteEventProcessorTests: XCTestCase {

    private var sut: ConversationDeleteEventProcessor!
    private var repository: MockConversationRepositoryProtocol!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        modelHelper = ModelHelper()
        repository = MockConversationRepositoryProtocol()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = ConversationDeleteEventProcessor(
            repository: repository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        modelHelper = nil
        repository = nil
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Delete_Conversation_Repo_Method() async throws {
        // Mock

        _ = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID.id,
                in: context
            )
        }

        repository.deleteConversationIdDomain_MockMethod = { _, _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(repository.deleteConversationIdDomain_Invocations.count, 1)
    }

    func testProcessEvent_It_Throws_Error_For_MLS_Conversation() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createMLSConversation(
                mlsGroupID: MLSGroupID(base64Encoded: Scaffolding.base64EncodedString),
                mlsStatus: .ready,
                conversationType: .group,
                epoch: 0,
                in: context
            )
        }

        repository.fetchConversationIdDomain_MockValue = conversation
        repository.deleteConversationIdDomain_MockError = Scaffolding.MockMLSError.failedToWipeGroup

        do {
            // When
            try await sut.processEvent(Scaffolding.event)
            XCTFail("It should throw an error.")
        } catch {
            // Then
            XCTAssertTrue(error is ConversationDeleteEventProcessor.Error)
        }
    }

    private enum Scaffolding {

        enum MockMLSError: Error {
            case failedToWipeGroup
        }

        static let id = UUID()

        static let domain = "domain.com"

        static let conversationID = ConversationID(id: id, domain: domain)

        static let base64EncodedString =
            "pQABARn//wKhAFggHsa0CszLXYLFcOzg8AA//E1+Dl1rDHQ5iuk44X0/PNYDoQChAFgg309rkhG6SglemG6kWae81P1HtQPx9lyb6wExTovhU4cE9g=="

        static let mlsServiceError = MockMLSError.failedToWipeGroup

        static let event = ConversationDeleteEvent(
            conversationID: conversationID,
            senderID: UserID(id: id, domain: domain),
            timestamp: .now
        )

    }

}
