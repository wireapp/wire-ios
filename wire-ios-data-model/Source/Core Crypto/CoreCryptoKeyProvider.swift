//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireCoreCrypto
import WireLogging
import WireSystem

public class CoreCryptoKeyProvider {

    public init() {}

    public func coreCryptoKey(
        createIfNeeded: Bool,
        path: String
    ) async throws -> Data {
        removeLegacyKeyIfNeeded()

        do {
            return try fetchCoreCryptoKeyV2()
        } catch {
            if createIfNeeded {
                let newKey = try createCoreCryptoKeyV2()
                guard let oldKey = try? fetchCoreCryptoKey() else {
                    return newKey
                }
                return try await migrateDatabaseKey(path: path, oldKey: oldKey, newKey: newKey)
            } else {
                throw error
            }
        }
    }

    private func fetchCoreCryptoKeyV2() throws -> Data {
        let item = CoreCryptoKeychainItemV2()
        let key: Data = try KeychainManager.fetchItem(item)
        WireLogger.coreCrypto.info("Core crypto key_v2 exists: \(key.base64String()). Returning...")
        return key
    }

    private func createCoreCryptoKeyV2() throws -> Data {
        let item = CoreCryptoKeychainItemV2()
        WireLogger.coreCrypto.info("Core crypto key_v2 doesn't exist. Creating...")
        let key = try KeychainManager.generateKey(numberOfBytes: 32)
        WireLogger.coreCrypto.info("Created core crypto key_v2: \(key.base64String()). Storing...")
        try KeychainManager.storeItem(item, value: key)
        WireLogger.coreCrypto.info("Stored core crypto key_v2. Returning...")
        return key
    }

    private func migrateDatabaseKey(path: String, oldKey: Data, newKey: Data) async throws -> Data {
        WireLogger.coreCrypto.info("Migrating CoreCrypto key from v1 to v2")

        try await migrateDatabaseKeyTypeToBytes(
            path: path,
            oldKey: oldKey.base64EncodedString(),
            newKey: newKey
        )

        removeKeyV1IfNeeded()
        return newKey
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

    private func removeKeyV1IfNeeded() {
        let item = CoreCryptoKeychainItem()

        do {
            _ = try KeychainManager.fetchItem(item) as Data
            WireLogger.coreCrypto.info("Found core crypto key_v1. Deleting...")
            try KeychainManager.deleteItem(item)
            WireLogger.coreCrypto.info("Deleted legacy core crypto key")
        } catch let KeychainManager.Error.failedToDeleteItemFromKeychain(error) {
            WireLogger.coreCrypto.error("Failed to delete core crypto key_v1: \(String(describing: error))")
        } catch {
            // key was not found. no action needed
        }
    }

}

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
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecValueData: value,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
    }

}

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
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ]
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecValueData: value,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ]
    }
}

struct CoreCryptoKeychainItemV2: KeychainItemProtocol {

    var id: String {
        "com.wire.mls.key"
    }

    var keychainServiceName: String {
        "wire.com"
    }

    var getQuery: [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainServiceName,
            kSecAttrAccount: id,
            kSecReturnData: true
        ]
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainServiceName,
            kSecAttrAccount: id,
            kSecAttrComment: "6.0.1",
            kSecValueData: value,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
    }

}
