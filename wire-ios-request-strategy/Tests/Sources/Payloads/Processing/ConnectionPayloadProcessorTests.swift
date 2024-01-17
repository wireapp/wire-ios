//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
@testable import WireRequestStrategy

final class ConnectionPayloadProcessorTests: MessagingTestBase {

    var sut: ConnectionPayloadProcessor!

    override func setUp() {
        super.setUp()
        sut = ConnectionPayloadProcessor()
        BackendInfo.storage = .temporary()
    }

    override func tearDown() {
        sut = nil
        BackendInfo.storage = .standard
        super.tearDown()
    }

    func testThatConversationIsMarkedForDownload() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let connection = self.oneToOneConversation.connection!
            let payload = self.createConnectionPayload(connection, status: .blocked)

            // when
            self.sut.updateOrCreateConnection(
                from: payload,
                in: self.syncMOC
            )

            // then
            XCTAssertTrue(connection.conversation.needsToBeUpdatedFromBackend)
        }
    }

    func testThatConversationLastModifiedDateIsUpdated() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let modifiedDate = Date()
            let connection = self.oneToOneConversation.connection!
            let payload = self.createConnectionPayload(connection, lastUpdate: modifiedDate)

            // when
            self.sut.updateOrCreateConnection(
                from: payload,
                in: self.syncMOC
            )

            // then
            XCTAssertEqual(connection.conversation.lastModifiedDate, modifiedDate)
        }
    }

    func testThatAnExistingConversationIsLinkedToTheConnection() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let connection = self.oneToOneConversation.connection!
            connection.conversation = nil
            let payload = self.createConnectionPayload(to: self.otherUser.qualifiedID!,
                                                                 conversation: self.oneToOneConversation.qualifiedID!)

            // when
            self.sut.updateOrCreateConnection(
                from: payload,
                in: self.syncMOC
            )

            // then
            XCTAssertEqual(connection.conversation, self.oneToOneConversation)
        }
    }

    func testThatANonExistingConversationIsCreatedAndLinkedToTheConnection() {
        syncMOC.performGroupedBlockAndWait {
            // given
            BackendInfo.isFederationEnabled = true
            let conversationID: QualifiedID = .randomID()
            let connection = self.oneToOneConversation.connection!
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
            XCTAssertEqual(connection.conversation.qualifiedID, conversationID)
        }
    }

    func testThatOtherUserIsAddedToConversation() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let payload = self.createConnectionPayload(to: self.thirdUser.qualifiedID!)

            // when
            self.sut.updateOrCreateConnection(
                from: payload,
                in: self.syncMOC
            )

            // then
            XCTAssertTrue(self.thirdUser.connection!.conversation.localParticipants.contains(self.thirdUser))
        }
    }

    func testThatConnectionStatusIsUpdated() {
        syncMOC.performGroupedBlockAndWait {
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
                let connection = self.oneToOneConversation.connection!
                let payload = self.createConnectionPayload(connection, status: status)

                // when
                self.sut.updateOrCreateConnection(
                    from: payload,
                    in: self.syncMOC
                )

                // then
                XCTAssertEqual(connection.status, status)
            }
        }
    }

}
