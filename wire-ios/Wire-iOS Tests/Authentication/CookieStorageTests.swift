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
import WireFoundationSupport

@testable import WireNetwork

@Suite(.serialized)
final class CookieStorageTests {

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

    // MARK: - Store

    @Test()
    func `test store cookies when no existing cookies for that user`() throws {
        // Given
        let cookie = Scaffolding.validCookieA
        let userID = UUID()
        let epoch = UUID()

        // When
        try sut.storeCookies([cookie], userID: userID, epoch: epoch)

        // Then
        let item = try #require(try fetchItemFromKeychain(userID: userID))
        #expect(item.epoch == epoch)
        #expect(item.accessible == kSecAttrAccessibleAfterFirstUnlock)

        let cookieData = try #require(item.secureValue)
        let decodedCookies = try Self.decryptAndDecodeCookieData(cookieData, encryptionKey: encryptionKey)
        #expect(decodedCookies == [cookie])
    }

    @Test()
    func `test store cookies when existing cookies for that user`() throws {
        // Given
        let userID = UUID()
        let initialEpoch = UUID()
        let updatedEpoch = UUID()

        try sut.storeCookies([Scaffolding.validCookieA], userID: userID, epoch: initialEpoch)

        // When
        try sut.storeCookies([Scaffolding.validCookieB], userID: userID, epoch: updatedEpoch)

        // Then
        let item = try #require(try fetchItemFromKeychain(userID: userID))
        #expect(item.epoch == updatedEpoch)
        #expect(item.accessible == kSecAttrAccessibleAfterFirstUnlock)

        let cookieData = try #require(item.secureValue)
        let decodedCookies = try Self.decryptAndDecodeCookieData(cookieData, encryptionKey: encryptionKey)
        #expect(decodedCookies == [Scaffolding.validCookieB])
    }

    @Test()
    func `test store cookies with invalid cookie`() throws {
        // Given
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
        let userID = UUID()

        // When / Then
        #expect(throws: HTTPCookieCodecError.invalidCookies) {
            try sut.storeCookies([], userID: userID)
        }

        #expect(try fetchItemFromKeychain(userID: userID) == nil)
    }

    // MARK: - Fetch

    @Test()
    func `test fetch cookies when no existing cookies for that user`() throws {
        // Given, When
        let cookies = try sut.fetchCookies(userID: UUID())

        // Then
        #expect(cookies.isEmpty)
    }

    @Test()
    func `test fetch cookies when existing cookies for that user`() throws {
        // Given
        let userID = UUID()
        try sut.storeCookies([Scaffolding.validCookieA], userID: userID)

        // When
        let cookies = try sut.fetchCookies(userID: userID)

        // Then
        #expect(cookies == [Scaffolding.validCookieA])
    }

    @Test()
    func `test fetch cookies repairs missing epoch`() throws {
        // Given
        let userID = UUID()
        let cookieData = try Self.encodeAndEncryptCookieData(
            for: [Scaffolding.validCookieA],
            encryptionKey: encryptionKey
        )

        try keychain.addItem(query: [
            .service("Wire: Credentials for wire.com"),
            .account(userID.uuidString),
            .itemClass(.genericPassword),
            .data(cookieData),
            .accessible(.afterFirstUnlock)
        ])

        // When
        let cookies = try sut.fetchCookies(userID: userID)

        // Then
        #expect(cookies == [Scaffolding.validCookieA])

        let item = try #require(try fetchItemFromKeychain(userID: userID))
        #expect(item.epoch != nil)

        let newCookieData = try #require(item.secureValue)
        let decodedCookies = try Self.decryptAndDecodeCookieData(newCookieData, encryptionKey: encryptionKey)
        #expect(decodedCookies == [Scaffolding.validCookieA])
    }

    @Test()
    func `test fetch cookies with different encryption key throws an error`() throws {
        // Given
        let userID = UUID()
        try sut.storeCookies([Scaffolding.validCookieA], userID: userID)

        let differentEncryptionKey = try AES256Crypto.generateRandomEncryptionKey()
        let sutWithDifferentKey = CookieStorage(
            cookieEncryptionKey: differentEncryptionKey,
            keychain: keychain,
            cache: CookieStorageCache(sharedStorage: .init(initialState: [:]))
        )

        #expect {
            _ = try sutWithDifferentKey.fetchCookies(userID: userID)
        } throws: { error in
            switch error {
            case HTTPCookieCodecError.invalidCookieData:
                true
            default:
                false
            }
        }

    }

    // MARK: - Remove

    @Test()
    func `test remove cookies deletes existing cookies for that user`() throws {
        // Given
        let userID = UUID()
        try sut.storeCookies([Scaffolding.validCookieA], userID: userID)

        // When
        try sut.removeCookies(userID: userID)

        // Then
        #expect(try fetchItemFromKeychain(userID: userID) == nil)
    }

    @Test()
    func `test remove cookies results in empty fetch for that user`() throws {
        // Given
        let userID = UUID()
        try sut.storeCookies([Scaffolding.validCookieA], userID: userID)

        // When
        try sut.removeCookies(userID: userID)
        let cookies = try sut.fetchCookies(userID: userID)

        // Then
        #expect(cookies.isEmpty)
    }

    @Test()
    func `test remove cookies does not delete cookies for another user`() throws {
        // Given
        let userA = UUID()
        let userB = UUID()

        try sut.storeCookies([Scaffolding.validCookieA], userID: userA)
        try sut.storeCookies([Scaffolding.validCookieB], userID: userB)

        // When
        try sut.removeCookies(userID: userA)

        // Then
        #expect(try sut.fetchCookies(userID: userA).isEmpty)
        #expect(try sut.fetchCookies(userID: userB) == [Scaffolding.validCookieB])
    }

    // MARK: - Caching

    @Test()
    func `test fetch cookies uses in memory cache`() throws {
        // Given
        let userID = UUID()
        let keychain = KeychainSpy(keychain: keychain)
        let sut = CookieStorage(
            cookieEncryptionKey: encryptionKey,
            keychain: keychain,
            cache: CookieStorageCache(sharedStorage: CookieStorageCache.sharedStorage)
        )
        try sut.storeCookies([Scaffolding.validCookieA], userID: userID)

        // When - 1st fetch should fetch both data and attributes (for the epoch)
        let firstFetch = try sut.fetchCookies(userID: userID)

        // Then
        #expect(firstFetch == [Scaffolding.validCookieA])
        #expect(keychain.fetchItem_Invocations == [
            [
                .service("Wire: Credentials for wire.com"),
                .account(userID.uuidString),
                .itemClass(.genericPassword),
                .returningData(true)
            ],
            [
                .service("Wire: Credentials for wire.com"),
                .account(userID.uuidString),
                .itemClass(.genericPassword),
                .returningData(false),
                .returningAttributes(true)
            ]
        ])

        // When - 2nd fetch should fetch only the attributes (for the epoch), not cookie data.
        keychain.fetchItem_Invocations.removeAll()
        let secondFetch = try sut.fetchCookies(userID: userID)

        // Then
        #expect(secondFetch == [Scaffolding.validCookieA])
        #expect(keychain.fetchItem_Invocations == [
            [
                .service("Wire: Credentials for wire.com"),
                .account(userID.uuidString),
                .itemClass(.genericPassword),
                .returningData(false),
                .returningAttributes(true)
            ]
        ])
    }

    @Test()
    func `test cache is invalidated if item deleted from keychain`() throws {
        // Given
        let userID = UUID()
        try sut.storeCookies([Scaffolding.validCookieA], userID: userID)

        // When
        let firstFetch = try sut.fetchCookies(userID: userID)

        // Then
        #expect(firstFetch == [Scaffolding.validCookieA])

        // When
        try Keychain().reset()
        let secondFetch = try sut.fetchCookies(userID: userID)

        // Then
        #expect(secondFetch == [])
    }

    @Test()
    func `test cache is invalidated if item updated in keychain`() throws {
        // Given
        let userID = UUID()
        let sutA = CookieStorage(
            cookieEncryptionKey: encryptionKey,
            keychain: keychain,
            cache: CookieStorageCache(sharedStorage: .init(initialState: [:]))
        )
        let sutB = CookieStorage(
            cookieEncryptionKey: encryptionKey,
            keychain: keychain,
            cache: CookieStorageCache(sharedStorage: .init(initialState: [:]))
        )
        try sutA.storeCookies([Scaffolding.validCookieA], userID: userID)

        // When cookies are updated from SUT B
        try sutB.storeCookies([Scaffolding.validCookieB], userID: userID) // <- SUT B

        // Then cache is invalidated in SUT A
        #expect(try sutA.fetchCookies(userID: userID) == [Scaffolding.validCookieB])
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

    private static func encodeAndEncryptCookieData(
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

    private static func decryptAndDecodeCookieData(
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

// MARK: - Helpers

private enum Scaffolding {

    static let invalidCookie = HTTPCookie(properties: [
        .name: "invalid-name",
        .path: "some path",
        .value: "some value",
        .domain: "some domain"
    ])!

    static let validCookieA = HTTPCookie(properties: [
        .name: "zuid",
        .path: "some path",
        .value: "some value A",
        .domain: "some domain"
    ])!

    static let validCookieB = HTTPCookie(properties: [
        .name: "zuid",
        .path: "some path",
        .value: "some value B",
        .domain: "some domain"
    ])!

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
        withUnsafeBytes(of: uuid) { Data($0) }
    }

}

private final class KeychainSpy: KeychainProtocol, @unchecked Sendable {

    let keychain: WireFoundation.Keychain
    var fetchItem_Invocations: [Set<KeychainQueryItem>] = []

    init(keychain: WireFoundation.Keychain) {
        self.keychain = keychain
    }

    func addItem(query: Set<WireFoundation.KeychainQueryItem>) throws {
        try keychain.addItem(query: query)
    }

    func updateItem(
        query: Set<WireFoundation.KeychainQueryItem>,
        attributesToUpdate: Set<WireFoundation.KeychainQueryItem>
    ) throws {
        try keychain.updateItem(query: query, attributesToUpdate: attributesToUpdate)
    }

    func fetchItem<T>(query: Set<WireFoundation.KeychainQueryItem>) throws -> T? {
        fetchItem_Invocations.append(query)
        return try keychain.fetchItem(query: query)
    }

    func deleteItem(query: Set<WireFoundation.KeychainQueryItem>) throws {
        try keychain.deleteItem(query: query)
    }

}
