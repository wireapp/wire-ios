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
@testable import WireMessageStrategy
import WireUtilities
import WireTesting
import WireDataModel
import WireRequestStrategy

class MissingClientsRequestStrategyTests: MessagingTestBase {

    var sut: MissingClientsRequestStrategy!
    var mockApplicationStatus : MockApplicationStatus!
    
    var validPrekey: String {
        return try! self.selfClient.keysStore.lastPreKey()
    }
        
    override func setUp() {
        super.setUp()
        
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .eventProcessing
        sut = MissingClientsRequestStrategy(withManagedObjectContext: self.syncMOC, applicationStatus: mockApplicationStatus)
    }
    
    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        super.tearDown()
    }
    
    func testThatItCreatesMissingClientsRequest() {
        
        // GIVEN
        let missingUser = self.createUser()
        
        let firstMissingClient = self.createClient(user: missingUser)
        let secondMissingClient = self.createClient(user: missingUser)
        
        // WHEN
        self.selfClient.missesClient(firstMissingClient)
        self.selfClient.missesClient(secondMissingClient)
        
        guard let request = sut.requestsFactory.fetchMissingClientKeysRequest(self.selfClient.missingClients!) else {
            return XCTFail()
        }
        
        // THEN
        XCTAssertEqual(request.transportRequest.method, ZMTransportRequestMethod.methodPOST)
        XCTAssertEqual(request.transportRequest.path, "/users/prekeys")
        guard let recipientsPayload = request.transportRequest.payload as? [String: [String]] else {
            return XCTFail()
        }
        guard let userPayload = recipientsPayload[missingUser.remoteIdentifier!.transportString()] else {
            return XCTFail()
        }
        XCTAssertEqual(userPayload.sorted(), [firstMissingClient.remoteIdentifier!, secondMissingClient.remoteIdentifier!].sorted())
        
    }

    func testThatItCreatesARequestToFetchMissedKeysIfClientHasMissingClientsAndMissingKeyIsModified() {
        // GIVEN
        
        self.selfClient.missesClient(self.otherClient)
        sut.notifyChangeTrackers(self.selfClient)
        
        // WHEN
        guard let request = self.sut.nextRequest() else {
            return XCTFail()
        }
        
        // THEN
        checkRequestForClientsPrekeys(request, expectedClients: [self.otherClient])
    }

    func testThatItDoesNotCreateARequestToFetchMissedKeysIfClientHasMissingClientsAndMissingKeyIsNotModified() {
        // GIVEN
        self.selfClient.mutableSetValue(forKey: ZMUserClientMissingKey).add(self.otherClient)
        sut.notifyChangeTrackers(self.selfClient)
        
        // WHEN
        let request = self.sut.nextRequest()
        
        // THEN
        XCTAssertNil(request, "Should not fetch missing clients keys if missing key is not modified")
    }

    func testThatItDoesNotCreateARequestToFetchMissedKeysIfClientDoesNotHaveMissingClientsAndMissingKeyIsNotModified() {
        // GIVEN
        self.selfClient.missingClients = nil
        sut.notifyChangeTrackers(self.selfClient)
        
        // WHEN
        let request = self.sut.nextRequest()
        
        // THEN
        XCTAssertNil(request, "Should not fetch missing clients keys if missing key is not modified")
    }

    func testThatItDoesNotCreateARequestToFetchMissedKeysIfClientDoesNotHaveMissingClientsAndMissingKeyIsModified() {
        // GIVEN
        self.selfClient.missingClients = nil
        self.selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
        sut.notifyChangeTrackers(self.selfClient)
        
        // WHEN
        let request = self.sut.nextRequest()
        
        // THEN
        XCTAssertNil(request, "Should not fetch missing clients keys if missing key is not modified")
    }

    func testThatItPaginatesMissedClientsRequest() {
        
        self.sut.requestsFactory = MissingClientsRequestFactory(pageSize: 1)
        
        // GIVEN
        self.selfClient.missesClient(self.otherClient)
        let user = self.createUser(alsoCreateClient: true)
        let otherClient2 = user.clients.first!
        self.selfClient.missesClient(otherClient2)
        
        sut.notifyChangeTrackers(selfClient)
        
        // WHEN
        guard let firstRequest = self.sut.nextRequest(),
            let firstPayload = firstRequest.payload as? [String: [String]] else {
            return XCTFail()
        }
        
        // THEN
        XCTAssertEqual(firstRequest.method, .methodPOST)
        XCTAssertEqual(firstRequest.path, "/users/prekeys")
        XCTAssertEqual(firstPayload.count, 1)
        guard let firstEntry = firstPayload.first else {
            return XCTFail()
        }
        
        firstRequest.complete(with: ZMTransportResponse(payload: NSDictionary(), httpStatus: 200, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // and when
        guard let secondRequest = self.sut.nextRequest(),
            let secondPayload = secondRequest.payload as? [String: [String]] else {
            return XCTFail()
        }
        
        // THEN
        XCTAssertEqual(secondRequest.method, .methodPOST)
        XCTAssertEqual(secondRequest.path, "/users/prekeys")
        XCTAssertEqual(secondPayload.count, 1)
        guard let secondEntry = secondPayload.first else {
            return XCTFail()
        }
        secondRequest.complete(with: ZMTransportResponse(payload: NSDictionary(), httpStatus: 200, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // and when
        let thirdRequest = self.sut.nextRequest()
        
        // THEN
        XCTAssertNil(thirdRequest, "Should not request clients keys any more")
        XCTAssertTrue([user.remoteIdentifier!.transportString(),
                       self.otherUser.remoteIdentifier!.transportString()].contains(firstEntry.key),
                      "Unrecognized user")
        XCTAssertTrue([user.remoteIdentifier!.transportString(),
                       self.otherUser.remoteIdentifier!.transportString()].contains(secondEntry.key),
                      "Unrecognized user")
        XCTAssertNotEqual(firstEntry.key, secondEntry.key)
        let expectedClients1 = [self.otherClient.remoteIdentifier!]
        let expectedClients2 = [otherClient2.remoteIdentifier!]
        XCTAssertTrue(firstEntry.value == expectedClients1 || firstEntry.value == expectedClients2, "Not matching clients")
        XCTAssertTrue(secondEntry.value == expectedClients1 || secondEntry.value == expectedClients2, "Not matching clients")
        XCTAssertNotEqual(firstEntry.value, secondEntry.value)
    }

    func testThatItRemovesMissingClientWhenResponseContainsItsKey() {
        // GIVEN
        let request = missingClientsRequest(missingClients: [self.otherClient])
        
        // WHEN
        let _ = self.sut.updateUpdatedObject(selfClient,
                                             requestUserInfo: request.userInfo,
                                             response: self.response(forMissing: [self.otherClient]),
                                             keysToParse: request.keys)
        
        // THEN
        XCTAssertEqual(selfClient.missingClients!.count, 0)
    }

    func testThatItRemovesMissingClientWhenResponseDoesNotContainItsKey() {
        // GIVEN
        let request = self.missingClientsRequest(missingClients: [otherClient])
        
        // WHEN
        let _ = self.sut.updateUpdatedObject(self.selfClient,
                                             requestUserInfo: request.userInfo,
                                             response: ZMTransportResponse(payload: [String: [String: AnyObject]]() as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                             keysToParse: request.keys)
        
        // THEN
        XCTAssertEqual(selfClient.missingClients!.count, 0)
    }

    func testThatItRemovesOtherMissingClientsEvenIfOneOfThemHasANilValue() {
        // GIVEN
        let payload : [ String : [String : Any]] = [
            otherClient.user!.remoteIdentifier!.transportString() :
                [
                    otherClient.remoteIdentifier!: [
                        "id": 3, "key": self.validPrekey
                    ],
                    "2360fe0d2adc69e8" : NSNull()
            ]
        ]
        let request = missingClientsRequest(missingClients: [otherClient])
        
        // WHEN
        let _ = self.sut.updateUpdatedObject(selfClient,
                                             requestUserInfo: request.userInfo,
                                             response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                             keysToParse: request.keys)
        
        // THEN
        XCTAssertEqual(selfClient.missingClients!.count, 0)
    }
    
    func testThatItRemovesMissingClientsIfTheRequestForThoseClientsDidNotGiveUsAnyPrekey() {
        
        // GIVEN
        let payload : [ String : [String : AnyObject]] = [
            self.otherUser.remoteIdentifier!.transportString() : [:]
        ]
        let otherClient2 = self.createClient(user: self.otherUser)
        let request = missingClientsRequest(missingClients: [self.otherClient, otherClient2])
        
        // WHEN
        let _ = self.sut.updateUpdatedObject(selfClient,
                                             requestUserInfo: request.userInfo,
                                             response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                             keysToParse: request.keys)
        
        // THEN
        XCTAssertEqual(selfClient.missingClients!.count, 0)
    }

    func testThatItAddsMissingClientToCorruptedClientsStoreIfTheRequestForTheClientDidNotGiveUsAnyPrekey() {
        
        // GIVEN
        let payload = [self.otherUser.remoteIdentifier!.transportString() : [self.otherClient.remoteIdentifier!: ""]] as [String: [String : Any]]
        let request = missingClientsRequest(missingClients: [self.otherClient])
        
        // WHEN
        performIgnoringZMLogError {
            _ = self.sut.updateUpdatedObject(self.selfClient,
                                             requestUserInfo: request.userInfo,
                                             response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                             keysToParse: request.keys)
        }
        
        // THEN
        XCTAssertEqual(selfClient.missingClients!.count, 0)
        XCTAssertTrue(self.otherClient.failedToEstablishSession)
    }
    

    func testThatItDoesNotRemovesMissingClientsIfTheRequestForThoseClientsGivesUsAtLeastOneNewPrekey() {
        
        // GIVEN
        let response = self.response(forMissing: [self.otherClient])
        let otherClient2 = self.createClient(user: self.otherUser)
        let request = missingClientsRequest(missingClients: [self.otherClient, otherClient2])
        
        // WHEN
        
        let _ = self.sut.updateUpdatedObject(selfClient,
                                             requestUserInfo: request.userInfo,
                                             response: response,
                                             keysToParse: request.keys)
        
        // THEN
        XCTAssertEqual(selfClient.missingClients, Set([otherClient2]))
        
    }

    func testThatItDoesNotRemovesMissingClientsThatWereNotInTheOriginalRequestWhenThePayloadDoesNotContainAnyPrekey() {
        
        // GIVEN
        let payload : [ String : [String : AnyObject]] = [
            self.otherUser.remoteIdentifier!.transportString() : [:]
        ]
        let otherClient2 = self.createClient(user: self.otherUser)
        let request = missingClientsRequest(missingClients: [self.otherClient])
        
        // WHEN
        selfClient.missesClient(otherClient2)
        let _ = self.sut.updateUpdatedObject(selfClient,
                                             requestUserInfo: request.userInfo,
                                             response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                             keysToParse: request.keys)
        
        // THEN
        XCTAssertEqual(selfClient.missingClients, Set(arrayLiteral: otherClient2))
    }
    

    func testThatItRemovesMessagesMissingClientWhenEstablishedSessionWithClient() {
        // GIVEN
        let message = self.message(missingRecipient: self.otherClient)
        let request = missingClientsRequest(missingClients: [self.otherClient])
        
        // WHEN
        let _ = self.sut.updateUpdatedObject(selfClient,
                                             requestUserInfo: request.userInfo,
                                             response: self.response(forMissing: [self.otherClient]),
                                             keysToParse: request.keys)
        
        // THEN
        XCTAssertEqual(message.missingRecipients.count, 0)
        XCTAssertFalse(message.isExpired)
    }

    func testThatItDoesNotExpireMessageWhenEstablishedSessionWithClient() {
        // GIVEN
        let message = self.message(missingRecipient: self.otherClient)
        let request = missingClientsRequest(missingClients: [self.otherClient])
        
        // WHEN
        let _ = self.sut.updateUpdatedObject(selfClient,
                                             requestUserInfo: request.userInfo,
                                             response:  self.response(forMissing: [self.otherClient]),
                                             keysToParse: request.keys)
        
        // THEN
        XCTAssertFalse(message.isExpired)
    }

    func testThatItSetsFailedToEstablishSessionOnAMessagesWhenFailedtoEstablishSessionWithClient() {
        // GIVEN
        let message = self.message(missingRecipient: otherClient)
        
        let payload: [String: [String: Any]] = [self.otherUser.remoteIdentifier!.transportString(): [self.otherClient.remoteIdentifier!: ["key": "a2V5"]]]
        let request = missingClientsRequest(missingClients: [otherClient])
        
        // WHEN
        self.performIgnoringZMLogError {
            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                                 keysToParse: request.keys)
        }
        // THEN
        XCTAssertFalse(message.isExpired)
        XCTAssertTrue(otherClient.failedToEstablishSession)
    }
    
    func testThatItRemovesMessagesMissingClientWhenFailedToEstablishSessionWithClient() {
        // GIVEN
        let message = self.message(missingRecipient: otherClient)
        
        let payload: [String: [String: Any]] = [otherClient.user!.remoteIdentifier!.transportString(): [otherClient.remoteIdentifier!: ["key": "a2V5"]]]
        let request = missingClientsRequest(missingClients: [self.otherClient])
        
        // WHEN
        self.performIgnoringZMLogError {
            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                                 keysToParse: request.keys)
        }
        
        // THEN
        XCTAssertEqual(message.missingRecipients.count, 0)
    }

    func testThatItRemovesMessagesMissingClientWhenClientHasNoKey() {
        // GIVEN
        let payload = [String: [String: AnyObject]]()
        let message = self.message(missingRecipient: otherClient)
        let request = missingClientsRequest(missingClients: [otherClient])
        
        // WHEN
        let _ = self.sut.updateUpdatedObject(selfClient,
                                             requestUserInfo: request.userInfo,
                                             response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                             keysToParse: request.keys)
        
        // THEN
        XCTAssertEqual(message.missingRecipients.count, 0)
    }
    
    func testThatItDoesSetFailedToEstablishSessionOnAMessageWhenClientHasNoKey() {
        // GIVEN
        let message = self.message(missingRecipient: otherClient)
        let payload = [String: [String: AnyObject]]()
        let request = missingClientsRequest(missingClients: [otherClient])
        
        // WHEN
        let _ = self.sut.updateUpdatedObject(selfClient,
                                             requestUserInfo: request.userInfo,
                                             response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                             keysToParse: request.keys)
        
        // THEN
        XCTAssertFalse(message.isExpired)
        XCTAssertTrue(otherClient.failedToEstablishSession)
    }
    

    
    func testThatItCreatesMissingClientsRequestAfterRemoteSelfClientIsFetched() {
        
        // GIVEN
        let identifier = UUID.create().transportString()
        let payload = [
            "id": identifier as NSString,
            "type": "permanent" as NSString,
            "time": Date().transportString() as NSString
        ] as [String: AnyObject]
        _ = UserClient.createOrUpdateSelfUserClient(payload, context: self.syncMOC)!
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        syncMOC.saveOrRollback()
        sut.notifyChangeTrackers(selfClient)
        
        // WHEN
        guard let request = self.sut.nextRequest() else {
            return XCTFail()
        }
        
        // THEN
        XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
        XCTAssertEqual(request.path, "/users/prekeys")
        let payloadDictionary = request.payload!.asDictionary()!
        guard let userPayload = payloadDictionary[payloadDictionary.keys.first!] as? NSArray else {
            return XCTFail()
        }
        XCTAssertTrue(userPayload.contains(identifier))
    }
    
    func testThatItResetsKeyForMissingClientIfThereIsNoMissingClient(){
        // GIVEN
        self.selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
        XCTAssertTrue(self.selfClient.keysThatHaveLocalModifications.contains(ZMUserClientMissingKey))
        
        // WHEN
        let shouldCreateRequest = sut.shouldCreateRequest(toSyncObject: selfClient,
                                                          forKeys: Set(arrayLiteral: ZMUserClientMissingKey),
                                                          withSync: sut.modifiedSync)
        
        // THEN
        XCTAssertFalse(shouldCreateRequest)
        XCTAssertFalse(self.selfClient.keysThatHaveLocalModifications.contains(ZMUserClientMissingKey))
        
    }

    func testThatItDoesNotResetKeyForMissingClientIfThereIsAMissingClient(){
        // GIVEN
        self.selfClient.missesClient(self.otherClient)
        self.selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
        XCTAssertTrue(self.selfClient.keysThatHaveLocalModifications.contains(ZMUserClientMissingKey))
        
        // WHEN
        let shouldCreateRequest = sut.shouldCreateRequest(toSyncObject: self.selfClient,
                                                          forKeys: Set(arrayLiteral: ZMUserClientMissingKey),
                                                          withSync: sut.modifiedSync)
        
        // THEN
        XCTAssertTrue(shouldCreateRequest)
        XCTAssertTrue(self.selfClient.keysThatHaveLocalModifications.contains(ZMUserClientMissingKey))
    }
}

extension MissingClientsRequestStrategyTests {
    
    func checkRequestForClientsPrekeys(_ request: ZMTransportRequest,
                                       expectedClients: [UserClient],
                                       file: StaticString = #file,
                                       line: UInt = #line) {
        guard let payload = request.payload as? [String: [String]] else {
            return XCTFail("Request should contain payload", file: file, line: line)
        }
        XCTAssertEqual(request.method, .methodPOST, file: file, line: line)
        XCTAssertEqual(request.path, "/users/prekeys", file: file, line: line)
        expectedClients.forEach {
            guard let userKey = $0.user?.remoteIdentifier?.transportString() else {
                return XCTFail("Invalid user ID", file: file, line: line)
            }
            guard let userPayload = payload[userKey] else {
                return XCTFail("No such user in payload \(userKey)", file: file, line: line)
            }
            XCTAssertTrue(userPayload.contains($0.remoteIdentifier!), file: file, line: line)
        }
    }
    
    /// Returns response for missing clients
    func response(forMissing clients: [UserClient]) -> ZMTransportResponse {
        var payload : [String: [String: Any]] = [:]
        for missingClient in clients {
            let key = missingClient.user!.remoteIdentifier!.transportString()
            var prevValue = payload[key] ?? [:]
            prevValue[missingClient.remoteIdentifier!] = [
                "id" : 12,
                "key" : self.validPrekey
            ]
            payload[key] = prevValue
        }
        return ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil)
    }
    
    /// Returns missing client request
    func missingClientsRequest(missingClients: [UserClient]) -> ZMUpstreamRequest
    {
        // make sure that we are missing those clients
        for missingClient in missingClients {
            self.selfClient.missesClient(missingClient)
        }
        return sut.requestsFactory.fetchMissingClientKeysRequest(selfClient.missingClients!)
    }
    
    /// Creates a message missing a client
    func message(missingRecipient: UserClient) -> ZMClientMessage {
        let message = self.groupConversation.appendMessage(withText: "Test message with missing") as! ZMClientMessage
        message.missesRecipient(missingRecipient)
        return message
    }
}
