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
import WireSystem

// MARK: - CoreCryptoKeyProvider

public class CoreCryptoKeyProvider {
    public init() {}

    public func coreCryptoKey(createIfNeeded: Bool) throws -> Data {
        removeLegacyKeyIfNeeded()

        do {
            return try fetchCoreCryptoKey()
        } catch {
            if createIfNeeded {
                return try createCoreCryptoKey()
            } else {
                throw error
            }
        }
    }

    private func fetchCoreCryptoKey() throws -> Data {
        let item = CoreCryptoKeychainItem()
        let key: Data = try KeychainManager.fetchItem(item)
        WireLogger.coreCrypto.info("Core crypto key exists: \(key.base64String()). Returning...")
        return key
    }

    private func createCoreCryptoKey() throws -> Data {
        let item = CoreCryptoKeychainItem()
        WireLogger.coreCrypto.info("Core crypto key doesn't exist. Creating...")
        let key = try KeychainManager.generateKey(numberOfBytes: 32)
        WireLogger.coreCrypto.info("Created core crypto key: \(key.base64String()). Storing...")
        try KeychainManager.storeItem(item, value: key)
        WireLogger.coreCrypto.info("Stored core crypto key. Returning...")
        return key
    }

    private func removeLegacyKeyIfNeeded() {
        let legacyItem = LegacyCoreCryptoKeychainItem()

        do {
            _ = try KeychainManager.fetchItem(legacyItem) as Data
            WireLogger.coreCrypto.info("Found legacy core crypto key. Deleting...")
            try KeychainManager.deleteItem(legacyItem)
            WireLogger.coreCrypto.info("Deleted legacy core crypto key")
        } catch let KeychainManager.Error.failedToDeleteItemFromKeychain(error) {
            WireLogger.coreCrypto.error("Failed to delete legacy core crypto key: \(String(describing: error))")
        } catch {
            // key was not found. no action needed
        }
    }
}

// MARK: - CoreCryptoKeychainItem

struct CoreCryptoKeychainItem: KeychainItemProtocol {
    var id: String {
        "com.wire.mls.key"
    }

    var tag: Data {
        id.data(using: .utf8)!
    }

    var getQuery: [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecReturnData: true,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
        ]
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecValueData: value,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
        ]
    }
}

// MARK: - LegacyCoreCryptoKeychainItem

struct LegacyCoreCryptoKeychainItem: KeychainItemProtocol {
    var id: String {
        "com.wire.mls.key"
    }

    var tag: Data {
        id.data(using: .utf8)!
    }

    var getQuery: [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecReturnData: true,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
        ]
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecValueData: value,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
        ]
    }
}
