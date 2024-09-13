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

import XCTest

@testable import WireDataModel

final class ZMConversationPrepareToSendTests: ZMConversationTestsBase {
    func testThatMessagesAddedToDegradedConversationAreExpiredAndFlaggedAsCauseDegradation() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.securityLevel = .secureWithIgnored

        // WHEN
        let message = try! conversation.appendText(content: "Foo") as! ZMMessage
        uiMOC.saveOrRollback()

        // THEN
        syncMOC.performGroupedAndWait {
            let message = self.syncMOC.object(with: message.objectID) as! ZMMessage
            XCTAssertTrue(message.isExpired)
            XCTAssertTrue(message.causedSecurityLevelDegradation)
        }
    }

    func testThatMessagesAddedToDegradedMlsConversationAreExpiredAndFlaggedAsCauseDegradation() throws {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.messageProtocol = .mls
        conversation.mlsVerificationStatus = .degraded

        // WHEN
        let message = try XCTUnwrap(
            conversation.appendText(content: "Foo") as? ZMMessage
        )
        uiMOC.saveOrRollback()

        // THEN
        try syncMOC.performAndWait {
            let message = try XCTUnwrap(self.syncMOC.object(with: message.objectID) as? ZMMessage)
            XCTAssertTrue(message.isExpired)
            XCTAssertTrue(message.causedSecurityLevelDegradation)
        }
    }

    func testThatMessagesResentToDegradedConversationAreExpiredAndFlaggedAsCauseDegradation() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.securityLevel = .secure
        let message = try! conversation.appendText(content: "Foo") as! ZMMessage
        message.expire()
        uiMOC.saveOrRollback()

        // WHEN
        conversation.securityLevel = .secureWithIgnored
        message.resend()
        uiMOC.saveOrRollback()

        // THEN
        syncMOC.performGroupedAndWait {
            let message = self.syncMOC.object(with: message.objectID) as! ZMMessage
            XCTAssertTrue(message.isExpired)
            XCTAssertTrue(message.causedSecurityLevelDegradation)
        }
    }
}
