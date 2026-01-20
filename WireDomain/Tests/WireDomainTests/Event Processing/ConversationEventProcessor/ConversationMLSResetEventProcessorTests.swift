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
import XCTest

@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class ConversationMLSResetEventProcessorTests: XCTestCase {

    private var sut: ConversationMLSResetEventProcessor!
    private var modelHelper: ModelHelper!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var mlsService: MockMLSServiceInterface!
    private var zmConversation: ZMConversation!
    private lazy var mockResetLockRepository = MockResetMLSConversationLockRepositoryProtocol()

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        conversationLocalStore = MockConversationLocalStoreProtocol()
        mlsService = MockMLSServiceInterface()

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID.id,
                domain: Scaffolding.conversationID.domain,
                in: context
            )
        }
        zmConversation = conversation

        mlsService.wipeGroup_MockMethod = { _ in }
        mlsService.conversationExistsGroupID_MockValue = false
        conversationLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationLocalStore
            .storeMLSConversationPendingJoinAfterResetNewMLSGroupIDConversation_MockMethod = { _, _ in }
        conversationLocalStore.storeMLSConversationEstablishedMlsGroupIDEpochConversation_MockMethod = { _, _, _ in }

        mockResetLockRepository.removeResetInitiatedConversationID_MockMethod = { _ in }
        mockResetLockRepository.wasResetInitiatedConversationID_MockValue = false

        sut = ConversationMLSResetEventProcessor(
            mlsService: mlsService,
            conversationLocalStore: conversationLocalStore,
            lockRepository: mockResetLockRepository
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
            conversationLocalStore.storeMLSConversationPendingJoinAfterResetNewMLSGroupIDConversation_Invocations.count,
            1
        )
        conversationLocalStore.storeMLSConversationPendingJoinAfterResetNewMLSGroupIDConversation_Invocations
            .forEach {
                XCTAssertEqual(
                    $0.newMLSGroupID,
                    MLSGroupID(Scaffolding.newMLSGroupIDData)
                )
            }
    }

    func testProcessEvent_AlreadyReset() async throws {
        // GIVEN
        let groupEpoch = UInt64(12)
        mlsService.conversationExistsGroupID_MockValue = true
        mlsService.epochFor_MockValue = groupEpoch
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
            conversationLocalStore.storeMLSConversationPendingJoinAfterResetNewMLSGroupIDConversation_Invocations.count,
            0
        )
        XCTAssertEqual(
            conversationLocalStore.storeMLSConversationEstablishedMlsGroupIDEpochConversation_Invocations.count,
            1
        )

        conversationLocalStore.storeMLSConversationEstablishedMlsGroupIDEpochConversation_Invocations
            .forEach {
                XCTAssertEqual(
                    $0.mlsGroupID,
                    MLSGroupID(Scaffolding.newMLSGroupIDData)
                )
                XCTAssertEqual($0.epoch, groupEpoch)
            }
    }

    func testProcessEvent_DoNothingWhenInitiatedFromSameDevice() async throws {

        mockResetLockRepository.wasResetInitiatedConversationID_MockValue = true

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(mockResetLockRepository.removeResetInitiatedConversationID_Invocations.count, 1)
        XCTAssertEqual(mlsService.wipeGroup_Invocations.count, 0)
        XCTAssertEqual(
            conversationLocalStore.storeMLSConversationPendingJoinAfterResetNewMLSGroupIDConversation_Invocations.count,
            0
        )
        XCTAssertEqual(mlsService.wipeGroup_Invocations.count, 0)
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

        let error = TestError(message: "some error")
        mlsService.wipeGroup_MockError = error

        // When and Then
        await XCTAssertThrowsErrorAsync(error) {
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
