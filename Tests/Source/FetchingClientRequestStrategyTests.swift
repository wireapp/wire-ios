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
import ZMTesting

class FetchClientRequestStrategyTests : RequestStrategyTestBase {
    
    var sut: FetchingClientRequestStrategy!
    var clientRegistrationStatus: MockClientRegistrationStatus!
    
    override func setUp() {
        super.setUp()
        clientRegistrationStatus = MockClientRegistrationStatus()
        sut = FetchingClientRequestStrategy(clientRegistrationStatus: clientRegistrationStatus, context: self.syncMOC)
        NotificationCenter.default.addObserver(self, selector: #selector(FetchClientRequestStrategyTests.didReceiveAuthenticationNotification(_:)), name: NSNotification.Name(rawValue: "ZMUserSessionAuthenticationNotificationName"), object: nil)
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        clientRegistrationStatus = nil
        sut.tearDown()
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
        // given
        let _ = createClients()
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
        let user = ZMUser.insertNewObject(in: syncMOC)
        user.remoteIdentifier = identifier
        
        // when
        clientRegistrationStatus.mockClientIsReadyForRequests = true
        _ = sut.nextRequest()
        sut.didReceive(response, remoteIdentifierObjectSync: nil, forRemoteIdentifiers: Set(arrayLiteral: identifier))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // then
        let expectedDeviceClasses = Set(arrayLiteral: "phone", "tablet")
        let actualDeviceClasses = Set(user.clients.flatMap { $0.deviceClass })
        let expectedIdentifiers = Set(arrayLiteral: firstIdentifier, secondIdentifier)
        let actualIdentifiers = Set(user.clients.map { $0.remoteIdentifier! })
        XCTAssertEqual(user.clients.count, 2)
        XCTAssertEqual(expectedDeviceClasses, actualDeviceClasses)
        XCTAssertEqual(expectedIdentifiers, actualIdentifiers)
    }
    
    func testThatItAddsOtherUsersNewFetchedClientsToSelfUsersMissingClients() {
        // given
        let (selfClient, _) = createClients()
        XCTAssertEqual(selfClient.missingClients?.count, 0)
        let (firstIdentifier, secondIdentifier) = (UUID.create().transportString(), UUID.create().transportString())
        let payload = payloadForOtherClients(firstIdentifier, secondIdentifier)
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        let identifier = UUID.create()
        let user = ZMUser.insertNewObject(in: syncMOC)
        user.remoteIdentifier = identifier
        
        // when
        clientRegistrationStatus.mockClientIsReadyForRequests = true
        _ = sut.nextRequest()
        sut.didReceive(response, remoteIdentifierObjectSync: nil, forRemoteIdentifiers: Set(arrayLiteral: identifier))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // then
        XCTAssertEqual(user.clients.count, 2)
        XCTAssertEqual(user.clients, selfClient.missingClients)
    }
    
    func testThatItDeletesLocalClientsNotIncludedInResponseToFetchOtherUsersClients() {
        // given
        let (selfClient, localOnlyClient) = createClients()
        XCTAssertEqual(selfClient.missingClients?.count, 0)
        
        let firstIdentifier = UUID.create().transportString()
        let payload = payloadForOtherClients(firstIdentifier)
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        let identifier = UUID.create()
        let user = ZMUser.insertNewObject(in: syncMOC)
        user.mutableSetValue(forKey: "clients").add(localOnlyClient)
        user.remoteIdentifier = identifier
        XCTAssertEqual(user.clients.count, 1)
        
        // when
        clientRegistrationStatus.mockClientIsReadyForRequests = true
        _ = sut.nextRequest()
        sut.didReceive(response, remoteIdentifierObjectSync: nil, forRemoteIdentifiers: Set(arrayLiteral: identifier))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        
        // then
        XCTAssertEqual(user.clients.count, 1)
        XCTAssertEqual(user.clients.first?.remoteIdentifier, firstIdentifier)
    }
}

// MARK: fetching other user's clients / RemoteIdentifierObjectSync
extension FetchClientRequestStrategyTests {
    
    func testThatItDoesNotDeleteAnObjectWhenResponseContainsRemoteID() {
        let (_, otherClient) = self.createClients()
        let user = otherClient.user
        let payload =  [["id" : otherClient.remoteIdentifier!]]
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        
        //when
        self.sut.didReceive(response, remoteIdentifierObjectSync: nil, forRemoteIdentifiers:Set(arrayLiteral: user!.remoteIdentifier!))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        XCTAssertFalse(otherClient.isDeleted)
    }
    
    func testThatItAddsNewInsertedClientsToIgnoredClients() {
        let (selfClient, otherClient) = self.createClients()
        let user = otherClient.user
        let payload =  [["id" : otherClient.remoteIdentifier!]]
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        
        //when
        self.sut.didReceive(response, remoteIdentifierObjectSync: nil, forRemoteIdentifiers:Set(arrayLiteral: user!.remoteIdentifier!))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        XCTAssertFalse(selfClient.trustedClients.contains(otherClient))
        XCTAssertTrue(selfClient.ignoredClients.contains(otherClient))
    }
    
    func testThatItDeletesAnObjectWhenResponseDoesNotContainRemoteID() {
        let (_, otherClient) = self.createClients()
        let user = otherClient.user
        let remoteID = "otherRemoteID"
        let payload: [[String]] = [[remoteID]]
        XCTAssertNotEqual(otherClient.remoteIdentifier, remoteID)
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil)
        
        //when
        self.sut.didReceive(response, remoteIdentifierObjectSync: nil, forRemoteIdentifiers:Set(arrayLiteral: user!.remoteIdentifier!))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        XCTAssertTrue(otherClient.isDeleted)
    }
}
