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

import WireDataModelSupport
import XCTest
@testable import WireRequestStrategy

// MARK: - MessageLogAttributesBuilderTests

final class MessageLogAttributesBuilderTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()

        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
    }

    override func tearDown() async throws {
        try coreDataStackHelper.cleanupDirectory()

        coreDataStackHelper = nil
        try await super.tearDown()
    }

    func testLogAttributes_givenZMClientMessage() async throws {
        // given
        let builder = makeBuilder()

        let clientMessage = try await context.perform {
            let genericMessage = GenericMessage(content: Text(content: "test"), nonce: Scaffolding.nonce)

            let conversation = ZMConversation(context: self.context)
            conversation.remoteIdentifier = Scaffolding.remoteIdentifier
            conversation.domain = "wire.com"

            let message = ZMClientMessage(nonce: Scaffolding.nonce, managedObjectContext: self.context)
            try message.setUnderlyingMessage(genericMessage)
            message.visibleInConversation = conversation

            return message
        }

        // when
        let attributes = await builder.logAttributes(clientMessage)

        // then
        XCTAssertEqual(attributes[.nonce] as? String, "9cb5d6f***")
        XCTAssertEqual(attributes[.messageType] as? String, "text")
        XCTAssertEqual(attributes[.conversationId] as? String, "f4d0b09*** - wire***")
        XCTAssertEqual(attributes[.public] as? Bool, true)
    }

    // MARK: Private

    // add more tests for supported types, but some are difficult to mock.

    private var coreDataStackHelper: CoreDataStackHelper!
    private var coreDataStack: CoreDataStack!

    private var context: NSManagedObjectContext { coreDataStack.viewContext }

    // MARK: Helpers

    private func makeBuilder() -> MessageLogAttributesBuilder {
        MessageLogAttributesBuilder(context: context)
    }
}

// MARK: - Scaffolding

private enum Scaffolding {
    static let nonce = UUID(uuidString: "9CB5D6FA-875E-406B-AA66-6A93F031FF5F")!
    static let remoteIdentifier = UUID(uuidString: "F4D0B090-53FD-491E-B4C8-815F840096A6")!
}
