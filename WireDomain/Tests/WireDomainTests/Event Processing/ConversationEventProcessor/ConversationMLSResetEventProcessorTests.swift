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
    private var zmConversation: ZMConversation!
    private var mockFeatureRepository: MockFeatureRepositoryInterface!

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        conversationLocalStore = MockConversationLocalStoreProtocol()
        mlsService = MockMLSServiceInterface()
        mockFeatureRepository = .init()
        mockFeatureRepository.fetchAllowGlobalOperations_MockValue = .init(
            status: .enabled,
            config: .init(mlsConversationReset: true)
        )

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID.id,
                domain: Scaffolding.conversationID.domain,
                in: context
            )
        }
        zmConversation = conversation

        mlsService.wipeGroup_MockMethod = { _ in }
        conversationLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationLocalStore.storeMLSConversationPendingJoinNewMLSGroupIDConversation_MockMethod = { _, _ in }

        sut = ConversationMLSResetEventProcessor(
            mlsService: mlsService,
            conversationLocalStore: conversationLocalStore,
            featureRepository: mockFeatureRepository
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
    }

    // MARK: - Tests

    func testProcessEvent() async throws {

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(mlsService.wipeGroup_Invocations.count, 1)
        mlsService.wipeGroup_Invocations
            .forEach {
                XCTAssertEqual(
                    $0,
                    MLSGroupID(Scaffolding.oldMLSGroupIDData)
                )
            }

        XCTAssertEqual(
            conversationLocalStore.storeMLSConversationPendingJoinNewMLSGroupIDConversation_Invocations.count,
            1
        )
        conversationLocalStore.storeMLSConversationPendingJoinNewMLSGroupIDConversation_Invocations
            .forEach {
                XCTAssertEqual(
                    $0.newMLSGroupID,
                    MLSGroupID(Scaffolding.newMLSGroupIDData)
                )
            }
    }

    func testProcessEvent_DoNothingWhenFFIsOff() async throws {

        mockFeatureRepository.fetchAllowGlobalOperations_MockValue = .init(
            status: .disabled,
            config: .init(mlsConversationReset: false)
        )

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(mlsService.wipeGroup_Invocations.count, 0)

        XCTAssertEqual(
            conversationLocalStore.storeMLSConversationPendingJoinNewMLSGroupIDConversation_Invocations.count,
            0
        )
    }

    func testNoConversationFound() async throws {

        // Given

        conversationLocalStore.fetchConversationIdDomain_MockValue = .some(nil)

        // When and Then
        await XCTAssertThrowsErrorAsync(ConversationMLSResetEventProcessor.Failure.conversationNotFound) {
            try await self.sut.processEvent(Scaffolding.event)
        }
    }

    func testErrorOnWipeGroup() async throws {

        // Given

        mlsService.wipeGroup_MockError = TestError(message: "some error")

        // When and Then
        await XCTAssertThrowsErrorAsync(
            ConversationMLSResetEventProcessor.Failure.failedToWipeMLSConversation
        ) {
            try await self.sut.processEvent(Scaffolding.event)
        }
    }

    private enum Scaffolding {
        static let domain = "domain.com"
        static let conversationID = ConversationID(id: .mockID1, domain: domain)
        static let senderID = UserID(id: .mockID2, domain: domain)
        static let oldMLSGroupIDData = Data.random()
        static let newMLSGroupIDData = Data.random()

        static let event = ConversationMLSResetEvent(
            conversationID: conversationID,
            senderID: senderID,
            oldMLSGroupIDBase64: oldMLSGroupIDData.base64EncodedString(),
            newMLSGroupIDBase64: newMLSGroupIDData.base64EncodedString()
        )
    }

}
