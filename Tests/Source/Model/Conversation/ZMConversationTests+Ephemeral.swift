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
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.tenSeconds.rawValue, 10)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.fiveMinutes.rawValue, 300)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.oneHour.rawValue, 3600)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.oneDay.rawValue, 86400)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.oneWeek.rawValue, 604800)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout.fourWeeks.rawValue, 2419200)
    }

    func testThatItCreatesAValidTimeOut() {
        XCTAssertEqual(ZMConversationMessageDestructionTimeout(rawValue: -2), .custom(-2))
        XCTAssertEqual(ZMConversationMessageDestructionTimeout(rawValue: 0), .none)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout(rawValue: 10), .tenSeconds)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout(rawValue: 300), .fiveMinutes)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout(rawValue: 3600), .oneHour)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout(rawValue: 86400), .oneDay)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout(rawValue: 604800), .oneWeek)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout(rawValue: 690000), .custom(690000))
        XCTAssertEqual(ZMConversationMessageDestructionTimeout(rawValue: 2419200), .fourWeeks)
        XCTAssertEqual(ZMConversationMessageDestructionTimeout(rawValue: 1234567890), .custom(1234567890))
    }

}



class ZMConversationTests_Ephemeral : BaseZMMessageTests {

    func testThatItAllowsSettingTimeoutsOnGroupConversations(){
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        
        // when
        conversation.updateMessageDestructionTimeout(timeout: .tenSeconds)
        
        // then
        XCTAssertEqual(conversation.messageDestructionTimeout, 10)
    }

    
    func testThatItAllowsSettingTimeoutsOnOneOnOneConversations(){
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        
        // when
        conversation.updateMessageDestructionTimeout(timeout: .tenSeconds)
        
        // then
        XCTAssertEqual(conversation.messageDestructionTimeout, 10)
    }
}

