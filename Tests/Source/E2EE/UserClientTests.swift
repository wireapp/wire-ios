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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import XCTest
@testable import zmessaging
import Cryptobox

class UserClientTests: MessagingTest {
    
    func clientWithTrustedClientCount(trustedCount: UInt, ignoredClientCount: UInt, missedClientCount: UInt) -> UserClient
    {
        let client = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
        
        func userClientSetWithClientCount(count :UInt) -> Set<UserClient>?
        {
            guard count != 0 else { return nil }
            
            var clients = Set<UserClient>()
            for _ in 0..<count {
                clients.insert(UserClient.insertNewObjectInManagedObjectContext(self.syncMOC))
            }
            return clients
        }
        
        let trustedClient = userClientSetWithClientCount(trustedCount)
        let ignoredClient = userClientSetWithClientCount(ignoredClientCount)
        let missedClient = userClientSetWithClientCount(missedClientCount)
        
        if let trustedClient = trustedClient { client.trustedClients = trustedClient }
        if let ignoredClient = ignoredClient { client.ignoredClients = ignoredClient }
        client.missingClients = missedClient
        
        return client
    }

    func testThatItCanInitializeClient() {
        let client = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
        if let client = client {
            XCTAssertEqual(client.type, ZMUserClientTypePermanent, "Client type should be 'permanent'")
        }
        else {
            XCTAssert(false, "Client should be created")
        }
    }
    
    func testThatItReturnsTrackedKeys() {
        let client = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
        if let trackedKeys = client.keysTrackedForLocalModifications() as? [String] {
            XCTAssertTrue(trackedKeys.contains(ZMUserClientMarkedToDeleteKey), "")
            XCTAssertTrue(trackedKeys.contains(ZMUserClientNumberOfKeysRemainingKey), "")
        }
    }
    
    func testThatItSyncClientsWithNoRemoteIdentifier() {
        let unsyncedClient = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
        let syncedClient = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC);
        syncedClient.remoteIdentifier = "synced"
        
        XCTAssertTrue(UserClient.predicateForObjectsThatNeedToBeInsertedUpstream().evaluateWithObject(unsyncedClient))
        XCTAssertFalse(UserClient.predicateForObjectsThatNeedToBeInsertedUpstream().evaluateWithObject(syncedClient))
    }
    
    func testThatClientCanBeMarkedForDeletion() {
        let client = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
        client.user = ZMUser.selfUserInContext(self.syncMOC)
        
        XCTAssertFalse(client.markedToDelete)
        client.markForDeletion()
        
        XCTAssertTrue(client.markedToDelete)
        XCTAssertTrue(client.hasLocalModificationsForKey(ZMUserClientMarkedToDeleteKey))
    }
    
    func testThatItTracksCorrectKeys() {
        let expectedKeys = [ZMUserClientMarkedToDeleteKey, ZMUserClientNumberOfKeysRemainingKey, ZMUserClientMissingKey]
        let client = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)

        XCTAssertEqual(client.keysTrackedForLocalModifications() as! [String], expectedKeys)
    }
    
    func testThatTrustingClientsRemovesThemFromIgnoredClientList() {
        
        let client = clientWithTrustedClientCount(0, ignoredClientCount:2, missedClientCount:0)
        
        let ignoredClient = client.ignoredClients.first!
        
        client.trustClients(Set(arrayLiteral: ignoredClient))
        
        XCTAssertFalse(client.ignoredClients.contains(ignoredClient))
        XCTAssertTrue(client.trustedClients.contains(ignoredClient))
    }
    
    func testThatIgnoringClientsRemovesThemFromTrustedList() {
        
        let client = clientWithTrustedClientCount(2, ignoredClientCount:1, missedClientCount:0)
        
        let trustedClient = client.trustedClients.first!
        
        client.ignoreClients(Set(arrayLiteral: trustedClient))
        
        XCTAssertFalse(client.trustedClients.contains(trustedClient))
        XCTAssertTrue(client.ignoredClients.contains(trustedClient))
    }
    
    func testThatTrustingClientsRemovesTheNeedToNotifyUser() {
        // Given
        let client = clientWithTrustedClientCount(0, ignoredClientCount:1, missedClientCount:0)
        let ignoredClient = client.ignoredClients.first!
        ignoredClient.needsToNotifyUser = true
        
        // When
        client.trustClient(ignoredClient)
        
        // Then
        XCTAssertFalse(ignoredClient.needsToNotifyUser)
    }
    
    func testThatItDeletesASession() {
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let selfClient = self.createSelfClient()
            let preKeys = try! selfClient.keysStore.box.generatePreKeys(NSMakeRange(0, 2)).map { $0.data!.base64String }
            
            let otherClient = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
            otherClient.remoteIdentifier = NSUUID.createUUID().transportString()
            
            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return
            }
            
            XCTAssertTrue(selfClient.establishSessionWithClient(otherClient, usingPreKey:preKey))
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)
            
            // when
            UserClient.deleteSession(forClientWithRemoteIdentifier:otherClient.remoteIdentifier, managedObjectContext:self.syncMOC)
            
            // then
            XCTAssertFalse(otherClient.hasSessionWithSelfClient)
        }
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
    
    
    func testThatItDeletesASessionWhenDeletingAClient() {
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let selfClient = self.createSelfClient()
            let preKeys = try! selfClient.keysStore.box.generatePreKeys(NSMakeRange(0, 2)).map { $0.data!.base64String }
            
            let otherClient = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
            otherClient.remoteIdentifier = NSUUID.createUUID().transportString()
            
            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return
            }
            
            XCTAssertTrue(selfClient.establishSessionWithClient(otherClient, usingPreKey:preKey))
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)
            
            // when
            otherClient.deleteClientAndEndSession()
            
            // then
            XCTAssertFalse(otherClient.hasSessionWithSelfClient)
            XCTAssertTrue(otherClient.isZombieObject)
        }
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
    
    func testThatItUpdatesConversationSecurityLevelWhenDeletingClient() {
        
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let selfClient = self.createSelfClient()
            
            let otherClient1 = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
            otherClient1.remoteIdentifier = NSUUID.createUUID().transportString()
            
            let otherUser = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
            otherClient1.user = otherUser
            let connection = ZMConnection.insertNewSentConnectionToUser(otherUser)
            connection.status = .Accepted
            
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.conversationType = .Group
            conversation.mutableOtherActiveParticipants.addObject(otherUser)
            
            selfClient.trustClient(otherClient1)
            
            conversation.securityLevel = ZMConversationSecurityLevel.NotSecure
            XCTAssertEqual(conversation.messages.count, 1)

            let otherClient2 = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
            otherClient2.remoteIdentifier = NSUUID.createUUID().transportString()
            otherClient2.user = otherUser
            
            selfClient.ignoreClient(otherClient2)

            // when
            otherClient2.deleteClientAndEndSession()
            
            // then
            XCTAssertTrue(otherClient2.isZombieObject)
            XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevel.Secure)
            XCTAssertEqual(conversation.messages.count, 2)
            if let message = conversation.messages.lastObject as? ZMSystemMessage {
                XCTAssertEqual(message.systemMessageType, ZMSystemMessageType.ConversationIsSecure)
                XCTAssertEqual(message.users, Set(arrayLiteral: otherUser))
            } else {
                XCTFail("Did not insert systemMessage")
            }
        }
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
    
    func testThatItRefetchesMissingFingerprintForUserWithSession() {
        // given
        let otherClientId = NSUUID.createUUID().transportString()
        
        self.syncMOC.performGroupedBlockAndWait {
            let selfClient = self.createSelfClient()
            
            let preKeys = try! selfClient.keysStore.box.generatePreKeys(NSMakeRange(0, 2)).map { $0.data!.base64String }
            
            let otherClient = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
            otherClient.remoteIdentifier = otherClientId
            
            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return }
            
            try! selfClient.keysStore.box.sessionWithId(otherClient.remoteIdentifier, fromStringPreKey: preKey)
            
            XCTAssertNil(otherClient.fingerprint)
            otherClient.managedObjectContext?.saveOrRollback()
        }
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            let fetchRequest = NSFetchRequest(entityName: UserClient.entityName())
            fetchRequest.predicate = NSPredicate(format: "%K == %@", "remoteIdentifier", otherClientId)
            fetchRequest.fetchLimit = 1
            // when
            let fetchedClient = self.syncMOC.executeFetchRequestOrAssert(fetchRequest).first as? UserClient
            
            // then
            XCTAssertNotNil(fetchedClient)
            XCTAssertNotNil(fetchedClient!.fingerprint)
        }
    }
    
    func testThatItSendsMessageWhenResettingSession() {
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let selfClient = self.createSelfClient()
            
            let otherClient = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
            otherClient.remoteIdentifier = NSUUID.createUUID().transportString()
            
            let otherUser = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
            otherClient.user = otherUser
            
            let connection = ZMConnection.insertNewSentConnectionToUser(otherUser)
            connection.status = .Accepted
            
            selfClient.trustClient(otherClient)
            
            // when
            otherClient.resetSession()
            
            // then
            XCTAssertEqual(connection.conversation.messages.count, 1)
            
            if let message = connection.conversation.messages.lastObject as? ZMClientMessage {
                XCTAssertTrue(message.genericMessage.hasClientAction())
                XCTAssertEqual(message.genericMessage.clientAction, ZMClientAction.RESETSESSION)
            } else {
                XCTFail("Did not insert session reset message")
            }
        }
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
}

extension UserClientTests {
    func testThatItStoresFailedToEstablishSessionInformation() {
        // given
        let client = UserClient.insertNewObjectInManagedObjectContext(syncMOC)
        
        // when & then
        XCTAssertFalse(client.failedToEstablishSession)
        
        // when
        client.failedToEstablishSession = true
        
        // then
        XCTAssertTrue(client.failedToEstablishSession)
        
        // when
        client.failedToEstablishSession = false
        
        // then
        XCTAssertFalse(client.failedToEstablishSession)
    }
}

extension UserClientTests {
    func testThatSelfClientIsTrusted() {
        // given & when
        let selfClient = self.createSelfClient()
    
        //then
        XCTAssertTrue(selfClient.verified)
    }
    
    func testThatSelfClientIsStillVerifiedAfterIgnoring() {
        // given
        let selfClient = self.createSelfClient()
        
        // when
        selfClient.ignoreClient(selfClient);
        
        //then
        XCTAssertTrue(selfClient.verified)
    }
    
    func testThatUnknownClientIsNotVerified() {
        // given & when
        self.createSelfClient()
        
        let otherClient = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC);
        otherClient.remoteIdentifier = NSString.createAlphanumericalString()
        
        // then
        XCTAssertFalse(otherClient.verified)
    }
    
    func testThatItIsVerifiedWhenTrusted() {
        // given
        let selfClient = self.createSelfClient()

        let otherClient = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC);
        otherClient.remoteIdentifier = NSString.createAlphanumericalString()
        
        // when
        selfClient.trustClient(otherClient)
        
        // then
        XCTAssertTrue(otherClient.verified)
    }
    
    func testThatItIsNotVerifiedWhenIgnored() {
        // given
        let selfClient = createSelfClient()
        
        let otherClient = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC);
        otherClient.remoteIdentifier = NSString.createAlphanumericalString()
        
        // when
        selfClient.ignoreClient(otherClient)
        
        // then
        XCTAssertFalse(otherClient.verified)
    }
    
    
}
