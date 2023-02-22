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

@testable import WireSyncEngine
import WireUtilities
import WireTesting
import WireCryptobox
import WireMockTransport
import WireDataModel
import Foundation

class UserClientRequestFactoryTests: MessagingTest {

    var sut: UserClientRequestFactory!
    var authenticationStatus: ZMAuthenticationStatus!
    var spyKeyStore: SpyUserClientKeyStore!
    var mockAuthenticationStatusDelegate: MockAuthenticationStatusDelegate!
    var userInfoParser: MockUserInfoParser!
    var proteusService: MockProteusServiceInterface!

    override func setUp() {
        super.setUp()
        spyKeyStore = SpyUserClientKeyStore(accountDirectory: accountDirectory, applicationContainer: sharedContainerURL)
        userInfoParser = MockUserInfoParser()
        mockAuthenticationStatusDelegate = MockAuthenticationStatusDelegate()
        authenticationStatus = MockAuthenticationStatus(
            delegate: mockAuthenticationStatusDelegate,
            userInfoParser: self.userInfoParser
        )
        proteusService = mockProteusService()

        sut = UserClientRequestFactory(
            keysStore: self.spyKeyStore,
            proteusService: nil
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: spyKeyStore.cryptoboxDirectory)
        authenticationStatus = nil
        mockAuthenticationStatusDelegate = nil
        sut = nil
        spyKeyStore = nil
        userInfoParser = nil
        proteusService = nil
        super.tearDown()
    }

    private func mockProteusService() -> MockProteusServiceInterface {
        let proteusService = MockProteusServiceInterface()

        proteusService.generatePrekeysStartCount_MockValue = [(1, "prekey")]
        proteusService.lastPrekey_MockValue = "prekey"
        proteusService.underlyingLastPrekeyID = UInt16.max

        return proteusService
    }

    // MARK: - Registration request creation 

    func testThatItCreatesRegistrationRequestWithEmailCorrectly() throws {
        let credentials = ZMEmailCredentials(email: "some@example.com", password: "123")

        try testThatItCreatesRegistrationRequestCorrectly(
            credentials: credentials,
            usingProteusService: false
        )

        try testThatItCreatesRegistrationRequestCorrectly(
            credentials: credentials,
            usingProteusService: true
        )
    }

    func testThatItCreatesRegistrationRequestWithEmailVerificationCodeCorrectly() throws {
        let credentials = ZMEmailCredentials(
            email: "some@example.com",
            password: "123",
            emailVerificationCode: "123456"
        )

        try testThatItCreatesRegistrationRequestCorrectly(
            credentials: credentials,
            usingProteusService: false
        )

        try testThatItCreatesRegistrationRequestCorrectly(
            credentials: credentials,
            usingProteusService: true
        )
    }

    func testThatItCreatesRegistrationRequestWithPhoneCredentialsCorrectly() throws {
        try testThatItCreatesRegistrationRequestCorrectly(
            credentials: nil,
            usingProteusService: false
        )

        try testThatItCreatesRegistrationRequestCorrectly(
            credentials: nil,
            usingProteusService: true
        )
    }

    private func testThatItCreatesRegistrationRequestCorrectly(
        credentials: ZMEmailCredentials?,
        usingProteusService: Bool
    ) throws {
        // given
        let sut = UserClientRequestFactory(
            keysStore: self.spyKeyStore,
            proteusService: usingProteusService ? proteusService : nil
        )

        let client = UserClient.insertNewObject(in: self.syncMOC)

        // when
        let request = try sut.registerClientRequest(
            client,
            credentials: credentials,
            cookieLabel: "mycookie",
            apiVersion: .v0
        )

        // then
        let transportRequest = try XCTUnwrap(request.transportRequest)
        assertRequest(transportRequest, path: "/clients", method: .methodPOST)

        let payload = try XCTUnwrap(payload(from: transportRequest))
        try assertLastPrekey(payload, usingProteusService: usingProteusService)
        try assertPrekeys(payload, client: client, usingProteusService: usingProteusService)
        try assertSigkeys(payload)

        XCTAssertEqual(payload.type, DeviceType.permanent.rawValue)

        if let credentials = credentials {
            XCTAssertEqual(payload.password, credentials.password)
        }

        if let emailVerificationCode = credentials?.emailVerificationCode {
            XCTAssertEqual(payload.verificationCode, emailVerificationCode)
        }
    }

    func testThatItReturnsNilForRegisterClientRequest_PrekeyError() {
        // Failing to generate prekeys

        testThatItReturnsNilForRegisterClientRequestIfPreKeyError(
            .failedToGeneratePrekeys,
            usingProteusService: false
        )
        testThatItReturnsNilForRegisterClientRequestIfPreKeyError(
            .failedToGeneratePrekeys,
            usingProteusService: true
        )

        // Failing to generate last prekey

        testThatItReturnsNilForRegisterClientRequestIfPreKeyError(
            .failedToGenerateLastPrekey,
            usingProteusService: false
        )
        testThatItReturnsNilForRegisterClientRequestIfPreKeyError(
            .failedToGenerateLastPrekey,
            usingProteusService: true
        )
    }

    private func testThatItReturnsNilForRegisterClientRequestIfPreKeyError(
        _ error: PrekeyError,
        usingProteusService: Bool
    ) {
        // given
        let sut = UserClientRequestFactory(
            keysStore: spyKeyStore,
            proteusService: usingProteusService ? proteusService : nil
        )

        switch error {
        case .failedToGeneratePrekeys:
            proteusService.generatePrekeysStartCount_MockError = error
            spyKeyStore.failToGeneratePreKeys = true
        case .failedToGenerateLastPrekey:
            proteusService.lastPrekey_MockError = error
            spyKeyStore.failToGenerateLastPreKey = true
        }

        let client = UserClient.insertNewObject(in: syncMOC)
        let credentials = ZMEmailCredentials(email: "some@example.com", password: "123")

        // when
        let request = try? sut.registerClientRequest(
            client,
            credentials: credentials,
            cookieLabel: "mycookie",
            apiVersion: .v0
        )

        // then
        XCTAssertNil(request)
    }

    private enum PrekeyError: Error {
        case failedToGeneratePrekeys
        case failedToGenerateLastPrekey
    }

    // MARK: - Updating client request creation

    func testThatItCreatesUpdateClientRequestCorrectlyWhenStartingFromPrekey0() throws {
        try testThatItCreatesUpdateClientRequestCorrectlyWhenStartingFromPrekey(0, usingProteusService: false)
        try testThatItCreatesUpdateClientRequestCorrectlyWhenStartingFromPrekey(0, usingProteusService: true)
    }

    func testThatItCreatesUpdateClientRequestCorrectlyWhenStartingFromPrekey400() throws {
        try testThatItCreatesUpdateClientRequestCorrectlyWhenStartingFromPrekey(400, usingProteusService: false)
        try testThatItCreatesUpdateClientRequestCorrectlyWhenStartingFromPrekey(400, usingProteusService: true)
    }

    private func testThatItCreatesUpdateClientRequestCorrectlyWhenStartingFromPrekey(
        _ prekeyRangeMax: Int64,
        usingProteusService: Bool
    ) throws {
        // given
        let sut = UserClientRequestFactory(
            keysStore: self.spyKeyStore,
            proteusService: usingProteusService ? proteusService : nil
        )

        let client = UserClient.insertNewObject(in: self.syncMOC)
        client.remoteIdentifier = UUID.create().transportString()
        client.preKeysRangeMax = prekeyRangeMax

        // when
        let request = try sut.updateClientPreKeysRequest(client, apiVersion: .v0)

        // then
        let transportRequest = try XCTUnwrap(request.transportRequest)
        assertRequest(
            transportRequest,
            path: "/clients/\(client.remoteIdentifier!)",
            method: .methodPUT
        )

        let payload = try XCTUnwrap(payload(from: transportRequest))
        try assertPrekeys(payload, client: client, usingProteusService: usingProteusService)
    }

    func testThatItReturnsNilForUpdateClientRequestIfCanNotGeneratePreKeys() {
        testThatItReturnsNilForUpdateClientRequestIfCanNotGeneratePreKeys(usingProteusService: false)
        testThatItReturnsNilForUpdateClientRequestIfCanNotGeneratePreKeys(usingProteusService: true)
    }

    func testThatItReturnsNilForUpdateClientRequestIfCanNotGeneratePreKeys(usingProteusService: Bool) {
        // given
        let sut = UserClientRequestFactory(
            keysStore: spyKeyStore,
            proteusService: usingProteusService ? proteusService : nil
        )

        spyKeyStore.failToGeneratePreKeys = true
        proteusService.generatePrekeysStartCount_MockError = PrekeyError.failedToGeneratePrekeys

        let client = UserClient.insertNewObject(in: self.syncMOC)
        client.remoteIdentifier = UUID.create().transportString()

        // when
        let request = try? sut.updateClientPreKeysRequest(client, apiVersion: .v0)

        // then
        XCTAssertNil(request, "Should not return request if client fails to generate prekeys")
    }

    func testThatItDoesNotReturnRequestIfClientIsNotSynced() {
        // given
        let client = UserClient.insertNewObject(in: self.syncMOC)

        // when
        do {
            _ = try sut.updateClientPreKeysRequest(client, apiVersion: .v0)
        } catch let error {
            XCTAssertNotNil(error, "Should not return request if client does not have remoteIdentifier")
        }

    }

    // MARK: - Deleting client

    func testThatItCreatesARequestToDeleteAClient() throws {
        // given
        let email = "foo@example.com"
        let password = "gfsgdfgdfgdfgdfg"
        let credentials = ZMEmailCredentials(email: email, password: password)
        let client = UserClient.insertNewObject(in: self.syncMOC)
        client.remoteIdentifier = "\(client.objectID)"
        self.syncMOC.saveOrRollback()

        // when
        let nextRequest = sut.deleteClientRequest(client, credentials: credentials, apiVersion: .v0)

        // then
        let transportRequest = try XCTUnwrap(nextRequest.transportRequest)
        assertRequest(
            transportRequest,
            path: "/clients/\(client.remoteIdentifier!)",
            method: .methodDELETE
        )

        let payload = try XCTUnwrap(payload(from: transportRequest))
        XCTAssertEqual(payload.password, password)
        XCTAssertEqual(payload.email, email)
    }

    // MARK: - MLS public keys

    func test_ItGeneratesRequestToUploadMLSPublicKeys() throws {
        // Given
        let client = UserClient.insertNewObject(in: self.syncMOC)
        client.remoteIdentifier = "\(client.objectID)"
        client.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "foo")
        self.syncMOC.saveOrRollback()

        // When
        let request = try XCTUnwrap(sut.updateClientMLSPublicKeysRequest(client, apiVersion: .v1))

        // Then
        XCTAssertEqual(request.keys, Set([UserClient.needsToUploadMLSPublicKeysKey]))

        let transportRequest = try XCTUnwrap(request.transportRequest)
        assertRequest(
            transportRequest,
            path: "/v1/clients/\(client.remoteIdentifier!)",
            method: .methodPUT
        )

        let payload = try XCTUnwrap(payload(from: transportRequest))
        XCTAssertEqual(payload.mlsPublicKeys?.ed25519, "foo")
    }

    // MARK: - Helpers

    private func payload(from request: ZMTransportRequest) -> [String: Any]? {
        return request.payload?.asDictionary() as? [String: Any]
    }

    private func assertRequest(_ request: ZMTransportRequest, path: String, method: ZMTransportRequestMethod) {
        XCTAssertEqual(request.path, path)
        XCTAssertEqual(request.method, method)
    }

    private func assertLastPrekey(_ payload: [String: Any], usingProteusService: Bool) throws {
        let expectedLastPrekey = try expectedLastPrekey(usingProteusService: usingProteusService)
        let lastPrekey = try XCTUnwrap(payload.lastKey)

        XCTAssertEqual(lastPrekey.key, expectedLastPrekey.key)
        XCTAssertEqual(lastPrekey.id, expectedLastPrekey.id)
    }

    private func assertPrekeys(_ payload: [String: Any], client: UserClient, usingProteusService: Bool) throws {
        let expectedPrekeys = try expectedKeyPayloadForClientPreKeys(
            client,
            usingProteusService: usingProteusService
        )
        let prekeys = try XCTUnwrap(payload.prekeys)

        zip(prekeys, expectedPrekeys).forEach { (lhs, rhs) in
            XCTAssertEqual(lhs.key, rhs.key)
            XCTAssertEqual(lhs.id, rhs.id)
        }
    }

    private func assertSigkeys(_ payload: [String: Any]) throws {
        let sigkeys = try XCTUnwrap(payload.sigkeys)
        XCTAssertNotNil(sigkeys.enckey)
        XCTAssertNotNil(sigkeys.mackey)
    }

    private func expectedLastPrekey(usingProteusService: Bool) throws -> (key: String, id: NSNumber) {
        let expectedLastPrekey = usingProteusService
        ? try proteusService.lastPrekey()
        : try XCTUnwrap(spyKeyStore.lastGeneratedLastPrekey)

        let expectedLastPrekeyID = usingProteusService
        ? NSNumber(value: proteusService.lastPrekeyID)
        : NSNumber(value: CBOX_LAST_PREKEY_ID)

        return (expectedLastPrekey, expectedLastPrekeyID)
    }

    private func expectedKeyPayloadForClientPreKeys(_ client: UserClient, usingProteusService: Bool) throws -> [[String: Any]] {
        let generatedKeys = usingProteusService
        ? try proteusService.generatePrekeys(start: 0, count: 100)
        : self.spyKeyStore.lastGeneratedKeys

        let expectedPrekeys: [[String: Any]] = generatedKeys.map { (key: (id: UInt16, prekey: String)) in
            return ["key": key.prekey, "id": NSNumber(value: key.id)]
        }
        return expectedPrekeys
    }

}

private extension Dictionary where Key == String, Value == Any {
    enum PayloadKey: String {
        case type
        case email
        case password
        case verificationCode = "verification_code"
        case lastkey
        case key
        case id
        case prekeys
        case sigkeys
        case enckey
        case mackey
        case mlsPublicKeys = "mls_public_keys"
        case ed25519
    }

    var type: String? {
        value(forKey: .type)
    }

    var password: String? {
        value(forKey: .password)
    }

    var email: String? {
        value(forKey: .email)
    }

    var verificationCode: String? {
        value(forKey: .verificationCode)
    }

    var lastKey: [String: Any]? {
        value(forKey: .lastkey)
    }

    var key: String? {
        value(forKey: .key)
    }

    var id: NSNumber? {
        value(forKey: .id)
    }

    var prekeys: [[String: Any]]? {
        value(forKey: .prekeys)
    }

    var sigkeys: [String: Any]? {
        value(forKey: .sigkeys)
    }

    var enckey: String? {
        value(forKey: .enckey)
    }

    var mackey: String? {
        value(forKey: .mackey)
    }

    var mlsPublicKeys: [String: Any]? {
        value(forKey: .mlsPublicKeys)
    }

    var ed25519: String? {
        value(forKey: .ed25519)
    }

    func value<T>(forKey key: PayloadKey) -> T? {
        return self[key.rawValue] as? T
    }
}
