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

import Foundation
import WireAPI
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireDomain

final class ConversationRenameEventProcessorTests: XCTestCase {

    var sut: ConversationRenameEventProcessor!

    var coreDataStack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = ConversationRenameEventProcessor(context: coreDataStack.syncContext)
        try await super.setUp()
    }

    override func tearDown() async throws {
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Tests

    func testItProcessesEvent() async throws {
        // Given alice and self user in a conversation called "I love bugs".
        try await context.perform { [context, modelHelper] in
            let selfUser = modelHelper.createSelfUser(
                id: Scaffolding.selfUserID,
                domain: Scaffolding.domain,
                in: context
            )

            let alice = modelHelper.createUser(
                id: Scaffolding.aliceID,
                domain: Scaffolding.domain,
                in: context
            )

            let conversation = modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                domain: Scaffolding.domain,
                in: context
            )

            conversation.userDefinedName = "I love bugs"
            conversation.addParticipantsAndUpdateConversationState(users: [selfUser, alice])
            try context.save()
        }

        // When the event is processed.
        try await sut.processEvent(Scaffolding.event)

        try await context.perform { [context] in
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.conversationID,
                    domain: Scaffolding.domain,
                    in: context
                )
            )

            let alice = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.aliceID,
                    domain: Scaffolding.domain,
                    in: context
                )
            )

            // Then the conversation was renamed.
            XCTAssertEqual(conversation.userDefinedName, Scaffolding.event.newName)

            // Then a system message was inserted.
            let lastMessage = try XCTUnwrap(conversation.lastMessage)
            let systemMessage = try XCTUnwrap(lastMessage as? ZMSystemMessage)
            XCTAssertEqual(systemMessage.systemMessageType, .conversationNameChanged)
            XCTAssertEqual(systemMessage.serverTimestamp, Scaffolding.event.timestamp)
            XCTAssertEqual(systemMessage.users, [alice])
            XCTAssertEqual(systemMessage.text, Scaffolding.event.newName)
        }
    }

}

// MARK: - Scaffolding

private enum Scaffolding {

    static let domain = "example.com"
    static let selfUserID = UUID()
    static let aliceID = UUID()
    static let conversationID = UUID()

    static let event = ConversationRenameEvent(
        conversationID: ConversationID(
            uuid: Scaffolding.conversationID,
            domain: Scaffolding.domain
        ),
        senderID: UserID(
            uuid: Scaffolding.aliceID,
            domain: Scaffolding.domain
        ),
        timestamp: .now,
        newName: "I love tests"
    )




}
