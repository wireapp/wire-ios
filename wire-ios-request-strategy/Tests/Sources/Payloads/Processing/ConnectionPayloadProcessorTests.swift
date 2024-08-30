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

@testable import WireRequestStrategy
import WireTransport
import XCTest

final class ConnectionPayloadProcessorTests: MessagingTestBase {

    var sut: ConnectionPayloadProcessor!

    override func setUp() {
        super.setUp()
        sut = ConnectionPayloadProcessor()
        BackendInfo.isFederationEnabled = false
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatConversationIsMarkedForDownload() {
        syncMOC.performGroupedAndWait {
            // given
            XCTAssertFalse(self.oneToOneConversation.needsToBeUpdatedFromBackend)
            let payload = self.createConnectionPayload(self.oneToOneConnection, status: .blocked)

            // when
            self.sut.updateOrCreateConnection(
                from: payload,
                in: self.syncMOC
            )

            // then
            XCTAssertTrue(self.oneToOneConversation.needsToBeUpdatedFromBackend)
        }
    }

    func testThatConversationLastModifiedDateIsUpdated() {
        syncMOC.performGroupedAndWait {
            // given
            let modifiedDate = Date()
            let payload = self.createConnectionPayload(self.oneToOneConnection, lastUpdate: modifiedDate)

            // when
            self.sut.updateOrCreateConnection(
                from: payload,
                in: self.syncMOC
            )

            // then
            XCTAssertEqual(self.oneToOneConversation.lastModifiedDate, modifiedDate)
        }
    }

    func testThatAnExistingConversationIsLinkedToTheConnection() {
        syncMOC.performGroupedAndWait {
            // given
            self.oneToOneConnection.to.oneOnOneConversation = nil

            let payload = self.createConnectionPayload(
                to: self.otherUser.qualifiedID!,
                conversation: self.oneToOneConversation.qualifiedID!
            )

            // when
            self.sut.updateOrCreateConnection(
                from: payload,
                in: self.syncMOC
            )

            // then
            XCTAssertEqual(self.otherUser.oneOnOneConversation, self.oneToOneConversation)
        }
    }

    func testThatANonExistingConversationIsCreatedAndLinkedToTheConnection() {
        syncMOC.performGroupedAndWait {
            // given
            BackendInfo.isFederationEnabled = true
            let conversationID: QualifiedID = .randomID()

            let payload = self.createConnectionPayload(
                to: self.otherUser.qualifiedID!,
                conversation: conversationID
            )

            // when
            self.sut.updateOrCreateConnection(
                from: payload,
                in: self.syncMOC
            )

            // then
            XCTAssertEqual(self.otherUser.oneOnOneConversation?.qualifiedID, conversationID)
        }
    }

    func testThatOtherUserIsAddedToConversation() {
        syncMOC.performGroupedAndWait {
            // given
            let payload = self.createConnectionPayload(to: self.thirdUser.qualifiedID!)

            // when
            self.sut.updateOrCreateConnection(
                from: payload,
                in: self.syncMOC
            )

            // then
            XCTAssertTrue(self.thirdUser.oneOnOneConversation!.localParticipants.contains(self.thirdUser))
        }
    }

    func testThatConnectionStatusIsUpdated() {
        syncMOC.performGroupedAndWait {
            let allCases: [ZMConnectionStatus] = [
                .accepted,
                .blocked,
                .blockedMissingLegalholdConsent,
                .ignored,
                .pending,
                .sent,
                .cancelled
            ]

            for status in allCases {
                // given
                let payload = self.createConnectionPayload(self.oneToOneConnection, status: status)

                // when
                self.sut.updateOrCreateConnection(
                    from: payload,
                    in: self.syncMOC
                )

                // then
                XCTAssertEqual(self.oneToOneConnection.status, status)
            }
        }
    }

}
