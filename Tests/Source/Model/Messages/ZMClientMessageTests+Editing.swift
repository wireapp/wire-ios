//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class ZMClientMessageTests_TextMessageData : BaseZMClientMessageTests {
    
    func testThatItUpdatesTheMesssageText_WhenEditing(){
        
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = UUID.create()
        
        let message = conversation.append(text: "hello") as! ZMClientMessage
        message.delivered = true
        
        // when
        message.textMessageData?.editText("good bye", mentions: [], fetchLinkPreview: false)
        
        // then
        XCTAssertEqual(message.textMessageData?.messageText, "good bye")
    }
    
    func testThatItClearReactions_WhenEditing(){
        
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = UUID.create()
        
        let message = conversation.append(text: "hello") as! ZMClientMessage
        message.delivered = true
        message.addReaction("🤠", forUser: selfUser)
        XCTAssertFalse(message.reactions.isEmpty)
        
        // when
        message.textMessageData?.editText("good bye", mentions: [], fetchLinkPreview: false)
        
        // then
        XCTAssertTrue(message.reactions.isEmpty)
    }
    
    func testThatItKeepsQuote_WhenEditing(){
        
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = UUID.create()
        
        let quotedMessage = conversation.append(text: "Let's grab some lunch") as! ZMClientMessage
        let message = conversation.append(text: "Yes!", replyingTo: quotedMessage) as! ZMClientMessage
        message.delivered = true
        XCTAssertTrue(message.hasQuote)
        
        // when
        message.textMessageData?.editText("good bye", mentions: [], fetchLinkPreview: false)
        
        // then
        XCTAssertTrue(message.hasQuote)
    }
    
}
