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

import WireDataModel
import WireDataModelSupport
import XCTest
@testable import WireNetwork

@testable import WireDomain
@testable import WireDomainSupport

final class UpdateEventDecryptorTests: XCTestCase {

    var sut: UpdateEventDecryptor!
    var proteusMessageDecryptor: MockProteusMessageDecryptorProtocol!
    var mlsMessageDecryptor: MockMLSMessageDecryptorProtocol!
    var messageLocalStore: MockMessageLocalStoreProtocol!
    var mlsService: MockMLSServiceInterface!

    var stack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    var modelHelper: ModelHelper!

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        try await insertScaffoldingData()
        proteusMessageDecryptor = MockProteusMessageDecryptorProtocol()
        mlsMessageDecryptor = MockMLSMessageDecryptorProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()
        mlsService = MockMLSServiceInterface()

        sut = UpdateEventDecryptor(
            proteusMessageDecryptor: proteusMessageDecryptor,
            mlsMessageDecryptor: mlsMessageDecryptor,
            mlsService: mlsService,
            messageLocalStore: messageLocalStore
        )
    }

    override func tearDown() async throws {
        stack = nil
        proteusMessageDecryptor = nil
        mlsMessageDecryptor = nil
        messageLocalStore = nil
        modelHelper = nil
        sut = nil
        mlsService = nil
        try coreDataStackHelper.cleanupDirectory()
    }

    func insertScaffoldingData() async throws {
        try await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(
                id: Scaffolding.selfUserID.id,
                domain: Scaffolding.selfUserID.domain,
                in: context
            )

            modelHelper.createSelfClient(
                id: Scaffolding.selfClientID,
                in: context
            )

            let alice = modelHelper.createUser(
                id: Scaffolding.aliceID.id,
                domain: Scaffolding.aliceID.domain,
                in: context
            )

            modelHelper.createClient(
                id: Scaffolding.aliceClientID,
                for: alice
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

        proteusMessageDecryptor.decryptedEventDataFromContext_MockMethod = { envelope, _ in
            envelope
        }

        // When
        let events = await sut.decryptEvents(in: envelope, context: nil).events

        // Then the "decrypted" (the mock just passes them right back) are returned.
        XCTAssertEqual(
            events,
            [
                .conversation(.proteusMessageAdd(Scaffolding.proteusMessage)),
                .user(.pushRemove)
            ]
        )
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
        proteusMessageDecryptor.decryptedEventDataFromContext_MockMethod = { _, _ in
            throw ProteusService.DecryptionError.failedToDecryptData(.DuplicateMessage)
        }

        // When
        let events = await sut.decryptEvents(in: envelope, context: nil).events

        // Then we skipped over the proteus message.
        XCTAssertEqual(events, [.user(.pushRemove)])

        // Then no system message was appended.
        try await context.perform { [context] in
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.conversationID.id,
                    domain: Scaffolding.conversationID.domain,
                    in: context
                )
            )

            XCTAssertNil(conversation.lastMessage)
        }
    }

    func testWhenDecryptionOfMLSMessagesIsSuccessfulThenEventsAreReturned() async throws {
        // Given some events.
        let envelope = UpdateEventEnvelope(
            id: UUID(),
            events: [
                .conversation(.mlsMessageAdd(Scaffolding.mlsMessage)),
                .user(.pushRemove)
            ],
            isTransient: false
        )

        // Mock
        mlsMessageDecryptor.decryptedMessageAddEventDataFromContext_MockMethod = { envelope, _ in
            envelope
        }

        // When
        let events = await sut.decryptEvents(in: envelope, context: nil).events

        // Then the "decrypted" (the mock just passes them right back) are returned.
        XCTAssertEqual(
            events,
            [
                .conversation(.mlsMessageAdd(Scaffolding.mlsMessage)),
                .user(.pushRemove)
            ]
        )
    }

    func testWhenWrongEpochErrorIsThrown() async throws {
        // Given some events.
        let envelope = UpdateEventEnvelope(
            id: UUID(),
            events: [
                .conversation(.mlsMessageAdd(Scaffolding.mlsMessage)),
                .user(.pushRemove)
            ],
            isTransient: false
        )

        // Mock
        mlsMessageDecryptor.decryptedMessageAddEventDataFromContext_MockMethod = { _, _ in
            throw MLSMessageDecryptorError.wrongEpoch(mlsGroupID: Scaffolding.mlsGroupID)
        }

        // When
        let decryptEvents = await sut.decryptEvents(in: envelope, context: nil)

        // Then we skipped over the mls message.
        XCTAssertEqual(decryptEvents.events, [.user(.pushRemove)])
        XCTAssertEqual(decryptEvents.brokenMLSGroupIDs.first, Scaffolding.mlsGroupID.description)
    }

}

private enum Scaffolding {

    static let localDomain = "local.com"

    static let selfUserID = UserID(id: UUID(), domain: localDomain)
    static let selfClientID = "abcd1234"

    static let aliceID = UserID(id: UUID(), domain: localDomain)
    static let aliceClientID = "efgh5678"

    static let conversationID = ConversationID(id: UUID(), domain: localDomain)
    static let mlsGroupID = MLSGroupID.random()
    static let messageContent = "foo"
    static let timestamp = Date()

    static let proteusMessage = ConversationProteusMessageAddEvent(
        conversationID: conversationID,
        senderID: aliceID,
        timestamp: timestamp,
        message: .init(encryptedMessage: messageContent),
        externalData: nil,
        messageSenderClientID: aliceClientID,
        messageRecipientClientID: selfClientID
    )

    static let mlsMessage = ConversationMLSMessageAddEvent(
        conversationID: conversationID,
        senderID: aliceID,
        subconversation: "",
        message: .init(messageContent),
        timestamp: .now,
        decryptedMessages: [.init(
            message: Scaffolding.base64EncodedString,
            senderClientID: UUID.mockID1.uuidString
        )]
    )

    static let base64EncodedString = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="
}
