// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import ZMCDataModel

class BaseZMClientMessageTests : BaseZMMessageTests {
    
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
        super.setUp()
        setUpCaches()
        self.syncMOC.performGroupedBlockAndWait {
            self.syncSelfUser = ZMUser.selfUserInContext(self.syncMOC)
            
            self.syncSelfClient1 = self.createSelfClientOnMOC(self.syncMOC)
            self.syncMOC.setPersistentStoreMetadata(self.syncSelfClient1.remoteIdentifier, forKey: "PersistedClientId")
            
            self.syncSelfClient2 = self.createClientForUser(self.syncSelfUser, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            
            self.syncUser1 = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
            self.syncUser1Client1 = self.createClientForUser(self.syncUser1, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            self.syncUser1Client2 = self.createClientForUser(self.syncUser1, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            
            self.syncUser2 = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
            self.syncUser2Client1 = self.createClientForUser(self.syncUser2, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            self.syncUser2Client2 = self.createClientForUser(self.syncUser2, createSessionWithSelfUser: false, onMOC: self.syncMOC)
            
            self.syncUser3 = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
            self.syncUser3Client1 = self.createClientForUser(self.syncUser3, createSessionWithSelfUser: false, onMOC: self.syncMOC)
            
            self.syncConversation = ZMConversation.insertGroupConversationIntoManagedObjectContext(self.syncMOC, withParticipants: [self.syncUser1, self.syncUser2, self.syncUser3])
            self.expectedRecipients = [
                self.syncSelfUser.remoteIdentifier!.transportString(): [
                    self.syncSelfClient2.remoteIdentifier
                ],
                self.syncUser1.remoteIdentifier!.transportString(): [
                    self.syncUser1Client1.remoteIdentifier,
                    self.syncUser1Client2.remoteIdentifier
                ],
                self.syncUser2.remoteIdentifier!.transportString(): [
                    self.syncUser2Client1.remoteIdentifier
                ]
            ]
            
            self.syncMOC.saveOrRollback()
        }
        
        self.selfUser = try! self.uiMOC.existingObjectWithID(self.syncSelfUser.objectID) as! ZMUser
        
        self.selfClient1 = try! self.uiMOC.existingObjectWithID(self.syncSelfClient1.objectID) as! UserClient
        self.uiMOC.setPersistentStoreMetadata(self.selfClient1.remoteIdentifier, forKey: "PersistedClientId")
        
        self.selfClient2 = try! self.uiMOC.existingObjectWithID(self.syncSelfClient2.objectID) as! UserClient
        
        self.user1 = try! self.uiMOC.existingObjectWithID(self.syncUser1.objectID) as! ZMUser
        self.user1Client1 = try! self.uiMOC.existingObjectWithID(self.syncUser1Client1.objectID) as! UserClient
        self.user1Client2 = try! self.uiMOC.existingObjectWithID(self.syncUser1Client2.objectID) as! UserClient
        
        self.user2 = try! self.uiMOC.existingObjectWithID(self.syncUser2.objectID) as! ZMUser
        self.user2Client1 = try! self.uiMOC.existingObjectWithID(self.syncUser2Client1.objectID) as! UserClient
        self.user2Client2 = try! self.uiMOC.existingObjectWithID(self.syncUser2Client2.objectID) as! UserClient
        
        self.user3 = try! self.uiMOC.existingObjectWithID(self.syncUser3.objectID) as! ZMUser
        self.user3Client1 = try! self.uiMOC.existingObjectWithID(self.syncUser3Client1.objectID) as! UserClient
        
        self.conversation = try! self.uiMOC.existingObjectWithID(self.syncConversation.objectID) as! ZMConversation
        self.expectedRecipients = [
            self.selfUser.remoteIdentifier!.transportString(): [
                self.selfClient2.remoteIdentifier
            ],
            self.user1.remoteIdentifier!.transportString(): [
                self.user1Client1.remoteIdentifier,
                self.user1Client2.remoteIdentifier
            ],
            self.user2.remoteIdentifier!.transportString(): [
                self.user2Client1.remoteIdentifier
            ]
        ]
    }
    
    override func tearDown() {
        syncMOC.performGroupedBlockAndWait {
            self.syncMOC.setPersistentStoreMetadata(nil, forKey: "PersistedClientId")
        }
        wipeCaches()
        super.tearDown()
    }
    
    func assertRecipients(recipients: [ZMUserEntry], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(recipients.count, expectedRecipients.count, file: file, line: line)
        
        for recipientEntry in recipients {
            let uuid = NSUUID(UUIDBytes: UnsafePointer(recipientEntry.user.uuid.bytes)).transportString()
            guard let expectedClientsIds = self.expectedRecipients[uuid]?.sort() else {
                XCTFail("Unexpected otr client in recipients", file: file, line: line)
                return
            }
            let clientIds = (recipientEntry.clients as! [ZMClientEntry]).map { String(format: "%llx", $0.client.client) } .sort()
            XCTAssertEqual(clientIds, expectedClientsIds, file: file, line: line)
            let hasTexts = (recipientEntry.clients as! [ZMClientEntry]).map { $0.hasText() }
            XCTAssertFalse(hasTexts.contains(false), file: file, line: line)
            
        }
    }
    
    func createUpdateEvent(nonce: NSUUID, conversationID: NSUUID, genericMessage: ZMGenericMessage, senderID: NSUUID = .createUUID(), eventSource: ZMUpdateEventSource = .Download) -> ZMUpdateEvent {
        let payload = [
            "id": NSUUID.createUUID().transportString(),
            "conversation": conversationID.transportString(),
            "from": senderID.transportString(),
            "time": NSDate().transportString(),
            "data": [
                "text": genericMessage.data().base64String()
            ],
            "type": "conversation.otr-message-add"
        ]
        switch eventSource {
        case .Download:
            return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nonce)
        default:
            let streamPayload = ["payload" : [payload],
                                 "id" : NSUUID.createUUID().transportString()]
            let event = ZMUpdateEvent.eventsArrayFromTransportData(streamPayload,
                                                                   source: eventSource)!.first!
            XCTAssertNotNil(event)
            return event
        }
    }

}
