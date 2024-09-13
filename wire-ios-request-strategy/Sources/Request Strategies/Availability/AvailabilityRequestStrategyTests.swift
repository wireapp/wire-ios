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

import WireRequestStrategy
import WireRequestStrategySupport
import XCTest

class AvailabilityRequestStrategyTests: MessagingTestBase {
    var messageSender: MockMessageSenderInterface!
    var sut: AvailabilityRequestStrategy!

    override func setUp() {
        super.setUp()

        messageSender = MockMessageSenderInterface()
        sut = AvailabilityRequestStrategy(context: syncMOC, messageSender: messageSender)
    }

    override func tearDown() {
        sut = nil
        messageSender = nil

        super.tearDown()
    }

    func testThatItBroadcastWhenAvailabilityIsModified() {
        syncMOC.performGroupedAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            let availabilityKeySet: Set<AnyHashable> = [AvailabilityKey]
            selfUser.needsToBeUpdatedFromBackend = false
            selfUser.setLocallyModifiedKeys(availabilityKeySet)
            self.messageSender.broadcastMessageMessage_MockMethod = { _ in }

            // when
            self.sut.contextChangeTrackers
                .forEach { $0.addTrackedObjects(Set<NSManagedObject>(arrayLiteral: selfUser)) }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(messageSender.broadcastMessageMessage_Invocations.count, 1)
    }

    func testThatItBroadcastWhenAvailabilityIsModifiedAndGuestShouldCommunicateStatus() {
        syncMOC.performGroupedAndWait {
            // given
            self.messageSender.broadcastMessageMessage_MockMethod = { _ in }

            let selfUser = ZMUser.selfUser(in: syncMOC)
            let availabilityKeySet: Set<AnyHashable> = [AvailabilityKey]
            selfUser.needsToBeUpdatedFromBackend = false
            selfUser.setLocallyModifiedKeys(availabilityKeySet)

            let team = Team.insertNewObject(in: syncMOC)

            let membership = Member.insertNewObject(in: syncMOC)
            membership.user = selfUser
            membership.team = team

            self.sut.contextChangeTrackers
                .forEach { $0.addTrackedObjects(Set<NSManagedObject>(arrayLiteral: selfUser)) }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(messageSender.broadcastMessageMessage_Invocations.count, 1)
    }

    func testThatItDoesntBroadcastWhenAvailabilityIsModifiedForOtherUsers() {
        syncMOC.performGroupedAndWait {
            // given
            self.messageSender.broadcastMessageMessage_MockMethod = { _ in }

            let availabilityKeySet: Set<AnyHashable> = [AvailabilityKey]
            self.otherUser.needsToBeUpdatedFromBackend = false
            self.otherUser.modifiedKeys = availabilityKeySet
            self.sut.contextChangeTrackers
                .forEach { $0.addTrackedObjects(Set<NSManagedObject>(arrayLiteral: self.otherUser)) }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(messageSender.broadcastMessageMessage_Invocations.count, 0)
    }

    func testThatItUpdatesAvailabilityFromUpdateEvent() throws {
        try syncMOC.performGroupedAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: syncMOC)
            _ = ZMConversation
                .fetchOrCreate(with: selfUser.remoteIdentifier!, domain: nil, in: syncMOC) // create self conversation

            let message = GenericMessage(content: WireProtos.Availability(.away))
            let messageData = try message.serializedData()
            let dict = [
                "recipient": self.selfClient.remoteIdentifier!,
                "sender": self.selfClient.remoteIdentifier!,
                "text": messageData.base64String(),
            ] as NSDictionary

            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: [
                "type": "conversation.otr-message-add",
                "data": dict,
                "from": selfUser.remoteIdentifier!,
                "conversation": ZMConversation.selfConversation(in: syncMOC).remoteIdentifier!.transportString(),
                "time": Date(timeIntervalSince1970: 555_555).transportString(),
            ] as NSDictionary, uuid: nil)!

            // when
            self.sut.processEvents([updateEvent], liveEvents: true, prefetchResult: nil)

            // then
            XCTAssertEqual(selfUser.availability, .away)
        }
    }
}
