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


import XCTest
@testable import ZMCDataModel

class ClientMessageTests_OTR: BaseZMClientMessageTests {
    
    var message: ZMClientMessage!
    


    func testThatItCreatesPayloadDataForTextMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            
            //given
            self.message = self.conversation.appendOTRMessageWithText(self.name, nonce: NSUUID.createUUID())
            
            //when
            let payload = self.message.encryptedMessagePayloadData()
            
            //then
            self.assertMessageMetadata(payload)
        }
    }
    
    func testThatItCreatesPayloadForZMLastReadMessages() {
        self.syncMOC.performGroupedBlockAndWait {
            // given

            self.conversation.lastReadServerTimeStamp = NSDate()
            self.conversation.remoteIdentifier = NSUUID()
            self.message = ZMConversation.appendSelfConversationWithLastReadOfConversation(self.conversation)
            
            self.expectedRecipients = [self.selfUser.remoteIdentifier!.transportString(): [self.selfClient2.remoteIdentifier]]
            
            // when
            let payload = self.message.encryptedMessagePayloadData()
            
            // then
            self.assertMessageMetadata(payload)
        }
    }

    func testThatItCreatesPayloadForZMClearedMessages() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.conversation.clearedTimeStamp = NSDate()
            self.conversation.remoteIdentifier = NSUUID()
            self.message = ZMConversation.appendSelfConversationWithClearedOfConversation(self.conversation)
            
            self.expectedRecipients = [self.selfUser.remoteIdentifier!.transportString(): [self.selfClient2.remoteIdentifier]]
            
            // when
            let payload = self.message.encryptedMessagePayloadData()
            
            // then
            self.assertMessageMetadata(payload)
        }
    }
    
    func testThatItCreatesPayloadForExternalMessage() {
        
        syncMOC.performGroupedBlockAndWait {
            // given
            self.message = self.conversation.appendOTRMessageWithText(self.name, nonce: NSUUID.createUUID())
            
            //when
            let payload = self.message.encryptedMessagePayloadData()
            
            //then
            self.assertMessageMetadata(payload)
        }
    }
}

// MARK: - Delivery
extension ClientMessageTests_OTR {
    
    func testThatItCreatesPayloadDataForConfirmationMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            
            //given
            let senderID = self.user1.clients.first!.remoteIdentifier
            let textMessage = self.conversation.appendOTRMessageWithText(self.stringLargeEnoughToRequireExternal, nonce: NSUUID.createUUID())
            textMessage.sender = self.user1
            textMessage.senderClientID = senderID
            let confirmationMessage = textMessage.confirmReception()
            
            //when
            let payload = confirmationMessage.encryptedMessagePayloadData()
            
            //then
            guard let messageMetadata = ZMNewOtrMessageBuilder().mergeFromData(payload).build() as? ZMNewOtrMessage else {
                XCTFail()
                return
            }
            
            if let recipients = messageMetadata.recipients as? [ZMUserEntry] {
                let payloadClients = recipients.flatMap { user -> [String] in
                    return (user.clients as? [ZMClientEntry])?.map({ String(format: "%llx", $0.client.client) }) ?? []
                }.flatMap { $0 }
                XCTAssertEqual(payloadClients.sort(), self.user1.clients.map { $0.remoteIdentifier }.sort())
            } else {
                XCTFail("Metadata does not contain recipients")
            }
        }
    }
    
}

// MARK: - Helper
extension ClientMessageTests_OTR {
    
    /// Returns a string large enough to have to be encoded in an external message
    private var stringLargeEnoughToRequireExternal: String {
        var text = "Hello"
        while (text.dataUsingEncoding(NSUTF8StringEncoding)?.length < Int(ZMClientMessageByteSizeExternalThreshold)) {
            text.appendContentsOf(text)
        }
        return text
    }
    
    /// Asserts that the message metadata is as expected
    private func assertMessageMetadata(payload: NSData!, file: StaticString = #file, line: UInt = #line) {
        guard let messageMetadata = ZMNewOtrMessageBuilder().mergeFromData(payload).build() as? ZMNewOtrMessage else {
            XCTFail(file: file, line: line)
            return
        }
        if let sender = messageMetadata.sender {
            XCTAssertEqual(sender.client, self.selfClient1.clientId.client, file: file, line: line)
        } else {
            XCTFail("Metadata does not contain sender", file: file, line: line)
        }
        if let recipients = messageMetadata.recipients as? [ZMUserEntry] {
            self.assertRecipients(recipients, file: file, line: line)
        } else {
            XCTFail("Metadata does not contain recipients", file: file, line: line)
        }
    }
}
