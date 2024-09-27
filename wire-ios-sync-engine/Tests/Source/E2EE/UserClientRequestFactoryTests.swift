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
import WireCryptobox
import WireDataModel
import WireDataModelSupport
import WireMockTransport
import WireTesting
import WireUtilities
@testable import WireSyncEngine

// MARK: - UserClientRequestFactoryTests

final class UserClientRequestFactoryTests: MessagingTest {
    var sut: UserClientRequestFactory!
    var authenticationStatus: ZMAuthenticationStatus!
    var mockAuthenticationStatusDelegate: MockAuthenticationStatusDelegate!
    var userInfoParser: MockUserInfoParser!

    override func setUp() {
        super.setUp()
        userInfoParser = MockUserInfoParser()
        mockAuthenticationStatusDelegate = MockAuthenticationStatusDelegate()
        authenticationStatus = MockAuthenticationStatus(
            delegate: mockAuthenticationStatusDelegate,
            userInfoParser: userInfoParser
        )

        sut = UserClientRequestFactory()
    }

    override func tearDown() {
        authenticationStatus = nil
        mockAuthenticationStatusDelegate = nil
        sut = nil
        userInfoParser = nil
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
        let credentials = UserEmailCredentials(email: "some@example.com", password: "123")

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
        let credentials = UserEmailCredentials(
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
        credentials: UserEmailCredentials?,
        usingProteusService: Bool
    ) throws {
        let request = try syncMOC.performAndWait {
            // given
            let client = UserClient.insertNewObject(in: self.syncMOC)
            let prekeys = [IdPrekeyTuple(id: 0, "prekey0")]
            let lastRestortPrekey = IdPrekeyTuple(id: UInt16.max, "last-resort-prekey")

            // when
            return try sut.registerClientRequest(
                client,
                credentials: credentials,
                cookieLabel: "mycookie",
                prekeys: prekeys,
                lastRestortPrekey: lastRestortPrekey,
                apiVersion: .v0
            )
        }

        // then
        let transportRequest = try XCTUnwrap(request.transportRequest)
        assertRequest(transportRequest, path: "/clients", method: .post)

        let payload = try XCTUnwrap(payload(from: transportRequest))
        try assertSigkeys(payload)

        XCTAssertEqual(payload.type, DeviceType.permanent.rawValue)

        if let credentials {
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
        let emptyPrekeys: [IdPrekeyTuple] = []
        let lastRestortPrekey = IdPrekeyTuple(id: UInt16.max, "last-resort-prekey")
        let credentials = UserEmailCredentials(email: "some@example.com", password: "123")

        syncMOC.performAndWait {
            let client = UserClient.insertNewObject(in: syncMOC)

            // when
            let request = try? sut.registerClientRequest(
                client,
                credentials: credentials,
                cookieLabel: "mycookie",
                prekeys: emptyPrekeys,
                lastRestortPrekey: lastRestortPrekey,
                apiVersion: .v0
            )

            // then
            XCTAssertNil(request)
        }
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
        try syncMOC.performAndWait {
            // given
            let prekeys = [IdPrekeyTuple(id: 1, "prekey1")]
            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = UUID.create().transportString()
            client.preKeysRangeMax = prekeyRangeMax

            // when
            let request = try sut.updateClientPreKeysRequest(client, prekeys: prekeys, apiVersion: .v0)

            // then
            let transportRequest = try XCTUnwrap(request.transportRequest)
            let id = try XCTUnwrap(client.remoteIdentifier)
            assertRequest(
                transportRequest,
                path: "/clients/\(id)",
                method: .put
            )

            _ = try XCTUnwrap(payload(from: transportRequest))
        }
    }

    func testThatItReturnsNilForUpdateClientRequestIfCanNotGeneratePreKeys() {
        testThatItReturnsNilForUpdateClientRequestIfCanNotGeneratePreKeys(usingProteusService: false)
        testThatItReturnsNilForUpdateClientRequestIfCanNotGeneratePreKeys(usingProteusService: true)
    }

    func testThatItReturnsNilForUpdateClientRequestIfCanNotGeneratePreKeys(usingProteusService: Bool) {
        syncMOC.performAndWait {
            // given
            let emptyPrekeys: [IdPrekeyTuple] = []
            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = UUID.create().transportString()

            // when
            let request = try? sut.updateClientPreKeysRequest(client, prekeys: emptyPrekeys, apiVersion: .v0)

            // then
            XCTAssertNil(request, "Should not return request if client fails to generate prekeys")
        }
    }

    func testThatItDoesNotReturnRequestIfClientIsNotSynced() {
        // given
        let prekeys = [IdPrekeyTuple(id: 1, "prekey1")]
        syncMOC.performAndWait {
            let client = UserClient.insertNewObject(in: self.syncMOC)

            // when
            do {
                _ = try sut.updateClientPreKeysRequest(client, prekeys: prekeys, apiVersion: .v0)
            } catch {
                XCTAssertNotNil(error, "Should not return request if client does not have remoteIdentifier")
            }
        }
    }

    // MARK: - Deleting client

    func testThatItCreatesARequestToDeleteAClient() throws {
        try syncMOC.performAndWait {
            // given
            let email = "foo@example.com"
            let password = "gfsgdfgdfgdfgdfg"
            let credentials = UserEmailCredentials(email: email, password: password)
            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "\(client.objectID)"
            self.syncMOC.saveOrRollback()

            // when
            let nextRequest = sut.deleteClientRequest(client, credentials: credentials, apiVersion: .v0)

            // then
            let transportRequest = try XCTUnwrap(nextRequest.transportRequest)
            let id = try XCTUnwrap(client.remoteIdentifier)
            assertRequest(
                transportRequest,
                path: "/clients/\(id)",
                method: .delete
            )

            let payload = try XCTUnwrap(payload(from: transportRequest))
            XCTAssertEqual(payload.password, password)
            XCTAssertEqual(payload.email, email)
        }
    }

    // MARK: - MLS public keys

    func test_ItGeneratesRequestToUploadMLSPublicKeys() throws {
        // Given
        try syncMOC.performAndWait {
            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = "\(client.objectID)"
            client.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "foo")
            self.syncMOC.saveOrRollback()

            // When
            let request = try XCTUnwrap(sut.updateClientMLSPublicKeysRequest(client, apiVersion: .v1))

            // Then
            XCTAssertEqual(request.keys, Set([UserClient.needsToUploadMLSPublicKeysKey]))

            let transportRequest = try XCTUnwrap(request.transportRequest)
            let id = try XCTUnwrap(client.remoteIdentifier)
            assertRequest(
                transportRequest,
                path: "/v1/clients/\(id)",
                method: .put
            )

            let payload = try XCTUnwrap(payload(from: transportRequest))
            XCTAssertEqual(payload.mlsPublicKeys?.ed25519, "foo")
        }
    }

    // MARK: - Helpers

    private func payload(from request: ZMTransportRequest) -> [String: Any]? {
        request.payload?.asDictionary() as? [String: Any]
    }

    private func assertRequest(_ request: ZMTransportRequest, path: String, method: ZMTransportRequestMethod) {
        XCTAssertEqual(request.path, path)
        XCTAssertEqual(request.method, method)
    }

    private func assertSigkeys(_ payload: [String: Any]) throws {
        let sigkeys = try XCTUnwrap(payload.sigkeys)
        XCTAssertNotNil(sigkeys.enckey)
        XCTAssertNotNil(sigkeys.mackey)
    }
}

extension [String: Any] {
    fileprivate enum PayloadKey: String {
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

    fileprivate var type: String? {
        value(forKey: .type)
    }

    fileprivate var password: String? {
        value(forKey: .password)
    }

    fileprivate var email: String? {
        value(forKey: .email)
    }

    fileprivate var verificationCode: String? {
        value(forKey: .verificationCode)
    }

    private var lastKey: [String: Any]? {
        value(forKey: .lastkey)
    }

    private var key: String? {
        value(forKey: .key)
    }

    fileprivate var id: NSNumber? {
        value(forKey: .id)
    }

    fileprivate var prekeys: [[String: Any]]? {
        value(forKey: .prekeys)
    }

    fileprivate var sigkeys: [String: Any]? {
        value(forKey: .sigkeys)
    }

    fileprivate var enckey: String? {
        value(forKey: .enckey)
    }

    fileprivate var mackey: String? {
        value(forKey: .mackey)
    }

    fileprivate var mlsPublicKeys: [String: Any]? {
        value(forKey: .mlsPublicKeys)
    }

    fileprivate var ed25519: String? {
        value(forKey: .ed25519)
    }

    private func value<T>(forKey key: PayloadKey) -> T? {
        self[key.rawValue] as? T
    }
}
