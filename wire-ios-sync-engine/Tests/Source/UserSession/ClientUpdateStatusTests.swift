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
import WireDataModel
import WireTesting

@testable import WireSyncEngine

struct ClientUpdateStatusChange {
    let type: ZMClientUpdateNotificationType
    var clientObjectIDs: [NSManagedObjectID]
    var error: NSError?
}

class ClientUpdateStatusTests: MessagingTest {
    var sut: ClientUpdateStatus!
    var clientObserverToken: Any?
    var receivedNotifications: [ClientUpdateStatusChange] = []

    override func setUp() {
        super.setUp()

        syncMOC.performAndWait { [self] in
            self.sut = ClientUpdateStatus(syncManagedObjectContext: syncMOC)
            self.sut.determineInitialClientStatus()
        }

        clientObserverToken = ZMClientUpdateNotification.addObserver(context: uiMOC) { [weak self] type, clientObjectIDs, error in
            let change = ClientUpdateStatusChange(type: type, clientObjectIDs: clientObjectIDs, error: error)
            self?.receivedNotifications.append(change)
        }
    }

    override func tearDown() {
        sut = nil
        clientObserverToken = nil
        receivedNotifications = []
        super.tearDown()
    }

    func testThatItReturnsfetchingClientsByDefault() {
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.fetchingClients)
    }

    func testThatItReturnsFetchingClientsWhenFetchStarted() {
        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.fetchingClients)
    }

    func insertNewClient(_ isSelfClient: Bool) -> UserClient! {
        var client: UserClient!
        syncMOC.performGroupedAndWait {
            client = UserClient.insertNewObject(in: syncMOC)
            client.remoteIdentifier = isSelfClient ? "selfIdentifier" : "identifier"
            client.user = ZMUser.selfUser(in: syncMOC)
            syncMOC.saveOrRollback()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        if isSelfClient {
            syncMOC.performAndWait {
                syncMOC.setPersistentStoreMetadata(client.remoteIdentifier, key: ZMPersistedClientIdKey)
            }
        }
        return client
    }

    func insertSelfClient() -> UserClient {
        return insertNewClient(true)!
    }

    func insertNewClient() -> UserClient {
        return insertNewClient(false)!
    }

    func testThatFetchedClientsDoNotContainSelfClient() {
        // given
        let selfClient = insertSelfClient()
        let otherClient = insertNewClient()

        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        syncMOC.performGroupedAndWait {
            self.sut.didFetchClients([selfClient, otherClient])
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, .waitingForPrekeys)

        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note {
            let clientIDs = note.clientObjectIDs
            XCTAssertEqual(clientIDs.count, 1)
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.fetchCompleted)
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
        syncMOC.performGroupedAndWait {
            self.sut.didFetchClients([client, selfClient])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, .waitingForPrekeys)

        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note {
            let clientIDs = note.clientObjectIDs
            XCTAssertEqual(clientIDs.count, 1)
            XCTAssertEqual(clientIDs.first, client.objectID)
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.fetchCompleted)
            XCTAssertNil(note.error)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItCallsTheCompletionHandlerWithErrorWhenFetchFails() {
        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        self.sut.failedToFetchClients()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.fetchingClients) // if we go back online we want to try to verify the client
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note {
            let clients = note.clientObjectIDs
            XCTAssertEqual(clients, [])
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.fetchFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.deviceIsOffline.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItCallsCompletionHandlerAfterDeletingClient_AllClientsDeleted() {
        // given
        let selfClient = insertSelfClient()
        let client = insertNewClient()

        self.sut.needsToFetchClients(andVerifySelfClient: true)
        syncMOC.performAndWait { self.sut.didFetchClients([client, selfClient]) }
        XCTAssertEqual(self.sut.currentPhase, .waitingForPrekeys)
        self.receivedNotifications.removeAll()

        // when
        let credentials = UserEmailCredentials(email: "hallo@example.com", password: "secret123456")
        self.sut.deleteClients(withCredentials: credentials)
        XCTAssertEqual(self.sut.currentPhase, ClientUpdatePhase.deletingClients)

        syncMOC.performGroupedAndWait {
            self.sut.didDeleteClient()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, .waitingForPrekeys)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note {
            XCTAssertNotNil(note.clientObjectIDs)
            XCTAssertEqual(note.clientObjectIDs.first, client.objectID)
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.deletionCompleted)
            XCTAssertNil(note.error)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItReturnsAnErrorIfSelfClientWasRemovedRemotely() {
        // given
        _ = insertSelfClient()
        let otherClient = insertNewClient()

        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        syncMOC.performGroupedAndWait {
            self.sut.didFetchClients([otherClient])
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, .waitingForPrekeys)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note {
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.fetchFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.selfClientIsInvalid.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItReturnsAnErrorIfSelfClientIsNotRegistered() {
        // given
        let otherClient = insertNewClient()

        // when
        self.sut.needsToFetchClients(andVerifySelfClient: true)
        syncMOC.performGroupedAndWait {
            self.sut.didFetchClients([otherClient])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, .waitingForPrekeys)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note {
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.fetchFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.selfClientIsInvalid.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItReturnsAnErrorIfCredentialsAreInvalid() {
        // given
        let selfClient = insertSelfClient()
        let client = insertNewClient()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.sut.needsToFetchClients(andVerifySelfClient: true)
        syncMOC.performGroupedAndWait {
            self.sut.didFetchClients([client, selfClient])
        }

        let error = NSError(domain: "ClientManagement", code: ClientUpdateError.invalidCredentials.rawValue, userInfo: nil)
        self.receivedNotifications.removeAll()

        // when
        let credentials = UserEmailCredentials(email: "hallo@example.com", password: "secret123456")
        self.sut.deleteClients(withCredentials: credentials)
        self.sut.failedToDeleteClient(client, error: error)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(self.sut.currentPhase, .waitingForPrekeys)
        XCTAssertEqual(self.receivedNotifications.count, 1)
        let note = self.receivedNotifications.first
        if let note {
            XCTAssertEqual(note.type, ZMClientUpdateNotificationType.deletionFailed)
            XCTAssertNotNil(note.error)
            XCTAssertEqual(note.error?.code, ClientUpdateError.invalidCredentials.rawValue)
        } else {
            XCTFail("no notification received")
        }
    }

    func testThatItResetsTheDeletionOfTheSelfClientAtInit() {

        // GIVEN
        // remove previous
        clientObserverToken = nil

        // delete self client
        let selfClient = insertSelfClient()
        self.syncMOC.performAndWait {
            selfClient.markedToDelete = true
            selfClient.setLocallyModifiedKeys(Set([ZMUserClientMarkedToDeleteKey]))
            selfClient.managedObjectContext?.saveOrRollback()
        }

        // WHEN
        // re-create
        self.syncMOC.performAndWait {
            self.sut = ClientUpdateStatus(syncManagedObjectContext: self.syncMOC)
            self.sut.determineInitialClientStatus()
        }
        clientObserverToken = ZMClientUpdateNotification.addObserver(context: uiMOC) { [weak self] type, clientObjectIDs, error in
            self?.receivedNotifications.append(ClientUpdateStatusChange(type: type, clientObjectIDs: clientObjectIDs, error: error))
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performAndWait {
            XCTAssertFalse(selfClient.markedToDelete)
            XCTAssertFalse(selfClient.hasLocalModifications(forKey: ZMUserClientMarkedToDeleteKey))
        }

    }

    func testThatItReturnsWaitsForPrekeys_WhenThereAreNoPrekeysAvailable() {
        // given
        let selfClient = insertSelfClient()
        self.sut.didFetchClients([selfClient])

        // then
        XCTAssertEqual(self.sut.currentPhase, .waitingForPrekeys)
    }

    func testThatItReturnsGeneratesPrekeys_AfterPrekeyGenerationAsBegun() {
        // given
        let selfClient = insertSelfClient()
        self.sut.didFetchClients([selfClient])

        // when
        sut.willGeneratePrekeys()

        // then
        XCTAssertEqual(self.sut.currentPhase, .generatingPrekeys)
    }

    func testThatItReturnsDone_AfterPrekeyGenerationIsCompleted() {
        // given
        let prekey = IdPrekeyTuple(id: 1, prekey: "prekey1")
        let selfClient = insertSelfClient()
        self.sut.didFetchClients([selfClient])
        sut.willGeneratePrekeys()

        // when
        sut.didGeneratePrekeys([prekey])

        // then
        XCTAssertEqual(self.sut.currentPhase, .done)
    }

    func testThatItReturnsWaitingForPrekeys_AfterPrekeysHaveBeenUploaded() {
        // given
        let prekey = IdPrekeyTuple(id: 1, prekey: "prekey1")
        let selfClient = insertSelfClient()
        self.sut.didFetchClients([selfClient])
        sut.willGeneratePrekeys()
        sut.didGeneratePrekeys([prekey])

        // when
        sut.didUploadPrekeys()

        // then
        XCTAssertEqual(self.sut.currentPhase, .waitingForPrekeys)
    }
}
