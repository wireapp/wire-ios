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

final class ProteusMessageDecryptorTests: XCTestCase {
    var sut: ProteusMessageDecryptor!
    var proteusService: MockProteusServiceInterface!

    var stack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        proteusService = MockProteusServiceInterface()
        sut = ProteusMessageDecryptor(
            proteusService: proteusService,
            managedObjectContext: context
        )

        // Scenario:
        // - Self user is the recipient, Alice is the sender.
        // - Self user and alice are connected and have a conversation.
        // - Self user has one client, Alice has two (one of which is unknown to self user).
        // - Alice has 2 clients, one is already known to the self user.
        // - Alice will send a message from the second unknown client.
        try await context.perform { [context, modelHelper] in
            let selfUser = modelHelper.createSelfUser(
                id: Scaffolding.selfUserID.uuid,
                domain: Scaffolding.selfUserID.domain,
                in: context
            )

            let selfClient = modelHelper.createSelfClient(
                id: Scaffolding.selfClientID,
                in: context
            )

            selfClient.numberOfKeysRemaining = Scaffolding.selfClientNumberOfKeys

            let alice = modelHelper.createUser(
                id: Scaffolding.aliceID.uuid,
                domain: Scaffolding.aliceID.domain,
                in: context
            )

            _ = modelHelper.createClient(
                id: Scaffolding.aliceClientID1,
                for: alice
            )

            modelHelper.createConnection(
                status: .accepted,
                to: alice,
                in: context
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

    override func tearDown() async throws {
        stack = nil
        proteusService = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Tests

    func testItDecryptsOnlyIfNeeded() async throws {
        // Given an event with plaintext
        let alreadyDecryptedEvent = Scaffolding.makeEvent(content: .plaintext("foo"))

        // When
        let decryptedEvent = try await sut.decryptedEventData(from: alreadyDecryptedEvent)

        // Then it was returned as is
        XCTAssertEqual(decryptedEvent, alreadyDecryptedEvent)
    }

    func testItThrowsWhenSenderFailedToEncrypt() async throws {
        // Given a special payload
        let invalidEvent = Scaffolding.makeEvent(content: .ciphertext(ZMFailedToCreateEncryptedMessagePayloadString))

        // When
        do {
            _ = try await sut.decryptedEventData(from: invalidEvent)
            XCTFail("expected an error but none was thrown")
            return
        } catch ProteusMessageDecryptorError.senderFailedToEncrypt {
            // Then we got the right error
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testItThrowsWhenCiphertextIsTooBig() async throws {
        // Given a message that exceeds the max ciphertext size
        let longMessage = String(repeating: "!", count: 20000)
        let invalidEvent = Scaffolding.makeEvent(content: .ciphertext(longMessage))

        // When
        do {
            _ = try await sut.decryptedEventData(from: invalidEvent)
            XCTFail("expected an error but none was thrown")
            return
        } catch ProteusError.decodeError {
            // Then we got the right error
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testItThrowsWhenExternalCiphertextIsTooBig() async throws {
        // Given an external message that exceeds the max ciphertext size
        var invalidEvent = Scaffolding.makeEvent(content: .ciphertext("valid message"))
        let longMessage = String(repeating: "!", count: 20000)
        invalidEvent.externalData = .ciphertext(longMessage)

        // When
        do {
            _ = try await sut.decryptedEventData(from: invalidEvent)
            XCTFail("expected an error but none was thrown")
            return
        } catch ProteusError.decodeError {
            // Then we got the right error
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testItDecryptsAnEventFromANewSenderAndUpdatesSecurityLevel() async throws {
        // Given
        try await context.perform { [context] in
            let selfClient = try XCTUnwrap(
                ZMUser.selfUser(in: context).selfClient()
            )

            let alice = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.aliceID.uuid,
                    domain: Scaffolding.aliceID.domain,
                    in: context
                )
            )

            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.conversationID.uuid,
                    domain: Scaffolding.conversationID.domain,
                    in: context
                )
            )

            // The conversation with Alice is secure
            selfClient.trustClients(alice.clients)
            selfClient.updateSecurityLevelAfterDiscovering(alice.clients)
            XCTAssertEqual(conversation.securityLevel, .secure)

            // Alice's second client (from which the message is sent) is unknown
            XCTAssertEqual(alice.clients.count, 1)
        }

        // Given an encrypted event
        let encryptedMessage = try XCTUnwrap("!?@".base64EncodedString)
        let encryptedMessageData = try XCTUnwrap(encryptedMessage.base64DecodedData)
        let encryptedEvent = Scaffolding.makeEvent(content: .ciphertext(encryptedMessage))

        let decryptedMessage = try XCTUnwrap("foo".base64EncodedString)
        let decryptedMessageData = try XCTUnwrap(decryptedMessage.base64DecodedData)

        // Mock decryption
        proteusService.decryptDataForSession_MockMethod = { _, _ in
            (didCreateNewSession: true, decryptedData: decryptedMessageData)
        }

        // When
        let decryptedEvent = try await sut.decryptedEventData(from: encryptedEvent)

        // Then the event was decrypted
        XCTAssertEqual(decryptedEvent, Scaffolding.makeEvent(content: .plaintext(decryptedMessage)))

        let decryptInvocations = proteusService.decryptDataForSession_Invocations
        XCTAssertEqual(decryptInvocations.count, 1)
        XCTAssertEqual(decryptInvocations.first?.data, encryptedMessageData)
        XCTAssertEqual(decryptInvocations.first?.id, Scaffolding.proteusSessionID)

        try await context.perform { [context] in
            let selfClient = try XCTUnwrap(ZMUser.selfUser(in: context).selfClient())

            // Then the self clients remaining keys were decremented
            XCTAssertEqual(selfClient.numberOfKeysRemaining, Scaffolding.selfClientNumberOfKeys - 1)

            let alice = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.aliceID.uuid,
                    domain: Scaffolding.aliceID.domain,
                    in: context
                )
            )

            let discoveredClient = try XCTUnwrap(
                alice.clients.first {
                    $0.remoteIdentifier == Scaffolding.aliceClientID2
                }
            )

            // Then the client was discovered by the event.
            XCTAssertEqual(discoveredClient.discoveryDate, Scaffolding.timestamp)

            // Then the new client is marked as untrusted.
            XCTAssertTrue(selfClient.ignoredClients.contains(discoveredClient))

            // Then the verified conversation degraded due to the new client.
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.conversationID.uuid,
                    domain: Scaffolding.conversationID.domain,
                    in: context
                )
            )

            XCTAssertEqual(conversation.securityLevel, .secureWithIgnored)
        }
    }

    func testItDecryptsAnEventFromAKnownSender() async throws {
        // Given
        try await context.perform { [context, modelHelper] in
            let selfClient = try XCTUnwrap(
                ZMUser.selfUser(in: context).selfClient()
            )

            let alice = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.aliceID.uuid,
                    domain: Scaffolding.aliceID.domain,
                    in: context
                )
            )

            _ = modelHelper.createClient(
                id: Scaffolding.aliceClientID2,
                for: alice
            )

            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.conversationID.uuid,
                    domain: Scaffolding.conversationID.domain,
                    in: context
                )
            )

            // The conversation with Alice is secure
            selfClient.trustClients(alice.clients)
            selfClient.updateSecurityLevelAfterDiscovering(alice.clients)
            XCTAssertEqual(conversation.securityLevel, .secure)

            // Alice's second client (from which the message is sent) is known
            XCTAssertEqual(alice.clients.count, 2)

            try context.save()
        }

        // Given an encrypted event
        let encryptedMessage = try XCTUnwrap("!?@".base64EncodedString)
        let encryptedMessageData = try XCTUnwrap(encryptedMessage.base64DecodedData)
        let encryptedEvent = Scaffolding.makeEvent(content: .ciphertext(encryptedMessage))

        let decryptedMessage = try XCTUnwrap("foo".base64EncodedString)
        let decryptedMessageData = try XCTUnwrap(decryptedMessage.base64DecodedData)

        // Mock decryption
        proteusService.decryptDataForSession_MockMethod = { _, _ in
            (didCreateNewSession: false, decryptedData: decryptedMessageData)
        }

        // When
        let decryptedEvent = try await sut.decryptedEventData(from: encryptedEvent)

        // Then the event was decrypted
        XCTAssertEqual(decryptedEvent, Scaffolding.makeEvent(content: .plaintext(decryptedMessage)))

        let decryptInvocations = proteusService.decryptDataForSession_Invocations
        XCTAssertEqual(decryptInvocations.count, 1)
        XCTAssertEqual(decryptInvocations.first?.data, encryptedMessageData)
        XCTAssertEqual(decryptInvocations.first?.id, Scaffolding.proteusSessionID)

        try await context.perform { [context] in
            let selfClient = try XCTUnwrap(ZMUser.selfUser(in: context).selfClient())

            // Then the self clients remaining keys was not decremented
            XCTAssertEqual(selfClient.numberOfKeysRemaining, Scaffolding.selfClientNumberOfKeys)

            // Then the conversation security reamains secure.
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.conversationID.uuid,
                    domain: Scaffolding.conversationID.domain,
                    in: context
                )
            )

            XCTAssertEqual(conversation.securityLevel, .secure)
        }
    }
}

private enum Scaffolding {
    static let localDomain = "local.com"

    static let selfUserID = UserID(uuid: UUID(), domain: localDomain)
    static let selfClientID = "selfClientID"
    static let selfClientNumberOfKeys: Int32 = 10

    static let aliceID = UserID(uuid: UUID(), domain: localDomain)
    static let aliceClientID1 = "aliceClientID1"
    static let aliceClientID2 = "aliceClientID2"

    static let proteusSessionID = ProteusSessionID(
        domain: aliceID.domain,
        userID: aliceID.uuid.uuidString,
        clientID: aliceClientID2
    )

    static let conversationID = ConversationID(uuid: UUID(), domain: localDomain)
    static let timestamp = Date()

    static func makeEvent(content: MessageContent) -> ConversationProteusMessageAddEvent {
        ConversationProteusMessageAddEvent(
            conversationID: conversationID,
            senderID: aliceID,
            timestamp: timestamp,
            message: content,
            externalData: nil,
            messageSenderClientID: aliceClientID2,
            messageRecipientClientID: selfClientID
        )
    }
}
