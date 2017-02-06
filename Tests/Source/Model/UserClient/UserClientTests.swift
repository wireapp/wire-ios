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


import XCTest
import ZMUtilities
import Cryptobox
@testable import ZMCDataModel

class UserClientTests: ZMBaseManagedObjectTest {
        
    func clientWithTrustedClientCount(_ trustedCount: UInt, ignoredClientCount: UInt, missedClientCount: UInt) -> UserClient
    {
        let client = UserClient.insertNewObject(in: self.uiMOC)
        
        func userClientSetWithClientCount(_ count :UInt) -> Set<UserClient>?
        {
            guard count != 0 else { return nil }
            
            var clients = Set<UserClient>()
            for _ in 0..<count {
                clients.insert(UserClient.insertNewObject(in: uiMOC))
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
        let client = UserClient.insertNewObject(in: self.uiMOC)
        XCTAssertEqual(client.type, ZMUserClientTypePermanent, "Client type should be 'permanent'")
    }
    
    func testThatItReturnsTrackedKeys() {
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let trackedKeys = client.keysTrackedForLocalModifications()
        XCTAssertTrue(trackedKeys.contains(ZMUserClientMarkedToDeleteKey), "")
        XCTAssertTrue(trackedKeys.contains(ZMUserClientNumberOfKeysRemainingKey), "")
    }
    
    func testThatItSyncClientsWithNoRemoteIdentifier() {
        let unsyncedClient = UserClient.insertNewObject(in: self.uiMOC)
        let syncedClient = UserClient.insertNewObject(in: self.uiMOC)
        syncedClient.remoteIdentifier = "synced"
        
        XCTAssertTrue(UserClient.predicateForObjectsThatNeedToBeInsertedUpstream().evaluate(with: unsyncedClient))
        XCTAssertFalse(UserClient.predicateForObjectsThatNeedToBeInsertedUpstream().evaluate(with: syncedClient))
    }
    
    func testThatClientCanBeMarkedForDeletion() {
        let client = UserClient.insertNewObject(in: self.uiMOC)
        client.user = ZMUser.selfUser(in: self.uiMOC)
        
        XCTAssertFalse(client.markedToDelete)
        client.markForDeletion()
        
        XCTAssertTrue(client.markedToDelete)
        XCTAssertTrue(client.hasLocalModifications(forKey: ZMUserClientMarkedToDeleteKey))
    }
    
    func testThatItTracksCorrectKeys() {
        let expectedKeys = Set(arrayLiteral: ZMUserClientMarkedToDeleteKey, ZMUserClientNumberOfKeysRemainingKey, ZMUserClientMissingKey, ZMUserClientNeedsToUpdateSignalingKeysKey)
        let client = UserClient.insertNewObject(in: self.uiMOC)

        XCTAssertEqual(client.keysTrackedForLocalModifications() , expectedKeys)
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
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            
            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                preKeys = try! sessionsDirectory.generatePrekeys(CountableRange<UInt16>(0..<2))
            })
            
            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            otherClient.user = ZMUser.insertNewObject(in: self.syncMOC)
            otherClient.user?.remoteIdentifier = UUID.create()
            
            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return
            }
            
            XCTAssertTrue(selfClient.establishSessionWithClient(otherClient, usingPreKey:preKey.prekey))
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)
            
            // when
            UserClient.deleteSession(for:otherClient.sessionIdentifier!, managedObjectContext:self.syncMOC)
            
            // then
            XCTAssertFalse(otherClient.hasSessionWithSelfClient)
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    
    func testThatItDeletesASessionWhenDeletingAClient() {
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                preKeys = try! sessionsDirectory.generatePrekeys(CountableRange<UInt16>(0..<2))            })
            
            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser
            
            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return
            }
            
            XCTAssertTrue(selfClient.establishSessionWithClient(otherClient, usingPreKey:preKey.prekey))
            XCTAssertTrue(otherClient.hasSessionWithSelfClient)
            
            // when
            otherClient.deleteClientAndEndSession()
            
            // then
            XCTAssertFalse(otherClient.hasSessionWithSelfClient)
            XCTAssertTrue(otherClient.isZombieObject)
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testThatItUpdatesConversationSecurityLevelWhenDeletingClient() {
        
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            
            let otherClient1 = UserClient.insertNewObject(in: self.syncMOC)
            otherClient1.remoteIdentifier = UUID.create().transportString()
            
            let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient1.user = otherUser
            let connection = ZMConnection.insertNewSentConnection(to: otherUser)!
            connection.status = .accepted
            
            let conversation = ZMConversation.insertNewObject(in:self.syncMOC)
            conversation.conversationType = .group
            conversation.mutableOtherActiveParticipants.add(otherUser)
            
            selfClient.trustClient(otherClient1)
            
            conversation.securityLevel = ZMConversationSecurityLevel.notSecure
            XCTAssertEqual(conversation.messages.count, 1)

            let otherClient2 = UserClient.insertNewObject(in: self.syncMOC)
            otherClient2.remoteIdentifier = UUID.create().transportString()
            otherClient2.user = otherUser
            
            selfClient.ignoreClient(otherClient2)

            // when
            otherClient2.deleteClientAndEndSession()
            
            // then
            XCTAssertTrue(otherClient2.isZombieObject)
            XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevel.secure)
            XCTAssertEqual(conversation.messages.count, 2)
            if let message = conversation.messages.lastObject as? ZMSystemMessage {
                XCTAssertEqual(message.systemMessageType, ZMSystemMessageType.conversationIsSecure)
                XCTAssertEqual(message.users, Set(arrayLiteral: otherUser))
            } else {
                XCTFail("Did not insert systemMessage")
            }
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testThatItRefetchesMissingFingerprintForUserWithSession() {
        // given
        let otherClientId = UUID.create().transportString()
        
        self.syncMOC.performGroupedBlockAndWait {
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            
            var preKeys : [(id: UInt16, prekey: String)] = []
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                preKeys = try! sessionsDirectory.generatePrekeys(CountableRange<UInt16>(0..<2))
            })
            
            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = otherClientId
            let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser
            
            guard let preKey = preKeys.first
                else {
                    XCTFail("could not generate prekeys")
                    return }
            
            selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
                try! sessionsDirectory.createClientSession(otherClient.sessionIdentifier!, base64PreKeyString: preKey.prekey)
            })
            
            XCTAssertNil(otherClient.fingerprint)
            otherClient.managedObjectContext?.saveOrRollback()
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            let fetchRequest = NSFetchRequest<UserClient>(entityName: UserClient.entityName())
            fetchRequest.predicate = NSPredicate(format: "%K == %@", "remoteIdentifier", otherClientId)
            fetchRequest.fetchLimit = 1
            // when
            do {
                let fetchedClient = try self.syncMOC.fetch(fetchRequest).first
                XCTAssertNotNil(fetchedClient)
                XCTAssertNotNil(fetchedClient!.fingerprint)
            } catch let error{
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testThatItSendsMessageWhenResettingSession() {
        var connection: ZMConnection?

        self.syncMOC.performGroupedBlockAndWait {
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            
            let otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            
            let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser
            
            connection = ZMConnection.insertNewSentConnection(to: otherUser)!
            connection?.status = .accepted
            
            selfClient.trustClient(otherClient)
            
            // when
            otherClient.resetSession()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.syncMOC.performGroupedBlockAndWait {
            // then
            XCTAssertEqual(connection?.conversation.messages.count, 1)
            
            if let message = connection?.conversation.messages.lastObject as? ZMClientMessage {
                XCTAssertTrue(message.genericMessage!.hasClientAction())
                XCTAssertEqual(message.genericMessage!.clientAction, ZMClientAction.RESETSESSION)
            } else {
                XCTFail("Did not insert session reset message")
            }
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}

extension UserClientTests {
    func testThatItStoresFailedToEstablishSessionInformation() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let client = UserClient.insertNewObject(in: self.syncMOC)
            
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
        
        let otherClient = UserClient.insertNewObject(in: self.uiMOC);
        otherClient.remoteIdentifier = String.createAlphanumerical()
        
        // then
        XCTAssertFalse(otherClient.verified)
    }
    
    func testThatItIsVerifiedWhenTrusted() {
        // given
        let selfClient = self.createSelfClient()

        let otherClient = UserClient.insertNewObject(in: self.uiMOC);
        otherClient.remoteIdentifier = String.createAlphanumerical()
        
        // when
        selfClient.trustClient(otherClient)
        
        // then
        XCTAssertTrue(otherClient.verified)
    }
    
    func testThatItIsNotVerifiedWhenIgnored() {
        // given
        let selfClient = createSelfClient()
        
        let otherClient = UserClient.insertNewObject(in: self.uiMOC);
        otherClient.remoteIdentifier = String.createAlphanumerical()
        
        // when
        selfClient.ignoreClient(otherClient)
        
        // then
        XCTAssertFalse(otherClient.verified)
    }
}


// MARK : SignalingStore

extension UserClientTests {

    func testThatItDeletesExistingSignalingKeys() {
        
        // given
        let selfClient = createSelfClient()
        selfClient.apsVerificationKey =  Data()
        selfClient.apsDecryptionKey = Data()
        
        XCTAssertNotNil(selfClient.apsVerificationKey)
        XCTAssertNotNil(selfClient.apsDecryptionKey)
        
        // when
        UserClient.resetSignalingKeysInContext(self.uiMOC)
        
        // then
        XCTAssertNil(selfClient.apsVerificationKey)
        XCTAssertNil(selfClient.apsDecryptionKey)
    }
    
    func testThatItSetsKeysNeedingToBeSynced() {
        
        // given
        let selfClient = createSelfClient()
        
        // when
        UserClient.resetSignalingKeysInContext(self.uiMOC)
        
        // then
        XCTAssertTrue(selfClient.needsToUploadSignalingKeys)
        XCTAssertTrue(selfClient.keysThatHaveLocalModifications.contains(ZMUserClientNeedsToUpdateSignalingKeysKey))
    }
    
}

// MARK : fetchFingerprintOrPrekeys

extension UserClientTests {
    func testThatItDoNothingWhenHasAFingerprint() {
        // GIVEN
        let fingerprint = Data(base64Encoded: "cmVhZGluZyB0ZXN0cyBpcyBjb29s")
        
        let client = UserClient.insertNewObject(in: self.uiMOC)
        client.fingerprint = fingerprint
        
        self.uiMOC.saveOrRollback()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
        
        // WHEN
        client.fetchFingerprintOrPrekeys()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
        
        // THEN
        XCTAssertTrue(client.keysThatHaveLocalModifications.isEmpty)
        XCTAssertEqual(client.fingerprint, fingerprint)
    }
    
    func testThatItLoadsFingerprintForSelfClient() {
        // GIVEN
        let selfClient = createSelfClient(onMOC: self.syncMOC)
        selfClient.fingerprint = .none
        
        var newFingerprint : Data?
        syncMOC.zm_cryptKeyStore.encryptionContext.perform { (sessionsDirectory) in
            newFingerprint = sessionsDirectory.localFingerprint
        }
        
        self.syncMOC.saveOrRollback()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
        
        // WHEN
        selfClient.fetchFingerprintOrPrekeys()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
        
        // THEN
        XCTAssertTrue(selfClient.keysThatHaveLocalModifications.isEmpty)
        XCTAssertEqual(selfClient.fingerprint!, newFingerprint)
    }
    
    func testThatItLoadsFingerprintForExistingSession() {
        // GIVEN
        let selfClient = createSelfClient(onMOC: self.syncMOC)
        
        var preKeys : [(id: UInt16, prekey: String)] = []
        
        selfClient.keysStore.encryptionContext.perform({ (sessionsDirectory) in
            preKeys = try! sessionsDirectory.generatePrekeys(CountableRange<UInt16>(0..<2))
        })
    
        guard let preKey = preKeys.first
            else {
                XCTFail("could not generate prekeys")
                return }
        
        let client = UserClient.insertNewObject(in: self.syncMOC)
        let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
        otherUser.remoteIdentifier = UUID.create()
        client.user = otherUser
        client.remoteIdentifier = "badf00d"
        
        syncMOC.zm_cryptKeyStore.encryptionContext.perform { (sessionsDirectory) in
            try! sessionsDirectory.createClientSession(client.sessionIdentifier!, base64PreKeyString: preKey.prekey)
        }
        
        // WHEN
        client.fetchFingerprintOrPrekeys()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
        
        // THEN
        XCTAssertTrue(client.keysThatHaveLocalModifications.isEmpty)
        XCTAssertNotEqual(client.fingerprint!.count, 0)
    }
    
    func testThatItMarksMissingWhenNoSession() {
        // GIVEN
        let selfClient = createSelfClient(onMOC: self.syncMOC)
        let client = UserClient.insertNewObject(in: self.syncMOC)
        let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
        otherUser.remoteIdentifier = UUID.create()
        client.user = otherUser
        client.remoteIdentifier = "badf00d"

        self.syncMOC.saveOrRollback()
        
        // WHEN
        client.fetchFingerprintOrPrekeys()
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.05))
        
        // THEN
        XCTAssertTrue(selfClient.hasLocalModifications(forKey: ZMUserClientMissingKey))
        XCTAssertEqual(client.fingerprint, .none)
    }
    
}

