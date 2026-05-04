//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireCrypto
import WireFoundation
import WireTestingPackage
import XCTest

@testable import WireFoundationSupport
@testable import WireNetwork

final class CookieStorageTests: XCTestCase {

    var sut: CookieStorage!
    var cookieEncryptionKey: Data!
    var keychain: KeychainProtocolMock!

    override func setUpWithError() throws {
        cookieEncryptionKey = try Scaffolding.cookieEncryptionKey()
        keychain = KeychainProtocolMock()
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
        await XCTAssertThrowsErrorAsync {
            // When
            try await sut.storeCookies(cookies)
        } errorHandler: { error in
            guard case HTTPCookieCodecError.invalidCookies = error else {
                XCTFail("unexpected error: \(error)")
                return
            }
        }
    }

    func testStoreCookies_Invalid_Cookie() async throws {
        // Given
        let invalidCookie = try XCTUnwrap(Scaffolding.invalidCookie)

        // Then
        await XCTAssertThrowsErrorAsync {
            // When
            try await sut.storeCookies([invalidCookie])
        } errorHandler: { error in
            guard case HTTPCookieCodecError.invalidCookies = error else {
                XCTFail("unexpected error: \(error)")
                return
            }
        }
    }

    func testStoreCookies_Adds_To_Keychain() async throws {
        // Given
        let validCookie = try XCTUnwrap(Scaffolding.validCookie)

        // Mock no existing cookie.
        await keychain.setFetchItemQuery_MockValue(nil)

        // Mock successul add.
        await keychain.setAddItemQuery_MockMethod { _ in }

        // When
        try await sut.storeCookies([validCookie])

        // Then first we tried to fetch an existing cookie.
        let fetchInvocations = await keychain.fetchItemQuery_Invocations
        try XCTAssertCount(fetchInvocations, count: 1)
        XCTAssertEqual(fetchInvocations[0], Scaffolding.fetchQuery)

        // Then we added the new cookie.
        let addInvocations = await keychain.addItemQuery_Invocations
        try XCTAssertCount(addInvocations, count: 1)
        try assertAddQuery(addInvocations[0], addedCookie: validCookie)
    }

    func testStoreCookies_Updates_Keychain() async throws {
        // Given
        let validCookie = try XCTUnwrap(Scaffolding.validCookie)

        // Mock existing cookie.
        let data = Data("raw cookie".utf8).base64EncodedData()
        await keychain.setFetchItemQuery_MockValue(data)

        // Mock successul update.
        await keychain.setUpdateItemQueryAttributesToUpdate_MockMethod { _, _ in }

        // When
        try await sut.storeCookies([validCookie])

        // Then first we tried to fetch an existing cookie.
        let fetchInvocations = await keychain.fetchItemQuery_Invocations
        try XCTAssertCount(fetchInvocations, count: 1)
        XCTAssertEqual(fetchInvocations[0], Scaffolding.fetchQuery)

        // Then we updated the keychain with the new cookie.
        let updateInvocations = await keychain.updateItemQueryAttributesToUpdate_Invocations
        try XCTAssertCount(updateInvocations, count: 1)

        XCTAssertEqual(updateInvocations[0].query, Scaffolding.baseQuery)
        try assertUpdateQuery(updateInvocations[0].attributesToUpdate, updatedCookie: validCookie)
    }

    func testFetchCookies_No_Cookies_EXist() async throws {
        // Mock no existing cookie.
        await keychain.setFetchItemQuery_MockValue(nil)

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
        await keychain.setFetchItemQuery_MockValue(storedCookieData)

        // When
        let cookies = try await sut.fetchCookies()

        // Then
        try assertCookies(
            cookies,
            equals: validCookie
        )
    }

    // MARK: - Helpers

    private func assertAddQuery(
        _ query: Set<KeychainQueryItem>,
        addedCookie: HTTPCookie,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        XCTAssertTrue(query.contains(.accessible(.afterFirstUnlock)), file: file, line: line)
        try assertUpdateQuery(query, updatedCookie: addedCookie, file: file, line: line)
    }

    private func assertUpdateQuery(
        _ query: Set<KeychainQueryItem>,
        updatedCookie: HTTPCookie,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        var storedData: Data?
        for item in query {
            if case let .data(data) = item {
                storedData = data
                break
            }
        }

        let encryptedCookieData = try XCTUnwrap(storedData, file: file, line: line)
        assertStoredCookieData(encryptedCookieData, equals: updatedCookie, file: file, line: line)
    }

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
                equals: cookie,
                file: file,
                line: line
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
        try XCTAssertCount(cookies, count: 1, file: file, line: line)
        XCTAssertEqual(cookies[0].name, cookie.name, file: file, line: line)
        XCTAssertEqual(cookies[0].value, cookie.value, file: file, line: line)
        XCTAssertEqual(cookies[0].path, cookie.path, file: file, line: line)
        XCTAssertEqual(cookies[0].domain, cookie.domain, file: file, line: line)
    }

}

private enum Scaffolding {

    static let userID = UUID()

    static func cookieEncryptionKey() throws -> Data {
        try AES256Crypto.generateRandomEncryptionKey()
    }

    static var baseQuery: Set<KeychainQueryItem> {
        [
            .service("Wire: Credentials for wire.com"),
            .account(userID.uuidString),
            .itemClass(.genericPassword)
        ]
    }

    static var fetchQuery: Set<KeychainQueryItem> {
        baseQuery.union([.returningData(true)])
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
