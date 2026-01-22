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

final class ConversationMLSMessageAddEventProcessorTests: XCTestCase {

    private var sut: ConversationMLSMessageAddEventProcessor!
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

        sut = ConversationMLSMessageAddEventProcessor(
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

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(messageLocalStore.canAddMessageConversationSenderID_Invocations.count, 1)
        XCTAssertEqual(
            protobufMessageProcessor
                .processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_Invocations
                .count,
            1
        )
        XCTAssertEqual(
            conversationLocalStore.updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate_Invocations
                .count,
            1
        )
        XCTAssertEqual(
            conversationLocalStore.addParticipantIfNeededParticipantIDParticipantDomainInDate_Invocations.count,
            1
        )

        XCTAssertNil(callEventInfo)
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

    private enum Scaffolding {
        static let event = ConversationMLSMessageAddEvent(
            conversationID: ConversationID(id: UUID(), domain: "domain.com"),
            senderID: UserID(id: UUID(), domain: "domain.com"),
            subconversation: "",
            message: "",
            timestamp: .now,
            decryptedMessages: [.init(
                message: Scaffolding.base64EncodedString,
                senderClientID: UUID.mockID1.uuidString
            )]
        )

        static let callingMessageEvent = ConversationMLSMessageAddEvent(
            conversationID: ConversationID(id: UUID(), domain: "domain.com"),
            senderID: UserID(id: UUID(), domain: "domain.com"),
            subconversation: "",
            message: "",
            timestamp: .now,
            decryptedMessages: [.init(
                message: text!,
                senderClientID: UUID.mockID1.uuidString
            )]
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

        static let base64EncodedString = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="
    }
}
