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
import LocalAuthentication
import Security

// MARK: - KeychainItem

public protocol KeychainItem {
    associatedtype Value
    func queryForSetting(value: Value) -> [CFString: Any]
    var queryForGettingValue: [CFString: Any] { get }
}

// MARK: - Keychain

public enum Keychain {
    public enum KeychainError: Error {
        case failedToStoreItemInKeychain(OSStatus)
        case failedToFetchItemFromKeychain(OSStatus?)
        case failedToDeleteItemFromKeychain(OSStatus)
    }

    // MARK: - Keychain access

    public static func storeItem<T: KeychainItem>(_ item: T, value: T.Value) throws {
        WireLogger.keychain.info("storing item (\(item))")

        let query = item.queryForSetting(value: value) as CFDictionary
        let status = SecItemAdd(query, nil)

        guard status == errSecSuccess else {
            throw KeychainError.failedToStoreItemInKeychain(status)
        }
    }

    public static func fetchItem<T: KeychainItem>(_ item: T) throws -> T.Value {
        WireLogger.keychain.info("fetching item (\(item))")

        var value: CFTypeRef?
        let status = SecItemCopyMatching(item.queryForGettingValue as CFDictionary, &value)

        guard status == errSecSuccess else {
            throw KeychainError.failedToFetchItemFromKeychain(status)
        }

        guard let valueCasted = value as? T.Value else {
            throw KeychainError.failedToFetchItemFromKeychain(nil)
        }

        return valueCasted
    }

    public static func deleteItem(_ item: some KeychainItem) throws {
        WireLogger.keychain.info("deleting item (\(item))")

        let status = SecItemDelete(item.queryForGettingValue as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.failedToDeleteItemFromKeychain(status)
        }
    }

    public static func updateItem<T: KeychainItem>(_ item: T, value: T.Value) throws {
        try deleteItem(item)
        try storeItem(item, value: value)
    }
}
