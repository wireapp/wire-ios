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

final class CookieStorageTests: XCTestCase {

    var sut: CookieStorage!
    var cookieEncryptionKey: Data!
    var keychain: MockKeychainProtocol!

    override func setUpWithError() throws {
        cookieEncryptionKey = try Scaffolding.cookieEncryptionKey()
        keychain = MockKeychainProtocol()
        sut = CookieStorage(
            userID: Scaffolding.userID,
            cookieEncryptionKey: cookieEncryptionKey,
            keychain: keychain
        )
    }

    override func tearDown() {
        cookieEncryptionKey = nil
        keychain = nil
        sut = nil
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
        let storedCookieData = try Scaffolding.encodeAndEncryptCookieData(
            for: [validCookie],
            encryptionKey: cookieEncryptionKey
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

    // MARK: - Helpers

    private func assertStoredCookieData(
        _ storedCookieData: Data,
        equals cookie: HTTPCookie,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            let actualHTTPCookies = try Scaffolding.decryptAndDecodeCookieData(
                storedCookieData,
                encryptionKey: cookieEncryptionKey
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

}

private enum Scaffolding {

    static let userID = UUID()

    static func cookieEncryptionKey() throws -> Data {
        try AES256Crypto.generateRandomEncryptionKey()
    }

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

