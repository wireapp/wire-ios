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

import Foundation
@testable import WireDataModel

class BaseZMClientMessageTests: BaseZMMessageTests {
    var syncSelfUser: ZMUser!
    var syncUser1: ZMUser!
    var syncUser2: ZMUser!
    var syncUser3: ZMUser!

    var syncSelfClient1: UserClient!
    var syncSelfClient2: UserClient!
    var syncUser1Client1: UserClient!
    var syncUser1Client2: UserClient!
    var syncUser2Client1: UserClient!
    var syncUser2Client2: UserClient!
    var syncUser3Client1: UserClient!

    var syncConversation: ZMConversation!
    var syncExpectedRecipients: [String: [String]]!

    var user1: ZMUser!
    var user2: ZMUser!
    var user3: ZMUser!

    var selfClient1: UserClient!
    var selfClient2: UserClient!
    var user1Client1: UserClient!
    var user1Client2: UserClient!
    var user2Client1: UserClient!
    var user2Client2: UserClient!
    var user3Client1: UserClient!

    var conversation: ZMConversation!

    var expectedRecipients: [String: [String]]!

    override func setUp() {
        DeveloperFlag.storage = UserDefaults(suiteName: UUID().uuidString)!
        var flag = DeveloperFlag.proteusViaCoreCrypto
        flag.isOn = false

        super.setUp()

        syncMOC.performGroupedAndWait {
            self.syncSelfUser = ZMUser.selfUser(in: self.syncMOC)

            self.syncSelfClient1 = self.createSelfClient(onMOC: self.syncMOC)
            self.syncMOC.setPersistentStoreMetadata(self.syncSelfClient1.remoteIdentifier!, key: ZMPersistedClientIdKey)

            self.syncSelfClient2 = self.createClient(
                for: self.syncSelfUser,
                createSessionWithSelfUser: true,
                onMOC: self.syncMOC
            )

            self.syncUser1 = ZMUser.insertNewObject(in: self.syncMOC)
            self.syncUser1Client1 = self.createClient(
                for: self.syncUser1,
                createSessionWithSelfUser: true,
                onMOC: self.syncMOC
            )
            self.syncUser1Client2 = self.createClient(
                for: self.syncUser1,
                createSessionWithSelfUser: true,
                onMOC: self.syncMOC
            )

            self.syncUser2 = ZMUser.insertNewObject(in: self.syncMOC)
            self.syncUser2Client1 = self.createClient(
                for: self.syncUser2,
                createSessionWithSelfUser: true,
                onMOC: self.syncMOC
            )
            self.syncUser2Client2 = self.createClient(
                for: self.syncUser2,
                createSessionWithSelfUser: false,
                onMOC: self.syncMOC
            )

            self.syncUser3 = ZMUser.insertNewObject(in: self.syncMOC)
            self.syncUser3Client1 = self.createClient(
                for: self.syncUser3,
                createSessionWithSelfUser: false,
                onMOC: self.syncMOC
            )

            self.syncConversation = ZMConversation.insertGroupConversation(
                moc: self.syncMOC,
                participants: [
                    self.syncUser1!,
                    self.syncUser2!,
                    self.syncUser3!,
                ]
            )

            self.syncConversation.remoteIdentifier = UUID.create()

            self.expectedRecipients = [
                self.syncSelfUser.remoteIdentifier!.transportString(): [
                    self.syncSelfClient2.remoteIdentifier!,
                ],
                self.syncUser1.remoteIdentifier!.transportString(): [
                    self.syncUser1Client1.remoteIdentifier!,
                    self.syncUser1Client2.remoteIdentifier!,
                ],
                self.syncUser2.remoteIdentifier!.transportString(): [
                    self.syncUser2Client1.remoteIdentifier!,
                ],
            ]

            self.syncMOC.saveOrRollback()
        }

        uiMOC.refreshAllObjects()

        selfUser = try! uiMOC.existingObject(with: syncSelfUser.objectID) as! ZMUser
        selfClient1 = try! uiMOC.existingObject(with: syncSelfClient1.objectID) as! UserClient
        uiMOC.setPersistentStoreMetadata(selfClient1.remoteIdentifier!, key: ZMPersistedClientIdKey)

        selfClient2 = try! uiMOC.existingObject(with: syncSelfClient2.objectID) as! UserClient

        user1 = try! uiMOC.existingObject(with: syncUser1.objectID) as! ZMUser
        user1Client1 = try! uiMOC.existingObject(with: syncUser1Client1.objectID) as! UserClient
        user1Client2 = try! uiMOC.existingObject(with: syncUser1Client2.objectID) as! UserClient

        user2 = try! uiMOC.existingObject(with: syncUser2.objectID) as! ZMUser
        user2Client1 = try! uiMOC.existingObject(with: syncUser2Client1.objectID) as! UserClient
        user2Client2 = try! uiMOC.existingObject(with: syncUser2Client2.objectID) as! UserClient

        user3 = try! uiMOC.existingObject(with: syncUser3.objectID) as! ZMUser
        user3Client1 = try! uiMOC.existingObject(with: syncUser3Client1.objectID) as! UserClient

        conversation = try! uiMOC.existingObject(with: syncConversation.objectID) as! ZMConversation
        expectedRecipients = [
            selfUser.remoteIdentifier!.transportString(): [
                selfClient2.remoteIdentifier!,
            ],
            user1.remoteIdentifier!.transportString(): [
                user1Client1.remoteIdentifier!,
                user1Client2.remoteIdentifier!,
            ],
            user2.remoteIdentifier!.transportString(): [
                user2Client1.remoteIdentifier!,
            ],
        ]
    }

    override func tearDown() {
        syncMOC.performGroupedAndWait {
            self.syncMOC.setPersistentStoreMetadata(nil as String?, key: ZMPersistedClientIdKey)
        }
        wipeCaches()
        syncSelfUser = nil
        syncUser1 = nil
        syncUser2 = nil
        syncUser3 = nil

        syncSelfClient1 = nil
        syncSelfClient2 = nil
        syncUser1Client1 = nil
        syncUser1Client2 = nil
        syncUser2Client1 = nil
        syncUser2Client2 = nil
        syncUser3Client1 = nil

        syncConversation = nil
        syncExpectedRecipients = nil

        user1 = nil
        user2 = nil
        user3 = nil

        selfClient1 = nil
        selfClient2 = nil
        user1Client1 = nil
        user1Client2 = nil
        user2Client1 = nil
        user2Client2 = nil
        user3Client1 = nil

        conversation = nil

        expectedRecipients = nil
        super.tearDown()
        DeveloperFlag.storage = UserDefaults.standard
    }

    func assertRecipients(_ recipients: [Proteus_UserEntry], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(recipients.count, expectedRecipients.count, file: file, line: line)

        for recipientEntry in recipients {
            guard let uuid = UUID(data: recipientEntry.user.uuid) else {
                XCTFail("Missing user UUID", file: file, line: line)
                return
            }
            guard let expectedClientsIds: [String] = expectedRecipients[uuid.transportString()]?.sorted() else {
                XCTFail("Unexpected otr client in recipients", file: file, line: line)
                return
            }
            let clientIds = (recipientEntry.clients).map { String(format: "%llx", $0.client.client) }.sorted()
            XCTAssertEqual(clientIds, expectedClientsIds, file: file, line: line)
            let hasTexts = (recipientEntry.clients).map(\.hasText)
            XCTAssertFalse(hasTexts.contains(false), file: file, line: line)
        }
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
                "sender": senderClientID,
            ],
            "type": "conversation.otr-message-add",
        ]
        switch eventSource {
        case .download:
            return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nonce)!
        default:
            let streamPayload = [
                "payload": [payload],
                "id": UUID.create(),
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
