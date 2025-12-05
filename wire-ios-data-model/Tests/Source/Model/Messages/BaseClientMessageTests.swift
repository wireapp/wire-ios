//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import Foundation
import GenericMessageProtocol

@testable import WireDataModel

class BaseZMClientMessageTests: BaseZMMessageTests {

    var syncSelfUser: ZMUser!
    var syncUser1: ZMUser!
    var syncUser2: ZMUser!
    var syncSelfClient1: UserClient!
    var syncConversation: ZMConversation!

    var user1: ZMUser!
    var user2: ZMUser!
    var selfClient1: UserClient!
    var conversation: ZMConversation!

    override func setUp() {

        super.setUp()

        syncMOC.performGroupedAndWait {
            self.syncSelfUser = ZMUser.selfUser(in: self.syncMOC)

            self.syncSelfClient1 = self.createSelfClient(onMOC: self.syncMOC)
            self.syncMOC.setPersistentStoreMetadata(self.syncSelfClient1.remoteIdentifier!, key: ZMPersistedClientIdKey)

            self.syncUser1 = ZMUser.insertNewObject(in: self.syncMOC)
            self.syncUser2 = ZMUser.insertNewObject(in: self.syncMOC)

            _ = self.createClient(for: syncUser1, onMOC: syncMOC)
            _ = self.createClient(for: syncUser2, onMOC: syncMOC)

            self.syncConversation = ZMConversation.insertGroupConversation(
                moc: self.syncMOC,
                participants: [self.syncUser1!, self.syncUser2!]
            )

            self.syncConversation.remoteIdentifier = UUID.create()

            self.syncMOC.saveOrRollback()
        }

        uiMOC.refreshAllObjects()

        selfUser = try! uiMOC.existingObject(with: syncSelfUser.objectID) as! ZMUser
        selfClient1 = try! uiMOC.existingObject(with: syncSelfClient1.objectID) as! UserClient
        uiMOC.setPersistentStoreMetadata(selfClient1.remoteIdentifier!, key: ZMPersistedClientIdKey)

        user1 = try! uiMOC.existingObject(with: syncUser1.objectID) as! ZMUser
        user2 = try! uiMOC.existingObject(with: syncUser2.objectID) as! ZMUser

        conversation = try! uiMOC.existingObject(with: syncConversation.objectID) as! ZMConversation
    }

    override func tearDown() {
        syncMOC.performGroupedAndWait {
            self.syncMOC.setPersistentStoreMetadata(nil as String?, key: ZMPersistedClientIdKey)
        }
        wipeCaches()
        syncSelfUser = nil
        syncUser1 = nil
        syncUser2 = nil
        syncSelfClient1 = nil
        syncConversation = nil
        user1 = nil
        user2 = nil
        selfClient1 = nil
        conversation = nil
        super.tearDown()
    }

    func createUpdateEvent(
        _ nonce: UUID,
        conversationID: UUID,
        timestamp: Date = .init(),
        genericMessage: GenericMessage,
        senderID: UUID = .create(),
        senderClientID: String = UUID().transportString(),
        eventSource: ZMUpdateEventSource = .download
    ) -> ZMUpdateEvent {
        let data = try? genericMessage.serializedData().base64String()
        return createUpdateEvent(
            nonce,
            conversationID: conversationID,
            timestamp: timestamp,
            genericMessageData: data ?? "",
            senderID: senderID,
            senderClientID: senderClientID,
            eventSource: eventSource
        )
    }

    private func createUpdateEvent(
        _ nonce: UUID,
        conversationID: UUID,
        timestamp: Date,
        genericMessageData: String,
        senderID: UUID,
        senderClientID: String,
        eventSource: ZMUpdateEventSource
    ) -> ZMUpdateEvent {
        let payload: [String: Any] = [
            "conversation": conversationID.transportString(),
            "from": senderID.transportString(),
            "time": timestamp.transportString(),
            "data": [
                "text": genericMessageData,
                "sender": senderClientID
            ],
            "type": "conversation.otr-message-add"
        ]
        switch eventSource {
        case .download:
            return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nonce)!
        default:
            let streamPayload = [
                "payload": [payload],
                "id": UUID.create()
            ] as [String: Any]
            let event = ZMUpdateEvent.eventsArray(
                from: streamPayload as ZMTransportData,
                source: eventSource
            )!.first!
            XCTAssertNotNil(event)
            return event
        }
    }
}
