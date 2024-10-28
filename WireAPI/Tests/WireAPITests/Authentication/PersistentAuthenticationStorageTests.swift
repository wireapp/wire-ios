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

import WireFoundation
import WireTestingPackage
import XCTest

@testable import WireAPI
@testable import WireFoundationSupport

final class PersistentAuthenticationStorageTests: XCTestCase {

    var sut: PersistentAuthenticationStorage!
    var userDefaults: UserDefaults!
    var keychain: MockKeychainProtocol!

    override func setUp() {
        userDefaults = .temporary()
        keychain = MockKeychainProtocol()
        sut = PersistentAuthenticationStorage(
            userID: Scaffolding.userID,
            sharedUserDefaults: userDefaults,
            keychain: keychain
        )
    }

    override func tearDown() {
        sut = nil
        userDefaults = nil
        keychain = nil
    }

    // MARK: - Helpers

    private func assertStoredCookieData(
        _ storedCookieData: Data,
        equals cookie: HTTPCookie,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            let encryptionKey = try XCTUnwrap(userDefaults.data(forKey: "ZMCookieKey"))
            let actualHTTPCookies = try Scaffolding.decryptAndDecodeCookieData(
                storedCookieData,
                encryptionKey: encryptionKey
            )
            try assertCookies(
                actualHTTPCookies,
                equals: cookie
            )
        } catch {
            XCTFail(
                "failed to assert cookie data: \(error)",
                file: file,
                line: line
            )
        }
    }

    private func assertCookies(
        _ cookies: [HTTPCookie],
        equals cookie: HTTPCookie,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        try XCTAssertCount(cookies, count: 1)
        XCTAssertEqual(cookies[0].name, cookie.name)
        XCTAssertEqual(cookies[0].value, cookie.value)
        XCTAssertEqual(cookies[0].path, cookie.path)
        XCTAssertEqual(cookies[0].domain, cookie.domain)
    }

    // MARK: - Access token

    func testFetchAccessToken_Non_Exists() async {
        // When
        let accessToken = await sut.fetchAccessToken()

        // Then
        XCTAssertNil(accessToken)
    }

    func testStoreAccessToken_Then_Fetch() async throws {
        // When
        await sut.storeAccessToken(Scaffolding.accessToken)

        // Then
        let storedAccessToken = await sut.fetchAccessToken()
        XCTAssertEqual(storedAccessToken, Scaffolding.accessToken)
    }

    // MARK: - Cookies

    func testStoreCookies_No_Cookies() async throws {
        // Given
        let cookies = [HTTPCookie]()

        // Then
        await XCTAssertThrowsErrorAsync({
            // When
            try await sut.storeCookies(cookies)
        }, errorHandler: { error in
            guard case HTTPCookieCodecError.invalidCookies = error else {
                XCTFail("unexpected error: \(error)")
                return
            }
        })
    }

    func testStoreCookies_Invalid_Cookie() async throws {
        // Given
        let invalidCookie = try XCTUnwrap(Scaffolding.invalidCookie)

        // Then
        await XCTAssertThrowsErrorAsync({
            // When
            try await sut.storeCookies([invalidCookie])
        }, errorHandler: { error in
            guard case HTTPCookieCodecError.invalidCookies = error else {
                XCTFail("unexpected error: \(error)")
                return
            }
        })
    }

    func testStoreCookies_Adds_To_Keychain() async throws {
        // Given
        let validCookie = try XCTUnwrap(Scaffolding.validCookie)

        // Mock no existing cookie.
        keychain.fetchItemQueryResult_MockValue = errSecItemNotFound

        // Mock successul add.
        keychain.addItemQuery_MockValue = errSecSuccess

        // When
        try await sut.storeCookies([validCookie])

        // Then first we tried to fetch an existing cookie.
        let fetchInvocations = keychain.fetchItemQueryResult_Invocations
        try XCTAssertCount(fetchInvocations, count: 1)
        let fetchQuery = fetchInvocations[0].query

        XCTAssertEqual(fetchQuery[kSecAttrService] as? String, "Wire: Credentials for wire.com")
        XCTAssertEqual(fetchQuery[kSecAttrAccount] as? String, Scaffolding.userID.uuidString)
        XCTAssertEqual(fetchQuery[kSecClass] as! CFString, kSecClassGenericPassword)
        XCTAssertEqual(fetchQuery[kSecReturnData] as? Bool, true)

        // Then we added the new cookie.
        let addInvocations = keychain.addItemQuery_Invocations
        try XCTAssertCount(addInvocations, count: 1)
        let addQuery = addInvocations[0]

        XCTAssertEqual(addQuery[kSecAttrService] as? String, "Wire: Credentials for wire.com")
        XCTAssertEqual(addQuery[kSecAttrAccount] as? String, Scaffolding.userID.uuidString)
        XCTAssertEqual(addQuery[kSecClass] as! CFString, kSecClassGenericPassword)
        XCTAssertEqual(addQuery[kSecAttrAccessible] as! CFString, kSecAttrAccessibleAfterFirstUnlock)

        let encryptedCookieData = try XCTUnwrap(addQuery[kSecValueData] as? Data)
        assertStoredCookieData(encryptedCookieData, equals: validCookie)
    }

    func testStoreCookies_Updates_Keychain() async throws {
        // Given
        let validCookie = try XCTUnwrap(Scaffolding.validCookie)

        // Mock existing cookie.
        keychain.fetchItemQueryResult_MockMethod = { _, result in
            let data = Data("raw cookie".utf8).base64EncodedData()
            result?.pointee = data as AnyObject?
            return errSecSuccess
        }

        // Mock successul update.
        keychain.updateItemQueryAttributesToUpdate_MockValue = errSecSuccess

        // When
        try await sut.storeCookies([validCookie])

        // Then first we tried to fetch an existing cookie.
        let fetchInvocations = keychain.fetchItemQueryResult_Invocations
        try XCTAssertCount(fetchInvocations, count: 1)

        let fetchQuery1 = fetchInvocations[0].query
        XCTAssertEqual(fetchQuery1[kSecAttrService] as? String, "Wire: Credentials for wire.com")
        XCTAssertEqual(fetchQuery1[kSecAttrAccount] as? String, Scaffolding.userID.uuidString)
        XCTAssertEqual(fetchQuery1[kSecClass] as! CFString, kSecClassGenericPassword)
        XCTAssertEqual(fetchQuery1[kSecReturnData] as? Bool, true)

        // Then we updated the keychain with the new cookie.
        let updateInvocations = keychain.updateItemQueryAttributesToUpdate_Invocations
        try XCTAssertCount(updateInvocations, count: 1)

        let fetchQuery2 = updateInvocations[0].query
        XCTAssertEqual(fetchQuery2[kSecAttrService] as? String, "Wire: Credentials for wire.com")
        XCTAssertEqual(fetchQuery2[kSecAttrAccount] as? String, Scaffolding.userID.uuidString)
        XCTAssertEqual(fetchQuery2[kSecClass] as! CFString, kSecClassGenericPassword)
        XCTAssertEqual(fetchQuery2[kSecReturnData] as? Bool, true)

        let updateQuery = updateInvocations[0].attributesToUpdate
        XCTAssertEqual(updateQuery[kSecAttrService] as? String, "Wire: Credentials for wire.com")
        XCTAssertEqual(updateQuery[kSecAttrAccount] as? String, Scaffolding.userID.uuidString)
        XCTAssertEqual(updateQuery[kSecClass] as! CFString, kSecClassGenericPassword)

        let encryptedCookieData = try XCTUnwrap(updateQuery[kSecValueData] as? Data)
        assertStoredCookieData(encryptedCookieData, equals: validCookie)
    }

    func testFetchCookies_No_Cookies_EXist() async throws {
        // Mock no existing cookie.
        keychain.fetchItemQueryResult_MockValue = errSecItemNotFound

        // When
        let cookies = try await sut.fetchCookies()

        // Then
        XCTAssertTrue(cookies.isEmpty)
    }

    func testFetchCookies() async throws {
        // Given
        let validCookie = try XCTUnwrap(Scaffolding.validCookie)
        let encryptionKey = try AES256Crypto.generateRandomEncryptionKey()
        userDefaults.set(encryptionKey, forKey: "ZMCookieKey")
        let storedCookieData = try Scaffolding.encodeAndEncryptCookieData(
            for: [validCookie],
            encryptionKey: encryptionKey
        )

        // Mock existing cookie.
        keychain.fetchItemQueryResult_MockMethod = { _, result in
            result?.pointee = storedCookieData as AnyObject?
            return errSecSuccess
        }

        // When
        let cookies = try await sut.fetchCookies()

        // Then
        try assertCookies(
            cookies,
            equals: validCookie
        )
    }

}

private enum Scaffolding {

    static let userID = UUID()

    static let accessToken = AccessToken(
        userID: userID,
        token: "123456789",
        type: "Bearer",
        expirationDate: Date(timeIntervalSinceNow: 10)
    )

    static let invalidCookie = HTTPCookie(properties: [
        .name: "invalid-name",
        .path: "some path",
        .value: "some value",
        .domain: "some domain"
    ])

    static let validCookie = HTTPCookie(properties: [
        .name: "zuid",
        .path: "some path",
        .value: "some value",
        .domain: "some domain"
    ])

    static func encodeAndEncryptCookieData(
        for cookies: [HTTPCookie],
        encryptionKey: Data
    ) throws -> Data {
        let encodedData = try HTTPCookieCodec.encodeCookies(cookies)
        let encryptedData = try AES256Crypto.encryptAllAtOnceWithPrefixedIV(
            plaintext: encodedData,
            key: encryptionKey
        )
        return encryptedData.data.base64EncodedData()
    }

    static func decryptAndDecodeCookieData(
        _ base64CookieData: Data,
        encryptionKey: Data
    ) throws -> [HTTPCookie] {
        let encryptedData = try XCTUnwrap(Data(base64Encoded: base64CookieData))
        let decryptedData = try AES256Crypto.decryptAllAtOnceWithPrefixedIV(
            ciphertext: AES256Crypto.PrefixedData(data: encryptedData),
            key: encryptionKey
        )
        return try HTTPCookieCodec.decodeData(decryptedData)
    }

}
