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
import WireDataModelSupport

final class ConnectionPayloadProcessorTests: MessagingTestBase {

    var sut: ConnectionPayloadProcessor!
    var mockResolver: MockOneOnOneResolverInterface!

    override func setUp() {
        super.setUp()
        mockResolver = MockOneOnOneResolverInterface()
        sut = ConnectionPayloadProcessor(resolver: mockResolver)
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
        syncMOC.performGroupedBlockAndWait {
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
        syncMOC.performGroupedBlockAndWait {
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
        syncMOC.performGroupedBlockAndWait {
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

    func testThatOneOnOneResolverIsInvoked_WhenConnectionRequestIsAccepted() throws {
        // GIVEN
        syncMOC.performAndWait {
            let otherUser = ZMUser.insertNewObject(in: syncMOC)
            otherUser.remoteIdentifier = .create()

            let connection = ZMConnection.insertNewObject(in: syncMOC)
            connection.status = .pending
            connection.to = otherUser

            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.remoteIdentifier = .create()
            conversation.conversationType = .connection
            conversation.oneOnOneUser = otherUser

            mockResolver.resolveOneOnOneConversationWithIn_MockMethod = { _, _ in

               return OneOnOneConversationResolution.noAction
            }

            // WHEN
            let payload = self.createConnectionPayload(connection, status: .accepted)
            sut.updateOrCreateConnection(from: payload, in: syncMOC, delay: TimeInterval(UInt64(0.5)))

            // THEN
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertEqual(mockResolver.resolveOneOnOneConversationWithIn_Invocations.count, 1)
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
            XCTAssertTrue(self.thirdUser.oneOnOneConversation!.localParticipants.contains(self.thirdUser))
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
