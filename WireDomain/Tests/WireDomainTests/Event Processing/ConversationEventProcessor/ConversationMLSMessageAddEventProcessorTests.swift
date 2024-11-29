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

@testable import WireAPI
@testable import WireDomain
import WireDomainSupport
import WireDataModel
import WireDataModelSupport
import XCTest

final class ConversationMLSMessageAddEventProcessorTests: XCTestCase {

    private var sut: ConversationMLSMessageAddEventProcessor!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var messageLocalStore: MockMessageLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var protobufMessageProcessor: MockConversationProtobufMessageProcessorProtocol!
    
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

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
            protobufMessageProcessor: protobufMessageProcessor
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
        conversationLocalStore.updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate_MockMethod = { _, _, _ in }
        conversationLocalStore.addParticipantParticipantIDParticipantDomainInDate_MockMethod = { _, _, _, _ in }
        messageLocalStore.canAddMessageConversationSenderIDLogAttributes_MockValue = true
        protobufMessageProcessor.processProtobufMessageContentConversationConversationIDSenderIDSenderClientIDLogAttributesDate_MockMethod = { _, _, _, _, _, _, _, _ in }
        

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(messageLocalStore.canAddMessageConversationSenderIDLogAttributes_Invocations.count, 1)
        XCTAssertEqual(protobufMessageProcessor.processProtobufMessageContentConversationConversationIDSenderIDSenderClientIDLogAttributesDate_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.updateSecurityLevelAfterReceivingMessageConversationGenericMessageDate_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.addParticipantParticipantIDParticipantDomainInDate_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let event = ConversationMLSMessageAddEvent(
            conversationID: ConversationID(uuid: UUID(), domain: "domain.com"),
            senderID: UserID(uuid: UUID(), domain: "domain.com"),
            subconversation: "",
            message: "",
            timestamp: .now,
            decryptedMessages: [.init(message: Scaffolding.base64EncodedString, senderClientID: UUID.mockID1.uuidString)]
        )
        
        static let base64EncodedString = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="
    }
}
