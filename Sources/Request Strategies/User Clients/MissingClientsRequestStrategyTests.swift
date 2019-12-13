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
@testable import WireRequestStrategy
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

        self.syncMOC.performGroupedAndWait { syncMOC in
            self.mockApplicationStatus = MockApplicationStatus()
            self.mockApplicationStatus.mockSynchronizationState = .eventProcessing
            self.sut = MissingClientsRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: self.mockApplicationStatus)
        }
    }
    
    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        super.tearDown()
    }
    
    func testThatItCreatesMissingClientsRequest() {
        self.syncMOC.performGroupedAndWait { syncMOC in

            // GIVEN
            let missingUser = self.createUser()

            let firstMissingClient = self.createClient(user: missingUser)
            let secondMissingClient = self.createClient(user: missingUser)

            // WHEN
            self.selfClient.missesClient(firstMissingClient)
            self.selfClient.missesClient(secondMissingClient)

            guard let request = self.sut.requestsFactory.fetchMissingClientKeysRequest(self.selfClient.missingClients!) else { XCTFail(); return }

            // THEN
            XCTAssertEqual(request.transportRequest.method, ZMTransportRequestMethod.methodPOST)
            XCTAssertEqual(request.transportRequest.path, "/users/prekeys")
                guard let recipientsPayload = request.transportRequest.payload as? [String: [String]] else { XCTFail(); return  }
                guard let userPayload = recipientsPayload[missingUser.remoteIdentifier!.transportString()] else { XCTFail(); return }
            XCTAssertEqual(userPayload.sorted(), [firstMissingClient.remoteIdentifier!, secondMissingClient.remoteIdentifier!].sorted())
        }
        
    }

    func testThatItCreatesARequestToFetchMissedKeysIfClientHasMissingClientsAndMissingKeyIsModified() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN

            self.selfClient.missesClient(self.otherClient)
            self.sut.notifyChangeTrackers(self.selfClient)

            // WHEN
            guard let request = self.sut.nextRequest() else {
                XCTFail(); return
            }

            // THEN
            self.checkRequestForClientsPrekeys(request, expectedClients: [self.otherClient])
        }
    }

    func testThatItDoesNotCreateARequestToFetchMissedKeysIfClientHasMissingClientsAndMissingKeyIsNotModified() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            self.selfClient.mutableSetValue(forKey: ZMUserClientMissingKey).add(self.otherClient!)
            self.sut.notifyChangeTrackers(self.selfClient)

            // WHEN
            let request = self.sut.nextRequest()

            // THEN
            XCTAssertNil(request, "Should not fetch missing clients keys if missing key is not modified")
        }
    }

    func testThatItDoesNotCreateARequestToFetchMissedKeysIfClientDoesNotHaveMissingClientsAndMissingKeyIsNotModified() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            self.selfClient.missingClients = nil
            self.sut.notifyChangeTrackers(self.selfClient)

            // WHEN
            let request = self.sut.nextRequest()

            // THEN
            XCTAssertNil(request, "Should not fetch missing clients keys if missing key is not modified")
        }
    }

    func testThatItDoesNotCreateARequestToFetchMissedKeysIfClientDoesNotHaveMissingClientsAndMissingKeyIsModified() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            self.selfClient.missingClients = nil
            self.selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
            self.sut.notifyChangeTrackers(self.selfClient)

            // WHEN
            let request = self.sut.nextRequest()

            // THEN
            XCTAssertNil(request, "Should not fetch missing clients keys if missing key is not modified")
        }
    }

    func testThatItPaginatesMissedClientsRequest() {
        var user: ZMUser!
        var firstEntry: (key: String, value: [String])!
        var otherClient2: UserClient!
        self.syncMOC.performGroupedAndWait { syncMOC in
            self.sut.requestsFactory = MissingClientsRequestFactory(pageSize: 1)

            // GIVEN
            self.selfClient.missesClient(self.otherClient)
            user = self.createUser(alsoCreateClient: true)
            otherClient2 = user.clients.first!
            self.selfClient.missesClient(otherClient2)

            self.sut.notifyChangeTrackers(self.selfClient)

            // WHEN
            guard let firstRequest = self.sut.nextRequest(),
                let firstPayload = firstRequest.payload as? [String: [String]] else {
                XCTFail(); return
            }

            // THEN
            XCTAssertEqual(firstRequest.method, .methodPOST)
            XCTAssertEqual(firstRequest.path, "/users/prekeys")
            XCTAssertEqual(firstPayload.count, 1)
            guard let first = firstPayload.first else {
                XCTFail(); return
            }
            firstEntry = first

            firstRequest.complete(with: ZMTransportResponse(payload: NSDictionary(), httpStatus: 200, transportSessionError: nil))
        }

        var secondEntry: (key: String, value: [String])!
        self.syncMOC.performGroupedAndWait { syncMOC in
            // and when
            guard let secondRequest = self.sut.nextRequest(),
                let secondPayload = secondRequest.payload as? [String: [String]] else {
                XCTFail(); return
            }

            // THEN
            XCTAssertEqual(secondRequest.method, .methodPOST)
            XCTAssertEqual(secondRequest.path, "/users/prekeys")
            XCTAssertEqual(secondPayload.count, 1)
            guard let second = secondPayload.first else {
                XCTFail(); return
            }
            secondEntry = second
            secondRequest.complete(with: ZMTransportResponse(payload: NSDictionary(), httpStatus: 200, transportSessionError: nil))
        }

        self.syncMOC.performGroupedAndWait { syncMOC in
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
    }

    func testThatItRemovesMissingClientWhenResponseContainsItsKey() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let request = self.missingClientsRequest(missingClients: [self.otherClient])

            // WHEN
            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: self.response(forMissing: [self.otherClient]),
                                                 keysToParse: request.keys)

            // THEN
            XCTAssertEqual(self.selfClient.missingClients!.count, 0)
        }
    }

    func testThatItRemovesMissingClientWhenResponseDoesNotContainItsKey() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let request = self.missingClientsRequest(missingClients: [self.otherClient])

            // WHEN
            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: ZMTransportResponse(payload: [String: [String: AnyObject]]() as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                                 keysToParse: request.keys)

            // THEN
            XCTAssertEqual(self.selfClient.missingClients!.count, 0)
        }
    }

    func testThatItRemovesOtherMissingClientsEvenIfOneOfThemHasANilValue() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let payload : [ String : [String : Any]] = [
                self.otherClient.user!.remoteIdentifier!.transportString() :
                    [
                        self.otherClient.remoteIdentifier!: [
                            "id": 3, "key": self.validPrekey
                        ],
                        "2360fe0d2adc69e8" : NSNull()
                ]
            ]
            let request = self.missingClientsRequest(missingClients: [self.otherClient])

            // WHEN
            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                                 keysToParse: request.keys)

            // THEN
            XCTAssertEqual(self.selfClient.missingClients!.count, 0)
        }
    }
    
    func testThatItRemovesMissingClientsIfTheRequestForThoseClientsDidNotGiveUsAnyPrekey() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let payload : [ String : [String : AnyObject]] = [
                self.otherUser.remoteIdentifier!.transportString() : [:]
            ]
            let otherClient2 = self.createClient(user: self.otherUser)
            let request = self.missingClientsRequest(missingClients: [self.otherClient, otherClient2])

            // WHEN
            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                                 keysToParse: request.keys)

            // THEN
            XCTAssertEqual(self.selfClient.missingClients!.count, 0)
        }
    }

    func testThatItAddsMissingClientToCorruptedClientsStoreIfTheRequestForTheClientDidNotGiveUsAnyPrekey() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let payload = [self.otherUser.remoteIdentifier!.transportString() : [self.otherClient.remoteIdentifier!: ""]] as [String: [String : Any]]
            let request = self.missingClientsRequest(missingClients: [self.otherClient])

            // WHEN
            self.performIgnoringZMLogError {
                _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                                 keysToParse: request.keys)
            }

            // THEN
            XCTAssertEqual(self.selfClient.missingClients!.count, 0)
            XCTAssertTrue(self.otherClient.failedToEstablishSession)
        }
    }
    

    func testThatItDoesNotRemovesMissingClientsIfTheRequestForThoseClientsGivesUsAtLeastOneNewPrekey() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let response = self.response(forMissing: [self.otherClient])
            let otherClient2 = self.createClient(user: self.otherUser)
            let request = self.missingClientsRequest(missingClients: [self.otherClient, otherClient2])

            // WHEN

            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: response,
                                                 keysToParse: request.keys)

            // THEN
            XCTAssertEqual(self.selfClient.missingClients, Set([otherClient2]))
        }
        
    }

    func testThatItDoesNotRemovesMissingClientsThatWereNotInTheOriginalRequestWhenThePayloadDoesNotContainAnyPrekey() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let payload : [ String : [String : AnyObject]] = [
                self.otherUser.remoteIdentifier!.transportString() : [:]
            ]
            let otherClient2 = self.createClient(user: self.otherUser)
            let request = self.missingClientsRequest(missingClients: [self.otherClient])

            // WHEN
            self.selfClient.missesClient(otherClient2)
            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                                 keysToParse: request.keys)

            // THEN
            XCTAssertEqual(self.selfClient.missingClients, Set(arrayLiteral: otherClient2))
        }
    }
    

    func testThatItRemovesMessagesMissingClientWhenEstablishedSessionWithClient() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let message = self.message(missingRecipient: self.otherClient)
            let request = self.missingClientsRequest(missingClients: [self.otherClient])

            // WHEN
            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: self.response(forMissing: [self.otherClient]),
                                                 keysToParse: request.keys)

            // THEN
            XCTAssertEqual(message.missingRecipients.count, 0)
            XCTAssertFalse(message.isExpired)
        }
    }

    func testThatItDoesNotExpireMessageWhenEstablishedSessionWithClient() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let message = self.message(missingRecipient: self.otherClient)
            let request = self.missingClientsRequest(missingClients: [self.otherClient])

            // WHEN
            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response:  self.response(forMissing: [self.otherClient]),
                                                 keysToParse: request.keys)

            // THEN
            XCTAssertFalse(message.isExpired)
        }
    }

    func testThatItSetsFailedToEstablishSessionOnAMessagesWhenFailedtoEstablishSessionWithClient() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let message = self.message(missingRecipient: self.otherClient)

            let payload: [String: [String: Any]] = [self.otherUser.remoteIdentifier!.transportString(): [self.otherClient.remoteIdentifier!: ["key": "a2V5"]]]
            let request = self.missingClientsRequest(missingClients: [self.otherClient])

            // WHEN
            self.performIgnoringZMLogError {
                let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                     requestUserInfo: request.userInfo,
                                                     response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                                     keysToParse: request.keys)
            }
            // THEN
            XCTAssertFalse(message.isExpired)
            XCTAssertTrue(self.otherClient.failedToEstablishSession)
        }
    }
    
    func testThatItRemovesMessagesMissingClientWhenFailedToEstablishSessionWithClient() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let message = self.message(missingRecipient: self.otherClient)

            let payload: [String: [String: Any]] = [self.otherClient.user!.remoteIdentifier!.transportString(): [self.otherClient.remoteIdentifier!: ["key": "a2V5"]]]
            let request = self.missingClientsRequest(missingClients: [self.otherClient])

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
    }

    func testThatItRemovesMessagesMissingClientWhenClientHasNoKey() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let payload = [String: [String: AnyObject]]()
            let message = self.message(missingRecipient: self.otherClient)
            let request = self.missingClientsRequest(missingClients: [self.otherClient])

            // WHEN
            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                                 keysToParse: request.keys)

            // THEN
            XCTAssertEqual(message.missingRecipients.count, 0)
        }
    }
    
    func testThatItDoesSetFailedToEstablishSessionOnAMessageWhenClientHasNoKey() {
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            let message = self.message(missingRecipient: self.otherClient)
            let payload = [String: [String: AnyObject]]()
            let request = self.missingClientsRequest(missingClients: [self.otherClient])

            // WHEN
            let _ = self.sut.updateUpdatedObject(self.selfClient,
                                                 requestUserInfo: request.userInfo,
                                                 response: ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil),
                                                 keysToParse: request.keys)

            // THEN
            XCTAssertFalse(message.isExpired)
            XCTAssertTrue(self.otherClient.failedToEstablishSession)
        }
    }

    func testThatItCreatesMissingClientsRequestAfterRemoteSelfClientIsFetched() {
        // GIVEN
        let identifier = UUID.create().transportString()

        self.syncMOC.performGroupedAndWait { syncMOC in
            let payload = [
                "id": identifier as NSString,
                "type": "permanent" as NSString,
                "time": Date().transportString() as NSString
                ] as [String: AnyObject]

            _ = UserClient.createOrUpdateSelfUserClient(payload, context: syncMOC)!
            syncMOC.saveOrRollback()
        }

        self.syncMOC.performGroupedAndWait { syncMOC in
            self.sut.notifyChangeTrackers(self.selfClient)

            // WHEN
            guard let request = self.sut.nextRequest() else {
                XCTFail(); return
            }

            // THEN
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
            XCTAssertEqual(request.path, "/users/prekeys")
            let payloadDictionary = request.payload!.asDictionary()!
            guard let userPayload = payloadDictionary[payloadDictionary.keys.first!] as? NSArray else {
                XCTFail(); return
            }
            XCTAssertTrue(userPayload.contains(identifier))
        }
    }

    func testThatItResetsKeyForMissingClientIfThereIsNoMissingClient(){
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            self.selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
            XCTAssertTrue(self.selfClient.keysThatHaveLocalModifications.contains(ZMUserClientMissingKey))

            // WHEN
            let shouldCreateRequest = self.sut.shouldCreateRequest(toSyncObject: self.selfClient,
                                                              forKeys: Set(arrayLiteral: ZMUserClientMissingKey),
                                                              withSync: self.sut.modifiedSync!)

            // THEN
            XCTAssertFalse(shouldCreateRequest)
            XCTAssertFalse(self.selfClient.keysThatHaveLocalModifications.contains(ZMUserClientMissingKey))
        }
    }

    func testThatItDoesNotResetKeyForMissingClientIfThereIsAMissingClient(){
        self.syncMOC.performGroupedAndWait { syncMOC in
            // GIVEN
            self.selfClient.missesClient(self.otherClient)
            self.selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
            XCTAssertTrue(self.selfClient.keysThatHaveLocalModifications.contains(ZMUserClientMissingKey))

            // WHEN
            let shouldCreateRequest = self.sut.shouldCreateRequest(toSyncObject: self.selfClient,
                                                              forKeys: Set(arrayLiteral: ZMUserClientMissingKey),
                                                              withSync: self.sut.modifiedSync!)

            // THEN
            XCTAssertTrue(shouldCreateRequest)
            XCTAssertTrue(self.selfClient.keysThatHaveLocalModifications.contains(ZMUserClientMissingKey))
        }
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
        let message = self.groupConversation.append(text: "Test message with missing") as! ZMClientMessage
        message.missesRecipient(missingRecipient)
        return message
    }
}
