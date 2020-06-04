//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

@testable import WireDataModel

class ZMConversationTests_Confirmations: ZMConversationTestsBase {


    func testThatConfirmUnreadMessagesAsRead_DoesntConfirmAlreadyReadMessages() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        
        let user1 = createUser()
        let user2 = createUser()
        
        let message1 = conversation.append(text: "text1") as! ZMClientMessage
        let message2 = conversation.append(text: "text2") as! ZMClientMessage
        let message3 = conversation.append(text: "text3") as! ZMClientMessage
        let message4 = conversation.append(text: "text4") as! ZMClientMessage
        
        [message1, message2, message3, message4].forEach({ $0.expectsReadConfirmation = true })
        
        message1.sender = user2
        message2.sender = user1
        message3.sender = user2
        message4.sender = user1
        
        conversation.conversationType = .group
        conversation.lastReadServerTimeStamp = message1.serverTimestamp
        
        // when
        var confirmMessages = conversation.confirmUnreadMessagesAsRead(until: .distantFuture)
        
        // then
        XCTAssertEqual(confirmMessages.count, 2)
        
        if (confirmMessages[0].underlyingMessage?.confirmation.firstMessageID != message2.nonce?.transportString()) {
            // Confirm messages order is not stable so we need swap if they are not in the expected order
            confirmMessages.swapAt(0, 1)
        }
        
        XCTAssertEqual(confirmMessages[0].underlyingMessage?.confirmation.firstMessageID, message2.nonce?.transportString())
        XCTAssertEqual(confirmMessages[0].underlyingMessage?.confirmation.moreMessageIds as! [String], [message4.nonce!.transportString()])
        XCTAssertEqual(confirmMessages[1].underlyingMessage?.confirmation.firstMessageID, message3.nonce?.transportString())
        XCTAssertEqual(confirmMessages[1].underlyingMessage?.confirmation.moreMessageIds, [])
    }
    
    func testThatConfirmUnreadMessagesAsRead_DoesntConfirmMessageAfterTheTimestamp() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        
        let user1 = createUser()
        let user2 = createUser()
        
        let message1 = conversation.append(text: "text1") as! ZMClientMessage
        let message2 = conversation.append(text: "text2") as! ZMClientMessage
        let message3 = conversation.append(text: "text3") as! ZMClientMessage
        
        [message1, message2, message3].forEach({ $0.expectsReadConfirmation = true })
        
        message1.sender = user1
        message2.sender = user1
        message3.sender = user2
        
        conversation.conversationType = .group
        conversation.lastReadServerTimeStamp = .distantPast
        
        // when
        var confirmMessages = conversation.confirmUnreadMessagesAsRead(until: message2.serverTimestamp!)
        
        // then
        XCTAssertEqual(confirmMessages.count, 1)
        XCTAssertEqual(confirmMessages[0].underlyingMessage?.confirmation.firstMessageID, message1.nonce?.transportString())
        XCTAssertEqual(confirmMessages[0].underlyingMessage?.confirmation.moreMessageIds as! [String], [message2.nonce!.transportString()])
    }
    
    func testThatItConfirmsSentMessagesAsDelivered() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        
        let user1 = createUser()
        let user2 = createUser()
        
        let message1 = conversation.append(text: "text1") as! ZMClientMessage
        let message2 = conversation.append(text: "text2") as! ZMClientMessage
        let message3 = conversation.append(text: "text3") as! ZMClientMessage
        let messages = [message1, message2, message3]
        messages.forEach({ $0.markAsSent() })
        
        message1.sender = user1
        message2.sender = user1
        message3.sender = user2
        
        conversation.conversationType = .oneOnOne
        
        // when
        
        let messagesUUIDs: Set<UUID> = [message1.nonce!, message2.nonce!, message3.nonce!]
        let conversationsUUIDs: Set<UUID> = [conversation.remoteIdentifier!]
        
        _ = ZMConversation.confirmDeliveredMessages(messagesUUIDs,
                                                in: conversationsUUIDs,
                                                with: self.uiMOC)
        
        // then
        var nonces = Set(messagesUUIDs.map { $0.transportString() })
        guard let lastMessage = (conversation.hiddenMessages.first as? ZMClientMessage)?.underlyingMessage else { XCTFail(); return }
        XCTAssertNotNil(lastMessage.confirmation)
        
        // Verifies that first message ID is in the set of added nonces
        XCTAssertNotNil(nonces.remove(at: nonces.firstIndex(of: lastMessage.confirmation.firstMessageID)!))
        // Verifies that other nonces are included in the "moreMessageIds" array
        XCTAssertTrue(nonces.isSubset(of: lastMessage.confirmation.moreMessageIds as! [String]))
        
        XCTAssertEqual(lastMessage.confirmation.moreMessageIds.count, 2)
    }
    
    func testThatItConfirmsMessagesOnMultipleConversationsAsDelivered() {
        
        // given
        let conversation1 = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation1.remoteIdentifier = UUID.create()
        
        let conversation2 = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation2.remoteIdentifier = UUID.create()
        
        let user1 = createUser()
        let user2 = createUser()
        
        let message1 = conversation1.append(text: "text1") as! ZMClientMessage
        let message2 = conversation2.append(text: "text2") as! ZMClientMessage
        
        [message1, message2].forEach({ $0.markAsSent() })
        
        message1.sender = user1
        message2.sender = user2
        
        conversation1.conversationType = .oneOnOne
        conversation2.conversationType = .oneOnOne
        
        // when
        
        let messagesUUIDs: Set<UUID> = [message1.nonce!, message2.nonce!]
        let conversationsUUIDs: Set<UUID> = [conversation1.remoteIdentifier!, conversation2.remoteIdentifier!]
        
        _ = ZMConversation.confirmDeliveredMessages(messagesUUIDs,
                                                in: conversationsUUIDs,
                                                with: self.uiMOC)
        
        // then
        guard let lastMessageC1 = (conversation1.hiddenMessages.first as? ZMClientMessage)?.underlyingMessage else { XCTFail(); return }
        XCTAssertNotNil(lastMessageC1.confirmation)
        XCTAssertEqual(lastMessageC1.confirmation.firstMessageID, message1.nonce!.transportString())
        XCTAssertEqual(lastMessageC1.confirmation.moreMessageIds, [])
        
        guard let lastMessageC2 = (conversation2.hiddenMessages.first as? ZMClientMessage)?.underlyingMessage else { XCTFail(); return }
        XCTAssertNotNil(lastMessageC2.confirmation)
        XCTAssertEqual(lastMessageC2.confirmation.firstMessageID, message2.nonce!.transportString())
        XCTAssertEqual(lastMessageC2.confirmation.moreMessageIds, [])
    }
    
    func testThatConfirmedMessagesAreNotMarkedAsConfirmed() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        
        let user1 = createUser()
        let user2 = createUser()
        
        let message1 = conversation.append(text: "text1") as! ZMClientMessage
        let message2 = conversation.append(text: "text2") as! ZMClientMessage
        [message1, message2].forEach({ $0.markAsSent() })
        
        message1.sender = user1
        message2.sender = user2
        
        conversation.conversationType = .oneOnOne
        
        // when
        
        let confirmation = ZMMessageConfirmation(type: .delivered, message: message1, sender: user1, serverTimestamp: Date(), managedObjectContext: uiMOC)
        message1.mutableSetValue(forKey: "confirmations").add(confirmation)
        
        let messagesUUIDs: Set<UUID> = [message1.nonce!, message2.nonce!]
        let conversationsUUIDs: Set<UUID> = [conversation.remoteIdentifier!]
        
        _ = ZMConversation.confirmDeliveredMessages(messagesUUIDs,
                                                in: conversationsUUIDs,
                                                with: self.uiMOC)
        
        // then
        XCTAssertEqual(message1.deliveryState, ZMDeliveryState.delivered)
        XCTAssertEqual(message1.confirmations.count, 1)
        guard let lastMessage = (conversation.hiddenMessages.first as? ZMClientMessage)?.underlyingMessage else { XCTFail(); return }
        XCTAssertNotNil(lastMessage.confirmation)
        XCTAssertEqual(lastMessage.confirmation.firstMessageID, message2.nonce!.transportString())
        XCTAssertEqual(lastMessage.confirmation.moreMessageIds, [])
    }
    
    func testThatReadMessagesAreNotMarkedAsConfirmed() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        
        let user1 = createUser()
        let user2 = createUser()
        
        let message1 = conversation.append(text: "text1") as! ZMClientMessage
        let message2 = conversation.append(text: "text2") as! ZMClientMessage
        [message1, message2].forEach({ $0.markAsSent() })
        
        message1.sender = user1
        message2.sender = user2
        
        conversation.conversationType = .oneOnOne
        
        // when
        
        let confirmation = ZMMessageConfirmation(type: .read, message: message1, sender: user1, serverTimestamp: Date(), managedObjectContext: uiMOC)
        message1.mutableSetValue(forKey: "confirmations").add(confirmation)
        
        let messagesUUIDs: Set<UUID> = [message1.nonce!, message2.nonce!]
        let conversationsUUIDs: Set<UUID> = [conversation.remoteIdentifier!]
        
        _ = ZMConversation.confirmDeliveredMessages(messagesUUIDs,
                                                in: conversationsUUIDs,
                                                with: self.uiMOC)
        
        // then
        XCTAssertEqual(message1.deliveryState, ZMDeliveryState.read)
        XCTAssertEqual(message1.confirmations.count, 1)
        guard let lastMessage = (conversation.hiddenMessages.first as? ZMClientMessage)?.underlyingMessage else { XCTFail(); return }
        XCTAssertNotNil(lastMessage.confirmation)
        XCTAssertEqual(lastMessage.confirmation.firstMessageID, message2.nonce!.transportString())
        XCTAssertEqual(lastMessage.confirmation.moreMessageIds, [])
    }
    
}
