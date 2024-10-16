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

public actor PersistentAuthenticationStorage: AuthenticationStorage {

    private typealias Error = PersistentAuthenticationStorageError

    private let userID: UUID
    private var accessToken: AccessToken?
    private let sharedUserDefaults: UserDefaults
    private static let cookieEncryptionKeyKey = "ZMCookieKey"

    public init(
        userID: UUID,
        sharedUserDefaults: UserDefaults
    ) {
        self.userID = userID
        self.sharedUserDefaults = sharedUserDefaults
    }

    // MARK: - Access token

    public func storeAccessToken(_ accessToken: AccessToken) async {
        self.accessToken = accessToken
    }

    public func fetchAccessToken() async -> AccessToken? {
        accessToken
    }

    // MARK: - Cookie

    public func storeCookies(_ cookies: [HTTPCookie]) async throws {
        let properties = cookies.compactMap(\.properties)

        // How many cookies do we expect to have?
        guard
            let name = properties.first?[.name] as? String,
            name == "zuid"
        else {
            // What should we do?
            fatalError()
        }

        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(properties, forKey: "properties")
        archiver.finishEncoding()

        let cookieData = archiver.encodedData
        try await storeCookieData(cookieData)
    }

    public func fetchCookies() async throws -> [HTTPCookie] {
        guard let cookieData = try await fetchCookieData() else {
            return []
        }

        let unarchiver: NSKeyedUnarchiver
        do {
            unarchiver = try NSKeyedUnarchiver(forReadingFrom: cookieData)
            unarchiver.requiresSecureCoding = true
        } catch {
            throw Error.failedToDecodeCookieData(error)
        }

        guard let properties = unarchiver.decodePropertyList(forKey: "properties") as? [[HTTPCookiePropertyKey: Any]] else {
            throw Error.malformedCookieData
        }

        return properties.compactMap(HTTPCookie.init)
    }

    // MARK: - Cookie data

    private func storeCookieData(_ cookieData: Data) async throws {
        guard let encryptionKey = fetchCookieEncryptionKey() else {
            throw Error.missingCookieEncryptionKey
        }

        let encryptedCookieData: Data
        do {
            encryptedCookieData = try AES256Crypto.encryptAllAtOnceWithPrefixedIV(
                plaintext: cookieData,
                key: encryptionKey
            ).data
        } catch {
            throw PersistentAuthenticationStorageError.failedToEncryptCookie(error)
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

        guard let encryptionKey = fetchCookieEncryptionKey() else {
            throw PersistentAuthenticationStorageError.missingCookieEncryptionKey
        }

        do {
            return try AES256Crypto.decryptAllAtOnceWithPrefixedIV(
                ciphertext: AES256Crypto.PrefixedData(data: encryptedCookieData),
                key: encryptionKey
            )
        } catch {
            throw PersistentAuthenticationStorageError.failedToDecryptCookie(error)
        }
    }

    // MARK: - Keychain

    private func addCookieToKeychain(_ cookieData: Data) throws {
        let query = addQuery(cookieData: cookieData)
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw PersistentAuthenticationStorageError.failedKeychainAdd(status: status)
        }
    }

    private func updateCookieInKeychain(_ cookieData: Data) throws {
        let updateQuery = updateQuery(cookieData: cookieData)
        let status = SecItemUpdate(fetchQuery as CFDictionary, updateQuery as CFDictionary)

        guard status == errSecSuccess else {
            throw PersistentAuthenticationStorageError.failedKeychainUpdate(status: status)
        }
    }

    private func fetchCookieDataFromKeychain() throws -> Data? {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(fetchQuery as CFDictionary, &result)

        switch status {
        case errSecItemNotFound:
            return nil

        case errSecSuccess:
            guard let base64CookieData = result as? Data else {
                throw PersistentAuthenticationStorageError.failedKeychainFetch(status: nil)
            }

            guard let cookieData = Data(base64Encoded: base64CookieData) else {
                throw PersistentAuthenticationStorageError.malformedCookieData
            }

            return cookieData

        default:
            throw PersistentAuthenticationStorageError.failedKeychainFetch(status: status)
        }
    }

    private lazy var baseQuery: [CFString: Any] = [
        kSecAttrService: "Wire: Credentials for wire.com",
        kSecAttrAccount: userID.uuidString,
        kSecClass: kSecClassGenericPassword,
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

    // MARK: - Cookie encryption key

    private func fetchOrCreateCookieEncryptionKey() throws -> Data {
        if let key = fetchCookieEncryptionKey() {
            return key
        } else {
            let newKey = try AES256Crypto.generateRandomEncryptionKey()
            sharedUserDefaults.set(newKey, forKey: Self.cookieEncryptionKeyKey)
            return newKey
        }
    }

    private func fetchCookieEncryptionKey() -> Data? {
        sharedUserDefaults.data(forKey: Self.cookieEncryptionKeyKey)
    }

}
