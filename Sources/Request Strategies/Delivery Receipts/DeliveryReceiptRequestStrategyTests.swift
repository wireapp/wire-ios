//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

class DeliveryReceiptRequestStrategyTests: MessagingTestBase {
    
    var mockClientRegistrationStatus: MockClientRegistrationStatus!
    var secondOneToOneConveration: ZMConversation!
    var secondUser: ZMUser!
    var sut: DeliveryReceiptRequestStrategy!
    
    override func setUp() {
        super.setUp()
        mockClientRegistrationStatus = MockClientRegistrationStatus()
        
        sut = DeliveryReceiptRequestStrategy(managedObjectContext: syncMOC, clientRegistrationDelegate: mockClientRegistrationStatus)
        
        syncMOC.performGroupedBlockAndWait {
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
        super.tearDown()
    }
    
    // MARK: Request generation

    func testThatRequestIsGenerated_WhenProcessingEventWhichNeedsDeliveryReceipt() throws {
        try syncMOC.performGroupedAndWait { moc in
            let conversationID = self.oneToOneConversation.remoteIdentifier!.transportString()
            let event = self.createTextUpdateEvent(from: self.otherUser, in: self.oneToOneConversation)
            
            // when
            self.sut.processEventsWhileInBackground([event])
            
            // then
            let request = try XCTUnwrap(self.sut.nextRequest())
            XCTAssertEqual(request.path, "/conversations/\(conversationID)/otr/messages")
        }
    }
        
    // MARK: Delivery receipt creation
    
    func testThatDeliveryReceiptIsCreatedFromUpdateEvent() {
        syncMOC.performGroupedAndWait { _ in
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
    
    func testThatDeliveryReceiptIsNotCreatedFromUpdateEvent_WhenMessageIsSentInGroupConversation() {
        syncMOC.performGroupedAndWait { _ in
            // given
            let event = self.createTextUpdateEvent(from: self.otherUser, in: self.groupConversation)
            
            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: [event])
            
            // then
            XCTAssertEqual(deliveryReceipts.count, 0)
        }
    }
    
    func testThatDeliveryReceiptIsNotCreatedFromUpdateEvent_WhenMessageIsSentBySelfUser() {
        syncMOC.performGroupedAndWait { _ in
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
        syncMOC.performGroupedAndWait { _ in
            // given
            let eightDaysAgo = Date(timeIntervalSinceNow: -(60 * 60 * 24 * 8))
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let event = self.createTextUpdateEvent(from: selfUser, in: self.oneToOneConversation, timestamp: eightDaysAgo)
            
            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: [event])
            
            // then
            XCTAssertEqual(deliveryReceipts.count, 0)
        }
    }
    
    func testMessagesAreCombined_WhenSameSenderMultipleMessageInAConversation() {
        syncMOC.performGroupedAndWait { _ in
            // given
            let events = [self.createTextUpdateEvent(from: self.otherUser, in: self.oneToOneConversation),
                          self.createTextUpdateEvent(from: self.otherUser, in: self.oneToOneConversation)]
            
            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: events)
            
            // then
            XCTAssertEqual(deliveryReceipts.count, 1)
            XCTAssertEqual(deliveryReceipts.first?.messageIDs.count, 2)
            XCTAssertEqual(deliveryReceipts.first?.conversation, self.oneToOneConversation)
        }
    }
    
    func testMessagesAreNotCombined_WhenSameSenderMultipleMessageInDifferentConversations() {
        syncMOC.performGroupedAndWait { _ in
            // given
            let events = [self.createTextUpdateEvent(from: self.otherUser, in: self.oneToOneConversation),
                          self.createTextUpdateEvent(from: self.otherUser, in: self.secondOneToOneConveration)]
            
            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: events)
            
            // then
            XCTAssertEqual(deliveryReceipts.count, 2)
            XCTAssertEqual(deliveryReceipts.first?.messageIDs.count, 1)
        }
    }
    
    func testMessagesAreNotCombined_WhenDifferentSendersSendMultipleMessageInAConversations() {
        syncMOC.performGroupedAndWait { _ in
            // given
            let events = [self.createTextUpdateEvent(from: self.otherUser, in: self.oneToOneConversation),
                          self.createTextUpdateEvent(from: self.secondUser, in: self.oneToOneConversation)]
            
            // when
            let deliveryReceipts = self.sut.deliveryReceipts(for: events)
            
            // then
            XCTAssertEqual(deliveryReceipts.count, 2)
            XCTAssertEqual(deliveryReceipts[0].messageIDs.count, 1)
            XCTAssertEqual(deliveryReceipts[1].messageIDs.count, 1)
        }
    }
    
    // MARK: Helpers
    
    func createTextUpdateEvent(from: ZMUser,
                               in conversation: ZMConversation,
                               timestamp: Date = Date()) -> ZMUpdateEvent {
        let conversationID = conversation.remoteIdentifier!.transportString()
        let message = GenericMessage(content: WireProtos.Text(content: "Hello World"))
        let dict = ["recipient": self.selfClient.remoteIdentifier!,
                    "sender": self.selfClient.remoteIdentifier!,
                    "text": try! message.serializedData().base64String()] as NSDictionary

        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: ([
            "type": "conversation.otr-message-add",
            "data":dict,
            "from" : from.remoteIdentifier!.transportString(),
            "conversation": conversationID,
            "time":Date().transportString()] as NSDictionary), uuid: nil)!
        
        return updateEvent
    }
 

}
