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

import WireDataModel
import WireDataModelSupport
import WireMockTransport
import WireTesting
import WireTransportSupport
import WireUtilities
import XCTest
@testable import WireSyncEngine

@objcMembers
public final class MockClientRegistrationStatusDelegate: NSObject, ZMClientRegistrationStatusDelegate {
    public var didCallRegisterMLSClient = false
    public func didRegisterMLSClient(_: WireDataModel.UserClient) {
        didCallRegisterMLSClient = true
    }

    public var currentError: Error?

    public var didCallRegisterSelfUserClient = false
    public func didRegisterSelfUserClient(_: UserClient) {
        didCallRegisterSelfUserClient = true
    }

    public var didCallFailRegisterSelfUserClient = false
    public func didFailToRegisterSelfUserClient(error: Error) {
        currentError = error
        didCallFailRegisterSelfUserClient = true
    }

    public var didCallDeleteSelfUserClient = false
    public func didDeleteSelfUserClient(error: Error) {
        currentError = error
        didCallDeleteSelfUserClient = true
    }
}

final class UserClientRequestStrategyTests: RequestStrategyTestBase {
    var sut: UserClientRequestStrategy!
    var clientRegistrationStatus: ZMMockClientRegistrationStatus!
    var mockClientRegistrationStatusDelegate: MockClientRegistrationStatusDelegate!
    var authenticationStatus: MockAuthenticationStatus!
    var clientUpdateStatus: ZMMockClientUpdateStatus!
    let fakeCredentialsProvider = FakeCredentialProvider()

    var cookieStorage: ZMPersistentCookieStorage!

    var spyKeyStore: SpyUserClientKeyStore!
    var proteusService: MockProteusServiceInterface!
    var proteusProvider: MockProteusProvider!
    var coreCryptoProvider: MockCoreCryptoProviderProtocol!

    var postLoginAuthenticationObserverToken: Any?

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedAndWait {
            let spyKeyStore = SpyUserClientKeyStore(
                accountDirectory: self.accountDirectory,
                applicationContainer: self.sharedContainerURL
            )
            self.spyKeyStore = spyKeyStore
            self.proteusService = MockProteusServiceInterface()
            self.proteusProvider = MockProteusProvider(
                mockProteusService: self.proteusService,
                mockKeyStore: spyKeyStore
            )
            self.coreCryptoProvider = MockCoreCryptoProviderProtocol()
            self.cookieStorage = ZMPersistentCookieStorage(
                forServerName: "myServer",
                userIdentifier: self.userIdentifier,
                useCache: true
            )
            self.mockClientRegistrationStatusDelegate = MockClientRegistrationStatusDelegate()
            self.clientRegistrationStatus = ZMMockClientRegistrationStatus(
                context: self.syncMOC,
                cookieProvider: self.cookieStorage,
                coreCryptoProvider: self.coreCryptoProvider
            )
            self.clientRegistrationStatus.registrationStatusDelegate = self.mockClientRegistrationStatusDelegate
            self.clientUpdateStatus = ZMMockClientUpdateStatus(syncManagedObjectContext: self.syncMOC)
            self.sut = UserClientRequestStrategy(
                clientRegistrationStatus: self.clientRegistrationStatus,
                clientUpdateStatus: self.clientUpdateStatus,
                context: self.syncMOC,
                proteusProvider: self.proteusProvider
            )
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = self.userIdentifier
            selfUser.handle = "handle"
            self.syncMOC.saveOrRollback()
        }
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: spyKeyStore.cryptoboxDirectory)

        clientRegistrationStatus = nil
        mockClientRegistrationStatusDelegate = nil
        clientUpdateStatus = nil
        spyKeyStore = nil
        sut.tearDown()
        sut = nil
        postLoginAuthenticationObserverToken = nil
        super.tearDown()
    }
}

// MARK: Inserting

extension UserClientRequestStrategyTests {
    func createSelfClient(_ context: NSManagedObjectContext) -> UserClient {
        let selfClient = UserClient.insertNewObject(in: context)
        selfClient.remoteIdentifier = nil
        selfClient.user = ZMUser.selfUser(in: context)
        return selfClient
    }

    func testThatPrekeysAreGeneratedBeforeAttemptingToRegisterClient() {
        syncMOC.performGroupedAndWait {
            // given
            let client = self.createSelfClient(self.sut.managedObjectContext!)
            self.sut.notifyChangeTrackers(client)
            self.clientRegistrationStatus.prepareForClientRegistration()

            // when
            XCTAssertNil(self.sut.nextRequest(for: .v0))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertNotNil(self.clientRegistrationStatus.prekeys)
            XCTAssertNotNil(self.clientRegistrationStatus.lastResortPrekey)
        }
    }

    func testThatItReturnsRequestForInsertedObject() {
        syncMOC.performGroupedAndWait {
            // given
            let prekeys = [(UInt16(1), "prekey1")]
            let lastResortPrekey = (ushort.max, "last-resort-prekey")
            let client = self.createSelfClient(self.sut.managedObjectContext!)
            self.sut.notifyChangeTrackers(client)
            self.clientRegistrationStatus.prekeys = prekeys
            self.clientRegistrationStatus.lastResortPrekey = lastResortPrekey
            self.clientRegistrationStatus.mockPhase = .unregistered

            // when
            self.clientRegistrationStatus.prepareForClientRegistration()

            let request = self.sut.nextRequest(for: .v0)

            // then
            let expectedRequest = try! self.sut.requestsFactory.registerClientRequest(
                client,
                credentials: self.fakeCredentialsProvider.emailCredentials(),
                cookieLabel: "mycookie",
                prekeys: self.clientRegistrationStatus.prekeys!,
                lastRestortPrekey: self.clientRegistrationStatus.lastResortPrekey!,
                apiVersion: .v0
            ).transportRequest!

            AssertOptionalNotNil(request, "Should return request if there is inserted UserClient object") { request in
                XCTAssertNotNil(request.payload, "Request should contain payload")
                XCTAssertEqual(request.method, expectedRequest.method, "")
                XCTAssertEqual(request.path, expectedRequest.path, "")
            }
        }
    }

    func testThatItDoesNotReturnRequestIfThereIsNoInsertedObject() {
        syncMOC.performGroupedAndWait {
            // given
            self.clientRegistrationStatus.isWaitingForLoginValue = true
            let client = self.createSelfClient(self.sut.managedObjectContext!)
            self.sut.notifyChangeTrackers(client)

            // when
            self.clientRegistrationStatus.prepareForClientRegistration()

            _ = self.sut.nextRequest(for: .v0)
            let nextRequest = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNil(nextRequest, "Should return request only if UserClient object inserted")
        }
    }

    func testThatItStoresTheRemoteIdentifierWhenUpdatingAnInsertedObject() {
        syncMOC.performGroupedAndWait {
            // given
            let client = self.createSelfClient(self.sut.managedObjectContext!)
            self.sut.managedObjectContext!.saveOrRollback()
            self.clientRegistrationStatus.prekeys = [(UInt16(1), "prekey1")]
            self.clientRegistrationStatus.lastResortPrekey = (ushort.max, "last-resort-prekey")

            let remoteIdentifier = "superRandomIdentifer"
            let payload = ["id": remoteIdentifier]
            let response = ZMTransportResponse(
                payload: payload as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            let request = self.sut.request(forInserting: client, forKeys: Set(), apiVersion: .v0)

            // when
            self.sut.updateInsertedObject(client, request: request!, response: response)

            // then
            XCTAssertNotNil(client.remoteIdentifier, "Should store remoteIdentifier provided by response")
            XCTAssertEqual(client.remoteIdentifier, remoteIdentifier)

            let storedRemoteIdentifier = self.syncMOC.persistentStoreMetadata(forKey: ZMPersistedClientIdKey) as? String
            AssertOptionalEqual(storedRemoteIdentifier, expression2: remoteIdentifier)
            self.syncMOC.setPersistentStoreMetadata(nil as String?, key: ZMPersistedClientIdKey)
        }
    }

    func testThatItStoresTheLastGeneratedPreKeyIDWhenUpdatingAnInsertedObject() {
        var client: UserClient!
        var maxID_before: UInt16!
        let expectedMaxID: UInt16 = 1

        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.prekeys = [(expectedMaxID, "prekey1")]
            self.clientRegistrationStatus.lastResortPrekey = (ushort.max, "last-resort-prekey")
            self.clientRegistrationStatus.mockPhase = .unregistered

            client = self.createSelfClient(self.sut.managedObjectContext!)
            maxID_before = UInt16(client.preKeysRangeMax)
            XCTAssertEqual(maxID_before, 0)

            self.sut.notifyChangeTrackers(client)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            let response = ZMTransportResponse(
                payload: ["id": "fakeRemoteID"] as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            let maxID_after = UInt16(client.preKeysRangeMax)
            XCTAssertEqual(maxID_after, expectedMaxID)
        }
    }

    func testThatItStoresTheSignalingKeysWhenUpdatingAnInsertedObject() {
        var client: UserClient!
        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.prekeys = [(UInt16(1), "prekey1")]
            self.clientRegistrationStatus.lastResortPrekey = (ushort.max, "last-resort-prekey")
            self.clientRegistrationStatus.mockPhase = .unregistered

            client = self.createSelfClient(self.syncMOC)
            XCTAssertNil(client.apsDecryptionKey)
            XCTAssertNil(client.apsVerificationKey)

            self.sut.notifyChangeTrackers(client)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            let response = ZMTransportResponse(
                payload: ["id": "fakeRemoteID"] as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertNotNil(client.apsDecryptionKey)
            XCTAssertNotNil(client.apsVerificationKey)
        }
    }

    func testThatItNotifiesObserversWhenUpdatingAnInsertedObject() {
        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.prekeys = [(UInt16(1), "prekey1")]
            self.clientRegistrationStatus.lastResortPrekey = (ushort.max, "last-resort-prekey")
            self.clientRegistrationStatus.mockPhase = .unregistered

            let client = self.createSelfClient(self.syncMOC)
            self.sut.notifyChangeTrackers(client)

            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            let response = ZMTransportResponse(
                payload: ["id": "fakeRemoteID"] as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        XCTAssertTrue(mockClientRegistrationStatusDelegate.didCallRegisterSelfUserClient)
    }

    func testThatItProcessFailedInsertResponseWithAuthenticationError_NoEmail() {
        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.prekeys = [(UInt16(1), "prekey1")]
            self.clientRegistrationStatus.lastResortPrekey = (ushort.max, "last-resort-prekey")
            self.clientRegistrationStatus.mockPhase = .unregistered

            let client = self.createSelfClient(self.syncMOC)
            self.sut.notifyChangeTrackers(client)

            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            let responsePayload = [
                "code": 403,
                "message": "Re-authentication via password required",
                "label": "missing-auth",
            ] as [String: Any]
            let response = ZMTransportResponse(
                payload: responsePayload as ZMTransportData,
                httpStatus: 403,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        XCTAssertTrue(mockClientRegistrationStatusDelegate.didCallFailRegisterSelfUserClient)
        let expectedError = NSError(
            domain: NSError.userSessionErrorDomain,
            code: UserSessionErrorCode.invalidCredentials.rawValue,
            userInfo: nil
        )
        XCTAssertEqual(mockClientRegistrationStatusDelegate.currentError as NSError?, expectedError)
    }

    func testThatItProcessFailedInsertResponseWithAuthenticationError_HasEmail() {
        let emailAddress = "hello@example.com"

        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.prekeys = [(UInt16(1), "prekey1")]
            self.clientRegistrationStatus.lastResortPrekey = (ushort.max, "last-resort-prekey")
            self.clientRegistrationStatus.mockPhase = .unregistered

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.setValue(emailAddress, forKey: #keyPath(ZMUser.emailAddress))

            let client = self.createSelfClient(self.syncMOC)
            self.sut.notifyChangeTrackers(client)

            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            let responsePayload = [
                "code": 403,
                "message": "Re-authentication via password required",
                "label": "missing-auth",
            ] as [String: Any]
            let response = ZMTransportResponse(
                payload: responsePayload as ZMTransportData,
                httpStatus: 403,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            request.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            let expectedError = NSError(
                domain: NSError.userSessionErrorDomain,
                code: UserSessionErrorCode.needsPasswordToRegisterClient.rawValue,
                userInfo: [
                    ZMEmailCredentialKey: emailAddress,
                    ZMUserHasPasswordKey: true,
                    ZMUserUsesCompanyLoginCredentialKey: false,
                    ZMUserLoginCredentialsKey: LoginCredentials(
                        emailAddress: emailAddress,
                        hasPassword: true,
                        usesCompanyLogin: false
                    ),
                ]
            )

            XCTAssertTrue(self.mockClientRegistrationStatusDelegate.didCallFailRegisterSelfUserClient)
            XCTAssertEqual(self.mockClientRegistrationStatusDelegate.currentError as NSError?, expectedError)
        }
    }

    func testThatItProcessFailedInsertResponseWithTooManyClientsError() {
        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.prekeys = [(UInt16(1), "prekey1")]
            self.clientRegistrationStatus.lastResortPrekey = (ushort.max, "last-resort-prekey")
            self.cookieStorage.authenticationCookieData = HTTPCookie.validCookieData()
            self.clientRegistrationStatus.mockPhase = .unregistered

            let client = self.createSelfClient(self.syncMOC)
            self.sut.notifyChangeTrackers(client)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID.create()

            guard let request = self.sut.nextRequest(for: .v0) else {
                XCTFail()
                return
            }
            let responsePayload = [
                "code": 403,
                "message": "Too many clients",
                "label": "too-many-clients",
            ] as [String: Any]
            let response = ZMTransportResponse(
                payload: responsePayload as ZMTransportData?,
                httpStatus: 403,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            _ = NSError(
                domain: NSError.userSessionErrorDomain,
                code: UserSessionErrorCode.canNotRegisterMoreClients.rawValue,
                userInfo: nil
            )

            // when
            self.clientRegistrationStatus.mockPhase = nil
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertEqual(self.clientRegistrationStatus.currentPhase, .fetchingClients)
        }
    }
}

// MARK: Updating

extension UserClientRequestStrategyTests {
    func testThatPrekeysAreGeneratedBeforeRefillingPrekeys() {
        syncMOC.performGroupedAndWait {
            // given
            self.clientRegistrationStatus.mockPhase = .registered
            let client = self.createSelfClient(self.sut.managedObjectContext!)
            client.remoteIdentifier = UUID.create().transportString()
            client.numberOfKeysRemaining = Int32(self.sut.minNumberOfRemainingKeys - 1)
            client.preKeysRangeMax = 5
            client.setLocallyModifiedKeys([ZMUserClientNumberOfKeysRemainingKey])
            self.sut.managedObjectContext!.saveOrRollback()
            self.sut.notifyChangeTrackers(client)

            // when
            XCTAssertNil(self.sut.nextRequest(for: .v0))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertNotNil(self.clientUpdateStatus.prekeys)
            XCTAssertEqual(self.clientUpdateStatus.prekeys?.first?.id, 6)
        }
    }

    func testThatItReturnsRequestIfNumberOfRemainingKeysIsLessThanMinimum() {
        syncMOC.performGroupedAndWait {
            // given
            let prekeys = [IdPrekeyTuple(id: 1, prekey: "prekey1")]
            self.clientRegistrationStatus.mockPhase = .registered
            self.clientUpdateStatus.didGeneratePrekeys(prekeys)

            let client = UserClient.insertNewObject(in: self.sut.managedObjectContext!)
            let userClientNumberOfKeysRemainingKeySet: Set<AnyHashable> = [ZMUserClientNumberOfKeysRemainingKey]
            client.remoteIdentifier = UUID.create().transportString()
            self.sut.managedObjectContext!.saveOrRollback()

            client.numberOfKeysRemaining = Int32(self.sut.minNumberOfRemainingKeys - 1)
            client.setLocallyModifiedKeys(userClientNumberOfKeysRemainingKeySet)
            self.sut.notifyChangeTrackers(client)

            // when
            guard let request = self.sut.nextRequest(for: .v0) else {
                XCTFail()
                return
            }

            // then
            let expectedRequest = try! self.sut.requestsFactory.updateClientPreKeysRequest(
                client,
                prekeys: prekeys,
                apiVersion: .v0
            ).transportRequest

            AssertOptionalNotNil(request, "Should return request if there is inserted UserClient object") { request in
                XCTAssertNotNil(request.payload, "Request should contain payload")
                XCTAssertEqual(request.method, expectedRequest?.method)
                XCTAssertEqual(request.path, expectedRequest?.path)
            }
        }
    }

    func testThatItDoesNotReturnsRequestIfNumberOfRemainingKeysIsLessThanMinimum_NoRemoteIdentifier() {
        syncMOC.performGroupedAndWait {
            // given
            self.clientRegistrationStatus.mockPhase = .registered

            let client = UserClient.insertNewObject(in: self.sut.managedObjectContext!)
            let userClientNumberOfKeysRemainingKeySet: Set<AnyHashable> = [ZMUserClientNumberOfKeysRemainingKey]

            // when
            client.remoteIdentifier = nil
            self.sut.managedObjectContext!.saveOrRollback()

            client.numberOfKeysRemaining = Int32(self.sut.minNumberOfRemainingKeys - 1)
            client.setLocallyModifiedKeys(userClientNumberOfKeysRemainingKeySet)
            self.sut.notifyChangeTrackers(client)

            // then
            XCTAssertNil(self.sut.nextRequest(for: .v0))
        }
    }

    func testThatItDoesNotReturnRequestIfNumberOfRemainingKeysIsAboveMinimum() {
        syncMOC.performGroupedAndWait {
            // given
            self.clientRegistrationStatus.mockPhase = .registered

            let client = UserClient.insertNewObject(in: self.sut.managedObjectContext!)
            client.remoteIdentifier = UUID.create().transportString()
            self.sut.managedObjectContext!.saveOrRollback()

            client.numberOfKeysRemaining = Int32(self.sut.minNumberOfRemainingKeys)

            let userClientNumberOfKeysRemainingKeySet: Set<AnyHashable> = [ZMUserClientNumberOfKeysRemainingKey]
            client.setLocallyModifiedKeys(userClientNumberOfKeysRemainingKeySet)
            self.sut.notifyChangeTrackers(client)

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNil(request, "Should not return request if there are enouth keys left")
        }
    }

    func testThatItResetsNumberOfRemainingKeysAfterNewKeysUploaded() {
        syncMOC.performGroupedAndWait {
            // given
            let client = UserClient.insertNewObject(in: self.sut.managedObjectContext!)
            client.remoteIdentifier = UUID.create().transportString()
            self.sut.managedObjectContext!.saveOrRollback()

            client.numberOfKeysRemaining = Int32(self.sut.minNumberOfRemainingKeys - 1)
            let expectedNumberOfKeys = client.numberOfKeysRemaining + Int32(self.sut.prekeyGenerator.keyCount)

            // when
            let response = ZMTransportResponse(
                payload: nil,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            let userClientNumberOfKeysRemainingKeySet: Set<String> = [ZMUserClientNumberOfKeysRemainingKey]
            _ = self.sut.updateUpdatedObject(
                client,
                requestUserInfo: nil,
                response: response,
                keysToParse: userClientNumberOfKeysRemainingKeySet
            )

            // then
            XCTAssertEqual(client.numberOfKeysRemaining, expectedNumberOfKeys)
        }
    }

    func testThatItReturnsRequestIfItNeedsToRegisterMLSClient() {
        var selfClient: UserClient!
        let request = syncMOC.performAndWait {
            // given
            selfClient = UserClient.insertNewObject(in: self.sut.managedObjectContext!)
            selfClient.remoteIdentifier = UUID.create().transportString()
            selfClient.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "key")
            self.sut.managedObjectContext!.saveOrRollback()
            self.clientRegistrationStatus.mockPhase = .registeringMLSClient
            self.sut.notifyChangeTrackers(selfClient)

            // when
            return self.sut.nextRequest(for: .v0)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performAndWait {
            XCTAssertEqual(request?.method, .put)
            XCTAssertEqual(request?.path, "/clients/\(selfClient.remoteIdentifier!)")
        }
    }
}

// MARK: Fetching Clients

extension UserClientRequestStrategyTests {
    func  payloadForClients() -> ZMTransportData {
        let payload = [
            [
                "id": UUID.create().transportString(),
                "type": "permanent",
                "label": "client",
                "time": Date().transportString(),
            ],
            [
                "id": UUID.create().transportString(),
                "type": "permanent",
                "label": "client",
                "time": Date().transportString(),
            ],
        ]

        return payload as ZMTransportData
    }

    func testThatItNotifiesWhenFinishingFetchingTheClient() {
        syncMOC.performGroupedAndWait {
            // given
            self.clientUpdateStatus.mockPhase = .fetchingClients
            let nextResponse = ZMTransportResponse(
                payload: self.payloadForClients() as ZMTransportData?,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            _ = self.sut.nextRequest(for: .v0)
            self.sut.didReceive(nextResponse, forSingleRequest: self.sut.fetchAllClientsSync)

            // then
            AssertOptionalNotNil(self.clientUpdateStatus.fetchedClients, "userinfo should contain clientIDs") { _ in
                XCTAssertEqual(self.clientUpdateStatus.fetchedClients.count, 2)
                for client in self.clientUpdateStatus.fetchedClients {
                    XCTAssertEqual(client?.label!, "client")
                }
            }
        }
    }

    func testThatDeletesClientsThatWereNotInTheFetchResponse() {
        var selfUser: ZMUser!
        var selfClient: UserClient!
        var newClient: UserClient!

        syncMOC.performGroupedAndWait {
            // given
            selfClient = self.createSelfClient()
            selfUser = ZMUser.selfUser(in: self.syncMOC)
            let nextResponse = ZMTransportResponse(
                payload: self.payloadForClients() as ZMTransportData?,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            newClient = UserClient.insertNewObject(in: self.syncMOC)
            newClient.user = selfUser
            newClient.remoteIdentifier = "deleteme"
            self.syncMOC.saveOrRollback()

            // when
            _ = self.sut.nextRequest(for: .v0)
            self.sut.didReceive(nextResponse, forSingleRequest: self.sut.fetchAllClientsSync)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertTrue(selfUser.clients.contains(selfClient))
            XCTAssertFalse(selfUser.clients.contains(newClient))
        }
    }
}

// MARK: Deleting

extension UserClientRequestStrategyTests {
    func testThatItCreatesARequestToDeleteAClient_UpdateStatus() {
        syncMOC.performGroupedAndWait {
            // given
            self.clientRegistrationStatus.mockPhase = .unregistered
            self.clientUpdateStatus.mockPhase = .deletingClients
            let clients = [
                UserClient.insertNewObject(in: self.syncMOC),
                UserClient.insertNewObject(in: self.syncMOC),
            ]
            for client in clients {
                client.remoteIdentifier = "\(client.objectID)"
                client.user = ZMUser.selfUser(in: self.syncMOC)
            }
            self.syncMOC.saveOrRollback()

            // when
            clients[0].markForDeletion()
            self.sut.notifyChangeTrackers(clients[0])

            let nextRequest = self.sut.nextRequest(for: .v0)

            // then
            AssertOptionalNotNil(nextRequest) {
                XCTAssertEqual($0.path, "/clients/\(clients[0].remoteIdentifier!)")
                XCTAssertEqual($0.payload as! [String: String], [
                    "email": self.clientUpdateStatus.mockCredentials.email!,
                    "password": self.clientUpdateStatus.mockCredentials.password!,
                ])
                XCTAssertEqual($0.method, ZMTransportRequestMethod.delete)
            }
        }
    }

    func testThatItDeletesAClientOnSuccess() {
        // given
        var client: UserClient!

        syncMOC.performGroupedBlock {
            client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "\(client.objectID)"
            client.user = ZMUser.selfUser(in: self.syncMOC)
            self.syncMOC.saveOrRollback()

            let response = ZMTransportResponse(
                payload: [:] as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            let userClientMarkedToDeleteKeySet: Set<String> = [ZMUserClientMarkedToDeleteKey]
            _ = self.sut.updateUpdatedObject(
                client,
                requestUserInfo: nil,
                response: response,
                keysToParse: userClientMarkedToDeleteKeySet
            )
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            XCTAssertTrue(client.isZombieObject)
        }
    }
}

// MARK: - Updating from push events

extension UserClientRequestStrategyTests {
    func testThatItCreatesARequestForClientsThatNeedToUploadSignalingKeys() {
        var existingClient: UserClient!
        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .registered

            existingClient = self.createSelfClient()
            let existingClientSet: Set<NSManagedObject> = [existingClient]
            let userClientNeedsToUpdateSignalingKeysKeySet: Set<AnyHashable> =
                [ZMUserClientNeedsToUpdateSignalingKeysKey]

            XCTAssertNil(existingClient.apsVerificationKey)
            XCTAssertNil(existingClient.apsDecryptionKey)

            // when
            existingClient.needsToUploadSignalingKeys = true
            existingClient.setLocallyModifiedKeys(userClientNeedsToUpdateSignalingKeysKeySet)
            for contextChangeTracker in self.sut.contextChangeTrackers {
                contextChangeTracker.objectsDidChange(existingClientSet)
            }
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNotNil(request)

            // and when
            let response = ZMTransportResponse(
                payload: nil,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performGroupedBlock {
            XCTAssertNotNil(existingClient.apsVerificationKey)
            XCTAssertNotNil(existingClient.apsDecryptionKey)
            XCTAssertFalse(existingClient.needsToUploadSignalingKeys)
            XCTAssertFalse(existingClient.hasLocalModifications(forKey: ZMUserClientNeedsToUpdateSignalingKeysKey))
        }
    }

    func testThatItRetriesOnceWhenUploadSignalingKeysFails() {
        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .registered

            let existingClient = self.createSelfClient()
            let existingClientSet: Set<NSManagedObject> = [existingClient]
            let userClientNeedsToUpdateSignalingKeysKeySet: Set<AnyHashable> =
                [ZMUserClientNeedsToUpdateSignalingKeysKey]
            XCTAssertNil(existingClient.apsVerificationKey)
            XCTAssertNil(existingClient.apsDecryptionKey)

            existingClient.needsToUploadSignalingKeys = true
            existingClient.setLocallyModifiedKeys(userClientNeedsToUpdateSignalingKeysKeySet)
            for contextChangeTracker in self.sut.contextChangeTrackers {
                contextChangeTracker.objectsDidChange(existingClientSet)
            }

            // when
            let request = self.sut.nextRequest(for: .v0)
            XCTAssertNotNil(request)
            let badResponse = ZMTransportResponse(
                payload: ["label": "bad-request"] as ZMTransportData,
                httpStatus: 400,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            request?.complete(with: badResponse)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // and when
        syncMOC.performGroupedBlock {
            let secondRequest = self.sut.nextRequest(for: .v0)
            XCTAssertNotNil(secondRequest)
            let success = ZMTransportResponse(
                payload: nil,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            secondRequest?.complete(with: success)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // and when
        syncMOC.performGroupedBlock {
            let thirdRequest = self.sut.nextRequest(for: .v0)
            XCTAssertNil(thirdRequest)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func testThatItCreatesARequestForClientsThatNeedToUpdateCapabilities() {
        var existingClient: UserClient!
        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .registered

            existingClient = self.createSelfClient()
            let existingClientSet: Set<NSManagedObject> = [existingClient]
            let userClientNeedsToUpdateCapabilitiesKeySet: Set<AnyHashable> = [ZMUserClientNeedsToUpdateCapabilitiesKey]

            // when
            existingClient.needsToUpdateCapabilities = true
            existingClient.setLocallyModifiedKeys(userClientNeedsToUpdateCapabilitiesKeySet)
            for contextChangeTracker in self.sut.contextChangeTrackers {
                contextChangeTracker.objectsDidChange(existingClientSet)
            }
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNotNil(request)

            // and when
            let response = ZMTransportResponse(
                payload: nil,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performGroupedBlock {
            XCTAssertFalse(existingClient.needsToUpdateCapabilities)
            XCTAssertFalse(existingClient.hasLocalModifications(forKey: ZMUserClientNeedsToUpdateCapabilitiesKey))
        }
    }

    func testThatItRetriesOnceWhenUpdateCapabilitiesFails() {
        syncMOC.performGroupedBlock {
            // given
            self.clientRegistrationStatus.mockPhase = .registered

            let existingClient = self.createSelfClient()
            let existingClientSet: Set<NSManagedObject> = [existingClient]
            let userClientNeedsToUpdateCapabilitiesKeySet: Set<AnyHashable> = [ZMUserClientNeedsToUpdateCapabilitiesKey]

            existingClient.needsToUpdateCapabilities = true

            existingClient.setLocallyModifiedKeys(userClientNeedsToUpdateCapabilitiesKeySet)
            for contextChangeTracker in self.sut.contextChangeTrackers {
                contextChangeTracker.objectsDidChange(existingClientSet)
            }

            // when
            let request = self.sut.nextRequest(for: .v0)
            XCTAssertNotNil(request)
            let badResponse = ZMTransportResponse(
                payload: ["label": "bad-request"] as ZMTransportData,
                httpStatus: 400,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            request?.complete(with: badResponse)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // and when
        syncMOC.performGroupedBlock {
            let secondRequest = self.sut.nextRequest(for: .v0)
            XCTAssertNotNil(secondRequest)
            let success = ZMTransportResponse(
                payload: nil,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            secondRequest?.complete(with: success)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // and when
        syncMOC.performGroupedBlock {
            let thirdRequest = self.sut.nextRequest(for: .v0)
            XCTAssertNil(thirdRequest)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }

    func test_ItCreatesARequest_ForClientsThatNeedToUpdateMLSPublicKeys() {
        var existingClient: UserClient!

        syncMOC.performGroupedBlock {
            // Given
            self.clientRegistrationStatus.mockPhase = .registered

            existingClient = self.createSelfClient()
            let existingClientSet: Set<NSManagedObject> = [existingClient]

            // When
            existingClient.needsToUploadMLSPublicKeys = true
            existingClient.setLocallyModifiedKeys(Set([UserClient.needsToUploadMLSPublicKeysKey]))

            for contextChangeTracker in self.sut.contextChangeTrackers {
                contextChangeTracker.objectsDidChange(existingClientSet)
            }

            let request = self.sut.nextRequest(for: .v1)

            // Then
            XCTAssertNotNil(request)

            // And when
            let response = ZMTransportResponse(
                payload: nil,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v1.rawValue
            )

            request?.complete(with: response)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        syncMOC.performGroupedBlock {
            XCTAssertFalse(existingClient.needsToUploadMLSPublicKeys)
            XCTAssertFalse(existingClient.hasLocalModifications(forKey: UserClient.needsToUploadMLSPublicKeysKey))
        }
    }
}

extension UserClientRequestStrategy {
    func notifyChangeTrackers(_ object: ZMManagedObject) {
        contextChangeTrackers.forEach { $0.objectsDidChange(Set([object])) }
    }
}
