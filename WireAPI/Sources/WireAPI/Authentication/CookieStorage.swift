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
import WireFoundation

// sourcery: AutoMockable
protocol CookieStorageProtocol: Sendable {

    func storeCookies(_ cookies: [HTTPCookie]) async throws
    func fetchCookies() async throws -> [HTTPCookie]

}

actor CookieStorage: CookieStorageProtocol {

    enum Failure: Error {

        case malformedCookieData
        case failedToDecodeCookieData(any Error)
        case failedKeychainFetch(status: Int32?)
        case failedKeychainAdd(status: Int32)
        case failedKeychainUpdate(status: Int32)
        case missingCookieEncryptionKey
        case failedToEncryptCookie(any Error)
        case failedToDecryptCookie(any Error)

    }

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

    /// Store cookies.
    ///
    /// Cookie data is stored in the device keychain and may persist across
    /// different installations of the application, such as when the app is
    /// deleted without the user logging out.
    ///
    /// - Parameter cookies: The cookies to store.

    func storeCookies(_ cookies: [HTTPCookie]) async throws {
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

    func fetchCookies() async throws -> [HTTPCookie] {
        guard let cookieData = try await fetchCookieData() else {
            return []
        }

        return try HTTPCookieCodec.decodeData(cookieData)
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
            try updateCookieInKeychain(encryptedCookieData)
        } else {
            try addCookieToKeychain(encryptedCookieData)
        }
    }

    private func fetchCookieData() async throws -> Data? {
        guard let encryptedCookieData = try fetchCookieDataFromKeychain() else {
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

    private func addCookieToKeychain(_ cookieData: Data) throws {
        let query = addQuery(cookieData: cookieData)
        let status = keychain.addItem(query: query)

        guard status == errSecSuccess else {
            throw Failure.failedKeychainAdd(status: status)
        }
    }

    private func updateCookieInKeychain(_ cookieData: Data) throws {
        let updateQuery = updateQuery(cookieData: cookieData)
        let status = keychain.updateItem(query: fetchQuery, attributesToUpdate: updateQuery)

        guard status == errSecSuccess else {
            throw Failure.failedKeychainUpdate(status: status)
        }
    }

    private func fetchCookieDataFromKeychain() throws -> Data? {
        var result: CFTypeRef?
        let status = keychain.fetchItem(query: fetchQuery, result: &result)

        switch status {
        case errSecItemNotFound:
            return nil

        case errSecSuccess:
            guard let base64CookieData = result as? Data else {
                throw Failure.failedKeychainFetch(status: nil)
            }

            guard let cookieData = Data(base64Encoded: base64CookieData) else {
                throw Failure.malformedCookieData
            }

            return cookieData

        default:
            throw Failure.failedKeychainFetch(status: status)
        }
    }

    private lazy var baseQuery: [CFString: Any] = [
        kSecAttrService: "Wire: Credentials for wire.com",
        kSecAttrAccount: userID.uuidString,
        kSecClass: kSecClassGenericPassword
    ]

    private lazy var fetchQuery: [CFString: Any] = {
        var result = baseQuery
        result[kSecReturnData] = true
        return result
    }()

    private func addQuery(cookieData: Data) -> [CFString: Any] {
        var result = updateQuery(cookieData: cookieData)
        result[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
        return result
    }

    private func updateQuery(cookieData: Data) -> [CFString: Any] {
        var result = baseQuery
        result[kSecValueData] = cookieData.base64EncodedData()
        return result
    }

}
