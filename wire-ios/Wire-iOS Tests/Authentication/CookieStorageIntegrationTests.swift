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

import Foundation
import Testing
import WireCrypto
import WireFoundation

@testable import WireNetwork

@Suite(.serialized)
final class CookieStorageIntegrationTests {

    private let encryptionKey: Data
    private let keychain = Keychain()
    private let sut: CookieStorage

    init() throws {
        self.encryptionKey = try AES256Crypto.generateRandomEncryptionKey()
        self.sut = CookieStorage(cookieEncryptionKey: encryptionKey)

        try keychain.reset()
    }

    deinit {
        try? keychain.reset()
    }

    @Test()
    func `test store cookies when no existing cookies for that user`() throws {
        // Given
        try keychain.reset()
        let cookie = Scaffolding.validCookie
        let userID = UUID()
        let epoch = UUID()

        // When
        try sut.storeCookies([cookie], userID: userID, epoch: epoch)

        // Then
        let item = try #require(try fetchItemFromKeychain(userID: userID))
        #expect(item.epoch == epoch)
        #expect(item.accessible == kSecAttrAccessibleAfterFirstUnlock)

        let cookieData = try #require(item.secureValue)
        let decodedCookies = try Scaffolding.decryptAndDecodeCookieData(cookieData, encryptionKey: encryptionKey)
        #expect(decodedCookies == [cookie])
    }

    @Test()
    func `test store cookies when existing cookies for that user`() throws {
        // Given
        try keychain.reset()
        let userID = UUID()
        let initialEpoch = UUID()
        let updatedEpoch = UUID()

        try sut.storeCookies([Scaffolding.validCookie], userID: userID, epoch: initialEpoch)

        // When
        try sut.storeCookies([Scaffolding.updatedCookie], userID: userID, epoch: updatedEpoch)

        // Then
        let item = try #require(try fetchItemFromKeychain(userID: userID))
        #expect(item.epoch == updatedEpoch)
        #expect(item.accessible == kSecAttrAccessibleAfterFirstUnlock)

        let cookieData = try #require(item.secureValue)
        let decodedCookies = try Scaffolding.decryptAndDecodeCookieData(cookieData, encryptionKey: encryptionKey)
        #expect(decodedCookies == [Scaffolding.updatedCookie])
    }

    @Test()
    func `test store cookies with invalid cookie`() throws {
        // Given
        try keychain.reset()
        let userID = UUID()

        // When / Then
        #expect(throws: HTTPCookieCodecError.invalidCookies) {
            try sut.storeCookies([Scaffolding.invalidCookie], userID: userID)
        }

        #expect(try fetchItemFromKeychain(userID: userID) == nil)
    }

    @Test()
    func `test store cookies with empty array`() throws {
        // Given
        try keychain.reset()
        let userID = UUID()

        // When / Then
        #expect(throws: HTTPCookieCodecError.invalidCookies) {
            try sut.storeCookies([], userID: userID)
        }

        #expect(try fetchItemFromKeychain(userID: userID) == nil)
    }

    @Test()
    func `test fetch cookies when no existing cookies for that user`() throws {
        // Given
        try keychain.reset()

        // When
        let cookies = try sut.fetchCookies(userID: UUID())

        // Then
        #expect(cookies.isEmpty)
    }

    @Test()
    func `test fetch cookies when existing cookies for that user`() throws {
        // Given
        try keychain.reset()
        let userID = UUID()
        try sut.storeCookies([Scaffolding.validCookie], userID: userID)

        // When
        let cookies = try sut.fetchCookies(userID: userID)

        // Then
        #expect(cookies == [Scaffolding.validCookie])
    }

    @Test()
    func `test fetch cookies repairs missing epoch`() throws {
        // Given
        try keychain.reset()
        let userID = UUID()
        let cookieData = try Scaffolding.encodeAndEncryptCookieData(
            for: [Scaffolding.validCookie],
            encryptionKey: encryptionKey
        )
        try addItemToKeychain(userID: userID, cookieData: cookieData, epoch: nil)

        // When
        let cookies = try sut.fetchCookies(userID: userID)

        // Then
        #expect(cookies == [Scaffolding.validCookie])

        let item = try #require(try fetchItemFromKeychain(userID: userID))
        #expect(item.epoch != nil)

        let newCookieData = try #require(item.secureValue)
        let decodedCookies = try Scaffolding.decryptAndDecodeCookieData(newCookieData, encryptionKey: encryptionKey)
        #expect(decodedCookies == [Scaffolding.validCookie])
    }

    // MARK: - Helpers

    private func fetchItemFromKeychain(userID: UUID) throws -> [CFString: Any]? {
        let query: Set<KeychainQueryItem> = [
            .service("Wire: Credentials for wire.com"),
            .account(userID.uuidString),
            .itemClass(.genericPassword),
            .returningData(true),
            .returningAttributes(true)
        ]

        return try keychain.fetchItem(query: query)
    }

    private func addItemToKeychain(userID: UUID, cookieData: Data, epoch: UUID?) throws {
        var query: Set<KeychainQueryItem> = [
            .service("Wire: Credentials for wire.com"),
            .account(userID.uuidString),
            .itemClass(.genericPassword),
            .data(cookieData),
            .accessible(.afterFirstUnlock)
        ]

        if let epoch {
            query.insert(.generic(epoch.data))
        }

        try keychain.addItem(query: query)
    }

}

// MARK: - Helpers

private enum Scaffolding {

    static let invalidCookie = HTTPCookie(properties: [
        .name: "invalid-name",
        .path: "some path",
        .value: "some value",
        .domain: "some domain"
    ])!

    static let validCookie = HTTPCookie(properties: [
        .name: "zuid",
        .path: "some path",
        .value: "some value",
        .domain: "some domain"
    ])!

    static let updatedCookie = HTTPCookie(properties: [
        .name: "zuid",
        .path: "some path",
        .value: "some updated value",
        .domain: "some domain"
    ])!

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
        let encryptedData = try #require(Data(base64Encoded: base64CookieData))
        let decryptedData = try AES256Crypto.decryptAllAtOnceWithPrefixedIV(
            ciphertext: AES256Crypto.PrefixedData(data: encryptedData),
            key: encryptionKey
        )
        return try HTTPCookieCodec.decodeData(decryptedData)
    }

}


private extension [CFString: Any] {

    var accessible: CFString? {
        guard let value = self[kSecAttrAccessible] as? String else { return nil }
        return value as CFString
    }

    var epoch: UUID? {
        guard let epochData = self[kSecAttrGeneric] as? Data else { return nil }
        return epochData.withUnsafeBytes { $0.load(as: UUID.self) }
    }

    var secureValue: Data? {
        self[kSecValueData] as? Data
    }

}

private extension UUID {

    var data: Data {
        withUnsafeBytes(of: self.uuid) { Data($0) }
    }

}
