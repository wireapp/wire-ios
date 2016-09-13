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
}

// MARK: - Payload creation
extension ClientMessageTests_OTR {

    func testThatCreatesEncryptedDataAndAddsItToGenericMessageAsBlob() {
        self.syncMOC.performGroupedBlockAndWait { 
            let otherUser = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
            otherUser.remoteIdentifier = NSUUID.createUUID()
            let firstClient = self.createClientForUser(otherUser, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            let secondClient = self.createClientForUser(otherUser, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            let selfClients = ZMUser.selfUserInContext(self.syncMOC).clients
            let selfClient = ZMUser.selfUserInContext(self.syncMOC).selfClient()
            let notSelfClients = selfClients.filter { $0 != selfClient }
            
            let nonce = NSUUID.createUUID()
            let builder = ZMGenericMessage.builder()
            let textBuilder = ZMText.builder()
            textBuilder.setContent(self.textMessageRequiringExternalMessage(2))
            builder.setText(textBuilder.build())
            builder.setMessageId(nonce.transportString())
            let textMessage = builder.build()
            
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.conversationType = .Group
            conversation.remoteIdentifier = NSUUID.createUUID()
            conversation.addParticipant(otherUser)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when
            guard let dataAndStrategy = textMessage.encryptedMessagePayloadData(conversation, externalData: nil) else {
                XCTFail()
                return
            }
            
            // then
            guard let createdMessage = ZMNewOtrMessage.builder().mergeFromData(dataAndStrategy.data).build() as? ZMNewOtrMessage else {
                XCTFail()
                return
            }
            XCTAssertEqual(createdMessage.hasBlob(), true)
                        let clientIds = (createdMessage.recipients as! [ZMUserEntry]).flatMap { userEntry -> [ZMClientId] in
                return (userEntry.clients as! [ZMClientEntry]).map { clientEntry -> ZMClientId in
                    return clientEntry.client
                }
            }
            let clientSet = Set(clientIds)
            XCTAssertEqual(clientSet.count, 2 + notSelfClients.count)
            XCTAssertTrue(clientSet.contains(firstClient.clientId))
            XCTAssertTrue(clientSet.contains(secondClient.clientId))
            notSelfClients.forEach{
                XCTAssertTrue(clientSet.contains($0.clientId))
            }
        }
    }
    
    func testThatItCreatesPayloadDataForTextMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            
            //given
            let message = self.syncConversation.appendOTRMessageWithText(self.name, nonce: NSUUID.createUUID())
            
            //when
            guard let payloadAndStrategy = message.encryptedMessagePayloadData() else {
                XCTFail()
                return
            }
            
            //then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .DoNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }
    
    func testThatItCreatesPayloadForZMLastReadMessages() {
        self.syncMOC.performGroupedBlockAndWait {
            // given

            self.syncConversation.lastReadServerTimeStamp = NSDate()
            self.syncConversation.remoteIdentifier = NSUUID()
            let message = ZMConversation.appendSelfConversationWithLastReadOfConversation(self.syncConversation)
            
            self.expectedRecipients = [self.syncSelfUser.remoteIdentifier!.transportString(): [self.syncSelfClient2.remoteIdentifier]]
            
            // when
            guard let payloadAndStrategy = message.encryptedMessagePayloadData() else {
                XCTFail()
                return
            }
            
            // then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .DoNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }

    func testThatItCreatesPayloadForZMClearedMessages() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.clearedTimeStamp = NSDate()
            self.syncConversation.remoteIdentifier = NSUUID()
            let message = ZMConversation.appendSelfConversationWithClearedOfConversation(self.syncConversation)
            
            self.expectedRecipients = [self.syncSelfUser.remoteIdentifier!.transportString(): [self.syncSelfClient2.remoteIdentifier]]
            
            // when
            guard let payloadAndStrategy = message.encryptedMessagePayloadData() else {
                XCTFail()
                return
            }
            
            // then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .DoNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }
    
    func testThatItCreatesPayloadForExternalMessage() {
        
        syncMOC.performGroupedBlockAndWait {
            // given
            let message = self.syncConversation.appendOTRMessageWithText(self.name, nonce: NSUUID.createUUID())
            
            //when
            // when
            guard let payloadAndStrategy = message.encryptedMessagePayloadData() else {
                XCTFail()
                return
            }
            
            // then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .DoNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }
}

// MARK: - Delivery
extension ClientMessageTests_OTR {
    
    func testThatItCreatesPayloadDataForConfirmationMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            
            //given
            let senderID = self.syncUser1.clients.first!.remoteIdentifier
            let textMessage = self.syncConversation.appendOTRMessageWithText(self.stringLargeEnoughToRequireExternal, nonce: NSUUID.createUUID())
            textMessage.sender = self.syncUser1
            textMessage.senderClientID = senderID
            let confirmationMessage = textMessage.confirmReception()
            
            //when
            guard let payloadAndStrategy = confirmationMessage.encryptedMessagePayloadData() else {
                XCTFail()
                return
            }
            
            //then
            switch payloadAndStrategy.strategy {
            case .IgnoreAllMissingClientsNotFromUser(let user):
                XCTAssertEqual(user, self.syncUser1)
            default:
                XCTFail()
            }
            guard let messageMetadata = ZMNewOtrMessageBuilder().mergeFromData(payloadAndStrategy.data).build() as? ZMNewOtrMessage else {
                XCTFail()
                return
            }
            
            if let recipients = messageMetadata.recipients as? [ZMUserEntry] {
                let payloadClients = recipients.flatMap { user -> [String] in
                    return (user.clients as? [ZMClientEntry])?.map({ String(format: "%llx", $0.client.client) }) ?? []
                }.flatMap { $0 }
                XCTAssertEqual(payloadClients.sort(), self.syncUser1.clients.map { $0.remoteIdentifier }.sort())
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
    
    /// Returns a string that is big enough to require external message payload
    private func textMessageRequiringExternalMessage(numberOfClients: UInt) -> String {
        var string = "Exponential growth!"
        while string.dataUsingEncoding(NSUTF8StringEncoding)!.length < Int(ZMClientMessageByteSizeExternalThreshold / numberOfClients) {
            string = string + string
        }
        return string
    }
}
