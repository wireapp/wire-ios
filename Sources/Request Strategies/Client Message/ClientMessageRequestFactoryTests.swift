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
import WireProtos
import WireDataModel
import WireUtilities
@testable import WireRequestStrategy

class ClientMessageRequestFactoryTests: MessagingTestBase {
}

// MARK: - Text messages
extension ClientMessageRequestFactoryTests {
    
    func testThatItCreatesRequestToPostOTRTextMessage() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let text = "Antani"
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            
            // WHEN
            guard let request = ClientMessageRequestFactory().upstreamRequestForMessage(message, in: self.groupConversation, useFederationEndpoint: false) else {
                return XCTFail("No request")
            }
            
            // THEN
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
            XCTAssertEqual(request.path, "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages")
            
            guard let receivedMessage = self.outgoingEncryptedMessage(from: request, for: self.otherClient) else {
                return XCTFail("Invalid message")
            }
            XCTAssertEqual(receivedMessage.textData?.content, text)
        }
    }
}

// MARK: - Confirmation Messages
extension ClientMessageRequestFactoryTests {
    
    func testThatItCreatesRequestToPostOTRConfirmationMessage() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let text = "Antani"
            let message = try! self.oneToOneConversation.appendText(content: text) as! ZMClientMessage
            message.sender = self.otherUser
            let confirmation = Confirmation(messageId: message.nonce!, type: .delivered)
            let confirmationMessage = try! self.oneToOneConversation.appendClientMessage(with: GenericMessage(content: confirmation), expires: false, hidden: true)
            
            // WHEN
            guard let request = ClientMessageRequestFactory().upstreamRequestForMessage(confirmationMessage, in: self.oneToOneConversation, useFederationEndpoint: false) else {
                return XCTFail("No request")
            }
            
            // THEN
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
            XCTAssertEqual(request.path, "/conversations/\(self.oneToOneConversation.remoteIdentifier!.transportString())/otr/messages")
            guard let receivedMessage = self.outgoingEncryptedMessage(from: request, for: self.otherClient) else {
                return XCTFail("Invalid message")
            }
            XCTAssertTrue(receivedMessage.hasConfirmation)
        }
    }
}

// MARK: Ephemeral Messages
extension ClientMessageRequestFactoryTests {
    
    func testThatItCreatesRequestToPostEphemeralTextMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let text = "Boo"
            self.groupConversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
            let message = try! self.groupConversation.appendText(content: text) as! ZMClientMessage
            
            // WHEN
            guard let request = ClientMessageRequestFactory().upstreamRequestForMessage(message, in: self.groupConversation, useFederationEndpoint: false) else {
                return XCTFail()
            }
            
            // THEN
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
            XCTAssertEqual(request.path, "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages")
            guard let receivedMessage = self.outgoingEncryptedMessage(from: request, for: self.otherClient) else {
                return XCTFail("Invalid message")
            }
            XCTAssertEqual(receivedMessage.textData?.content, text)
        }
    }
    
}

// MARK: - Targeted messages
extension ClientMessageRequestFactoryTests {

    func testThatItCreatesRequestToPostTargetedOTRTextMessage() {

        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let text = "Antani"
            let entity = GenericMessageEntity(conversation: self.groupConversation,
                                              message: GenericMessage(content: Text(content: text)),
                                              targetRecipients: .clients([self.otherUser: Set(arrayLiteral: self.otherClient)]),
                                              completionHandler: nil)

            // WHEN
            guard let request = ClientMessageRequestFactory().upstreamRequestForMessage(entity, in: self.groupConversation, useFederationEndpoint: false) else {
                return XCTFail("No request")
            }

            // THEN
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
            XCTAssertEqual(request.path, "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages?ignore_missing=true")

            guard let receivedMessage = self.outgoingEncryptedMessage(from: request, for: self.otherClient) else {
                return XCTFail("Invalid message")
            }

            XCTAssertEqual(receivedMessage.textData?.content, text)
        }
    }
}
