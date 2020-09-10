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
import WireDataModel


// MARK: - Dependency
extension ClientMessageTranscoderTests {
    
    func testThatItReturnsNewClientAsDependentObjectForMessageIfItHasNotBeenFetched() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            
            // WHEN
            self.otherClient.needsToBeUpdatedFromBackend = true
            
            // THEN
            let dependency = self.sut.dependentObjectNeedingUpdate(beforeProcessingObject: message)
            XCTAssertEqual(dependency as? UserClient, self.otherClient)
        }
    }
    
    func testThatItReturnsSelfClientAsDependentObjectForMessageIfItHasMissingClients() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            
            // WHEN
            self.selfClient.missesClient(self.otherClient)
            
            // THEN
            let dependency = self.sut.dependentObjectNeedingUpdate(beforeProcessingObject: message)
            XCTAssertEqual(dependency as? UserClient, self.selfClient)
        }
    }
    
    func testThatItReturnsConversationIfNeedsToBeUpdatedFromBackendBeforeMissingClients() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            
            // WHEN
            self.selfClient.missesClient(self.otherClient)
            self.groupConversation.needsToBeUpdatedFromBackend = true
            
            // THEN
            let dependency = self.sut.dependentObjectNeedingUpdate(beforeProcessingObject: message)
            XCTAssertEqual(dependency as? ZMConversation, self.groupConversation)
        }
    }
    
    func testThatItReturnsConnectionIfNeedsToBeUpdatedFromBackendBeforeMissingClients() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = try! self.oneToOneConversation.appendText(content: "foo") as! ZMClientMessage
            
            // WHEN
            self.selfClient.missesClient(self.otherClient)
            self.oneToOneConversation.connection?.needsToBeUpdatedFromBackend = true
            
            // THEN
            let dependency = self.sut.dependentObjectNeedingUpdate(beforeProcessingObject: message)
            XCTAssertEqual(dependency as? ZMConnection, self.oneToOneConversation.connection)
        }
    }
    
    func testThatItDoesNotReturnSelfClientAsDependentObjectForMessageIfConversationIsNotAffectedByMissingClients() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let user2 = self.createUser()
            let conversation2 = self.createGroupConversation(with: user2)
            let message = try! conversation2.appendText(content: "foo") as! ZMClientMessage
            
            // WHEN
            self.selfClient.missesClient(self.otherClient)
            
            // THEN
            let dependency = self.sut.dependentObjectNeedingUpdate(beforeProcessingObject: message)
            XCTAssertNil(dependency)
        }
    }
    
    func testThatItReturnsNilAsDependentObjectForMessageIfItHasNoMissingClients() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            
            // THEN
            let dependency = self.sut.dependentObjectNeedingUpdate(beforeProcessingObject: message)
            XCTAssertNil(dependency)
        }
    }
    
    func testThatItReturnsAPreviousPendingMessageAsDependency() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let timeZero = Date(timeIntervalSince1970: 10000)
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            message.serverTimestamp = timeZero
            message.markAsSent()
            
            let nextMessage = try! self.groupConversation.appendText(content: "bar") as! ZMClientMessage
            // nextMessage.serverTimestamp = timeZero.addingTimeInterval(100) // this ensures the sorting
            
            // WHEN
            let lastMessage = try! self.groupConversation.appendText(content: "zoo") as! ZMClientMessage
            
            // THEN
            let dependency = self.sut.dependentObjectNeedingUpdate(beforeProcessingObject: lastMessage)
            XCTAssertEqual(dependency as? ZMClientMessage, nextMessage)
        }
    }
    
    func testThatItDoesNotReturnAPreviousSentMessageAsDependency() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let timeZero = Date(timeIntervalSince1970: 10000)
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            message.serverTimestamp = timeZero
            message.markAsSent()
            
            // WHEN
            let lastMessage = try! self.groupConversation.appendText(content: "zoo") as! ZMClientMessage
            
            // THEN
            let dependency = self.sut.dependentObjectNeedingUpdate(beforeProcessingObject: lastMessage)
            XCTAssertNil(dependency)
        }
    }
    
    func testThatItReturnConversationAsDependencyIfSecurityLevelIsSecureWithIgnored() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            
            // WHEN
            self.set(conversation: self.groupConversation, securityLevel: .secureWithIgnored)
            
            // THEN
            let dependency = self.sut.dependentObjectNeedingUpdate(beforeProcessingObject: message)
            XCTAssertEqual(dependency as? ZMConversation, self.groupConversation)
        }
    }
    
    func testThatItDoesNotReturnConversationAsDependencyIfSecurityLevelIsNotSecure() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            
            // WHEN
            self.set(conversation: self.groupConversation, securityLevel: .notSecure)
            
            // THEN
            XCTAssertNil(self.sut.dependentObjectNeedingUpdate(beforeProcessingObject: message))
        }
    }
    
    func testThatItDoesNotReturnConversationAsDependencyIfSecurityLevelIsSecure() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            
            // WHEN
            self.set(conversation: self.groupConversation, securityLevel: .secure)
            
            // THEN
            XCTAssertNil(self.sut.dependentObjectNeedingUpdate(beforeProcessingObject: message))
        }
    }
}
