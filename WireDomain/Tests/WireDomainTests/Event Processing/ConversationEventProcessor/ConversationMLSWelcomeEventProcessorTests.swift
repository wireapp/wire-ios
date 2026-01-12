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

final class ConversationMLSWelcomeEventProcessorTests: XCTestCase {

    private var sut: ConversationMLSWelcomeEventProcessor!
    private var modelHelper: ModelHelper!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var conversationRepository: MockConversationRepositoryProtocol!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var mlsService: MockMLSServiceInterface!
    private var mlsDecryptionService: MockMLSDecryptionServiceInterface!
    private var oneOnOneResolver: MockOneOnOneResolverProtocol!

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        conversationRepository = MockConversationRepositoryProtocol()
        conversationLocalStore = MockConversationLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()
        mlsService = MockMLSServiceInterface()
        mlsDecryptionService = MockMLSDecryptionServiceInterface()
        oneOnOneResolver = MockOneOnOneResolverProtocol()

        sut = ConversationMLSWelcomeEventProcessor(
            conversationRepository: conversationRepository,
            conversationLocalStore: conversationLocalStore,
            mlsService: mlsService,
            mlsDecryptionService: mlsDecryptionService,
            oneOnOneResolver: oneOnOneResolver
        )
    }

    override func tearDown() async throws {
        modelHelper = nil
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        conversationRepository = nil
        conversationLocalStore = nil
        userLocalStore = nil
        mlsService = nil
        mlsDecryptionService = nil
        oneOnOneResolver = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Repository_Local_Store_And_MLS_Services_Methods() async throws {

        // Mock

        let conversation = await context.perform { [modelHelper, context] in
            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID.id,
                domain: Scaffolding.conversationID.domain,
                in: context
            )
        }

        mlsDecryptionService.processWelcomeMessageWelcomeMessageContext_MockValue = Scaffolding.mlsGroupID
        conversationRepository.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationLocalStore.storeMLSConversationEstablishedMlsGroupIDConversation_MockMethod = { _, _ in }
        conversationLocalStore.updateOrCreateMLSGroupGroupID_MockMethod = { _ in }
        mlsService.uploadKeyPackagesIfNeeded_MockMethod = {}
        conversationLocalStore.fetchOtherUserIDInOneOnOneConversationConversation_MockValue = Scaffolding.qualifiedID
        oneOnOneResolver
            .resolveOneOnOneConversationWith_MockMethod = { _ in
                .migratedToMLSGroup(identifier: Scaffolding.mlsGroupID)
            }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(mlsDecryptionService.processWelcomeMessageWelcomeMessageContext_Invocations.count, 1)
        XCTAssertEqual(conversationRepository.fetchOrCreateConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(
            conversationLocalStore.storeMLSConversationEstablishedMlsGroupIDConversation_Invocations.count,
            1
        )
        XCTAssertEqual(conversationLocalStore.updateOrCreateMLSGroupGroupID_Invocations.count, 1)
        XCTAssertEqual(mlsService.uploadKeyPackagesIfNeeded_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.fetchOtherUserIDInOneOnOneConversationConversation_Invocations.count, 1)
        XCTAssertEqual(oneOnOneResolver.resolveOneOnOneConversationWith_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let domain = "domain.com"
        static let conversationID = ConversationID(id: .mockID1, domain: domain)
        static let senderID = UserID(id: .mockID2, domain: domain)
        static let mlsGroupID = MLSGroupID.random()
        static let qualifiedID = WireDataModel.QualifiedID(uuid: .mockID1, domain: domain)

        static let event = ConversationMLSWelcomeEvent(
            conversationID: conversationID,
            senderID: senderID,
            welcomeMessage: Data.random().base64EncodedString()
        )
    }

}
