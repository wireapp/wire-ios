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

import WireAPI
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireDomain
@testable import WireDomainSupport

final class UpdateEventDecryptorTests: XCTestCase {

    var sut: UpdateEventDecryptor!
    var proteusMessageDecryptor: MockProteusMessageDecryptorProtocol!

    var stack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        try await insertScaffoldingData()
        proteusMessageDecryptor = MockProteusMessageDecryptorProtocol()
        sut = UpdateEventDecryptor(
            proteusMessageDecryptor: proteusMessageDecryptor,
            context: context
        )
    }

    override func tearDown() async throws {
        stack = nil
        proteusMessageDecryptor = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    func insertScaffoldingData() async throws {
        try await context.perform { [context, modelHelper] in
            let selfUser = modelHelper.createSelfUser(
                id: Scaffolding.selfUserID.uuid,
                domain: Scaffolding.selfUserID.domain,
                in: context
            )

            modelHelper.createSelfClient(
                id: Scaffolding.selfClientID,
                in: context
            )

            let alice = modelHelper.createUser(
                id: Scaffolding.aliceID.uuid,
                domain: Scaffolding.aliceID.domain,
                in: context
            )

            modelHelper.createClient(
                id: Scaffolding.aliceClientID,
                for: alice
            )

            let conversation = modelHelper.createGroupConversation(
                id: Scaffolding.conversationID.uuid,
                domain: Scaffolding.conversationID.domain,
                in: context
            )

            conversation.addParticipantsAndUpdateConversationState(users: [selfUser, alice])

            try context.save()
        }
    }

    // MARK: - Tests

    func testWhenDecryptionIsSuccessfulThenEventsAreReturned() async throws {
        // Given some events.
        let envelope = UpdateEventEnvelope(
            id: UUID(),
            events: [
                .conversation(.proteusMessageAdd(Scaffolding.proteusMessage)),
                .user(.pushRemove)
            ],
            isTransient: false
        )

        // Mock
        proteusMessageDecryptor.decryptedEventDataFrom_MockMethod = { $0 }

        // When
        let events = try await sut.decryptEvents(in: envelope)

        // Then the "decrypted" (the mock just passes them right back) are returned.
        XCTAssertEqual(
            events,
            [
                .conversation(.proteusMessageAdd(Scaffolding.proteusMessage)),
                .user(.pushRemove)
            ]
        )
    }

    func testWhenDecryptionErrorIsThrownThenSystemMessageIsAppended() async throws {
        // Given some events.
        let envelope = UpdateEventEnvelope(
            id: UUID(),
            events: [
                .conversation(.proteusMessageAdd(Scaffolding.proteusMessage)),
                .user(.pushRemove)
            ],
            isTransient: false
        )

        // Mock
        proteusMessageDecryptor.decryptedEventDataFrom_MockMethod = { _ in
            throw ProteusError.invalidSignature
        }

        // When
        let events = try await sut.decryptEvents(in: envelope)

        // Then we skipped over the proteus message.
        XCTAssertEqual(events, [.user(.pushRemove)])

        // Then we appended a system message.
        try await context.perform { [context] in
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.conversationID.uuid,
                    domain: Scaffolding.conversationID.domain,
                    in: context
                )
            )

            let alice = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.aliceID.uuid,
                    domain: Scaffolding.aliceID.domain,
                    in: context
                )
            )

            let aliceClient = try XCTUnwrap(
                alice.clients.first {
                    $0.remoteIdentifier == Scaffolding.aliceClientID
                }
            )

            let lastMessage = try XCTUnwrap(conversation.lastMessage as? ZMSystemMessage)
            XCTAssertEqual(lastMessage.systemMessageType, .decryptionFailed)
            XCTAssertEqual(lastMessage.decryptionErrorCode?.intValue, ProteusError.invalidSignature.rawValue)
            XCTAssertEqual(lastMessage.serverTimestamp, Scaffolding.timestamp)
            XCTAssertEqual(lastMessage.sender, alice)
            XCTAssertEqual(lastMessage.clients, [aliceClient])
        }
    }

    func testWhenDuplicateMessageErrorIsThrownThenNoSystemMessageIsAppended() async throws {
        // Given some events.
        let envelope = UpdateEventEnvelope(
            id: UUID(),
            events: [
                .conversation(.proteusMessageAdd(Scaffolding.proteusMessage)),
                .user(.pushRemove)
            ],
            isTransient: false
        )

        // Mock
        proteusMessageDecryptor.decryptedEventDataFrom_MockMethod = { _ in
            throw ProteusError.duplicateMessage
        }

        // When
        let events = try await sut.decryptEvents(in: envelope)

        // Then we skipped over the proteus message.
        XCTAssertEqual(events, [.user(.pushRemove)])

        // Then no system message was appended.
        try await context.perform { [context] in
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.conversationID.uuid,
                    domain: Scaffolding.conversationID.domain,
                    in: context
                )
            )

            XCTAssertNil(conversation.lastMessage)
        }
    }

    func testWhenOutdatedMessageErrorIsThrownThenNoSystemMessageIsAppended() async throws {
        // Given some events.
        let envelope = UpdateEventEnvelope(
            id: UUID(),
            events: [
                .conversation(.proteusMessageAdd(Scaffolding.proteusMessage)),
                .user(.pushRemove)
            ],
            isTransient: false
        )

        // Mock
        proteusMessageDecryptor.decryptedEventDataFrom_MockMethod = { _ in
            throw ProteusError.outdatedMessage
        }

        // When
        let events = try await sut.decryptEvents(in: envelope)

        // Then we skipped over the proteus message.
        XCTAssertEqual(events, [.user(.pushRemove)])

        // Then no system message was appended.
        try await context.perform { [context] in
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.conversationID.uuid,
                    domain: Scaffolding.conversationID.domain,
                    in: context
                )
            )

            XCTAssertNil(conversation.lastMessage)
        }
    }

}

private enum Scaffolding {

    static let localDomain = "local.com"

    static let selfUserID = UserID(uuid: UUID(), domain: localDomain)
    static let selfClientID = "abcd1234"

    static let aliceID = UserID(uuid: UUID(), domain: localDomain)
    static let aliceClientID = "efgh5678"

    static let conversationID = ConversationID(uuid: UUID(), domain: localDomain)
    static let messageContent = "foo"
    static let timestamp = Date()

    static let proteusMessage = ConversationProteusMessageAddEvent(
        conversationID: conversationID,
        senderID: aliceID,
        timestamp: timestamp,
        message: .ciphertext(messageContent),
        externalData: nil,
        messageSenderClientID: aliceClientID,
        messageRecipientClientID: selfClientID
    )

}
