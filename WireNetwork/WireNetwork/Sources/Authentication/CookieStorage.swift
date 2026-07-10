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

public import Foundation
import os
public import WireFoundation

import WireCrypto

// sourcery: AutoMockable
public protocol CookieStorageProtocol: Sendable {

    func storeCookies(_ cookies: [HTTPCookie], userID: UUID) throws
    func fetchCookies(userID: UUID) throws -> [HTTPCookie]
    func removeCookies(userID: UUID) throws
}

/// A cache for cookies, keyed by user ID.
///
/// This class is thread-safe and can be shared across multiple `CookieStorage` instances.
/// It is intended to be used as a singleton within a process to avoid redundant keychain reads.

public final class CookieStorageCache: Sendable {

    public struct Item: Sendable {
        let cookies: [HTTPCookie]
        let epoch: UUID
    }

    public static let sharedStorage = OSAllocatedUnfairLock<[UUID: Item]>(initialState: [:])

    private let cache: OSAllocatedUnfairLock<[UUID: Item]>

    public init(sharedStorage: OSAllocatedUnfairLock<[UUID: Item]> = CookieStorageCache.sharedStorage) {
        self.cache = sharedStorage
    }

    func get(for userID: UUID) -> Item? {
        cache.withLock { $0[userID] }
    }

    func set(_ item: Item, for userID: UUID) {
        cache.withLock { $0[userID] = item }
    }

    func remove(for userID: UUID) {
        cache.withLock { $0[userID] = nil }
    }

    func removeAll() {
        cache.withLock { $0.removeAll() }
    }

}

public struct CookieStorage: CookieStorageProtocol, Sendable {

    enum Failure: Error {

        case malformedCookieData
        case failedToEncryptCookie(any Error)
        case failedToDecryptCookie(any Error)

    }

    private static let lock = OSAllocatedUnfairLock()

    private let cookieEncryptionKey: Data
    private let keychain: any KeychainProtocol
    private let cache: CookieStorageCache

    /// Creates a new `CookieStorage`.
    ///
    /// - Parameters:
    ///  - cookieEncryptionKey: A key used to encrypt and decrypt cookie data. This key should be stored in defaults
    ///  so that it is destroyed when the app is deleted.

    public init(
        cookieEncryptionKey: Data
    ) {
        self.cookieEncryptionKey = cookieEncryptionKey
        self.keychain = Keychain()
        self.cache = CookieStorageCache()
    }

    #if DEBUG
        /// Creates a new `CookieStorage` with injected dependencies for testing purposes only.
        public init(
            cookieEncryptionKey: Data,
            keychain: any KeychainProtocol,
            cache: CookieStorageCache
        ) {
            self.cookieEncryptionKey = cookieEncryptionKey
            self.keychain = keychain
            self.cache = cache
        }
    #endif

    /// Store cookies.
    ///
    /// Cookie data is stored in the device keychain and may persist across
    /// different installations of the application, such as when the app is
    /// deleted without the user logging out.
    ///
    /// - Parameters:
    ///   - cookies: The cookies to store.
    ///   - userID: The unique identifier for the user whose cookies are being stored.

    public func storeCookies(_ cookies: [HTTPCookie], userID: UUID) throws {
        try storeCookies(cookies, userID: userID, epoch: UUID())
    }

    /// Store cookies with a specific epoch. This is intended for testing purposes only.

    func storeCookies(_ cookies: [HTTPCookie], userID: UUID, epoch: UUID) throws {
        try Self.lock.withLock {
            try makeStorage(userID: userID).storeCookies(cookies, epoch: epoch)
        }
    }

    /// Fetch stored cookies.
    ///
    /// Note: Cookie data may be persisted across installations for the same
    /// account, however it is likely that fetching an old cookie would result
    /// in a decoding error.
    ///
    /// - Parameter userID: The unique identifier for the user whose cookies are being fetched.
    /// - Returns: The stored cookies.

    public func fetchCookies(userID: UUID) throws -> [HTTPCookie] {
        try Self.lock.withLock {
            try makeStorage(userID: userID).fetchCookies()
        }
    }

    /// Remove stored cookies from the keychain.
    ///
    /// This will delete any cookie data associated with the given user ID
    /// from the device keychain. This operation is irreversible and is typically
    /// used during logout or account removal.
    ///
    /// - Parameter userID: The unique identifier for the user whose cookies are being removed.
    /// - Throws: An error if the keychain deletion fails.

    public func removeCookies(userID: UUID) throws {
        try Self.lock.withLock {
            try makeStorage(userID: userID).removeCookies()
        }
    }

    // MARK: - Helper

    private func makeStorage(userID: UUID) -> _CookieStorage {
        _CookieStorage(
            userID: userID,
            cookieEncryptionKey: cookieEncryptionKey,
            keychain: keychain,
            cache: cache
        )
    }

}

// MARK: - Private implementation

/// To allow for simple locking of the cookie storage operations, we encapsulate the actual storage logic in a separate
/// class.

private final class _CookieStorage: Sendable {

    private let userID: UUID
    private let cookieEncryptionKey: Data
    private let keychain: any KeychainProtocol
    private let cache: CookieStorageCache

    init(
        userID: UUID,
        cookieEncryptionKey: Data,
        keychain: any KeychainProtocol,
        cache: CookieStorageCache
    ) {
        self.userID = userID
        self.cookieEncryptionKey = cookieEncryptionKey
        self.keychain = keychain
        self.cache = cache
    }

    func storeCookies(_ cookies: [HTTPCookie], epoch: UUID) throws {
        let newEpoch = epoch.data
        let cookieData = try Self.encodeAndEncryptCookies(cookies, key: cookieEncryptionKey)

        do {
            // The typical case is updating so try that first.
            try keychain.updateItem(query: baseQuery(), attributesToUpdate: [.data(cookieData), .generic(newEpoch)])
        } catch let KeychainError.errorStatus(status) where status == errSecItemNotFound {
            try keychain.addItem(query: addQuery(cookieData: cookieData, epoch: newEpoch))
        }
    }

    func fetchCookies() throws -> [HTTPCookie] {
        if let cached = cache.get(for: userID), let epoch = try fetchEpochFromKeychain(), cached.epoch == epoch {
            return cached.cookies
        }

        guard let cookiesAndEpoch = try fetchCookiesFromKeychain() else { return [] }
        cache.set(.init(cookies: cookiesAndEpoch.cookies, epoch: cookiesAndEpoch.epoch), for: userID)
        return cookiesAndEpoch.cookies
    }

    func removeCookies() throws {
        try keychain.deleteItem(query: baseQuery())
        cache.remove(for: userID)
    }

    // MARK: - Fetching

    private func fetchCookiesFromKeychain() throws -> (cookies: [HTTPCookie], epoch: UUID)? {
        guard let data: Data = try keychain.fetchItem(query: fetchValueQuery()) else { return nil }
        let cookies = try Self.decryptAndDecodeCookies(data, key: cookieEncryptionKey)

        if let epoch = try fetchEpochFromKeychain() {
            return (cookies, epoch)
        } else {
            let newEpoch = UUID()
            try storeCookies(cookies, epoch: newEpoch)
            return (cookies, newEpoch)
        }
    }

    private func fetchEpochFromKeychain() throws -> UUID? {
        guard let attributes: [String: Any] = try keychain.fetchItem(query: fetchAttributesQuery()),
              let epochData = attributes[kSecAttrGeneric as String] as? Data,
              epochData.count == MemoryLayout<UUID>.size else {
            return nil
        }

        return epochData.withUnsafeBytes { $0.load(as: UUID.self) }
    }

    // MARK: - Queries

    private func baseQuery() -> Set<KeychainQueryItem> {
        [
            .service("Wire: Credentials for wire.com"),
            .account(userID.uuidString),
            .itemClass(.genericPassword)
        ]
    }

    private func fetchValueQuery() -> Set<KeychainQueryItem> {
        var query = baseQuery()
        query.insert(.returningData(true))
        return query
    }

    private func addQuery(cookieData: Data, epoch: Data) -> Set<KeychainQueryItem> {
        var query = baseQuery()
        query.insert(.data(cookieData))
        query.insert(.accessible(.afterFirstUnlock))
        query.insert(.generic(epoch))
        return query
    }

    private func fetchAttributesQuery() -> Set<KeychainQueryItem> {
        var query = baseQuery()
        query.insert(.returningData(false))
        query.insert(.returningAttributes(true))
        return query
    }

    // MARK: - Cookie encoding / decoding

    private static func encodeAndEncryptCookies(_ cookies: [HTTPCookie], key: Data) throws -> Data {
        let cookieData = try HTTPCookieCodec.encodeCookies(cookies)

        let encryptedData: Data
        do {
            encryptedData = try AES256Crypto.encryptAllAtOnceWithPrefixedIV(
                plaintext: cookieData,
                key: key
            ).data
        } catch {
            throw CookieStorage.Failure.failedToEncryptCookie(error)
        }

        return encryptedData.base64EncodedData()
    }

    private static func decryptAndDecodeCookies(_ base64Data: Data, key: Data) throws -> [HTTPCookie] {
        guard let encryptedData = Data(base64Encoded: base64Data) else {
            throw CookieStorage.Failure.malformedCookieData
        }

        let cookieData: Data
        do {
            cookieData = try AES256Crypto.decryptAllAtOnceWithPrefixedIV(
                ciphertext: AES256Crypto.PrefixedData(data: encryptedData),
                key: key
            )
        } catch {
            throw CookieStorage.Failure.failedToDecryptCookie(error)
        }

        return try HTTPCookieCodec.decodeData(cookieData)
    }

}

private extension UUID {

    var data: Data {
        withUnsafeBytes(of: uuid) { Data($0) }
    }

}
