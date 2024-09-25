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
import WireRequestStrategySupport
import WireDataModelSupport
@testable import WireDataModel
@testable import WireRequestStrategy

final class ProteusMessageTests: XCTestCase {
    
    var coreDataStack: CoreDataStack!
    var coreDataHelper: CoreDataStackHelper!
    
    override func setUp() async throws {
        try await super.setUp()
        coreDataHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataHelper.createStack()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        coreDataStack = nil
        coreDataHelper = nil
    }
    
    func testThatItUpdatesLegalHoldStatusFlag_WhenLegalHoldIsEnabled() async throws {
        try await internalTestThatItUpdatesLegalHoldStatusFlag_WhenLegalHold(enabled: true)
    }

    func testThatItUpdatesLegalHoldStatusFlag_WhenLegalHoldIsDisabled() async throws {
        try await internalTestThatItUpdatesLegalHoldStatusFlag_WhenLegalHold(enabled: false)
    }

    private func internalTestThatItUpdatesLegalHoldStatusFlag_WhenLegalHold(enabled: Bool, 
                                                                    file: StaticString = #filePath,
                                                                    line: UInt = #line) async throws {
        // Given
        let message = try await coreDataStack.syncContext.perform {
            let conversation = ModelHelper().createGroupConversation(in: self.coreDataStack.syncContext)
            let message = try self.createClientTextMessage(withText: "test", in: self.coreDataStack.syncContext)
            conversation.append(message)
            var genericMessage = try XCTUnwrap(message.underlyingMessage)

            genericMessage.setLegalHoldStatus(enabled ? .disabled : .enabled)
            try message.setUnderlyingMessage(genericMessage)
            conversation.legalHoldStatus = enabled ? .enabled : .disabled
            return message
        }

        // When
         _ = try await message.prepareMessageForSending()

        // Then
        await coreDataStack.syncContext.perform {
            XCTAssertEqual(message.underlyingMessage?.text.legalHoldStatus, enabled ? .enabled : .disabled, file: file, line: line)
        }
    }
    
    private func createClientTextMessage(withText text: String, in context: NSManagedObjectContext) throws -> ZMClientMessage {
        let nonce = UUID.create()
        let message = ZMClientMessage.init(nonce: nonce, managedObjectContext: context )
        let textMessage = GenericMessage(content: Text(content: text, mentions: [], linkPreviews: [], replyingTo: nil), nonce: nonce)

        try message.setUnderlyingMessage(textMessage)
        return message
    }
}
