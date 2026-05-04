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

import GenericMessageProtocol
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import XCTest

@testable import WireDomain
@testable import WireNetwork

final class ConversationProteusMessageAddEventProcessorTests: XCTestCase {

    private var sut: ConversationProteusMessageAddEventProcessor!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var messageLocalStore: MockMessageLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var protobufMessageProcessor: MockConversationProtobufMessageProcessorProtocol!

    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var callEventInfo: CallEventInfo?

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()

        conversationLocalStore = MockConversationLocalStoreProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()
        protobufMessageProcessor = MockConversationProtobufMessageProcessorProtocol()

        sut = ConversationProteusMessageAddEventProcessor(
            conversationLocalStore: conversationLocalStore,
            messageLocalStore: messageLocalStore,
            userLocalStore: userLocalStore,
            protobufMessageProcessor: protobufMessageProcessor,
            onProcessedCallEvent: { self.callEventInfo = $0 }
        )
    }

    override func tearDown() async throws {
        conversationLocalStore = nil
        messageLocalStore = nil
        userLocalStore = nil
        modelHelper = nil
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Local_Stores_And_Protobuf_Processor_Methods() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        conversationLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationLocalStore
            .updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate_MockMethod = { _, _, _ in }
        conversationLocalStore.addParticipantIfNeededParticipantIDParticipantDomainInDate_MockMethod = { _, _, _, _ in }
        messageLocalStore.canAddMessageConversationSenderID_MockValue = true
        protobufMessageProcessor
            .processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_MockMethod =
            { _, _, _, _, _, _, _ in }

        // When

        try await sut.processEvent(Scaffolding.largeMessageEvent)

        // Then

        XCTAssertEqual(
            conversationLocalStore.updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate_Invocations
                .count,
            1
        )
        XCTAssertEqual(
            conversationLocalStore.addParticipantIfNeededParticipantIDParticipantDomainInDate_Invocations.count,
            1
        )
        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(messageLocalStore.canAddMessageConversationSenderID_Invocations.count, 1)
        XCTAssertEqual(
            protobufMessageProcessor
                .processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_Invocations
                .count,
            1
        )
        XCTAssertNil(callEventInfo)

        let processProtobufMessageInvocation = try XCTUnwrap(
            protobufMessageProcessor
                .processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_Invocations
                .first
        )

        // Ensuring large message payload has been correctly processed by protobuf processor.
        switch processProtobufMessageInvocation.message.content {
        case let .text(text):
            XCTAssertEqual(text.content, Scaffolding.mockDecryptedLargeMessagePayload)
        default:
            XCTFail("External message content should have been decrypted.")
        }
    }

    func testProcessEvent_It_Invokes_Local_Stores_And_Protobuf_Processor_Methods_Message_Is_Regular() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        conversationLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationLocalStore
            .updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate_MockMethod = { _, _, _ in }
        conversationLocalStore.addParticipantIfNeededParticipantIDParticipantDomainInDate_MockMethod = { _, _, _, _ in }
        messageLocalStore.canAddMessageConversationSenderID_MockValue = true
        protobufMessageProcessor
            .processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_MockMethod =
            { _, _, _, _, _, _, _ in }

        // When

        try await sut.processEvent(Scaffolding.regularMessageEvent)

        // Then

        XCTAssertEqual(
            conversationLocalStore.updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate_Invocations
                .count,
            1
        )
        XCTAssertEqual(
            conversationLocalStore.addParticipantIfNeededParticipantIDParticipantDomainInDate_Invocations.count,
            1
        )
        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(messageLocalStore.canAddMessageConversationSenderID_Invocations.count, 1)
        XCTAssertEqual(
            protobufMessageProcessor
                .processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_Invocations
                .count,
            1
        )

        XCTAssertNil(callEventInfo)

        let processProtobufMessageInvocation = try XCTUnwrap(
            protobufMessageProcessor
                .processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_Invocations
                .first
        )

        // Ensuring regular message payload has been correctly processed by protobuf processor.
        switch processProtobufMessageInvocation.message.content {
        case let .text(text):
            let regularMessageText = "Everything"
            XCTAssertEqual(text.content, regularMessageText)

        default:
            XCTFail("Should be external message.")
        }
    }

    func testProcessEvent_Message_Has_Calling_It_Invokes_Handler_With_Call_Event_Info() async throws {

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        conversationLocalStore.fetchConversationIdDomain_MockValue = conversation
        messageLocalStore.canAddMessageConversationSenderID_MockValue = true

        // When

        try await sut.processEvent(Scaffolding.callingMessageEvent)

        // Then

        XCTAssertNotNil(callEventInfo) // There's a call, we got the call info.
    }

    enum Scaffolding {
        static let domain = "domain.com"

        static let regularMessage = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="
        static let externalMessage =
            "CiQzMzRmN2Y3Yi1hNDk5LTQ1MTMtOTJhOC1hZTg4MDI0OTQ0ZTlCRAog4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7wSIJCkkpWzMVxHXfu33pMQfEK+u/5qY426AbK9sC3Fu8Mx"

        static let largeMessageEvent = ConversationProteusMessageAddEvent(
            conversationID: ConversationID(id: .mockID1, domain: domain),
            senderID: UserID(id: .mockID1, domain: domain),
            timestamp: .now,
            message: .init(encryptedMessage: "", decryptedMessage: externalMessage),
            // Large message payload -> message is external
            externalData: .init(encryptedMessage: mockEncryptedLargeMessagePayload), // Large encrypted message payload
            messageSenderClientID: UUID.mockID1.uuidString,
            messageRecipientClientID: UUID.mockID2.uuidString
        )

        static let regularMessageEvent = ConversationProteusMessageAddEvent(
            conversationID: ConversationID(id: .mockID1, domain: domain),
            senderID: UserID(id: .mockID1, domain: domain),
            timestamp: .now,
            message: .init(encryptedMessage: "", decryptedMessage: regularMessage),
            // Message is regular, no external data payload
            messageSenderClientID: UUID.mockID1.uuidString,
            messageRecipientClientID: UUID.mockID2.uuidString
        )

        static let callingMessageEvent = ConversationProteusMessageAddEvent(
            conversationID: ConversationID(id: .mockID1, domain: domain),
            senderID: UserID(id: .mockID1, domain: domain),
            timestamp: .now,
            message: .init(encryptedMessage: "", decryptedMessage: text!),
            // Message has calling
            messageSenderClientID: UUID.mockID1.uuidString,
            messageRecipientClientID: UUID.mockID2.uuidString
        )

        private static let message = GenericMessage(
            content: Calling(content: content, conversationId: .random())
        )

        private static let text = try? message.serializedData().base64String()

        private static let content: String = {
            let json = [
                "src_userid": UUID.mockID1.uuidString,
                "src_clientid": "clientID",
                "resp": false,
                "type": ""
            ] as [String: Any]

            let data = try! JSONSerialization.data(withJSONObject: json, options: [])
            return String(decoding: data, as: UTF8.self)
        }()

    }
}
