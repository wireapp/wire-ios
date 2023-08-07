////
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
import WireDataModel
@testable import WireRequestStrategy

class FederationTerminationManagerTests: MessagingTestBase {
    var sut: FederationTerminationManager!

    override func setUp() {
        super.setUp()
        sut = FederationTerminationManager(syncContext: syncMOC)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testThatFederationDelete_markOneToOneConversationAsReadOnly()  throws {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // GIVEN
            let domain = "other.user.domain"
            otherUser.domain = domain
            guard let conversation = otherUser.connection?.conversation else { return }

            // WHEN
            sut.handleFederationTerminationWith(domain)

            // THEN
            XCTAssertTrue(conversation.isForcedReadOnly)
            XCTAssertTrue(conversation.isReadOnly)
        }
    }


    func testThatFederationDelete_RemovePendingConnectionRequest()  throws {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // GIVEN
            let domain = "other.user.domain"
            otherUser.domain = domain
            otherUser.connection?.status = .pending

            // WHEN
            sut.handleFederationTerminationWith(domain)

            // THEN
            XCTAssertEqual(otherUser.connection?.status, .ignored)
        }
    }


    func testThatFederationDelete_RemoveMyConnectionRequest()  throws {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // GIVEN
            let domain = "other.user.domain"
            otherUser.domain = domain
            otherUser.connection?.status = .sent

            // WHEN
            sut.handleFederationTerminationWith(domain)

            // THEN
            XCTAssertEqual(otherUser.connection, nil)
        }
    }

    func testThatFederationDelete_removeSelfUserFromSecondBackendConversation()  throws {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // GIVEN
            let domain = "other.user.domain"
            otherUser.domain = domain
            let conversation = createGroupConversation(with: [otherUser], hostedByDomain: domain)
            XCTAssertTrue(conversation.localParticipants.contains(ZMUser.selfUser(in: syncMOC)))

            // WHEN
            sut.handleFederationTerminationWith(domain)

            // THEN
            XCTAssertFalse(conversation.localParticipants.contains(ZMUser.selfUser(in: syncMOC)))
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))
        }
    }

    func testThatFederationDelete_removeOtherUserFromMyBackendConversation()  throws {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // GIVEN
            let domain = "other.user.domain"
            otherUser.domain = domain
            let conversation = createGroupConversation(with: [otherUser], hostedByDomain: owningDomain)
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))

            // WHEN
            sut.handleFederationTerminationWith(domain)

            // THEN
            XCTAssertTrue(conversation.localParticipants.contains(ZMUser.selfUser(in: syncMOC)))
            XCTAssertFalse(conversation.localParticipants.contains(otherUser))
        }
    }

    func testThatFederationDelete_removeMeAndOtherUserFromThirdBackendConversation()  throws {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // GIVEN
            let domain = "other.user.domain"
            let thirdDomain = "third.user.domain"
            otherUser.domain = domain
            thirdUser.domain = thirdDomain
            let conversation = createGroupConversation(with: [otherUser, thirdUser], hostedByDomain: thirdDomain)
            XCTAssertTrue(conversation.localParticipants.contains(ZMUser.selfUser(in: syncMOC)))
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))

            // WHEN
            sut.handleFederationTerminationWith(domain)

            // THEN
            XCTAssertFalse(conversation.localParticipants.contains(ZMUser.selfUser(in: syncMOC)))
            XCTAssertFalse(conversation.localParticipants.contains(otherUser))
            XCTAssertTrue(conversation.localParticipants.contains(thirdUser))
        }
    }

    func testThatDomainsStopFederating_removeParticipantsFromMyConversation()  throws {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // GIVEN
            otherUser.domain = "otherUser.domain"
            thirdUser.domain = "thirdUser.domain"
            let conversation = createGroupConversation(with: [thirdUser, otherUser], hostedByDomain: owningDomain)
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))
            XCTAssertTrue(conversation.localParticipants.contains(thirdUser))

            // WHEN
            sut.handleFederationTerminationBetween("otherUser.domain", otherDomain: "thirdUser.domain")

            // THEN
            XCTAssertTrue(conversation.localParticipants.contains(ZMUser.selfUser(in: syncMOC)))
            XCTAssertFalse(conversation.localParticipants.contains(otherUser))
            XCTAssertFalse(conversation.localParticipants.contains(thirdUser))
        }
    }

    func testThatDomainsStopFederating_removeParticipantFromNonHostingdBackend()  throws {
        syncMOC.performGroupedAndWait { [self] syncMOC in
            // GIVEN
            otherUser.domain = "otherUser.domain"
            thirdUser.domain = "thirdUser.domain"
            let conversation = createGroupConversation(with: [thirdUser, otherUser], hostedByDomain: "otherUser.domain")
            XCTAssertTrue(conversation.localParticipants.contains(thirdUser))

            // WHEN
            sut.handleFederationTerminationBetween("otherUser.domain", otherDomain: "thirdUser.domain")

            // THEN
            XCTAssertTrue(conversation.localParticipants.contains(ZMUser.selfUser(in: syncMOC)))
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))
            XCTAssertFalse(conversation.localParticipants.contains(thirdUser))
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
        for user in users {
            conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        }
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
