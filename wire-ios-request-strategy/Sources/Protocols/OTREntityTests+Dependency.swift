//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireSystem
import WireUtilities
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
            let timeZero = Date(timeIntervalSince1970: 10_000)
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

    func testThatItDoesNotReturnAPreviousPendingMessageOlderThanThreeMinutesAsDependency() {
        syncMOC.performGroupedAndWait {

            // GIVEN
            let timeZero = Date(timeIntervalSince1970: 10_000)
            let pendingMessage = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            pendingMessage.serverTimestamp = timeZero

            // WHEN
            let lastMessage = try! self.groupConversation.appendText(content: "zoo") as! ZMClientMessage
            lastMessage.serverTimestamp = timeZero.addingTimeInterval(4 * 60)

            // THEN
            XCTAssertNil(lastMessage.dependentObjectNeedingUpdateBeforeProcessing)
        }
    }

    func testThatItReturnsAPreviousPendingMessageOlderThanThreeMinutesAsDependency_OfflinePendingMessages() {
        DeveloperFlag.storage = .temporary()
        DeveloperFlag.offlinePendingMessages.enable(true)
        defer { DeveloperFlag.storage = .standard }

        syncMOC.performGroupedAndWait {

            // GIVEN
            let timeZero = Date(timeIntervalSince1970: 10_000)
            let pendingMessage = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            pendingMessage.serverTimestamp = timeZero

            // WHEN
            let lastMessage = try! self.groupConversation.appendText(content: "zoo") as! ZMClientMessage
            lastMessage.serverTimestamp = timeZero.addingTimeInterval(4 * 60)

            // THEN
            let dependency = lastMessage.dependentObjectNeedingUpdateBeforeProcessing
            XCTAssertEqual(dependency as? ZMClientMessage, pendingMessage)
        }
    }

    func testThatItReturnsAPreviousPendingMessageBeyondTheLastMessagesAsDependency_OfflinePendingMessages() {
        DeveloperFlag.storage = .temporary()
        DeveloperFlag.offlinePendingMessages.enable(true)
        defer { DeveloperFlag.storage = .standard }

        syncMOC.performGroupedAndWait {

            // GIVEN
            let timeZero = Date(timeIntervalSince1970: 10_000)
            let pendingMessage = try! self.groupConversation.appendText(content: "foo") as! ZMClientMessage
            pendingMessage.serverTimestamp = timeZero

            for index in 1 ... 300 {
                let message = try! self.groupConversation.appendText(content: "\(index)") as! ZMClientMessage
                message.serverTimestamp = timeZero.addingTimeInterval(TimeInterval(index))
                message.markAsSent()
            }

            // WHEN
            let lastMessage = try! self.groupConversation.appendText(content: "zoo") as! ZMClientMessage
            lastMessage.serverTimestamp = timeZero.addingTimeInterval(301)

            // THEN
            let dependency = lastMessage.dependentObjectNeedingUpdateBeforeProcessing
            XCTAssertEqual(dependency as? ZMClientMessage, pendingMessage)
        }
    }

    func testThatItReturnsAPreviousUploadingAssetOlderThanThreeMinutesAsDependency_OfflinePendingMessages() {
        DeveloperFlag.storage = .temporary()
        DeveloperFlag.offlinePendingMessages.enable(true)
        defer { DeveloperFlag.storage = .standard }

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).txt")
        try! Data("file".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        syncMOC.performGroupedAndWait {

            // GIVEN
            let timeZero = Date(timeIntervalSince1970: 10_000)
            let assetMessage = try! self.groupConversation
                .appendFile(with: ZMFileMetadata(fileURL: fileURL)) as! ZMAssetClientMessage
            assetMessage.serverTimestamp = timeZero
            XCTAssertEqual(assetMessage.transferState, .uploading)

            // WHEN
            let lastMessage = try! self.groupConversation.appendText(content: "zoo") as! ZMClientMessage
            lastMessage.serverTimestamp = timeZero.addingTimeInterval(4 * 60)

            // THEN
            let dependency = lastMessage.dependentObjectNeedingUpdateBeforeProcessing
            XCTAssertEqual(dependency as? ZMAssetClientMessage, assetMessage)
        }
    }

    func testThatItDoesNotReturnAPreviousSentMessageAsDependency() {
        syncMOC.performGroupedAndWait {

            // GIVEN
            let timeZero = Date(timeIntervalSince1970: 10_000)
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
