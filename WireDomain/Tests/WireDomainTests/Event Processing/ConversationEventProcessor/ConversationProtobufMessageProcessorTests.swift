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
import WireTestingPackage
import XCTest

@testable import WireDomain
@testable import WireNetwork

final class ConversationProtobufMessageProcessorTests: XCTestCase {

    private var sut: ConversationProtobufMessageProcessor!
    private var messageLocalStore: MockMessageLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!

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

        sut = ConversationProtobufMessageProcessor(
            messageLocalStore: messageLocalStore,
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore
        )
    }

    override func tearDown() async throws {
        messageLocalStore = nil
        conversationLocalStore = nil
        userLocalStore = nil
        modelHelper = nil
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Local_Store_Add_Text_Message_Method() async throws {
        // Mock

        let (conversation, clientMessage) = await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(in: context)
            let clientMessage = ZMClientMessage(context: context)

            return (conversation, clientMessage)
        }

        messageLocalStore.fetchOrCreateClientMessageIdConversationSenderDate_MockValue = (clientMessage, isNew: true)
        messageLocalStore
            .addClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain_MockMethod =
            { _, _, _, _, _, _ in
            }

        let genericMessage = try XCTUnwrap(GenericMessage(from: Scaffolding.base64EncodedString, validate: true))

        // When

        try await sut.processProtobufMessage(
            genericMessage,
            conversation: conversation,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID,
            senderClientID: "",
            date: Scaffolding.eventDate,
            eventMessage: ""
        )

        XCTAssertEqual(messageLocalStore.fetchOrCreateClientMessageIdConversationSenderDate_Invocations.count, 1)
        XCTAssertEqual(
            messageLocalStore.addClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain_Invocations
                .count,
            1
        )
    }

    func testProcessEvent_It_Invokes_Local_Store_Add_Message_Confirmation_Method() async throws {
        // Given
        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        messageLocalStore.addMessageConfirmationInSenderIDSenderDomainDate_MockMethod = { _, _, _, _, _ in }

        let confirmation = Confirmation.with {
            $0.firstMessageID = UUID().uuidString
            $0.type = .read
        }
        let genericMessage = GenericMessage.with {
            $0.messageID = UUID().uuidString
            $0.confirmation = confirmation
        }

        // When
        try await sut.processProtobufMessage(
            genericMessage,
            conversation: conversation,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID,
            senderClientID: "clientID123",
            date: Scaffolding.eventDate,
            eventMessage: "confirmation"
        )

        // Then
        try XCTAssertCount(messageLocalStore.addMessageConfirmationInSenderIDSenderDomainDate_Invocations, count: 1)

        let invocation = messageLocalStore.addMessageConfirmationInSenderIDSenderDomainDate_Invocations[0]
        XCTAssertEqual(invocation.confirmation, confirmation)
        XCTAssertEqual(invocation.conversation, conversation)
        XCTAssertEqual(invocation.senderID, Scaffolding.userID.id)
        XCTAssertEqual(invocation.senderDomain, Scaffolding.userID.domain)
        XCTAssertEqual(invocation.date, Scaffolding.eventDate)
    }

    func testProcessEvent_Availability_Invokes_UserLocalStoreMethod() async throws {
        // Given
        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }
        userLocalStore.updateUserWithAvailability_MockMethod = { _, _ in }
        messageLocalStore.addMessageConfirmationInSenderIDSenderDomainDate_MockMethod = { _, _, _, _, _ in }

        let genericMessage = GenericMessage.with {
            $0.messageID = UUID().uuidString
            $0.availability = GenericMessageProtocol.Availability(.available)
        }

        // When
        try await sut.processProtobufMessage(
            genericMessage,
            conversation: conversation,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID,
            senderClientID: "clientID123",
            date: Scaffolding.eventDate,
            eventMessage: "confirmation"
        )

        // Then
        let invocation = try XCTUnwrap(userLocalStore.updateUserWithAvailability_Invocations.first)
        XCTAssertEqual(invocation.availability, .available)
        XCTAssertEqual(invocation.userID.uuid, Scaffolding.userID.id)
        XCTAssertEqual(invocation.userID.domain, Scaffolding.userID.domain)
    }

    private enum Scaffolding {
        static let eventDate = Date()
        static let conversationID = ConversationID(id: .mockID1, domain: "domain.com")
        static let userID = ConversationID(id: .mockID1, domain: "domain.com")
        static let base64EncodedString = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="
    }
}
