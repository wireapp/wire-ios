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

import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import XCTest
@testable import WireAPI
@testable import WireDomain

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

        let genericMessage = try XCTUnwrap(GenericMessage(withBase64String: Scaffolding.base64EncodedString))
        let content = try XCTUnwrap(genericMessage.content) // .text

        // When

        try await sut.processProtobufMessage(
            genericMessage,
            content: content,
            conversation: conversation,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID,
            senderClientID: "",
            date: .now,
            eventMessage: ""
        )

        XCTAssertEqual(messageLocalStore.fetchOrCreateClientMessageIdConversationSenderDate_Invocations.count, 1)
        XCTAssertEqual(
            messageLocalStore.addClientMessageIsNewMessageGenericMessageConversationSenderIDSenderDomain_Invocations
                .count,
            1
        )
    }

    private enum Scaffolding {
        static let conversationID = ConversationID(uuid: .mockID1, domain: "domain.com")
        static let userID = ConversationID(uuid: .mockID1, domain: "domain.com")
        static let base64EncodedString = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="
    }
}
