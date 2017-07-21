//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import WireDataModel


class ZMConversationMessageDestructionTimeoutTests : XCTestCase {

    func testThatItReturnsTheCorrectTimeouts(){
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.none.rawValue, 0)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.fiveSeconds.rawValue, 5)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.fifteenSeconds.rawValue, 15)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.thirtySeconds.rawValue, 30)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.oneMinute.rawValue, 60)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.fiveMinutes.rawValue, 300)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.oneDay.rawValue, 86400)
    }
    
    func testThatItReturnsTheClosestTimeOut() {
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: -2), 5)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 0), 5)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 2), 5)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 5), 5)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 6), 6)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 14), 14)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 15), 15)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 16), 16)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 29), 29)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 30), 30)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 31), 31)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 59), 59)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 60), 60)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 61), 61)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 299), 299)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 300), 300)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 301), 301)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 86399), 86399)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 86400), 86400)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 86401), 86400)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.validTimeout(for: 1234567890), 86400)
    }

}



class ZMConversationTests_Ephemeral : BaseZMMessageTests {

    func testThatItAllowsSettingTimeoutsOnGroupConversations(){
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        
        // when
        conversation.updateMessageDestructionTimeout(timeout: .fiveSeconds)
        
        // then
        XCTAssertEqual(conversation.messageDestructionTimeout, 5)
    }

    
    func testThatItAllowsSettingTimeoutsOnOneOnOneConversations(){
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        
        // when
        conversation.updateMessageDestructionTimeout(timeout: .fiveSeconds)
        
        // then
        XCTAssertEqual(conversation.messageDestructionTimeout, 5)
    }
 
    func testThatSendingEphemeralToEmptyConversationIsNotPossible() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        // when
        conversation.internalAddParticipants(Set(arrayLiteral: selfUser), isAuthoritative: true)
                
        // then
        XCTAssertEqual(conversation.canSendEphemeral, false)
    }
    
    func testThatSendingEphemeralToNormalConversationIsPossible() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        
        // when
        let user = ZMUser.insert(in: uiMOC, name: "Test")
        user.remoteIdentifier = UUID()
        
        conversation.internalAddParticipants(Set(arrayLiteral: selfUser), isAuthoritative: true)
        conversation.addParticipant(user)
        
        // then
        XCTAssertEqual(conversation.canSendEphemeral, true)
    }
}

