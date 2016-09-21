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
            let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            let firstClient = self.createClient(for: otherUser, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            let secondClient = self.createClient(for: otherUser, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            let selfClients = ZMUser.selfUser(in: self.syncMOC).clients!
            let selfClient = ZMUser.selfUser(in: self.syncMOC).selfClient()
            let notSelfClients = selfClients.filter { $0 != selfClient }
            
            let nonce = UUID.create()
            let builder = ZMGenericMessage.builder()!
            let textBuilder = ZMText.builder()!
            textBuilder.setContent(self.textMessageRequiringExternalMessage(2))
            builder.setText(textBuilder.build()!)
            builder.setMessageId(nonce.transportString())
            let textMessage = builder.build()!
            
            let conversation = ZMConversation.insertNewObject(in:self.syncMOC)
            conversation.conversationType = .group
            conversation.remoteIdentifier = UUID.create()
            conversation.addParticipant(otherUser)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when
            guard let dataAndStrategy = textMessage.encryptedMessagePayloadData(conversation, externalData: nil)
            else { return XCTFail() }
            
            // then
            guard let createdMessage = ZMNewOtrMessage.builder()!.merge(from: dataAndStrategy.data).build()! as? ZMNewOtrMessage
            else { return XCTFail() }
            
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
            let message = self.syncConversation.appendOTRMessage(withText: self.name!, nonce: UUID.create())
            
            //when
            guard let payloadAndStrategy = message.encryptedMessagePayloadData() else {
                XCTFail()
                return
            }
            
            //then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .doNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }
    
    func testThatItCreatesPayloadForZMLastReadMessages() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.lastReadServerTimeStamp = Date()
            self.syncConversation.remoteIdentifier = UUID()
            let message = ZMConversation.appendSelfConversation(withLastReadOf: self.syncConversation)
            
            self.expectedRecipients = [self.syncSelfUser.remoteIdentifier!.transportString(): [self.syncSelfClient2.remoteIdentifier!]]
            
            // when
            guard let payloadAndStrategy = message.encryptedMessagePayloadData() else {
                XCTFail()
                return
            }
            
            // then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .doNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }

    func testThatItCreatesPayloadForZMClearedMessages() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.clearedTimeStamp = Date()
            self.syncConversation.remoteIdentifier = UUID()
            let message = ZMConversation.appendSelfConversation(withClearedOf: self.syncConversation)
            
            self.expectedRecipients = [self.syncSelfUser.remoteIdentifier!.transportString(): [self.syncSelfClient2.remoteIdentifier!]]
            
            // when
            guard let payloadAndStrategy = message.encryptedMessagePayloadData() else {
                XCTFail()
                return
            }
            
            // then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .doNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }
    
    func testThatItCreatesPayloadForExternalMessage() {
        
        syncMOC.performGroupedBlockAndWait {
            // given
            let message = self.syncConversation.appendOTRMessage(withText: self.name!, nonce: UUID.create())
            
            //when
            // when
            guard let payloadAndStrategy = message.encryptedMessagePayloadData() else {
                XCTFail()
                return
            }
            
            // then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .doNotIgnoreAnyMissingClient:
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
            let textMessage = self.syncConversation.appendOTRMessage(withText: self.stringLargeEnoughToRequireExternal, nonce: UUID.create())
            textMessage.sender = self.syncUser1
            textMessage.senderClientID = senderID
            let confirmationMessage = textMessage.confirmReception()
            
            //when
            guard let payloadAndStrategy = confirmationMessage?.encryptedMessagePayloadData()
            else { return XCTFail()}
            
            //then
            switch payloadAndStrategy.strategy {
            case .ignoreAllMissingClientsNotFromUser(let user):
                XCTAssertEqual(user, self.syncUser1)
            default:
                XCTFail()
            }
            guard let messageMetadata = ZMNewOtrMessageBuilder().merge(from: payloadAndStrategy.data).build()! as? ZMNewOtrMessage else {
                XCTFail()
                return
            }
            
            if let recipients = messageMetadata.recipients as? [ZMUserEntry] {
                let payloadClients = recipients.flatMap { user -> [String] in
                    return (user.clients as? [ZMClientEntry])?.map({ String(format: "%llx", $0.client.client) }) ?? []
                }.flatMap { $0 }
                XCTAssertEqual(payloadClients.sorted(), self.syncUser1.clients.map { $0.remoteIdentifier! }.sorted())
            } else {
                XCTFail("Metadata does not contain recipients")
            }
        }
    }
    
}

// MARK: - Helper
extension ClientMessageTests_OTR {
    
    /// Returns a string large enough to have to be encoded in an external message
    fileprivate var stringLargeEnoughToRequireExternal: String {
        var text = "Hello"
        while (text.data(using: String.Encoding.utf8)!.count < Int(ZMClientMessageByteSizeExternalThreshold)) {
            text.append(text)
        }
        return text
    }
    
    /// Asserts that the message metadata is as expected
    fileprivate func assertMessageMetadata(_ payload: Data!, file: StaticString = #file, line: UInt = #line) {
        guard let messageMetadata = ZMNewOtrMessageBuilder().merge(from: payload).build()! as? ZMNewOtrMessage else {
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
    fileprivate func textMessageRequiringExternalMessage(_ numberOfClients: UInt) -> String {
        var string = "Exponential growth!"
        while string.data(using: String.Encoding.utf8)!.count < Int(ZMClientMessageByteSizeExternalThreshold / numberOfClients) {
            string = string + string
        }
        return string
    }
}
