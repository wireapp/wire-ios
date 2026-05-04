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

final class ProteusMessageDecryptorTests: XCTestCase {

    private var sut: ProteusMessageDecryptor!
    private var proteusService: MockProteusServiceInterface!
    private var userClientsLocalStore: MockUserClientsLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!

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
        proteusService = MockProteusServiceInterface()
        userClientsLocalStore = MockUserClientsLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()

        sut = ProteusMessageDecryptor(
            proteusService: proteusService,
            userClientsLocalStore: userClientsLocalStore,
            userLocalStore: userLocalStore
        )

        // Scenario:
        // - Self user is the recipient, Alice is the sender.
        // - Self user and alice are connected and have a conversation.
        // - Self user has one client, Alice has two (one of which is unknown to self user).
        // - Alice has 2 clients, one is already known to the self user.
        // - Alice will send a message from the second unknown client.
        try await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(
                id: Scaffolding.selfUserID.id,
                domain: Scaffolding.selfUserID.domain,
                in: context
            )

            let selfClient = modelHelper.createSelfClient(
                id: Scaffolding.selfClientID,
                in: context
            )

            userLocalStore.fetchOrCreateUserIdDomain_MockValue = selfUser
            userClientsLocalStore.fetchClientIdForUserCreateIfNeeded_MockValue = selfClient
            userClientsLocalStore.storeClientDiscoveryDateClient_MockMethod = { _, _ in }
            userClientsLocalStore.addNewClientToIgnoredSelfClientNewClient_MockMethod = { _, _ in }
            userClientsLocalStore.proteusSessionIDFor_MockValue = .init(
                userID: Scaffolding.selfUserID.id.uuidString,
                clientID: Scaffolding.selfClientID
            )

            selfClient.numberOfKeysRemaining = Scaffolding.selfClientNumberOfKeys

            let alice = modelHelper.createUser(
                id: Scaffolding.aliceID.id,
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
                id: Scaffolding.conversationID.id,
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
        userClientsLocalStore = nil
        userLocalStore = nil
        modelHelper = nil
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testDecryptedEventData_It_Throws_When_Sender_Failed_To_Encrypt() async throws {
        // Given a special payload
        let invalidEvent = Scaffolding
            .makeEvent(content: .init(encryptedMessage: ZMFailedToCreateEncryptedMessagePayloadString))

        // When
        do {
            _ = try await sut.decryptedEventData(from: invalidEvent, context: nil)
            XCTFail("expected an error but none was thrown")
            return
        } catch ProteusMessageDecryptorError.senderFailedToEncrypt {
            // Then we got the right error
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testDecryptedEventData_It_Throws_When_Ciphertext_Is_Too_Big() async throws {
        // Given a message that exceeds the max ciphertext size
        let longMessage = String(repeating: "!", count: 20_000)
        let invalidEvent = Scaffolding.makeEvent(content: .init(encryptedMessage: longMessage))

        // When
        do {
            _ = try await sut.decryptedEventData(from: invalidEvent, context: nil)
            XCTFail("expected an error but none was thrown")
            return
        } catch ProteusMessageDecryptorError.invalidCiphertext {
            // Then we got the right error
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testDecryptedEventData_It_Decrypts_An_Event_And_Invokes_Repo_Methods() async throws {
        // Given

        let (selfClient, user, senderClient) = try await context.perform { [context] in
            let selfClient = try XCTUnwrap(
                ZMUser.selfUser(in: context).selfClient()
            )

            let user = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.aliceID.id,
                    domain: Scaffolding.aliceID.domain,
                    in: context
                )
            )

            return (selfClient, user, try XCTUnwrap(user.clients.first))
        }

        // Mock

        userClientsLocalStore.fetchSelfClient_MockValue = selfClient
        userClientsLocalStore.fetchClientIdForUserCreateIfNeeded_MockValue = senderClient
        userClientsLocalStore.storeClientDiscoveryDateClient_MockMethod = { _, _ in }
        userClientsLocalStore.addNewClientToIgnoredSelfClientNewClient_MockMethod = { _, _ in }
        userClientsLocalStore.proteusSessionIDFor_MockValue = Scaffolding.proteusSessionID
        userClientsLocalStore.clientSessionCreatedSelfClientNewClient_MockMethod = { _, _ in }
        userLocalStore.fetchOrCreateUserIdDomain_MockValue = user

        // Given an encrypted event
        let encryptedMessage = try XCTUnwrap("!?@".base64EncodedString)
        let encryptedMessageData = try XCTUnwrap(encryptedMessage.base64DecodedData)
        let encryptedEvent = Scaffolding.makeEvent(content: .init(encryptedMessage: encryptedMessage))

        let decryptedMessage = try XCTUnwrap("foo".base64EncodedString)
        let decryptedMessageData = try XCTUnwrap(decryptedMessage.base64DecodedData)

        // Mock decryption
        proteusService.decryptDataForSessionContext_MockMethod = { _, _, _ in
            (didCreateNewSession: true, decryptedData: decryptedMessageData)
        }

        // When
        let decryptedEvent = try await sut.decryptedEventData(from: encryptedEvent, context: nil)

        // Then the event was decrypted
        XCTAssertEqual(
            decryptedEvent,
            Scaffolding.makeEvent(content: .init(
                encryptedMessage: encryptedMessage,
                decryptedMessage: decryptedMessage
            ))
        )

        let decryptInvocations = proteusService.decryptDataForSessionContext_Invocations
        XCTAssertEqual(decryptInvocations.count, 1)
        XCTAssertEqual(decryptInvocations.first?.data, encryptedMessageData)
        XCTAssertEqual(decryptInvocations.first?.id, Scaffolding.proteusSessionID)
        XCTAssertEqual(userClientsLocalStore.fetchSelfClient_Invocations.count, 1)
        XCTAssertEqual(userClientsLocalStore.fetchClientIdForUserCreateIfNeeded_Invocations.count, 1)
        XCTAssertEqual(userClientsLocalStore.storeClientDiscoveryDateClient_Invocations.count, 1)
        XCTAssertEqual(userClientsLocalStore.addNewClientToIgnoredSelfClientNewClient_Invocations.count, 1)
        XCTAssertEqual(userClientsLocalStore.proteusSessionIDFor_Invocations.count, 1)
        XCTAssertEqual(userClientsLocalStore.clientSessionCreatedSelfClientNewClient_Invocations.count, 1)
        XCTAssertEqual(userLocalStore.fetchOrCreateUserIdDomain_Invocations.count, 1)
    }

    private enum Scaffolding {

        static let localDomain = "local.com"

        static let selfUserID = UserID(id: UUID(), domain: localDomain)
        static let selfClientID = "selfClientID"
        static let selfClientNumberOfKeys: Int32 = 10

        static let aliceID = UserID(id: UUID(), domain: localDomain)
        static let aliceClientID1 = "aliceClientID1"
        static let aliceClientID2 = "aliceClientID2"

        nonisolated(unsafe) static let proteusSessionID = ProteusSessionID(
            domain: aliceID.domain,
            userID: aliceID.id.uuidString,
            clientID: aliceClientID2
        )

        static let conversationID = ConversationID(id: UUID(), domain: localDomain)
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

}
