//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import Foundation
@testable import ZMCDataModel

class ZMConversationPrepareToSendTests : ZMConversationTestsBase {
    
    func testThatMessagesAddedToDegradedConversationAreExpiredAndFlaggedAsCauseDegradation() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.securityLevel = .secureWithIgnored
        
        // WHEN
        let message = conversation.appendMessage(withText: "Foo") as! ZMMessage
        self.uiMOC.saveOrRollback()
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            let message = self.syncMOC.object(with: message.objectID) as! ZMMessage
            XCTAssertTrue(message.isExpired)
            XCTAssertTrue(message.causedSecurityLevelDegradation)
        }
    }
    
    func testThatMessagesResentToDegradedConversationAreExpiredAndFlaggedAsCauseDegradation() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.securityLevel = .secure
        let message = conversation.appendMessage(withText: "Foo") as! ZMMessage
        message.expire()
        self.uiMOC.saveOrRollback()

        // WHEN
        conversation.securityLevel = .secureWithIgnored
        message.resend()
        self.uiMOC.saveOrRollback()

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            let message = self.syncMOC.object(with: message.objectID) as! ZMMessage
            XCTAssertTrue(message.isExpired)
            XCTAssertTrue(message.causedSecurityLevelDegradation)
        }
    }

}
