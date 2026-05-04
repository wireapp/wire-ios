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
public import WireFoundation

import WireCrypto

// sourcery: AutoMockable
public protocol CookieStorageProtocol: Sendable {

    func storeCookies(_ cookies: [HTTPCookie]) async throws
    func fetchCookies() async throws -> [HTTPCookie]
    func removeCookies() async throws
}

public actor CookieStorage: CookieStorageProtocol {

    enum Failure: Error {

        case malformedCookieData
        case failedToDecodeCookieData(any Error)
        case missingCookieEncryptionKey
        case failedToEncryptCookie(any Error)
        case failedToDecryptCookie(any Error)

    }

    private let userID: UUID
    private let cookieEncryptionKey: Data
    private let keychain: any KeychainProtocol

    private lazy var baseQuery: Set<KeychainQueryItem> = [
        .service("Wire: Credentials for wire.com"),
        .account(userID.uuidString),
        .itemClass(.genericPassword)
    ]

    private lazy var fetchQuery: Set<KeychainQueryItem> = {
        var result = baseQuery
        result.insert(.returningData(true))
        return result
    }()

    private func addQuery(cookieData: Data) -> Set<KeychainQueryItem> {
        var result = updateQuery(cookieData: cookieData)
        result.insert(.accessible(.afterFirstUnlock))
        return result
    }

    private func updateQuery(cookieData: Data) -> Set<KeychainQueryItem> {
        var result = baseQuery
        result.insert(.data(cookieData.base64EncodedData()))
        return result
    }

    public init(
        userID: UUID,
        cookieEncryptionKey: Data,
        keychain: any KeychainProtocol
    ) {
        self.userID = userID
        self.cookieEncryptionKey = cookieEncryptionKey
        self.keychain = keychain
    }

    /// Store cookies.
    ///
    /// Cookie data is stored in the device keychain and may persist across
    /// different installations of the application, such as when the app is
    /// deleted without the user logging out.
    ///
    /// - Parameter cookies: The cookies to store.

    public func storeCookies(_ cookies: [HTTPCookie]) async throws {
        let cookieData = try HTTPCookieCodec.encodeCookies(cookies)
        try await storeCookieData(cookieData)
    }

    /// Fetch stored cookies.
    ///
    /// Note: Cookie data may be persisted across installations for the same
    /// account, however it is likely that fetching an old cookie would result
    /// in a decoding error.
    ///
    /// - Returns: The stored cookies.

    public func fetchCookies() async throws -> [HTTPCookie] {
        guard let cookieData = try await fetchCookieData() else {
            return []
        }

        return try HTTPCookieCodec.decodeData(cookieData)
    }

    /// Remove stored cookies from the keychain.
    ///
    /// This will delete any cookie data associated with the current user ID
    /// from the device keychain. This operation is irreversible and is typically
    /// used during logout or account removal.
    ///
    /// - Throws: An error if the keychain deletion fails.

    public func removeCookies() async throws {
        try await keychain.deleteItem(query: baseQuery)
    }

    // MARK: - Cookie data

    private func storeCookieData(_ cookieData: Data) async throws {
        let encryptedCookieData: Data
        do {
            encryptedCookieData = try AES256Crypto.encryptAllAtOnceWithPrefixedIV(
                plaintext: cookieData,
                key: cookieEncryptionKey
            ).data
        } catch {
            throw Failure.failedToEncryptCookie(error)
        }

        if try await fetchCookieData() != nil {
            try await updateCookieInKeychain(encryptedCookieData)
        } else {
            try await addCookieToKeychain(encryptedCookieData)
        }
    }

    private func fetchCookieData() async throws -> Data? {
        guard let encryptedCookieData = try await fetchCookieDataFromKeychain() else {
            return nil
        }

        do {
            return try AES256Crypto.decryptAllAtOnceWithPrefixedIV(
                ciphertext: AES256Crypto.PrefixedData(data: encryptedCookieData),
                key: cookieEncryptionKey
            )
        } catch {
            throw Failure.failedToDecryptCookie(error)
        }
    }

    // MARK: - Keychain

    private func addCookieToKeychain(_ cookieData: Data) async throws {
        let query = addQuery(cookieData: cookieData)
        try await keychain.addItem(query: query)
    }

    private func updateCookieInKeychain(_ cookieData: Data) async throws {
        let updateQuery: Set<KeychainQueryItem> = [.data(cookieData.base64EncodedData())]
        try await keychain.updateItem(query: baseQuery, attributesToUpdate: updateQuery)
    }

    private func fetchCookieDataFromKeychain() async throws -> Data? {
        guard let base64CookieData: Data = try await keychain.fetchItem(query: fetchQuery) else {
            return nil
        }

        guard let cookieData = Data(base64Encoded: base64CookieData) else {
            throw Failure.malformedCookieData
        }

        return cookieData
    }

}
