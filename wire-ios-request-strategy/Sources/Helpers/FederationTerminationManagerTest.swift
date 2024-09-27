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

import WireDataModel
import XCTest
@testable import WireRequestStrategy

// MARK: - FederationTerminationManagerTests

class FederationTerminationManagerTests: MessagingTestBase {
    var sut: FederationTerminationManager!
    let defederatedDomain = "other.user.domain"

    override func setUp() {
        super.setUp()

        sut = FederationTerminationManager(with: syncMOC)
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
    }

    // MARK: - Handle federation termination with other domain

    func testThatItMarksOneToOneConversationAsReadOnly_AndAddsSystemMessage() throws {
        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            otherUser.domain = defederatedDomain
            guard let conversation = otherUser.oneOnOneConversation else {
                XCTFail("expected one on one conversation")
                return
            }
            XCTAssertFalse(conversation.isForcedReadOnly)

            // WHEN
            sut.handleFederationTerminationWith(defederatedDomain)

            // THEN
            XCTAssertTrue(conversation.isForcedReadOnly)
            XCTAssertTrue(conversation.isReadOnly)
            XCTAssertEqual(
                conversation.lastMessage?.systemMessageData?.systemMessageType,
                ZMSystemMessageType.domainsStoppedFederating
            )
        }
    }

    func testThatItRemovesPendingConnectionRequest() throws {
        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            otherUser.domain = defederatedDomain
            otherUser.connection?.status = .pending

            // WHEN
            sut.handleFederationTerminationWith(defederatedDomain)

            // THEN
            XCTAssertEqual(otherUser.connection?.status, .ignored)
        }
    }

    func testThatItCancelsSentConnectionRequest() throws {
        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            otherUser.domain = defederatedDomain
            otherUser.connection?.status = .sent

            // WHEN
            sut.handleFederationTerminationWith(defederatedDomain)

            // THEN
            XCTAssertEqual(otherUser.connection?.status, .cancelled)
        }
    }

    func testThatItRemovesConnectionForConnectedUsers() throws {
        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            otherUser.domain = defederatedDomain
            otherUser.connection?.status = .accepted

            // WHEN
            sut.handleFederationTerminationWith(defederatedDomain)

            // THEN
            XCTAssertEqual(otherUser.connection, nil)
        }
    }

    func testItRemovesSelfUserFromConversationHostedByDefederatedDomain_AndAddsSystemMessages() throws {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: syncMOC)
            otherUser.domain = defederatedDomain
            let conversation = createGroupConversation(with: [otherUser], hostedByDomain: defederatedDomain)
            XCTAssertTrue(conversation.localParticipants.contains(selfUser))

            // WHEN
            sut.handleFederationTerminationWith(defederatedDomain)

            // THEN
            XCTAssertFalse(conversation.localParticipants.contains(selfUser))
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))

            let lastMessages = conversation.lastMessages(limit: 2)
            XCTAssertEqual(
                lastMessages.first?.systemMessageData?.systemMessageType,
                ZMSystemMessageType.participantsRemoved
            )
            XCTAssertEqual(
                lastMessages.last?.systemMessageData?.systemMessageType,
                ZMSystemMessageType.domainsStoppedFederating
            )
        }
    }

    func testThatItRemovesOtherUserFromConversationHostedBySelfDomain_AndAddsSystemMessages() throws {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: syncMOC)
            otherUser.domain = defederatedDomain
            let conversation = createGroupConversation(with: [otherUser], hostedByDomain: owningDomain)
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))

            // WHEN
            sut.handleFederationTerminationWith(defederatedDomain)

            // THEN
            XCTAssertTrue(conversation.localParticipants.contains(selfUser))
            XCTAssertFalse(conversation.localParticipants.contains(otherUser))

            let lastMessages = conversation.lastMessages(limit: 2)
            XCTAssertEqual(
                lastMessages.first?.systemMessageData?.systemMessageType,
                ZMSystemMessageType.participantsRemoved
            )
            XCTAssertEqual(
                lastMessages.last?.systemMessageData?.systemMessageType,
                ZMSystemMessageType.domainsStoppedFederating
            )
        }
    }

    func testThatItRemovesSelfUserAndOtherUserFromConversationHostedByOtherDomain_AndAddsSystemMessages() throws {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: syncMOC)
            let thirdDomain = "third.user.domain"
            otherUser.domain = defederatedDomain
            thirdUser.domain = thirdDomain
            let conversation = createGroupConversation(with: [otherUser, thirdUser], hostedByDomain: thirdDomain)
            XCTAssertTrue(conversation.localParticipants.contains(selfUser))
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))
            XCTAssertTrue(conversation.localParticipants.contains(thirdUser))

            // WHEN
            sut.handleFederationTerminationWith(defederatedDomain)

            // THEN
            XCTAssertFalse(conversation.localParticipants.contains(selfUser))
            XCTAssertFalse(conversation.localParticipants.contains(otherUser))
            XCTAssertTrue(conversation.localParticipants.contains(thirdUser))

            let lastMessages = conversation.lastMessages(limit: 2)
            XCTAssertEqual(
                lastMessages.first?.systemMessageData?.systemMessageType,
                ZMSystemMessageType.participantsRemoved
            )
            XCTAssertEqual(
                lastMessages.last?.systemMessageData?.systemMessageType,
                ZMSystemMessageType.domainsStoppedFederating
            )
        }
    }

    // MARK: - Handle federation termination between two domains

    func testItRemovesDefederatedParticipantsFromConversationHostedBySelfDomain_AndAddsSystemMessages() throws {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: syncMOC)

            let firstDomain = "first.domain"
            let secondDomain = "second.domain"
            otherUser.domain = firstDomain
            thirdUser.domain = secondDomain
            let conversation = createGroupConversation(with: [thirdUser, otherUser], hostedByDomain: owningDomain)

            XCTAssertTrue(conversation.localParticipants.contains(otherUser))
            XCTAssertTrue(conversation.localParticipants.contains(thirdUser))

            // WHEN
            sut.handleFederationTerminationBetween(firstDomain, otherDomain: secondDomain)

            // THEN
            XCTAssertTrue(conversation.localParticipants.contains(selfUser))
            XCTAssertFalse(conversation.localParticipants.contains(otherUser))
            XCTAssertFalse(conversation.localParticipants.contains(thirdUser))

            let lastMessages = conversation.lastMessages(limit: 2)
            XCTAssertEqual(
                lastMessages.first?.systemMessageData?.systemMessageType,
                ZMSystemMessageType.participantsRemoved
            )
            XCTAssertEqual(
                lastMessages.last?.systemMessageData?.systemMessageType,
                ZMSystemMessageType.domainsStoppedFederating
            )
        }
    }

    func testThatItRemovesParticipantFromConversationHostedBySelfDomain_AndAddsSystemMessages() throws {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let selfUser = ZMUser.selfUser(in: syncMOC)

            let firstDomain = "first.domain"
            let secondDomain = "second.domain"
            otherUser.domain = firstDomain
            thirdUser.domain = secondDomain
            let conversation = createGroupConversation(with: [thirdUser, otherUser], hostedByDomain: firstDomain)

            XCTAssertTrue(conversation.localParticipants.contains(otherUser))
            XCTAssertTrue(conversation.localParticipants.contains(thirdUser))

            // WHEN
            sut.handleFederationTerminationBetween(firstDomain, otherDomain: secondDomain)

            // THEN
            XCTAssertTrue(conversation.localParticipants.contains(selfUser))
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))
            XCTAssertFalse(conversation.localParticipants.contains(thirdUser))

            let lastMessages = conversation.lastMessages(limit: 2)
            XCTAssertEqual(
                lastMessages.first?.systemMessageData?.systemMessageType,
                ZMSystemMessageType.participantsRemoved
            )
            XCTAssertEqual(
                lastMessages.last?.systemMessageData?.systemMessageType,
                ZMSystemMessageType.domainsStoppedFederating
            )
        }
    }
}

extension FederationTerminationManagerTests {
    /// Creates a group conversation with a user in given domain
    func createGroupConversation(with users: [ZMUser], hostedByDomain domain: String) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.conversationType = .group
        conversation.domain = domain
        conversation.remoteIdentifier = UUID.create()
        users.forEach { conversation.addParticipantAndUpdateConversationState(user: $0, role: nil) }

        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: syncMOC), role: nil)
        conversation.needsToBeUpdatedFromBackend = false
        return conversation
    }

    /// Creates a 1:1 conversation with a user
    func createOneToOneConversation(with user: ZMUser) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.conversationType = .oneOnOne
        conversation.remoteIdentifier = UUID.create()
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        conversation.needsToBeUpdatedFromBackend = false
        return conversation
    }
}
