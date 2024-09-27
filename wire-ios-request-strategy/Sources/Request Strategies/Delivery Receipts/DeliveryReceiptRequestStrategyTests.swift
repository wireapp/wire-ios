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

import XCTest
@testable import WireRequestStrategy
@testable import WireRequestStrategySupport

class DeliveryReceiptRequestStrategyTests: MessagingTestBase {
    var mockApplicationStatus: MockApplicationStatus!
    var mockClientRegistrationStatus: MockClientRegistrationStatus!
    var mockMessageSender: MockMessageSenderInterface!
    var secondOneToOneConveration: ZMConversation!
    var secondUser: ZMUser!
    var sut: DeliveryReceiptRequestStrategy!

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        mockClientRegistrationStatus = MockClientRegistrationStatus()
        mockMessageSender = MockMessageSenderInterface()

        sut = DeliveryReceiptRequestStrategy(
            managedObjectContext: syncMOC,
            messageSender: mockMessageSender
        )

        syncMOC.performGroupedAndWait {
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = UUID.create()

            self.secondUser = self.createUser(alsoCreateClient: true)
            self.secondOneToOneConveration = self.setupOneToOneConversation(with: self.secondUser)
        }
    }

    override func tearDown() {
        sut = nil
        secondUser = nil
        secondOneToOneConveration = nil
        mockClientRegistrationStatus = nil
        mockApplicationStatus = nil
        super.tearDown()
    }

    // MARK: Request generation

    func testThatDeliveryReceiptIsScheduled_WhenProcessingEventWhichNeedsDeliveryReceipt() throws {
        syncMOC.performGroupedAndWait {
            self.mockMessageSender.sendMessageMessage_MockMethod = { _ in }
            let event = self.createTextUpdateEvent(from: self.otherUser, in: self.oneToOneConversation)

            // when
            self.sut.processEvents([event], liveEvents: Bool.random(), prefetchResult: nil)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(1, mockMessageSender.sendMessageMessage_Invocations.count)
    }

    // MARK: Delivery receipt creation

    func testThatDeliveryReceiptIsCreatedFromUpdateEvent() {
        syncMOC.performGroupedAndWait {
            // given
            let event = self.createTextUpdateEvent(from: self.otherUser, in: self.oneToOneConversation)

            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: [event])

            // then
            XCTAssertEqual(deliveryReceipts.count, 1)
            XCTAssertEqual(deliveryReceipts.first?.messageIDs.count, 1)
            XCTAssertEqual(deliveryReceipts.first?.conversation, self.oneToOneConversation)
        }
    }

    func testThatDeliveryReceiptIsNotCreatedFromUpdateEvent_WhenMessageIsADeliveryReceipt() {
        syncMOC.performGroupedAndWait {
            // given
            let confirmation = GenericMessage(content: Confirmation(messageId: .create()))
            let event = self.createUpdateEvent(
                message: confirmation,
                from: self.otherUser,
                in: self.oneToOneConversation
            )

            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: [event])

            // then
            XCTAssertEqual(deliveryReceipts.count, 0)
        }
    }

    func testThatDeliveryReceiptIsNotCreatedFromUpdateEvent_WhenMessageIsSentInGroupConversation() {
        syncMOC.performGroupedAndWait {
            // given
            let event = self.createTextUpdateEvent(from: self.otherUser, in: self.groupConversation)

            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: [event])

            // then
            XCTAssertEqual(deliveryReceipts.count, 0)
        }
    }

    func testThatDeliveryReceiptIsNotCreatedFromUpdateEvent_WhenMessageIsSentBySelfUser() {
        syncMOC.performGroupedAndWait {
            // given
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let event = self.createTextUpdateEvent(from: selfUser, in: self.groupConversation)

            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: [event])

            // then
            XCTAssertEqual(deliveryReceipts.count, 0)
        }
    }

    func testThatDeliveryReceiptIsNotCreatedFromUpdateEvent_WhenMessageIsOlderThan7Days() {
        syncMOC.performGroupedAndWait {
            // given
            let eightDaysAgo = Date(timeIntervalSinceNow: -(60 * 60 * 24 * 8))
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let event = self.createTextUpdateEvent(
                from: selfUser,
                in: self.oneToOneConversation,
                timestamp: eightDaysAgo
            )

            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: [event])

            // then
            XCTAssertEqual(deliveryReceipts.count, 0)
        }
    }

    func testMessagesAreCombined_WhenSameSenderMultipleMessageInAConversation() {
        syncMOC.performGroupedAndWait {
            // given
            let events = [
                self.createTextUpdateEvent(from: self.otherUser, in: self.oneToOneConversation),
                self.createTextUpdateEvent(from: self.otherUser, in: self.oneToOneConversation),
            ]

            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: events)

            // then
            XCTAssertEqual(deliveryReceipts.count, 1)
            XCTAssertEqual(deliveryReceipts.first?.messageIDs.count, 2)
            XCTAssertEqual(deliveryReceipts.first?.conversation, self.oneToOneConversation)
        }
    }

    func testMessagesAreNotCombined_WhenSameSenderMultipleMessageInDifferentConversations() {
        syncMOC.performGroupedAndWait {
            // given
            let events = [
                self.createTextUpdateEvent(from: self.otherUser, in: self.oneToOneConversation),
                self.createTextUpdateEvent(from: self.otherUser, in: self.secondOneToOneConveration),
            ]

            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: events)

            // then
            XCTAssertEqual(deliveryReceipts.count, 2)
            XCTAssertEqual(deliveryReceipts.first?.messageIDs.count, 1)
        }
    }

    func testMessagesAreNotCombined_WhenDifferentSendersSendMultipleMessageInAConversations() {
        syncMOC.performGroupedAndWait {
            // given
            let events = [
                self.createTextUpdateEvent(from: self.otherUser, in: self.oneToOneConversation),
                self.createTextUpdateEvent(from: self.secondUser, in: self.oneToOneConversation),
            ]

            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: events)

            // then
            XCTAssertEqual(deliveryReceipts.count, 2)
            XCTAssertEqual(deliveryReceipts[0].messageIDs.count, 1)
            XCTAssertEqual(deliveryReceipts[1].messageIDs.count, 1)
        }
    }

    // MARK: Helpers

    func createTextUpdateEvent(
        from sender: ZMUser,
        in conversation: ZMConversation,
        timestamp: Date = Date()
    ) -> ZMUpdateEvent {
        let message = GenericMessage(content: WireProtos.Text(content: "Hello World"))
        return createUpdateEvent(message: message, from: sender, in: conversation, timestamp: timestamp)
    }

    func createUpdateEvent(
        message: GenericMessage,
        from sender: ZMUser,
        in conversation: ZMConversation,
        timestamp: Date = Date()
    ) -> ZMUpdateEvent {
        let dict: NSDictionary = [
            "recipient": selfClient.remoteIdentifier!,
            "sender": selfClient.remoteIdentifier!,
            "text": try! message.serializedData().base64String(),
        ]

        let payload: NSDictionary = [
            "type": "conversation.otr-message-add",
            "data": dict,
            "from": sender.remoteIdentifier!.transportString(),
            "conversation": conversation.remoteIdentifier!.transportString(),
            "time": timestamp.transportString(),
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
    }
}
