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
import WireSystem
import XCTest

@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class MLSMessageDecryptorTests: XCTestCase {

    private var sut: MLSMessageDecryptor!
    private var mlsService: MockMLSServiceInterface!
    private var mlsDecryptionService: MockMLSDecryptionServiceInterface!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var journal: Journal!

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        mlsService = MockMLSServiceInterface()
        mlsDecryptionService = MockMLSDecryptionServiceInterface()
        conversationLocalStore = MockConversationLocalStoreProtocol()
        journal = Journal(userID: UUID(), storage: UserDefaults.temporary())

        sut = makeSUT()
    }

    override func tearDown() async throws {
        stack = nil
        mlsService = nil
        mlsDecryptionService = nil
        conversationLocalStore = nil
        journal = nil
        modelHelper = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testDecryptedEventData_It_Decrypts_Add_Message_Event_And_Invokes_Repo_Methods() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            return modelHelper.createMLSConversation(
                id: Scaffolding.conversationID.id,
                mlsGroupID: Scaffolding.mlsGroupID,
                in: context
            )
        }

        let encryptedMessage = try XCTUnwrap("!?@".base64EncodedString)
        let decryptedMessage = try XCTUnwrap("foo".base64EncodedString)
        let decryptedMessageData = try XCTUnwrap(decryptedMessage.base64DecodedData)

        let mockDecryptionResult = MLSDecryptResult.message(
            decryptedMessageData,
            .randomAlphanumerical(length: 3)
        )

        conversationLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationLocalStore.mlsConversationInfoConversation_MockValue = (try XCTUnwrap(Scaffolding.mlsGroupID), true)
        mlsDecryptionService.decryptMessageForSubconversationTypeContext_MockValue = [mockDecryptionResult]

        // When

        let event = try await sut
            .decryptedMessageAddEventData(
                from: Scaffolding.makeAddMessageEvent(content: encryptedMessage),
                context: nil
            )

        // Then

        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.mlsConversationInfoConversation_Invocations.count, 1)
        XCTAssertEqual(mlsDecryptionService.decryptMessageForSubconversationTypeContext_Invocations.count, 1)
        XCTAssertEqual(event.decryptedMessages.first?.message, decryptedMessage)
    }

    func testDecryptedEventData_It_Decrypts_A_Welcome_Message_Event_And_Invokes_Repo_Methods() async throws {
        // Mock

        mlsDecryptionService.processWelcomeMessageWelcomeMessageContext_MockValue = Scaffolding.mlsGroupID
        conversationLocalStore
            .createMLSConversationConversationIDConversationDomainMlsGroupID_MockMethod = { _, _, _ in }

        // When

        try await sut.decryptedWelcomeMessageEventData(
            from: Scaffolding.makeWelcomeEvent(),
            context: nil
        )

        // Then

        XCTAssertEqual(mlsDecryptionService.processWelcomeMessageWelcomeMessageContext_Invocations.count, 1)
        XCTAssertEqual(
            conversationLocalStore.createMLSConversationConversationIDConversationDomainMlsGroupID_Invocations.count,
            1
        )
    }

    func testCancellation_stopsWelcomeMessageDecryption() async throws {
        // Mock
        mlsDecryptionService.processWelcomeMessageWelcomeMessageContext_MockValue = Scaffolding.mlsGroupID
        conversationLocalStore
            .createMLSConversationConversationIDConversationDomainMlsGroupID_MockMethod = { _, _, _ in }

        // When
        let task = Task {
            try await sut.decryptedWelcomeMessageEventData(
                from: Scaffolding.makeWelcomeEvent(),
                context: nil
            )
        }

        // Cancel the task before the decryption happens
        task.cancel()

        let result = await task.result

        // Then
        do {
            _ = try result.get()
            XCTFail("Expected CancellationError to be thrown")
        } catch is CancellationError {
            // Expected error
        } catch {
            XCTFail("Expected CancellationError but got \(error)")
        }

        // Verify that the MLS service was NOT called because we cancelled before decryption
        XCTAssertEqual(mlsDecryptionService.processWelcomeMessageWelcomeMessageContext_Invocations.count, 0)
        XCTAssertEqual(
            conversationLocalStore.createMLSConversationConversationIDConversationDomainMlsGroupID_Invocations.count,
            0
        )
    }

    func testCancellation_stopsMessageAddDecryption() async throws {
        // Mock
        let conversation = await context.perform { [self] in
            return modelHelper.createMLSConversation(
                id: Scaffolding.conversationID.id,
                mlsGroupID: Scaffolding.mlsGroupID,
                in: context
            )
        }

        let encryptedMessage = try XCTUnwrap("!?@".base64EncodedString)
        let decryptedMessage = try XCTUnwrap("foo".base64EncodedString)
        let decryptedMessageData = try XCTUnwrap(decryptedMessage.base64DecodedData)

        let mockDecryptionResult = MLSDecryptResult.message(
            decryptedMessageData,
            .randomAlphanumerical(length: 3)
        )

        conversationLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationLocalStore.mlsConversationInfoConversation_MockValue = (try XCTUnwrap(Scaffolding.mlsGroupID), true)
        mlsDecryptionService.decryptMessageForSubconversationTypeContext_MockValue = [mockDecryptionResult]

        // When
        let task = Task {
            try await sut.decryptedMessageAddEventData(
                from: Scaffolding.makeAddMessageEvent(content: encryptedMessage),
                context: nil
            )
        }

        // Cancel the task before the decryption happens
        task.cancel()

        let result = await task.result

        // Then
        do {
            _ = try result.get()
            XCTFail("Expected CancellationError to be thrown")
        } catch is CancellationError {
            // Expected error
        } catch {
            XCTFail("Expected CancellationError but got \(error)")
        }

        // Verify that conversation was fetched but decryption was NOT called
        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.mlsConversationInfoConversation_Invocations.count, 1)
        XCTAssertEqual(mlsDecryptionService.decryptMessageForSubconversationTypeContext_Invocations.count, 0)
    }

    // MARK: - Buffered messages recovery

    func testBufferedMessages_WithinThreshold_ReturnsEventWithoutDecryptedMessages() async throws {
        // Given
        try await mockMLSConversation()
        let groupID = try XCTUnwrap(Scaffolding.mlsGroupID)
        mockDecryptionThrowing(.bufferedMessage(groupID: groupID))

        // When
        let firstEvent = try await sut.decryptedMessageAddEventData(
            from: Scaffolding.makeAddMessageEvent(content: "", timestamp: Scaffolding.timestamp),
            context: nil
        )
        let secondEvent = try await sut.decryptedMessageAddEventData(
            from: Scaffolding.makeAddMessageEvent(content: "", timestamp: Scaffolding.timestamp + 60),
            context: nil
        )

        // Then
        XCTAssertTrue(firstEvent.decryptedMessages.isEmpty)
        XCTAssertTrue(secondEvent.decryptedMessages.isEmpty)
    }

    func testBufferedMessages_BeyondThreshold_ThrowsRecoveryRequiredForBufferedGroup() async throws {
        // Given
        try await mockMLSConversation()
        let subgroupID = MLSGroupID.random()
        mockDecryptionThrowing(.bufferedMessage(groupID: subgroupID))

        _ = try await sut.decryptedMessageAddEventData(
            from: Scaffolding.makeAddMessageEvent(content: "", timestamp: Scaffolding.timestamp),
            context: nil
        )

        // When / Then
        do {
            _ = try await sut.decryptedMessageAddEventData(
                from: Scaffolding.makeAddMessageEvent(content: "", timestamp: Scaffolding.timestamp + 61),
                context: nil
            )
            XCTFail("Expected recovery to be required")
        } catch let MLSMessageDecryptorError.bufferedMessageRecoveryRequired(mlsGroupID) {
            XCTAssertEqual(mlsGroupID, subgroupID)
        }
    }

    func testBufferedMessages_SuccessfulDecryptionInBetween_StartsNewWindow() async throws {
        // Given
        try await mockMLSConversation()
        let groupID = try XCTUnwrap(Scaffolding.mlsGroupID)
        var results: [Result<[MLSDecryptResult], any Error>] = [
            .failure(MLSDecryptionService.MLSMessageDecryptionError.bufferedMessage(groupID: groupID)),
            .success([]),
            .failure(MLSDecryptionService.MLSMessageDecryptionError.bufferedMessage(groupID: groupID))
        ]
        mlsDecryptionService.decryptMessageForSubconversationTypeContext_MockMethod = { _, _, _, _ in
            try results.removeFirst().get()
        }

        // When / Then
        for offset: TimeInterval in [0, 120, 240] {
            _ = try await sut.decryptedMessageAddEventData(
                from: Scaffolding.makeAddMessageEvent(content: "", timestamp: Scaffolding.timestamp + offset),
                context: nil
            )
        }
    }

    func testBufferedMessages_WrongEpochInBetween_StartsNewWindow() async throws {
        // Given
        try await mockMLSConversation()
        let groupID = try XCTUnwrap(Scaffolding.mlsGroupID)
        var errors: [MLSDecryptionService.MLSMessageDecryptionError] = [
            .bufferedMessage(groupID: groupID),
            .wrongEpoch,
            .bufferedMessage(groupID: groupID)
        ]
        mlsDecryptionService.decryptMessageForSubconversationTypeContext_MockMethod = { _, _, _, _ in
            throw errors.removeFirst()
        }

        // When
        _ = try await sut.decryptedMessageAddEventData(
            from: Scaffolding.makeAddMessageEvent(content: "", timestamp: Scaffolding.timestamp),
            context: nil
        )
        do {
            _ = try await sut.decryptedMessageAddEventData(
                from: Scaffolding.makeAddMessageEvent(content: "", timestamp: Scaffolding.timestamp + 120),
                context: nil
            )
            XCTFail("Expected wrong epoch error")
        } catch MLSMessageDecryptorError.wrongEpoch {
            // Expected
        }
        let event = try await sut.decryptedMessageAddEventData(
            from: Scaffolding.makeAddMessageEvent(content: "", timestamp: Scaffolding.timestamp + 240),
            context: nil
        )

        // Then
        XCTAssertTrue(event.decryptedMessages.isEmpty)
    }

    func testBufferedMessages_BeyondThresholdAcrossDecryptorInstances_ThrowsRecoveryRequired() async throws {
        // Given
        // Simulates the notification service extension, which creates a new decryptor for each payload.
        try await mockMLSConversation()
        let groupID = try XCTUnwrap(Scaffolding.mlsGroupID)
        mockDecryptionThrowing(.bufferedMessage(groupID: groupID))

        _ = try await makeSUT().decryptedMessageAddEventData(
            from: Scaffolding.makeAddMessageEvent(content: "", timestamp: Scaffolding.timestamp),
            context: nil
        )

        // When / Then
        do {
            _ = try await makeSUT().decryptedMessageAddEventData(
                from: Scaffolding.makeAddMessageEvent(content: "", timestamp: Scaffolding.timestamp + 61),
                context: nil
            )
            XCTFail("Expected recovery to be required")
        } catch let MLSMessageDecryptorError.bufferedMessageRecoveryRequired(mlsGroupID) {
            XCTAssertEqual(mlsGroupID, groupID)
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> MLSMessageDecryptor {
        MLSMessageDecryptor(
            mlsDecryptionService: mlsDecryptionService,
            conversationLocalStore: conversationLocalStore,
            bufferedMessageRecoveryTracker: BufferedMLSMessageRecoveryTracker(journal: journal)
        )
    }

    private func mockMLSConversation() async throws {
        let conversation = await context.perform { [self] in
            modelHelper.createMLSConversation(
                id: Scaffolding.conversationID.id,
                mlsGroupID: Scaffolding.mlsGroupID,
                in: context
            )
        }
        conversationLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationLocalStore.mlsConversationInfoConversation_MockValue = (try XCTUnwrap(Scaffolding.mlsGroupID), true)
    }

    private func mockDecryptionThrowing(_ error: MLSDecryptionService.MLSMessageDecryptionError) {
        mlsDecryptionService.decryptMessageForSubconversationTypeContext_MockMethod = { _, _, _, _ in
            throw error
        }
    }

    private enum Scaffolding {

        static let localDomain = "local.com"

        static let selfUserID = UserID(id: UUID(), domain: localDomain)
        static let selfClientID = "selfClientID"
        static let selfClientNumberOfKeys: Int32 = 10

        static let aliceID = UserID(id: UUID(), domain: localDomain)
        static let aliceClientID1 = "aliceClientID1"
        static let aliceClientID2 = "aliceClientID2"

        static let conversationID = ConversationID(id: UUID(), domain: localDomain)
        static let timestamp = Date()

        static let base64EncodedString = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="

        static let mlsGroupID = MLSGroupID(base64Encoded: base64EncodedString)

        static func makeAddMessageEvent(
            content: String,
            timestamp: Date = timestamp
        ) -> ConversationMLSMessageAddEvent {
            ConversationMLSMessageAddEvent(
                conversationID: conversationID,
                senderID: aliceID,
                subconversation: nil,
                message: content,
                timestamp: timestamp,
                decryptedMessages: []
            )
        }

        static func makeWelcomeEvent() -> ConversationMLSWelcomeEvent {
            ConversationMLSWelcomeEvent(
                conversationID: conversationID,
                senderID: UserID(id: .mockID1, domain: ""),
                welcomeMessage: ""
            )
        }

    }

}
