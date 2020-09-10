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
            let message = GenericMessage(content: Cleared(timestamp: clearedDate, conversationID: self.syncConversation.remoteIdentifier!), nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)
            
            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)
            
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
            let message = GenericMessage(content: LastRead(conversationID: self.syncConversation.remoteIdentifier!, lastReadTimestamp: lastReadDate), nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)
            self.syncConversation.lastReadServerTimeStamp = nil
            
            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)
            
            // then
            XCTAssertNil(self.syncConversation.lastReadServerTimeStamp)
        }
        
    }
    
    func testThatWeIgnoreHideMessageEventNotSentFromSelfUser() {
        
        syncMOC.performGroupedBlockAndWait {
            // given
            let nonce = UUID()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let toBehiddenMessage = try! self.syncConversation.appendText(content: "hello") as! ZMClientMessage
            let hideMessage = MessageHide(conversationId: self.syncConversation.remoteIdentifier!, messageId: toBehiddenMessage.nonce!)
            let message = GenericMessage(content: hideMessage, nonce: nonce)
            let event = self.createUpdateEvent(nonce, conversationID: selfConversation.remoteIdentifier!, timestamp: Date(), genericMessage: message, senderID: UUID(), eventSource: ZMUpdateEventSource.download)
            
            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)
            
            // then
            XCTAssertFalse(toBehiddenMessage.hasBeenDeleted)
        }
        
    }
    
}
