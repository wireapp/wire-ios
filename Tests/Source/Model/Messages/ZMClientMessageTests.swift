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

        syncSelfUser = ZMUser.selfUserInContext(self.syncMOC);
        
        selfClient1 = createSelfClient()
        syncMOC.setPersistentStoreMetadata(selfClient1.remoteIdentifier, forKey: "PersistedClientId")
        
        selfClient2 = createClientForUser(syncSelfUser, createSessionWithSelfUser: true)
        
        user1 = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC);
        user1Client1 = createClientForUser(user1, createSessionWithSelfUser: true)
        user1Client2 = createClientForUser(user1, createSessionWithSelfUser: true)
        
        user2 = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC);
        user2Client1 = createClientForUser(user2, createSessionWithSelfUser: true)
        user2Client2 = createClientForUser(user2, createSessionWithSelfUser: false)
        
        user3 = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC);
        user3Client1 = createClientForUser(user3, createSessionWithSelfUser: false)
        
        conversation = ZMConversation.insertGroupConversationIntoManagedObjectContext(self.syncMOC, withParticipants: [user1, user2, user3])
        
        expectedRecipients = [
            syncSelfUser.remoteIdentifier!.transportString(): [
                selfClient2.remoteIdentifier
            ],
            user1.remoteIdentifier!.transportString(): [
                user1Client1.remoteIdentifier,
                user1Client2.remoteIdentifier
            ],
            user2.remoteIdentifier!.transportString(): [
                user2Client1.remoteIdentifier
            ]
        ]
        
    }
    
    override func tearDown() {
        syncMOC.setPersistentStoreMetadata(nil, forKey: "PersistedClientId")
        wipeCaches()
        super.tearDown()
    }
    
    func assertRecipients(recipients: [ZMUserEntry]) {
        XCTAssertEqual(recipients.count, expectedRecipients.count)
        
        for recipientEntry in recipients {
            let uuid = NSUUID(UUIDBytes: UnsafePointer(recipientEntry.user.uuid.bytes)).transportString()
            let expectedClientsIds = self.expectedRecipients[uuid]?.sort()
            AssertOptionalNotNil(expectedClientsIds, "Unexpected otr client in recipients") { expectedClientsIds in
                let clientIds = (recipientEntry.clients as! [ZMClientEntry]).map { String(format: "%llx", $0.client.client) } .sort()
                XCTAssertEqual(clientIds, expectedClientsIds)
                let hasTexts = (recipientEntry.clients as! [ZMClientEntry]).map { $0.hasText() }
                XCTAssertFalse(hasTexts.contains(false))
            }
        }
    }
    

}
