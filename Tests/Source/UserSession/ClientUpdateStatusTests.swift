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


import Foundation
import ZMTesting

class ClientUpdateStatusTests: MessagingTest {
    var sut : ClientUpdateStatus!
    var clientObserverToken : ZMClientUpdateObserverToken!
    var receivedNotifications : [ZMClientUpdateNotification] = []
    
    override func setUp() {
        super.setUp()
        self.sut = ClientUpdateStatus(syncManagedObjectContext: self.syncMOC)
        
        clientObserverToken = ZMClientUpdateNotification.addObserverWithBlock{[weak self] in
            self?.receivedNotifications.append($0)
        }
    }
    
    override func tearDown() {
        ZMClientUpdateNotification.removeObserver(clientObserverToken)
        self.sut.tearDown()
        super.tearDown()
    }
    
    func testThatItReturnsDoneByDefault() {
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.Done)
    }
 
    func testThatItReturnsFetchingClientsWhenFetchStarted() {
        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        
        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.FetchingClients)
    }
    
    func insertNewClient(isSelfClient: Bool) -> UserClient! {
        var client : UserClient!
        self.syncMOC.performGroupedBlockAndWait { () -> Void in
            client = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
            client.remoteIdentifier = isSelfClient ? "selfIdentifier" : "identifier"
            client.user = ZMUser.selfUserInContext(self.syncMOC)
            self.syncMOC.saveOrRollback()
        }
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        if isSelfClient {
            self.syncMOC.setPersistentStoreMetadata(client.remoteIdentifier, forKey: "PersistedClientId")
        }
        return client
    }
    
    func insertSelfClient() -> UserClient! {
        return insertNewClient(true)
    }
    
    func insertNewClient() -> UserClient! {
        return insertNewClient(false)
    }
    
    func testThatFetchedClientsDoNotContainSelfClient() {
        // given
        let selfClient = insertSelfClient()
        let otherClient = insertNewClient()
        
        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([selfClient, otherClient])
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.Done)
        
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            let clientIDs = note.clientObjectIDs
            XCTAssertEqual(clientIDs?.count, 1)
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.FetchCompleted)
            XCTAssertNil(note.error)
        } else {
            XCTFail("no notification received")
        }

    }
    
    func testThatItCallsTheCompletionHandlerWhenFetchCompletes() {
        // given
        let selfClient = insertSelfClient()
        let client = insertNewClient()
        
        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([client, selfClient])
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.Done)
        
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            let clientIDs = note.clientObjectIDs
            XCTAssertEqual(clientIDs?.count, 1);
            XCTAssertEqual(clientIDs?.first, client.objectID)
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.FetchCompleted)
            XCTAssertNil(note.error)
        } else {
            XCTFail("no notification received")
        }
    }
    
    func testThatItCallsTheCompletionHandlerWithErrorWhenFetchFails() {
        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.failedToFetchClients()
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.FetchingClients) // if we go back online we want to try to verify the client
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            let clients = note.clientObjectIDs
            XCTAssertNil(clients);
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.FetchFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.DeviceIsOffline.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }
    
    func testThatItCallsCompletionHandlerAfterDeletingClient_AllClientsDeleted() {
        // given
        let selfClient = insertSelfClient()
        let client = insertNewClient()
        
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([client, selfClient])
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.Done)
        self.receivedNotifications.removeAll()

        // when
        let credentials = ZMEmailCredentials(email: "hallo@example.com", password: "secret123456")
        self.sut.deleteClients(withCredentials: credentials)
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.DeletingClients)

        self.sut.didDeleteClient()
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.Done)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            XCTAssertNotNil(note.clientObjectIDs)
            XCTAssertEqual(note.clientObjectIDs.first, client.objectID)
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.DeletionCompleted)
            XCTAssertNil(note.error)
        } else {
            XCTFail("no notification received")
        }
    }
    
    func testThatItDoesNotCallCompletionHandlerAfterDeletingClient_MoreClientsToDelete() {
        // given
        let selfClient = insertSelfClient()
        let client = insertNewClient()
        self.syncMOC.performGroupedBlockAndWait { () -> Void in
            client.markForDeletion()
        }
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([client, selfClient])
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.Done)
        self.receivedNotifications.removeAll()

        // when
        let credentials = ZMEmailCredentials(email: "hallo@example.com", password: "secret123456")
        self.sut.deleteClients(withCredentials: credentials)
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.DeletingClients)

        self.sut.didDeleteClient()
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.DeletingClients)
        XCTAssertEqual(self.receivedNotifications.count, 0)
        
        // when
        self.syncMOC.deleteObject(client)
        self.syncMOC.saveOrRollback()
        
        self.sut.didDeleteClient()
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.Done)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            XCTAssertNil(note.userInfo);
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.DeletionCompleted)
            XCTAssertNil(note.error)
        } else {
            XCTFail("no notification received")
        }
    }
    
    func testThatItReturnsAnErrorIfSelfClientWasRemovedRemotely() {
        // given
        insertSelfClient()
        let otherClient = insertNewClient()

        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([otherClient])
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.Done)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            XCTAssertNil(note.userInfo);
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.FetchFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.SelfClientIsInvalid.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }
    
    func testThatItReturnsAnErrorIfSelfClientIsNotRegistered() {
        // given
        let otherClient = insertNewClient()
        
        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([otherClient])
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.Done)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            XCTAssertNil(note.userInfo);
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.FetchFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.SelfClientIsInvalid.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }
    
    func testThatItReturnsAnErrorIfCredentialsAreInvalid() {
        // given
        let selfClient = insertSelfClient()
        let client = insertNewClient()
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.didFetchClients([client, selfClient])
        
        let error = NSError(domain: "ClientManagement", code: Int(ClientUpdateError.InvalidCredentials.rawValue), userInfo: nil)
        self.receivedNotifications.removeAll()

        // when
        let credentials = ZMEmailCredentials(email: "hallo@example.com", password: "secret123456")
        self.sut.deleteClients(withCredentials: credentials)
        self.sut.failedToDeleteClient(client, error:error)
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.Done)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note = note {
            XCTAssertNil(note.userInfo);
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.DeletionFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.InvalidCredentials.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }
}


