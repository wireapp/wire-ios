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

    public func storeAccessToken(_ accessToken: AccessToken) async {
        self.accessToken = accessToken
    }

    public func fetchAccessToken() async -> AccessToken? {
        accessToken
    }

    public func storeCookieData(_ cookieData: Data?) async {
        fatalError("not implemented yet")
        // encrypt data
        // check if a value already exists for the account name
        // the account name is just the user uuid string
        //  if yes, then do an update.
        //  if no, then do an add.
    }

    public func fetchCookieData() async throws -> Data? {
        let encryptedCookieData: Data
        do {
            encryptedCookieData = try fetchCookieDataFromKeychain()
        } catch PersistentAuthenticationStorageError.cookieNotFound {
            return nil
        }

        guard let encryptionKey = fetchCookieEncryptionKey() else {
            throw PersistentAuthenticationStorageError.missingCookieEncryptionKey
        }

        do {
            return try AES256Crypto.decryptAllAtOnceWithPrefixedIV(
                ciphertext: encryptedCookieData,
                key: encryptionKey
            )
        } catch {
            throw PersistentAuthenticationStorageError.unabledToDecryptCookie(error)
        }
    }

    // MARK: - Keychain

    // TODO: investigate: kSecAttrAccessGroup should be set to the
    // keychain access group, but the original code (in ZMKeychain)
    // always resulted in a nil group, and infact it works to fetch
    // existing cookie data if we omit the group from the query.
    // But if there is no group, how does the extensions access the
    // cookie? Is it needed?

    private var fetchQuery: [CFString: Any] {
        [
            kSecAttrService: "Wire: Credentials for wire.com",
            kSecAttrAccount: userID.uuidString,
            kSecClass: kSecClassGenericPassword,
            //kSecAttrAccessGroup: ..., // Is this needed?
            kSecReturnData: true
        ]
    }

    private func addQuery(cookieData: Data) -> [CFString: Any] {
        [
            kSecAttrService: "Wire: Credentials for wire.com",
            kSecAttrAccount: userID.uuidString,
            kSecClass: kSecClassGenericPassword,
            //kSecAttrAccessGroup: ..., // Is this needed?
            kSecValueData: cookieData,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
    }

    private func updateQuery(cookieData: Data) -> [CFString: Any] {
        [
            kSecAttrService: "Wire: Credentials for wire.com",
            kSecAttrAccount: userID.uuidString,
            kSecClass: kSecClassGenericPassword,
            //kSecAttrAccessGroup: ..., // Is this needed?
            kSecValueData: cookieData
        ]
    }

    private func fetchCookieDataFromKeychain() throws -> Data {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(fetchQuery as CFDictionary, &result)

        switch status {
        case errSecItemNotFound:
            throw PersistentAuthenticationStorageError.cookieNotFound

        case errSecSuccess:
            guard let base64CookieData = result as? Data else {
                throw PersistentAuthenticationStorageError.unableToFetchCookieData(status: nil)
            }

            guard let cookieData = Data(base64Encoded: base64CookieData) else {
                throw PersistentAuthenticationStorageError.failedToBase64DecodeCookie
            }

            return cookieData

        default:
            throw PersistentAuthenticationStorageError.unableToFetchCookieData(status: status)
        }
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

enum PersistentAuthenticationStorageError: Error {

    case cookieNotFound
    case unableToFetchCookieData(status: Int32?)
    case failedToBase64DecodeCookie
    case missingCookieEncryptionKey
    case unabledToDecryptCookie(any Error)

}
