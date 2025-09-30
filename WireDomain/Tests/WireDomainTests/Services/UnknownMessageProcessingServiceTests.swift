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

import XCTest
import WireDataModel
import WireDomain
import WireDomainSupport
import WireNetwork
import WireDataModelSupport

@testable import WireDomain

final class UnknownMessageProcessingServiceTests: XCTestCase {

    private var sut: UnknownMessageProcessingService!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var protobufMessageProcessor: MockConversationProtobufMessageProcessorProtocol!

    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        conversationLocalStore = MockConversationLocalStoreProtocol()
        protobufMessageProcessor = MockConversationProtobufMessageProcessorProtocol()

        sut = UnknownMessageProcessingService(
            contextProvider: coreDataStack,
            conversationLocalStore: conversationLocalStore,
            protobufMessageProcessor: protobufMessageProcessor
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sut = nil
        conversationLocalStore = nil
        protobufMessageProcessor = nil
        modelHelper = nil
        coreDataStack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    func testProcessStoredUnknownMessages_WithNoMessages() async throws {
        // Given - no unknown messages in database

        // When
        try await sut.processStoredUnknownMessages()

        // Then
        XCTAssertEqual(
            protobufMessageProcessor.processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_Invocations.count,
            0
        )
    }

    func testProcessStoredUnknownMessages_WithProcessableMessage() async throws {
        // Given
        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID.uuid,
                domain: Scaffolding.conversationID.domain,
                in: context
            )
        }

        let sender = await context.perform { [self] in
            modelHelper.createUser(
                id: Scaffolding.senderID.uuid,
                domain: Scaffolding.senderID.domain,
                in: context
            )
        }

        let unknownMessage = try await context.perform { [context] in
            let message = UnknownMessage(
                nonce: Scaffolding.messageID,
                managedObjectContext: context
            )
            message.payload = Scaffolding.validPayload
            message.visibleInConversation = conversation
            message.sender = sender
            message.eventTimestamp = Scaffolding.eventTimestamp
            message.senderClientID = Scaffolding.senderClientID
            try context.save()
            return message
        }

        // When
        try await sut.processStoredUnknownMessages()

        // Then
        XCTAssertEqual(
            protobufMessageProcessor.processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_Invocations.count,
            1
        )

        // Verify the message was deleted
        let remainingMessages = try await context.perform { [context] in
            let fetchRequest = UnknownMessage.fetchRequest()
            return try context.fetch(fetchRequest)
        }
        XCTAssertTrue(remainingMessages.isEmpty)
    }

    func testProcessStoredUnknownMessages_WithUnprocessableMessage() async throws {
        // Given
        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID.uuid,
                domain: Scaffolding.conversationID.domain,
                in: context
            )
        }

        let sender = await context.perform { [self] in
            modelHelper.createUser(
                id: Scaffolding.senderID.uuid,
                domain: Scaffolding.senderID.domain,
                in: context
            )
        }

        try await context.perform { [context] in
            let message = UnknownMessage(
                nonce: Scaffolding.messageID,
                managedObjectContext: context
            )
            message.payload = Scaffolding.invalidPayload
            message.visibleInConversation = conversation
            message.sender = sender
            message.eventTimestamp = Scaffolding.eventTimestamp
            try context.save()
        }

        // When
        try await sut.processStoredUnknownMessages()

        // Then
        XCTAssertEqual(
            protobufMessageProcessor.processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_Invocations.count,
            0
        )

        // Verify the message was NOT deleted (still unprocessable)
        let remainingMessages = try await context.perform { [context] in
            let fetchRequest = UnknownMessage.fetchRequest()
            return try context.fetch(fetchRequest)
        }
        XCTAssertEqual(remainingMessages.count, 1)
        let nonce = await context.perform { remainingMessages.first?.nonce }
        XCTAssertEqual(nonce, Scaffolding.messageID)
    }

    func testProcessStoredUnknownMessages_WithMessageMissingContext() async throws {
        // Given - create unknown message without proper conversation/sender context
        let unknownMessage = try await context.perform { [context] in
            let message = UnknownMessage(
                nonce: Scaffolding.messageID,
                managedObjectContext: context
            )
            message.payload = Scaffolding.validPayload
            message.eventTimestamp = Scaffolding.eventTimestamp
            // No conversation or sender set
            try context.save()
            return message
        }

        // When
        try await sut.processStoredUnknownMessages()

        // Then
        XCTAssertEqual(
            protobufMessageProcessor.processProtobufMessageConversationConversationIDSenderIDSenderClientIDDateEventMessage_Invocations.count,
            0
        )

        // Verify the message was deleted (missing context is considered unprocessable)
        let remainingMessages = try await context.perform { [context] in
            let fetchRequest = UnknownMessage.fetchRequest()
            return try context.fetch(fetchRequest)
        }
        XCTAssertTrue(remainingMessages.isEmpty)
    }

    // MARK: - Scaffolding

    private enum Scaffolding {
        static let conversationID = QualifiedID(uuid: UUID(), domain: "example.com")
        static let senderID = QualifiedID(uuid: UUID(), domain: "example.com")
        static let messageID = UUID()
        static let senderClientID = "client123"
        static let eventTimestamp = Date()
        
        // Valid protobuf payload that can be decoded
        static let validPayload = Data(base64Encoded: "CgR0ZXN0")! // "test" as base64
        
        // Invalid payload that cannot be decoded
        static let invalidPayload = Data("invalid protobuf data".utf8)
    }

}
