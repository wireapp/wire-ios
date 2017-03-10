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
import ZMCDataModel
import WireMessageStrategy

// MARK: - Confirmation message
extension ClientMessageTranscoderTests {
    
    func testThatItInsertAConfirmationMessageWhenReceivingAnEvent() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let event = self.decryptedUpdateEventFromOtherClient(text: "foo", conversation: self.oneToOneConversation)
            
            // WHEN
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            self.syncMOC.saveOrRollback()
            
            // THEN
            guard let confirmationMessage = self.lastConfirmationMessage else { return XCTFail() }
            XCTAssertTrue(confirmationMessage.genericMessage!.hasConfirmation())
            XCTAssertEqual(confirmationMessage.genericMessage!.confirmation.messageId, event.messageNonce()!.transportString())
        }
    }
    
    func testThatItSendsAConfirmationMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let event = self.decryptedUpdateEventFromOtherClient(text: "foo", conversation: self.oneToOneConversation)
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            self.syncMOC.saveOrRollback()
            guard let confirmationMessage = self.lastConfirmationMessage else { return XCTFail() }
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([confirmationMessage])) }
            
            // WHEN
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            
            // THEN
            guard let message = self.outgoingEncryptedMessage(from: request, for: self.otherClient) else { return XCTFail() }
            XCTAssertTrue(message.hasConfirmation())
        }
    }
    
    func testThatItDeletesTheConfirmationMessageWhenSentSuccessfully() {
        
        // GIVEN
        var confirmationMessage: ZMMessage!
        self.syncMOC.performGroupedBlockAndWait {
            
            let event = self.decryptedUpdateEventFromOtherClient(text: "foo", conversation: self.oneToOneConversation)            
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            self.syncMOC.saveOrRollback()
            guard let confirmMessage = self.lastConfirmationMessage else { return XCTFail() }
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([confirmMessage])) }
            confirmationMessage = confirmMessage
            
            // WHEN
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            request.complete(with: ZMTransportResponse(payload: NSDictionary(), httpStatus: 200, transportSessionError: nil))
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(confirmationMessage.isZombieObject)
        }
    }

    func testThatItDoesSyncAConfirmationMessageIfSenderUserIsNotSpecifiedButIsInferedWithConntection() {
        
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            // receive message
            let text = "This is the message!"
            let event = self.decryptedUpdateEventFromOtherClient(text: text, conversation: self.oneToOneConversation)
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            self.syncMOC.saveOrRollback()
            
            guard let confirmMessage = self.lastConfirmationMessage else { return XCTFail() }
            guard let originalMessage = self.oneToOneConversation.messages.lastObject as? ZMClientMessage else { return XCTFail() }
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([confirmMessage])) }
            
            // WHEN
            // remove sender
            originalMessage.sender = nil
            self.syncMOC.saveOrRollback()
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            
            // THEN
            guard let message = self.outgoingEncryptedMessage(from: request, for: self.otherClient) else { return XCTFail() }
            XCTAssertTrue(message.hasConfirmation())
        }
    }
    
    func testThatItDoesSyncAConfirmationMessageIfSenderUserAndConnectIsNotSpecifiedButIsWithConversation() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            // receive message
            let text = "This is the message!"
            let event = self.decryptedUpdateEventFromOtherClient(text: text, conversation: self.oneToOneConversation)
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            self.syncMOC.saveOrRollback()
            
            // find confirmation
            guard let confirmMessage = self.lastConfirmationMessage else { return XCTFail() }
            guard let originalMessage = self.oneToOneConversation.messages.lastObject as? ZMClientMessage else { return XCTFail() }
            guard originalMessage.textMessageData?.messageText == text else { return XCTFail("wrong message?") }
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([confirmMessage])) }
            
            // WHEN
            // remove sender and connection
            self.oneToOneConversation.connection = nil
            originalMessage.sender = nil
            self.syncMOC.saveOrRollback()
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            
            // THEN
            guard let message = self.outgoingEncryptedMessage(from: request, for: self.otherClient) else { return XCTFail() }
            XCTAssertTrue(message.hasConfirmation())
        }
    }
    
    func testThatItDoesNotSyncAConfirmationMessageIfCannotInferUser() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            // receive message
            let text = "This is the message!"
            let event = self.decryptedUpdateEventFromOtherClient(text: text, conversation: self.oneToOneConversation)
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            self.syncMOC.saveOrRollback()
            
            // find confirmation
            guard let confirmMessage = self.lastConfirmationMessage else { return XCTFail() }
            guard let originalMessage = self.oneToOneConversation.messages.lastObject as? ZMClientMessage else { return XCTFail() }
            guard originalMessage.textMessageData?.messageText == text else { return XCTFail("wrong message?") }
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([confirmMessage])) }
            
            // WHEN
            // remove sender and connection
            self.oneToOneConversation.connection = nil
            originalMessage.sender = nil
            self.oneToOneConversation.mutableOtherActiveParticipants.removeAllObjects()
            self.syncMOC.saveOrRollback()
            
            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItCallsConfirmationStatusWhenReceivingAnEventThroughPush() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let event = self.decryptedUpdateEventFromOtherClient(text: "foo",
                                                                 conversation: self.oneToOneConversation,
                                                                 source: .pushNotification)
            
            // WHEN
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            
            // THEN
            guard let confirmMessage = self.lastConfirmationMessage else { return XCTFail() }
            XCTAssertTrue(self.confirmationStatus.messagesToConfirm.contains(confirmMessage.nonce))
        }
    }
    
    func testThatItDoesNotCallsConfirmationStatusWhenReceivingAnEventThroughWebSocket() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let event = self.decryptedUpdateEventFromOtherClient(text: "foo",
                                                                 conversation: self.oneToOneConversation,
                                                                 source: .webSocket)
            
            // WHEN
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            
            // THEN
            guard let confirmMessage = self.lastConfirmationMessage else { return XCTFail() }
            XCTAssertFalse(self.confirmationStatus.messagesToConfirm.contains(confirmMessage.nonce))
        }
    }
    
    func testThatItDoesNotCallsConfirmationStatusWhenReceivingAnEventThroughDownload() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let event = self.decryptedUpdateEventFromOtherClient(text: "foo",
                                                                 conversation: self.oneToOneConversation,
                                                                 source: .download)
            
            // WHEN
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            
            // THEN
            guard let confirmMessage = self.lastConfirmationMessage else { return XCTFail() }
            XCTAssertFalse(self.confirmationStatus.messagesToConfirm.contains(confirmMessage.nonce))
            XCTAssertFalse(self.confirmationStatus.messagesConfirmed.contains(confirmMessage.nonce))
        }
    }
    
    func testThatItCallsConfirmationStatusWhenConfirmationMessageIsSentSuccessfully() {
        var confirmationNonce: UUID!
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let event = self.decryptedUpdateEventFromOtherClient(text: "foo", conversation: self.oneToOneConversation)
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            self.syncMOC.saveOrRollback()
            guard let confirmationMessage = self.lastConfirmationMessage else { return XCTFail() }
            confirmationNonce = confirmationMessage.nonce!
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([confirmationMessage])) }
            
            // WHEN
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            request.complete(with: ZMTransportResponse(payload: NSDictionary(), httpStatus: 200, transportSessionError: nil))
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(self.confirmationStatus.messagesConfirmed.contains(confirmationNonce))
        }
    }

}

// MARK: - Helpers
extension ClientMessageTranscoderTests {
    
    /// Last confirmation message in the one to one conversation
    var lastConfirmationMessage: ZMClientMessage? {
        for message in self.oneToOneConversation.hiddenMessages.array.reversed() {
            guard let clientMessage = message as? ZMClientMessage else { continue }
            if clientMessage.genericMessage!.hasConfirmation() {
                return clientMessage
            }
        }
        return nil
    }
}

