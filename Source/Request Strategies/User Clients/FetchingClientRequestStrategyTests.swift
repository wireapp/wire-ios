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
import WireTesting
import WireMessageStrategy
import WireDataModel
import WireCryptobox

class FetchClientRequestStrategyTests : MessagingTestBase {
    
    var sut: FetchingClientRequestStrategy!
    var mockApplicationStatus : MockApplicationStatus!
    
    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .eventProcessing
        sut = FetchingClientRequestStrategy(withManagedObjectContext: self.syncMOC, applicationStatus: mockApplicationStatus)
        NotificationCenter.default.addObserver(self, selector: #selector(FetchClientRequestStrategyTests.didReceiveAuthenticationNotification(_:)), name: NSNotification.Name(rawValue: "ZMUserSessionAuthenticationNotificationName"), object: nil)
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        mockApplicationStatus = nil
        sut = nil
        NotificationCenter.default.removeObserver(self)
        super.tearDown()
    }
    
    
    func didReceiveAuthenticationNotification(_ notification: NSNotification) {
        
    }
    
}

// MARK: Fetching Other Users Clients
extension FetchClientRequestStrategyTests {
    
    func payloadForOtherClients(_ identifiers: String...) -> ZMTransportData {
        return identifiers.reduce([]) { $0 + [["id": $1, "class" : "phone"]] } as ZMTransportData
    }
    
    func testThatItCreatesOtherUsersClientsCorrectly() {
        // GIVEN
        let (firstIdentifier, secondIdentifier) = (UUID.create().transportString(), UUID.create().transportString())
        let payload = [
            [
                "id" : firstIdentifier,
                "class" : "phone"
            ],
            [
                "id" : secondIdentifier,
                "class": "tablet"
            ]
        ]
        
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        
        let identifier = UUID.create()
        var user: ZMUser!
        self.syncMOC.performGroupedBlockAndWait {
            user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = identifier
            user.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            let expectedDeviceClasses = Set(arrayLiteral: "phone", "tablet")
            let actualDeviceClasses = Set(user.clients.flatMap { $0.deviceClass })
            let expectedIdentifiers = Set(arrayLiteral: firstIdentifier, secondIdentifier)
            let actualIdentifiers = Set(user.clients.map { $0.remoteIdentifier! })
            XCTAssertEqual(user.clients.count, 2)
            XCTAssertEqual(expectedDeviceClasses, actualDeviceClasses)
            XCTAssertEqual(expectedIdentifiers, actualIdentifiers)
        }
    }
    
    func testThatItAddsOtherUsersNewFetchedClientsToSelfUsersMissingClients() {
        // GIVEN
        var user: ZMUser!
        var payload: ZMTransportData!
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.selfClient.missingClients?.count, 0)
            let (firstIdentifier, secondIdentifier) = (UUID.create().transportString(), UUID.create().transportString())
            payload = self.payloadForOtherClients(firstIdentifier, secondIdentifier)
            let identifier = UUID.create()
            user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = identifier
            user.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let response = ZMTransportResponse(payload: payload, httpStatus: 200, transportSessionError: nil)

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(user.clients.count, 2)
            XCTAssertEqual(user.clients, self.selfClient.missingClients)
        }
    }
    
    func testThatItDeletesLocalClientsNotIncludedInResponseToFetchOtherUsersClients() {
        // GIVEN
        var payload: ZMTransportData!
        var firstIdentifier: String!
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.selfClient.missingClients?.count, 0)
            
            firstIdentifier = UUID.create().transportString()
            payload = self.payloadForOtherClients(firstIdentifier)
            self.otherUser.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.otherUser.clients.count, 1)
        }
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.otherUser.clients.count, 1)
            XCTAssertEqual(self.otherUser.clients.first?.remoteIdentifier, firstIdentifier)
        }
    }
    
    func testThatItCreateTheCorrectRequest() {
        
        // GIVEN
        var user: ZMUser!
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.selfClient.missingClients?.count, 0)
            user = self.selfClient.user!
            user.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        self.syncMOC.performGroupedBlockAndWait {
            // WHEN
            let request = self.sut.nextRequest()
            
            // THEN
            if let request = request {
                let path = "/users/\(user.remoteIdentifier!.transportString())/clients"
                XCTAssertEqual(request.path, path)
                XCTAssertEqual(request.method, .methodGET)
            } else {
                XCTFail()
            }
        }
    }
}

// MARK: fetching other user's clients / RemoteIdentifierObjectSync
extension FetchClientRequestStrategyTests {
    
    func testThatItDoesNotDeleteAnObjectWhenResponseContainsRemoteID() {
        
        // GIVEN
        var payload: ZMTransportData!
        self.syncMOC.performGroupedBlockAndWait {
            let user = self.otherClient.user
            user?.fetchUserClients()
            payload = [["id" : self.otherClient.remoteIdentifier!]] as NSArray
        }
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(self.otherClient.isDeleted)
        }
    }
    
    func testThatItAddsFetchedClientToIgnoredClientsWhenClientDoesNotExist() {
        
        // GIVEN
        var payload: ZMTransportData!
        let remoteIdentifier = "aabbccdd0011"
        self.syncMOC.performGroupedBlockAndWait {
            self.otherUser.fetchUserClients()
            payload = [["id" : remoteIdentifier]] as NSArray
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            request?.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.selfClient.trustedClients.first(where: { $0.remoteIdentifier == remoteIdentifier }))
            XCTAssertNotNil(self.selfClient.ignoredClients.first(where: { $0.remoteIdentifier == remoteIdentifier }))
        }
    }
    
    func testThatItAddsFetchedClientToIgnoredClientsWhenClientHasNoSession() {
        
        // GIVEN
        var payload: ZMTransportData!
        var client: UserClient!
        self.syncMOC.performGroupedBlockAndWait {
            client = self.createClient(user: self.otherUser)
            XCTAssertFalse(client.hasSessionWithSelfClient)
            self.otherUser.fetchUserClients()
            payload = [["id" : client.remoteIdentifier!]] as NSArray
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            request?.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(self.selfClient.trustedClients.contains(client))
            XCTAssertTrue(self.selfClient.ignoredClients.contains(client))
        }
    }
    
    func testThatItAddsFetchedClientToIgnoredClientsWhenSessionExistsButClientDoesNotExist() {
        
        // GIVEN
        var payload: ZMTransportData!
        let remoteIdentifier = "aabbccdd0011"
        let sessionIdentifier = EncryptionSessionIdentifier(rawValue: "\(self.otherUser.remoteIdentifier!)_\(remoteIdentifier)")
        self.syncMOC.performGroupedBlockAndWait {
            self.otherUser.fetchUserClients()
            payload = [["id" : remoteIdentifier]] as NSArray
            self.selfClient.keysStore.encryptionContext.perform {
                try! $0.createClientSession(sessionIdentifier, base64PreKeyString: self.selfClient.keysStore.lastPreKey()) // just a bogus key is OK
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            request?.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.selfClient.trustedClients.first(where: { $0.remoteIdentifier == remoteIdentifier }))
            XCTAssertNotNil(self.selfClient.ignoredClients.first(where: { $0.remoteIdentifier == remoteIdentifier }))
        }
    }
    
    func testThatItDeletesAnObjectWhenResponseDoesNotContainRemoteID() {
        
        // GIVEN
        let remoteID = "otherRemoteID"
        let payload: [[String:Any]] = [["id": remoteID]]
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNotEqual(self.otherClient.remoteIdentifier, remoteID)
            let user = self.otherClient.user
            user?.fetchUserClients()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(self.otherClient.isZombieObject)
        }
    }
}
