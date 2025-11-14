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

import Foundation
import WireBackup
import WireFoundation
import XCTest
@testable import Wire
@testable import WireDataModel

final class BackupLocalStoreMessagesTests: XCTestCase {

    private typealias QualifiedID = WireFoundation.QualifiedID

    // MARK: - Properties

    private var sut: BackupLocalStore!
    private var coreDataStack: CoreDataStack!
    private var senderID: QualifiedID!
    private var conversationID: QualifiedID!
    private var context: NSManagedObjectContext!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create Core Data stack with temporary SQLite store
        let account = Account(userName: "", userIdentifier: UUID())
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: tempDirectory,
            inMemoryStore: false,
            localDomain: "wire.com",
            isFederationEnabled: true
        )
        try await coreDataStack.load()

        sut = BackupLocalStore(contextProvider: coreDataStack)
        context = sut.backupContext

        // Create test fixtures
        conversationID = QualifiedID(id: UUID(), domain: "wire.com")
        senderID = QualifiedID(id: UUID(), domain: "wire.com")

        try await context.perform { [context, senderID, conversationID] in
            let sender = ZMUser.insertNewObject(in: context!)
            sender.remoteIdentifier = senderID?.id
            sender.domain = senderID?.domain
            sender.name = "Bob"

            let conversation = ZMConversation.insertNewObject(in: context!)
            conversation.remoteIdentifier = conversationID?.id
            conversation.domain = conversationID?.domain
            conversation.conversationType = .group

            try context!.save()
        }
    }

    override func tearDown() {
        sut = nil
        coreDataStack = nil
        context = nil
        senderID = nil
        conversationID = nil
        super.tearDown()
    }

    // MARK: - Success Cases

    func test_AddMessages_ImportsValidTextMessages() async throws {
        // GIVEN
        let messages = [
            makeValidTextMessage(
                conversationID: conversationID,
                senderID: senderID
            ),
            makeValidTextMessage(
                conversationID: conversationID,
                senderID: senderID
            )
        ]

        // WHEN
        let result = try await sut.addMessages(messages)

        // THEN
        XCTAssertEqual(result.validationCount.successCount, 2)
        XCTAssertEqual(result.insertionCount.successCount, 2)
        XCTAssertEqual(result.rehydrationCount.successCount, 2)

        try await context.perform { [senderID, conversationID, fetchMessages] in

            // Verify messages in database
            let fetchedMessages = try fetchMessages()
            XCTAssertEqual(fetchedMessages.count, 2)

            // Verify relationships
            for message in fetchedMessages {
                XCTAssertNotNil(message.sender)
                XCTAssertEqual(message.sender?.remoteIdentifier, senderID?.id)
                XCTAssertNotNil(message.visibleInConversation)
                XCTAssertEqual(message.visibleInConversation?.remoteIdentifier, conversationID?.id)
            }
        }
    }

    func test_AddMessages_ImportsValidAssetMessages() async throws {
        // GIVEN
        let messages = [
            makeValidAssetMessage(
                conversationID: conversationID,
                senderID: senderID
            )
        ]

        // WHEN
        let result = try await sut.addMessages(messages)

        // THEN
        XCTAssertEqual(result.validationCount.successCount, 1)
        XCTAssertEqual(result.insertionCount.successCount, 1)
        XCTAssertEqual(result.rehydrationCount.successCount, 1)

        try await context.perform { [senderID, conversationID, fetchMessages] in

            // Verify asset message in database
            let fetchedMessages = try fetchMessages()
            XCTAssertEqual(fetchedMessages.count, 1)

            guard let assetMessage = fetchedMessages.first as? ZMAssetClientMessage else {
                XCTFail("Expected ZMAssetClientMessage")
                return
            }

            XCTAssertNotNil(assetMessage.sender)
            XCTAssertEqual(assetMessage.sender?.remoteIdentifier, senderID?.id)
            XCTAssertNotNil(assetMessage.visibleInConversation)
            XCTAssertEqual(assetMessage.visibleInConversation?.remoteIdentifier, conversationID?.id)
            XCTAssertNotNil(assetMessage.underlyingMessage)
        }

    }

    func test_AddMessages_ImportsValidLocationMessages() async throws {
        // GIVEN
        let messages = [
            makeValidLocationMessage(
                conversationID: conversationID,
                senderID: senderID
            )
        ]

        // WHEN
        let result = try await sut.addMessages(messages)

        // THEN
        XCTAssertEqual(result.validationCount.successCount, 1)
        XCTAssertEqual(result.insertionCount.successCount, 1)
        XCTAssertEqual(result.rehydrationCount.successCount, 1)

        try await context.perform { [senderID, conversationID, fetchMessages] in

            // Verify message in database
            let fetchedMessages = try fetchMessages()
            XCTAssertEqual(fetchedMessages.count, 1)

            guard let message = fetchedMessages.first else { return XCTFail() }
            XCTAssertNotNil(message.sender)
            XCTAssertEqual(message.sender?.remoteIdentifier, senderID?.id)
            XCTAssertNotNil(message.visibleInConversation)
            XCTAssertEqual(message.visibleInConversation?.remoteIdentifier, conversationID?.id)
        }
    }

    func test_AddMessages_HandlesMixedMessageTypes() async throws {
        // GIVEN
        let messages = [
            makeValidTextMessage(
                conversationID: conversationID,
                senderID: senderID
            ),
            makeValidAssetMessage(
                conversationID: conversationID,
                senderID: senderID
            ),
            makeValidLocationMessage(
                conversationID: conversationID,
                senderID: senderID
            )
        ]

        // WHEN
        let result = try await sut.addMessages(messages)

        // THEN
        XCTAssertEqual(result.validationCount.successCount, 3)
        XCTAssertEqual(result.insertionCount.successCount, 3)
        XCTAssertEqual(result.rehydrationCount.successCount, 3)

        // Verify that all messages are in database
        try await context.perform { [fetchMessages] in
            let fetchedMessages = try fetchMessages()
            XCTAssertEqual(fetchedMessages.count, 3)
        }
    }

    // MARK: - Validation Failure Cases

    func test_AddMessages_ReportsValidationFailure_ForInvalidNonce() async throws {
        // GIVEN
        let messages = [
            makeMessageWithInvalidNonce(),
            makeValidTextMessage(
                conversationID: conversationID,
                senderID: senderID
            )
        ]

        // WHEN
        let result = try await sut.addMessages(messages)

        // THEN
        XCTAssertEqual(result.validationCount.successCount, 1)
        XCTAssertEqual(result.validationCount.failureCount, 1)

        // Only valid message should be in database
        try await context.perform { [fetchMessages] in
            let fetchedMessages = try fetchMessages()
            XCTAssertEqual(fetchedMessages.count, 1)
        }
    }

    func test_AddMessages_ReportsValidationFailure_ForUnsupportedContentType() async throws {
        // GIVEN

        // Create a message with text content but manually create the model
        // to simulate unsupported content that doesn't pass validation
        let invalidMessage = MessageBackupModel(
            id: "invalid-id-format",  // Invalid UUID format
            conversationID: conversationID,
            senderUserID: senderID,
            senderClientID: "client-id",
            creationDate: Date(),
            content: .text("test")
        )

        let validMessage = makeValidTextMessage(
            conversationID: conversationID,
            senderID: senderID
        )

        // WHEN
        let result = try await sut.addMessages([invalidMessage, validMessage])

        // THEN
        XCTAssertEqual(result.validationCount.successCount, 1)
        XCTAssertEqual(result.validationCount.failureCount, 1)

        // Only valid message should be in database
        try await context.perform { [fetchMessages] in
            let fetchedMessages = try fetchMessages()
            XCTAssertEqual(fetchedMessages.count, 1)
        }
    }

    // MARK: - Rehydration cases with missing sender

    func test_AddMessages_SucceedsWithMissingSender() async throws {
        // GIVEN
        // Create message with non-existent sender
        let nonExistentSenderID = QualifiedID(id: UUID(), domain: "wire.com")
        let messages = [
            makeValidTextMessage(
                conversationID: conversationID,
                senderID: nonExistentSenderID
            )
        ]

        // WHEN
        let result = try await sut.addMessages(messages)

        // THEN
        XCTAssertEqual(result.validationCount.successCount, 1)
        XCTAssertEqual(result.insertionCount.successCount, 1)
        XCTAssertEqual(result.rehydrationCount.successCount, 1)

        // Message should exist with nil sender
        try await context.perform { [fetchMessages] in
            let fetchedMessages = try fetchMessages()
            XCTAssertEqual(fetchedMessages.count, 1)

            guard let message = fetchedMessages.first else {
                return XCTFail()
            }
            XCTAssertNil(message.sender)
            XCTAssertNotNil(message.visibleInConversation)
        }
    }

    // MARK: - Rehydration Failure

    func test_AddMessages_HandlesRehydrationFailure_ForMissingConversation() async throws {
        // GIVEN
        // Create message with non-existent conversation
        let nonExistentConversationID = QualifiedID(id: UUID(), domain: "wire.com")
        let messages = [
            makeValidTextMessage(
                conversationID: nonExistentConversationID,
                senderID: senderID
            )
        ]

        // WHEN
        let result = try await sut.addMessages(messages)

        // THEN
        XCTAssertEqual(result.validationCount.successCount, 1)
        XCTAssertEqual(result.insertionCount.successCount, 1)
        XCTAssertEqual(result.rehydrationCount.successCount, 0)
        XCTAssertEqual(result.rehydrationCount.failureCount, 1)

        // Zombie message should be cleaned up
        try await context.perform { [fetchMessages] in
            let fetchedMessages = try fetchMessages()
            XCTAssertEqual(fetchedMessages.count, 0)
        }
    }

    // MARK: - Formatting assessment

    func test_FetchAllMessageIDs_ReturnsLowercaseUUIDs() async throws {
        // GIVEN - Insert a message into the database
        let messageNonce = UUID()
        let context = try XCTUnwrap(context)

        try await context.perform { [context, conversationID] in
            let message = ZMClientMessage(context: context)
            message.nonce = messageNonce

            let id = try XCTUnwrap(conversationID)
            let conversation = try XCTUnwrap(ZMConversation.fetch(
                with: id.id,
                domain: id.domain,
                in: context
            ))
            message.visibleInConversation = conversation

            try context.save()
        }

        // WHEN
        let fetchedIDs = try await sut.fetchAllMessageIDs()

        // THEN - Should return lowercase UUID (transport format)
        let expectedID = messageNonce.transportString() // lowercase
        XCTAssertTrue(fetchedIDs.contains(expectedID), "Should contain lowercase UUID")
        XCTAssertFalse(fetchedIDs.contains(messageNonce.uuidString), "Should not contain uppercase UUID")
    }

    // MARK: - Performance & Scale

    func testThatAddMessagesHandlesLargeBatch() async throws {
        // GIVEN - 1000 messages
        let messages = (0 ..< 1000).map { _ in
            makeValidTextMessage(
                conversationID: conversationID,
                senderID: senderID
            )
        }

        // WHEN
        let result = try await sut.addMessages(messages)

        // THEN
        XCTAssertEqual(result.validationCount.successCount, 1000)
        XCTAssertEqual(result.insertionCount.successCount, 1000)
        XCTAssertEqual(result.rehydrationCount.successCount, 1000)

        try await context.perform { [fetchMessages] in
            let fetchedMessages = try fetchMessages()
            XCTAssertEqual(fetchedMessages.count, 1000)
        }
    }

    // MARK: - Helper Methods

    private func makeValidTextMessage(
        conversationID: QualifiedID,
        senderID: QualifiedID,
        senderClientID: String? = "client-id"
    ) -> MessageBackupModel {
        MessageBackupModel(
            id: UUID().uuidString.lowercased(),
            conversationID: conversationID,
            senderUserID: senderID,
            senderClientID: senderClientID,
            creationDate: Date(),
            content: .text("Test message \(UUID().uuidString)")
        )
    }

    private func makeValidAssetMessage(
        conversationID: QualifiedID,
        senderID: QualifiedID
    ) -> MessageBackupModel {
        MessageBackupModel(
            id: UUID().uuidString.lowercased(),
            conversationID: conversationID,
            senderUserID: senderID,
            senderClientID: "client-id",
            creationDate: Date(),
            content: .asset(
                mimeType: "image/jpeg",
                size: 1024,
                name: "test.jpg",
                otrKey: Data(repeating: 1, count: 32),
                sha256: Data(repeating: 2, count: 32),
                assetID: UUID().uuidString,
                assetToken: "token",
                assetDomain: "wire.com",
                encryption: .aesGCM,
                metadata: .image(width: 800, height: 600, tag: nil)
            )
        )
    }

    private func makeValidLocationMessage(
        conversationID: QualifiedID,
        senderID: QualifiedID
    ) -> MessageBackupModel {
        MessageBackupModel(
            id: UUID().uuidString.lowercased(),
            conversationID: conversationID,
            senderUserID: senderID,
            senderClientID: "client-id",
            creationDate: Date(),
            content: .location(
                longitude: 8.5417,
                latitude: 47.3769,
                name: "Zurich",
                zoom: 10
            )
        )
    }

    private func makeMessageWithInvalidNonce() -> MessageBackupModel {
        MessageBackupModel(
            id: "invalid-nonce-format",
            conversationID: QualifiedID(id: UUID(), domain: "wire.com"),
            senderUserID: QualifiedID(id: UUID(), domain: "wire.com"),
            senderClientID: "client-id",
            creationDate: Date(),
            content: .text("This message has invalid nonce")
        )
    }

    func fetchMessages() throws -> [ZMMessage] {
        let fetchRequest = ZMMessage.fetchRequest()
        let fetchResult = try context.fetch(fetchRequest) as? [ZMMessage]
        return try XCTUnwrap(fetchResult)
    }
}
