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

import GenericMessageProtocol
import XCTest

@testable import WireDataModel

class ZMOTRMessage_SelfConversationUpdateEventTests: BaseZMClientMessageTests {

    func testThatWeIgnoreClearedEventNotSentFromSelfUser() {

        syncMOC.performGroupedAndWait {
            // given
            let nonce = UUID()
            let clearedDate = Date()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let message = GenericMessage(
                content: Cleared(timestamp: clearedDate, conversationID: self.syncConversation.remoteIdentifier!),
                nonce: nonce
            )
            let event = self.createUpdateEvent(
                nonce,
                conversationID: selfConversation.remoteIdentifier!,
                timestamp: Date(),
                genericMessage: message,
                senderID: UUID(),
                eventSource: ZMUpdateEventSource.download
            )

            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // then
            XCTAssertNil(self.syncConversation.clearedTimeStamp)
        }

    }

    func testThatWeIgnoreLastReadEventNotSentFromSelfUser() {

        syncMOC.performGroupedAndWait {
            // given
            guard let remoteIdentifier = self.syncConversation.remoteIdentifier else {
                XCTFail("There's no remoteIdentifier")
                return
            }
            let nonce = UUID()
            let lastReadDate = Date()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let conversationID = QualifiedID(uuid: remoteIdentifier, domain: "")
            let message = GenericMessage(
                content: LastRead(conversationID: conversationID, lastReadTimestamp: lastReadDate),
                nonce: nonce
            )
            let event = self.createUpdateEvent(
                nonce,
                conversationID: selfConversation.remoteIdentifier!,
                timestamp: Date(),
                genericMessage: message,
                senderID: UUID(),
                eventSource: ZMUpdateEventSource.download
            )
            self.syncConversation.lastReadServerTimeStamp = nil

            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // then
            XCTAssertNil(self.syncConversation.lastReadServerTimeStamp)
        }

    }

    func testThatWeIgnoreHideMessageEventNotSentFromSelfUser() {

        syncMOC.performGroupedAndWait {
            // given
            let nonce = UUID()
            let selfConversation = ZMConversation.selfConversation(in: self.syncMOC)
            let toBehiddenMessage = try! self.syncConversation.appendText(content: "hello") as! ZMClientMessage
            let hideMessage = MessageHide(
                conversationId: self.syncConversation.remoteIdentifier!,
                messageId: toBehiddenMessage.nonce!
            )
            let message = GenericMessage(content: hideMessage, nonce: nonce)
            let event = self.createUpdateEvent(
                nonce,
                conversationID: selfConversation.remoteIdentifier!,
                timestamp: Date(),
                genericMessage: message,
                senderID: UUID(),
                eventSource: ZMUpdateEventSource.download
            )

            // when
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // then
            XCTAssertFalse(toBehiddenMessage.hasBeenDeleted)
        }

    }

    // MARK: - Analytics Data Transfer

    func test_AfterProcessingDataTransferMessage_ContainingTrackingIdentifier_SelfUserIsUpdated() {
        syncMOC.performGroupedAndWait {
            // Given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let team = self.createTeam(in: self.syncMOC)
            self.createMembership(in: self.syncMOC, user: selfUser, team: team)
            selfUser.trackingID = UUID()

            let trackingID = UUID.create()

            let event = self.createUpdateEvent(
                trackingID: trackingID,
                conversation: .selfConversation(in: self.syncMOC),
                sender: selfUser
            )

            // When
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // Then
            XCTAssertEqual(selfUser.trackingID, trackingID)
        }
    }

    func test_WeIgnoreDataTransferMessage_IfNotSentFromSelfUser() {
        syncMOC.performGroupedAndWait {
            // Given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let team = self.createTeam(in: self.syncMOC)
            self.createMembership(in: self.syncMOC, user: selfUser, team: team)
            let trackingID = UUID()
            selfUser.trackingID = trackingID

            let event = self.createUpdateEvent(
                trackingID: UUID.create(),
                conversation: .selfConversation(in: self.syncMOC),
                sender: self.createUser(in: self.syncMOC)
            )

            // When
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // Then
            XCTAssertEqual(selfUser.trackingID, trackingID)
        }
    }

    func test_WeIgnoreDataTransferMessage_IfNotSentInSelfConversation() {
        syncMOC.performGroupedAndWait {
            // Given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let team = self.createTeam(in: self.syncMOC)
            self.createMembership(in: self.syncMOC, user: selfUser, team: team)
            let trackingID = UUID()
            selfUser.trackingID = trackingID

            let event = self.createUpdateEvent(
                trackingID: UUID.create(),
                conversation: self.conversation,
                sender: self.createUser(in: self.syncMOC)
            )

            // When
            ZMOTRMessage.createOrUpdate(from: event, in: self.syncMOC, prefetchResult: nil)

            // Then
            XCTAssertEqual(selfUser.trackingID, trackingID)
        }
    }

    private func createUpdateEvent(
        trackingID: UUID,
        conversation: ZMConversation,
        sender: ZMUser
    ) -> ZMUpdateEvent {
        let message = GenericMessage(content: DataTransfer(trackingIdentifier: trackingID))
        let nonce = UUID.create()

        return createUpdateEvent(
            nonce,
            conversationID: conversation.remoteIdentifier!,
            timestamp: Date(),
            genericMessage: message,
            senderID: sender.remoteIdentifier!,
            eventSource: ZMUpdateEventSource.download
        )
    }

}
