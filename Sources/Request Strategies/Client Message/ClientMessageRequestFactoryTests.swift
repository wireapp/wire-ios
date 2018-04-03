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
            let message = self.groupConversation.appendMessage(withText: text) as! ZMClientMessage
            
            // WHEN
            guard let request = ClientMessageRequestFactory().upstreamRequestForMessage(message, forConversationWithId: self.groupConversation.remoteIdentifier!) else {
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
            let message = self.oneToOneConversation.appendMessage(withText: text) as! ZMClientMessage
            message.sender = self.otherUser
            let confirmationMessage = message.confirmReception()!
            
            print("CLIENT ID", (message.conversation?.otherActiveParticipants.firstObject! as! ZMUser).remoteIdentifier!)
            print("OTHER USER", self.otherUser.remoteIdentifier!)
            // WHEN
            guard let request = ClientMessageRequestFactory().upstreamRequestForMessage(confirmationMessage, forConversationWithId: self.oneToOneConversation.remoteIdentifier!) else {
                return XCTFail("No request")
            }
            
            // THEN
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
            XCTAssertEqual(request.path, "/conversations/\(self.oneToOneConversation.remoteIdentifier!.transportString())/otr/messages?report_missing=\(self.otherUser.remoteIdentifier!.transportString())")
            guard let receivedMessage = self.outgoingEncryptedMessage(from: request, for: self.otherClient) else {
                return XCTFail("Invalid message")
            }
            XCTAssertTrue(receivedMessage.hasConfirmation())
        }
    }
}

// MARK: Ephemeral Messages
extension ClientMessageRequestFactoryTests {
    
    func testThatItCreatesRequestToPostEphemeralTextMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let text = "Boo"
            self.groupConversation.messageDestructionTimeout = 10
            let message = self.groupConversation.appendMessage(withText: text) as! ZMClientMessage
            
            // WHEN
            guard let request = ClientMessageRequestFactory().upstreamRequestForMessage(message, forConversationWithId: self.groupConversation.remoteIdentifier!) else {
                return XCTFail()
            }
            
            // THEN
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
            XCTAssertEqual(request.path, "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages?report_missing=\(self.otherUser.remoteIdentifier!.transportString())")
            guard let receivedMessage = self.outgoingEncryptedMessage(from: request, for: self.otherClient) else {
                return XCTFail("Invalid message")
            }
            XCTAssertEqual(receivedMessage.textData?.content, text)
        }
    }
    
}
