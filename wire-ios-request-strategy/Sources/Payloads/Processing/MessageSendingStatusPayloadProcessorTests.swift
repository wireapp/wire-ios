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

final class MessageSendingStatusPayloadProcessorTests: MessagingTestBase {

    let domain =  "example.com"
    var sut: MessageSendingStatusPayloadProcessor!

    override func setUp() {
        super.setUp()

        sut = MessageSendingStatusPayloadProcessor()

        syncMOC.performGroupedBlockAndWait {
            self.otherUser.domain = self.domain
        }
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Client Updates

    func testThatClientsAreDeleted_WhenDeletedClientsArePresent() async {
        // given
        var message: MockOTREntity!
        var payload: Payload.MessageSendingStatus!

        self.syncMOC.performGroupedAndWait { _ in
            message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            let deleted: Payload.ClientListByQualifiedUserID =
            [self.domain:
                [self.otherUser.remoteIdentifier.transportString(): [self.otherClient.remoteIdentifier!]]
            ]
            payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: [:],
                                                       redundant: [:],
                                                       deleted: deleted,
                                                       failedToSend: [:],
                                                       failedToConfirm: [:])
        }

        // when
        await sut.updateClientsChanges(
            from: payload,
            for: message
        )

        // then
        self.syncMOC.performGroupedAndWait { _ in
            XCTAssertTrue(self.otherClient.isDeleted)
        }
    }

    func testThatClientsAreMarkedAsMissing_WhenMissingClientsArePresent() async throws {
        // given
        var message: MockOTREntity!
        var payload: Payload.MessageSendingStatus!
        var clientID: String!

        syncMOC.performGroupedBlockAndWait {
            message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            clientID = UUID().transportString()
            let missing: Payload.ClientListByQualifiedUserID =
            [self.domain:
                [self.otherUser.remoteIdentifier.transportString(): [clientID]]
            ]
            payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: missing,
                                                       redundant: [:],
                                                       deleted: [:],
                                                       failedToSend: [:],
                                                       failedToConfirm: [:])
        }

        // when
        await sut.updateClientsChanges(
            from: payload,
            for: message
        )

        // then
        self.syncMOC.performGroupedAndWait { _ in
            XCTAssertEqual(self.selfClient.missingClients!.count, 1)
            XCTAssertEqual(self.selfClient.missingClients!.first!.remoteIdentifier, clientID)
        }
    }

    func testThatClientsAreNotMarkedAsMissing_WhenMissingClientsAlreadyHaveASession() async {
        // given
        var message: MockOTREntity!
        var payload: Payload.MessageSendingStatus!

        syncMOC.performGroupedBlockAndWait {
            message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            let clientID = UUID().transportString()
            let userClient = UserClient.fetchUserClient(withRemoteId: clientID,
                                                        forUser: self.otherUser,
                                                        createIfNeeded: true)!
            self.establishSessionFromSelf(to: userClient)
            let missing: Payload.ClientListByQualifiedUserID =
            [self.domain:
                [self.otherUser.remoteIdentifier.transportString(): [clientID]]
            ]
            payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: missing,
                                                       redundant: [:],
                                                       deleted: [:],
                                                       failedToSend: [:],
                                                       failedToConfirm: [:])
        }

        // when
        await sut.updateClientsChanges(
            from: payload,
            for: message
        )

        // then
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.selfClient.missingClients!.count, 0)
        }
    }

    func testThatUserIsMarkedToBeRefetched_WhenReduntantUsersArePresent() async {
        // given
        var message: MockOTREntity!
        var payload: Payload.MessageSendingStatus!

        syncMOC.performGroupedBlockAndWait {
            message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            let redundant: Payload.ClientListByQualifiedUserID =
            [self.domain:
                [self.otherUser.remoteIdentifier.transportString(): [self.otherClient.remoteIdentifier!]]
            ]
            payload = Payload.MessageSendingStatus(time: Date(),
                                                   missing: [:],
                                                   redundant: redundant,
                                                   deleted: [:],
                                                   failedToSend: [:],
                                                   failedToConfirm: [:])
        }

        // when
        await sut.updateClientsChanges(
            from: payload,
            for: message
        )

        // then
        syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatTheConversationIsMarkedToBeRefetched_WhenReduntantUsersArePresent() async {
        // given
        var message: MockOTREntity!
        var payload: Payload.MessageSendingStatus!

        syncMOC.performGroupedBlockAndWait {
            message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            let redundant: Payload.ClientListByQualifiedUserID =
            [self.domain:
                [self.otherUser.remoteIdentifier.transportString(): [self.otherClient.remoteIdentifier!]]
            ]
            payload = Payload.MessageSendingStatus(time: Date(),
                                                   missing: [:],
                                                   redundant: redundant,
                                                   deleted: [:],
                                                   failedToSend: [:],
                                                   failedToConfirm: [:])
        }

        // when
        await sut.updateClientsChanges(
            from: payload,
            for: message
        )

        // then
        syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(message.conversation!.needsToBeUpdatedFromBackend)
        }
    }

    func testThatItCallsTheAddFailedToSendRecipientsMethod() async throws {
        // given
        var message: MockOTREntity!
        var payload: Payload.MessageSendingStatus!

        syncMOC.performGroupedBlockAndWait {
            message = MockOTREntity(conversation: self.groupConversation, context: self.syncMOC)
            let clientID = UUID().transportString()
            let failedToConfirm: Payload.ClientListByQualifiedUserID =
            [self.domain:
                [self.otherUser.remoteIdentifier.transportString(): [clientID]]
            ]
            payload = Payload.MessageSendingStatus(time: Date(),
                                                   missing: [:],
                                                   redundant: [:],
                                                   deleted: [:],
                                                   failedToSend: [:],
                                                   failedToConfirm: failedToConfirm)
        }

        // when
        await sut.updateClientsChanges(
            from: payload,
            for: message
        )

        // then
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.isFailedToSendUsers, true)
        }
    }

    func testThatItAddsFailedToSendRecipients() async throws {
        // given
        var message: ZMClientMessage!
        var payload: Payload.MessageSendingStatus!

        try self.syncMOC.performGroupedAndWait { _ in
            guard let textMessage = try self.groupConversation.appendText(content: "Test message") as? ZMClientMessage else {
                XCTFail("Failed to add message")
                return
            }
            message = textMessage

            let domain = "example.com"
            let clientID = UUID().transportString()
            let failedToConfirm: Payload.ClientListByQualifiedUserID =
            [domain:
                [self.otherUser.remoteIdentifier.transportString(): [clientID]]
            ]
            XCTAssertEqual(message.failedToSendRecipients?.count, 0)

            payload = Payload.MessageSendingStatus(time: Date(),
                                                   missing: [:],
                                                   redundant: [:],
                                                   deleted: [:],
                                                   failedToSend: [:],
                                                   failedToConfirm: failedToConfirm)
        }

        // when
        await sut.updateClientsChanges(
            from: payload,
            for: message
        )

        // then
        syncMOC.performAndWait {
            XCTAssertEqual(message.failedToSendRecipients?.count, 1)
            XCTAssertEqual(message.failedToSendRecipients?.first, self.otherUser)
        }
    }

    // MARK: - Payload mapping

    func testThatItReturnsMissingClientListByUser() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let expectedThirdUserClientList = [UUID().transportString(), UUID().transportString()]
            let thirdDomain = "third.domain.com"

            self.syncMOC.saveOrRollback()

            let missing: Payload.ClientListByQualifiedUserID = [
                self.domain: [self.otherUser.remoteIdentifier.transportString(): [self.otherClient.remoteIdentifier!]],
                thirdDomain: [self.thirdUser.remoteIdentifier.transportString(): expectedThirdUserClientList]
            ]

            let payload = Payload.MessageSendingStatus(time: Date(),
                                                       missing: missing,
                                                       redundant: [:],
                                                       deleted: [:],
                                                       failedToSend: [:],
                                                       failedToConfirm: [:])

            // when
            let clientListByUser = self.sut.missingClientListByUser(
                from: payload,
                context: self.syncMOC
            )

            // then
            let otherUserClientList = clientListByUser[self.otherUser]
            XCTAssertNotNil(otherUserClientList)
            XCTAssertEqual(otherUserClientList, [self.otherClient.remoteIdentifier!])
            let thirdUserClientList = clientListByUser[self.thirdUser]
            XCTAssertNotNil(thirdUserClientList)
            XCTAssertEqual(thirdUserClientList, expectedThirdUserClientList)
        }
    }

    func testThatMissingClientListByUser_CreatesNewUserIfNeeded() {
        // given
        let userID = UUID()
        let clientID = UUID().transportString()

        let missing: Payload.ClientListByQualifiedUserID = [
            domain: [userID.transportString(): [clientID]]
        ]

        let payload = Payload.MessageSendingStatus(time: Date(),
                                                   missing: missing,
                                                   redundant: [:],
                                                   deleted: [:],
                                                   failedToSend: [:],
                                                   failedToConfirm: [:])

        // when
        var clientListByUser = Payload.ClientListByUser()
        syncMOC.performGroupedBlockAndWait {
            clientListByUser = self.sut.missingClientListByUser(
                from: payload,
                context: self.syncMOC
            )
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        syncMOC.performGroupedBlockAndWait {
            guard let user = ZMUser.fetch(with: userID, domain: self.domain, in: self.syncMOC) else {
                return XCTFail("user was not created")
            }

            let userClientList = clientListByUser[user]
            XCTAssertEqual(userClientList, [clientID])
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

}
