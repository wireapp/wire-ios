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

    func storeCookies(_ cookies: [HTTPCookie]) throws
    func fetchCookies() throws -> [HTTPCookie]
    func removeCookies() throws
}

public struct CookieStorage: CookieStorageProtocol, Sendable {

    enum Failure: Error {

        case malformedCookieData
        case failedToEncryptCookie(any Error)
        case failedToDecryptCookie(any Error)

    }

    private let storage: OSAllocatedUnfairLock<_CookieStorage>

    public init(
        userID: UUID,
        cookieEncryptionKey: Data,
        keychain: any KeychainProtocol
    ) {
        storage = OSAllocatedUnfairLock(
            initialState: _CookieStorage(
                userID: userID,
                cookieEncryptionKey: cookieEncryptionKey,
                keychain: keychain
            )
        )
    }

    /// Store cookies.
    ///
    /// Cookie data is stored in the device keychain and may persist across
    /// different installations of the application, such as when the app is
    /// deleted without the user logging out.
    ///
    /// - Parameter cookies: The cookies to store.

    public func storeCookies(_ cookies: [HTTPCookie]) throws {
        try storage.withLock { try $0.storeCookies(cookies) }
    }

    /// Fetch stored cookies.
    ///
    /// Note: Cookie data may be persisted across installations for the same
    /// account, however it is likely that fetching an old cookie would result
    /// in a decoding error.
    ///
    /// - Returns: The stored cookies.

    public func fetchCookies() throws -> [HTTPCookie] {
        try storage.withLock { try $0.fetchCookies() }
    }

    /// Remove stored cookies from the keychain.
    ///
    /// This will delete any cookie data associated with the current user ID
    /// from the device keychain. This operation is irreversible and is typically
    /// used during logout or account removal.
    ///
    /// - Throws: An error if the keychain deletion fails.

    public func removeCookies() throws {
        try storage.withLock { try $0.removeCookies() }
    }

}

// MARK: - Private implementation

/// To allow for simple locking of the cookie storage operations, we encapsulate the actual storage logic in a separate
/// class.

private final class _CookieStorage: Sendable {

    private let userID: UUID
    private let cookieEncryptionKey: Data
    private let keychain: any KeychainProtocol

    init(
        userID: UUID,
        cookieEncryptionKey: Data,
        keychain: any KeychainProtocol
    ) {
        self.userID = userID
        self.cookieEncryptionKey = cookieEncryptionKey
        self.keychain = keychain
    }

    func storeCookies(_ cookies: [HTTPCookie]) throws {
        let cookieData = try Self.encodeAndEncryptCookies(cookies, key: cookieEncryptionKey)

        do {
            // The typical case is updating so try that first.
            try keychain.updateItem(query: baseQuery(), attributesToUpdate: [.data(cookieData)])
        } catch let KeychainError.errorStatus(status) where status == errSecItemNotFound {
            try keychain.addItem(query: addQuery(cookieData: cookieData))
        }
    }

    func fetchCookies() throws -> [HTTPCookie] {
        guard let data: Data = try keychain.fetchItem(query: fetchQuery()) else {
            return []
        }

        return try Self.decryptAndDecodeCookies(data, key: cookieEncryptionKey)
    }

    func removeCookies() throws {
        try keychain.deleteItem(query: baseQuery())
    }

    // MARK: - Queries

    private func baseQuery() -> Set<KeychainQueryItem> {
        [
            .service("Wire: Credentials for wire.com"),
            .account(userID.uuidString),
            .itemClass(.genericPassword)
        ]
    }

    private func fetchQuery() -> Set<KeychainQueryItem> {
        var query = baseQuery()
        query.insert(.returningData(true))
        return query
    }

    private func addQuery(cookieData: Data) -> Set<KeychainQueryItem> {
        var query = baseQuery()
        query.insert(.data(cookieData))
        query.insert(.accessible(.afterFirstUnlock))
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
