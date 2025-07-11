//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class ConversationMLSResetEventProcessorTests: XCTestCase {

    private var sut: ConversationMLSResetEventProcessor!
    private var modelHelper: ModelHelper!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var mlsService: MockMLSServiceInterface!
//    private var mlsDecryptionService: MockMLSDecryptionServiceInterface!
//    private var oneOnOneResolver: MockOneOnOneResolverProtocol!

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        conversationLocalStore = MockConversationLocalStoreProtocol()
//        userLocalStore = MockUserLocalStoreProtocol()
        mlsService = MockMLSServiceInterface()
//        mlsDecryptionService = MockMLSDecryptionServiceInterface()
//        oneOnOneResolver = MockOneOnOneResolverProtocol()

        sut = ConversationMLSResetEventProcessor(
            mlsService: mlsService,
            conversationLocalStore: conversationLocalStore
        )
    }

    override func tearDown() async throws {
        modelHelper = nil
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        conversationLocalStore = nil
        mlsService = nil
//        mlsDecryptionService = nil
//        oneOnOneResolver = nil
    }

    // MARK: - Tests

    func testProcessEvent() async throws {

        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID.uuid,
                domain: Scaffolding.conversationID.domain,
                in: context
            )
        }

//        mlsDecryptionService.processWelcomeMessageWelcomeMessageContext_MockValue = Scaffolding.mlsGroupID
//        conversationRepository.fetchConversationIdDomain_MockValue = conversation
        conversationLocalStore.storeMLSConversationEstablishedMlsGroupIDConversation_MockMethod = { _, _ in }
        conversationLocalStore.updateOrCreateMLSGroupGroupID_MockMethod = { _ in }
        mlsService.uploadKeyPackagesIfNeeded_MockMethod = {}
//        oneOnOneResolver.resolveOneOnOneConversationWith_MockMethod = { _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

//        XCTAssertEqual(mlsDecryptionService.processWelcomeMessageWelcomeMessageContext_Invocations.count, 1)
//        XCTAssertEqual(conversationRepository.fetchConversationIdDomain_Invocations.count, 1)
//        XCTAssertEqual(
//            conversationLocalStore.storeMLSConversationEstablishedMlsGroupIDConversation_Invocations.count,
//            1
//        )
//        XCTAssertEqual(conversationLocalStore.updateOrCreateMLSGroupGroupID_Invocations.count, 1)
//        XCTAssertEqual(mlsService.uploadKeyPackagesIfNeeded_Invocations.count, 1)
//        XCTAssertEqual(conversationLocalStore.fetchOtherUserIDInOneOnOneConversationConversation_Invocations.count, 1)
//        XCTAssertEqual(oneOnOneResolver.resolveOneOnOneConversationWith_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let domain = "domain.com"
        static let conversationID = ConversationID(uuid: .mockID1, domain: domain)
        static let senderID = UserID(uuid: .mockID2, domain: domain)

        static let event = ConversationMLSResetEvent(
            conversationID: conversationID,
            senderID: senderID,
            oldMLSGroupIDBase64: Data.random().base64EncodedString(),
            newMLSGroupIDBase64: Data.random().base64EncodedString()
        )
    }

}
