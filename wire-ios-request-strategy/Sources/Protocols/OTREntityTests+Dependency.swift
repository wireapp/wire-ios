//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireDataModel
import XCTest

// Tests that an OTREntity returns the correct objects as dependencies
// which must be resolved before the message can be sent.
class OTREntityTests_Dependency: MessagingTestBase {
    /// Makes a conversation secure
    func set(conversation: ZMConversation, securityLevel: ZMConversationSecurityLevel) {
        conversation.setValue(NSNumber(value: securityLevel.rawValue), forKey: #keyPath(ZMConversation.securityLevel))
        if conversation.securityLevel != securityLevel {
            fatalError()
        }
    }

    func testThatItReturnsNewClientAsDependentObjectForMessageIfItHasNotBeenFetched() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage

            // WHEN
            self.otherClient.needsToBeUpdatedFromBackend = true

            // THEN
            let dependency = message.dependentObjectNeedingUpdateBeforeProcessing
            XCTAssertEqual(dependency as? UserClient, self.otherClient)
        }
    }

    func testThatItReturnsConversationIfNeedsToBeUpdatedFromBackendBeforeMissingClients() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage

            // WHEN
            self.selfClient.missesClient(self.otherClient)
            self.groupConversation.needsToBeUpdatedFromBackend = true

            // THEN
            let dependency = message.dependentObjectNeedingUpdateBeforeProcessing
            XCTAssertEqual(dependency as? ZMConversation, self.groupConversation)
        }
    }

    func testThatItReturnsConnectionIfNeedsToBeUpdatedFromBackendBeforeMissingClients() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let message = try! self.oneToOneConversation.appendText(content: "foo") as! ZMClientMessage

            // WHEN
            self.selfClient.missesClient(self.otherClient)
            self.oneToOneConnection?.needsToBeUpdatedFromBackend = true

            // THEN
            let dependency = message.dependentObjectNeedingUpdateBeforeProcessing
            XCTAssertEqual(dependency as? ZMConnection, self.oneToOneConnection)
        }
    }

    func testThatItDoesNotReturnSelfClientAsDependentObjectForMessageIfConversationIsNotAffectedByMissingClients() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let user2 = self.createUser()
            let conversation2 = self.createGroupConversation(with: user2)
            let message = try! conversation2.appendText(content: "foo") as! ZMClientMessage

            // WHEN
            self.selfClient.missesClient(self.otherClient)

            // THEN
            let dependency = message.dependentObjectNeedingUpdateBeforeProcessing
            XCTAssertNil(dependency)
        }
    }

    func testThatItReturnsNilAsDependentObjectForMessageIfItHasNoMissingClients() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage

            // THEN
            let dependency = message.dependentObjectNeedingUpdateBeforeProcessing
            XCTAssertNil(dependency)
        }
    }

    func testThatItReturnsAPreviousPendingMessageAsDependency() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let timeZero = Date(timeIntervalSince1970: 10000)
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            message.serverTimestamp = timeZero
            message.markAsSent()

            let nextMessage = try! self.groupConversation.appendText(content: "bar") as! ZMClientMessage
            nextMessage.serverTimestamp = timeZero.addingTimeInterval(1) // this ensures the sorting

            // WHEN
            let lastMessage = try! self.groupConversation.appendText(content: "zoo") as! ZMClientMessage
            lastMessage.serverTimestamp = timeZero.addingTimeInterval(2) // this ensures the sorting

            // THEN
            let dependency = lastMessage.dependentObjectNeedingUpdateBeforeProcessing
            XCTAssertEqual(dependency as? ZMClientMessage, nextMessage)
        }
    }

    func testThatItDoesNotReturnAPreviousSentMessageAsDependency() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let timeZero = Date(timeIntervalSince1970: 10000)
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            message.serverTimestamp = timeZero
            message.markAsSent()

            // WHEN
            let lastMessage = try! self.groupConversation.appendText(content: "zoo") as! ZMClientMessage

            // THEN
            let dependency = lastMessage.dependentObjectNeedingUpdateBeforeProcessing
            XCTAssertNil(dependency)
        }
    }

    func testThatItDoesNotReturnConversationAsDependencyIfSecurityLevelIsNotSecure() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage

            // WHEN
            self.set(conversation: self.groupConversation, securityLevel: .notSecure)

            // THEN
            XCTAssertNil(message.dependentObjectNeedingUpdateBeforeProcessing)
        }
    }

    func testThatItDoesNotReturnConversationAsDependencyIfSecurityLevelIsSecure() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let message = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage

            // WHEN
            self.set(conversation: self.groupConversation, securityLevel: .secure)

            // THEN
            XCTAssertNil(message.dependentObjectNeedingUpdateBeforeProcessing)
        }
    }
}
