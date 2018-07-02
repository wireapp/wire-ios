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

import XCTest

class ZMOTRMessage_SelfConversationUpdateEventTests: BaseZMClientMessageTests {
    
    
    func testThatWeIgnoreClearedEventNotSentFromSelfUser() {
        
        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let clearedDate = Date()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let message = ZMGenericMessage(clearedTimestamp: clearedDate, ofConversationWith: self.syncConversation.remoteIdentifier!, nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)
            
            // when
            ZMOTRMessage.messageUpdateResult(from: event, in: self.syncMOC, prefetchResult: nil)
            
            // then
            XCTAssertNil(self.syncConversation.clearedTimeStamp)
        }
        
    }
    
    func testThatWeIgnoreLastReadEventNotSentFromSelfUser() {
        
        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let lastReadDate = Date()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let message = ZMGenericMessage(lastRead: lastReadDate, ofConversationWith: self.syncConversation.remoteIdentifier!, nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)
            self.syncConversation.lastReadServerTimeStamp = nil
            
            // when
            ZMOTRMessage.messageUpdateResult(from: event, in: self.syncMOC, prefetchResult: nil)
            
            // then
            XCTAssertNil(self.syncConversation.lastReadServerTimeStamp)
        }
        
    }
    
    func testThatWeIgnoreHideMessageEventNotSentFromSelfUser() {
        
        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let toBehiddenMessage = self.syncConversation.appendMessage(withText: "hello") as! ZMClientMessage
            let message = ZMGenericMessage(hideMessage: toBehiddenMessage.nonce!, inConversation: self.syncConversation.remoteIdentifier!, nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)
            
            // when
            ZMOTRMessage.messageUpdateResult(from: event, in: self.syncMOC, prefetchResult: nil)
            
            // then
            XCTAssertFalse(toBehiddenMessage.hasBeenDeleted)
        }
        
    }
    
}
