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
import XCTest
import WireMessageStrategy
import WireDataModel

extension ClientMessageTranscoderTests {
    
    func recreateSut() {
        self.sut = ClientMessageTranscoder(in: self.syncMOC, localNotificationDispatcher: self.localNotificationDispatcher, clientRegistrationStatus: self.clientRegistrationStatus, apnsConfirmationStatus: self.confirmationStatus)
    }
    
    func testThatItDoesNotObfuscatesEphemeralMessagesOnStart_SenderSelfUser_TimeNotPassed() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            self.sut.tearDown()
            self.sut = nil
            self.groupConversation.messageDestructionTimeout = 10
            let message = self.groupConversation.appendMessage(withText: "Foo")! as! ZMClientMessage
            message.markAsSent()
            self.syncMOC.saveOrRollback()
            
            // WHEN
            self.recreateSut()
            
            // THEN
            XCTAssertFalse(message.isObfuscated)
        }
    }
    
    func testThatItObfuscatesEphemeralMessagesOnStart_SenderSelfUser_TimePassed() {
        
        // GIVEN
        var message: ZMClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            
            self.groupConversation.messageDestructionTimeout = 1
            message = self.groupConversation.appendMessage(withText: "Foo")! as! ZMClientMessage
            message.markAsSent()
            self.syncMOC.saveOrRollback()
            XCTAssertFalse(message.isObfuscated)
            XCTAssertNotNil(message.sender)
            XCTAssertNotNil(message.destructionDate)
        }
        
        // WHEN
        self.sut.tearDown()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.recreateSut()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.spinMainQueue(withTimeout: 2)
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(message.isObfuscated)
            XCTAssertTrue(self.groupConversation.messages.contains(message))
        }
    }

    @available(iOS 8.3, *)
    func testThatItDeletesEphemeralMessagesOnStart_SenderOtherUser_TimePassed() {
        
        // GIVEN
        let text = "Come fosse antani"
        self.syncMOC.performGroupedBlockAndWait {
            // the timeout here has to be at least 5. If I return something smaller, it will anyway be approximated to 5 internally
            // as it's the lowest allowed timeout
            let generic = ZMGenericMessage.message(text: text, nonce: UUID.create().transportString(), expiresAfter: 5)
            let event = self.decryptedUpdateEventFromOtherClient(message: generic)
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            self.syncMOC.saveOrRollback()
            self.sut.tearDown()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    
        // simulate "reading it"
        let uiConversation = try! self.uiMOC.existingObject(with: self.groupConversation.objectID) as! ZMConversation
        let message = uiConversation.messages.lastObject as! ZMConversationMessage
        _ = message.startSelfDestructionIfNeeded()
        self.uiMOC.saveOrRollback()
        
        // stop all timers
        self.stopEphemeralMessageTimers()
        
        // WHEN
        self.spinMainQueue(withTimeout: 8)
        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.refreshAllObjects()
        }
        self.recreateSut()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.saveOrRollback()
        }
        
        // THEN
        self.uiMOC.refreshAllObjects()
        XCTAssertNotEqual(message.textMessageData?.messageText, text) // or at least, it should not be one with that message
    }
    
    @available(iOS 8.3, *)
    func testThatItDoesNotDeletesEphemeralMessagesOnStart_SenderOtherUser_TimeNotPassed() {
        
        // GIVEN
        let text = "Come fosse antani"
        self.syncMOC.performGroupedBlockAndWait {
            // the timeout here has to be at least 5. If I return something smaller, it will anyway be approximated to 5
            let generic = ZMGenericMessage.message(text: text, nonce: UUID.create().transportString(), expiresAfter: 5)
            let event = self.decryptedUpdateEventFromOtherClient(message: generic)
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            self.syncMOC.saveOrRollback()
            self.sut.tearDown()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // simulate "reading it"
        let uiConversation = try! self.uiMOC.existingObject(with: self.groupConversation.objectID) as! ZMConversation
        let message = uiConversation.messages.lastObject as! ZMConversationMessage
        _ = message.startSelfDestructionIfNeeded()
        self.uiMOC.saveOrRollback()
        
        // stop all timers
        self.stopEphemeralMessageTimers()
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.refreshAllObjects()
            self.recreateSut()
            self.syncMOC.saveOrRollback()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.uiMOC.refreshAllObjects()
        XCTAssertEqual(message.textMessageData?.messageText, text) // or at least, it should not be one with that message
    }
}

