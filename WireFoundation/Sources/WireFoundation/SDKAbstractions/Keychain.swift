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

/// A simple wrapper around the Keychain api.

public struct Keychain: KeychainProtocol {

    /// Create a new `Keychain` instance.

    public init() {}

    /// Add one or more items to a keychain.
    ///
    /// For more information, refer to the documentation of `SecItemAdd`.

    public func addItem(
        query: Set<KeychainQueryItem>
    ) async throws {
        let status = SecItemAdd(
            query.toCFDictionary(),
            nil
        )

        guard status == errSecSuccess else {
            throw KeychainError.errorStatus(status)
        }
    }

    /// Modify zero or more items which match a search query.
    ///
    /// For more information, refer to the documentation of `SecItemUpdate`.

    public func updateItem(
        query: Set<KeychainQueryItem>,
        attributesToUpdate: Set<KeychainQueryItem>
    ) async throws {
        let status = SecItemUpdate(
            query.toCFDictionary(),
            attributesToUpdate.toCFDictionary()
        )

        guard status == errSecSuccess else {
            throw KeychainError.errorStatus(status)
        }
    }

    /// Returns one or more items which match a search query.
    ///
    /// For more information, refer to the documentation of `SecItemCopyMatching`.

    public func fetchItem<T>(
        query: Set<KeychainQueryItem>
    ) async throws -> T? {
        var result: CFTypeRef?

        let status = SecItemCopyMatching(
            query.toCFDictionary(),
            &result
        )

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.errorStatus(status)
        }

        guard let castedResult = result as? T else {
            throw KeychainError.failedToCastResult
        }

        return castedResult
    }

    /// Delete zero or more items which match a search query.
    ///
    /// For more information, refer to the documentation of `SecItemDelete`.

    public func deleteItem(
        query: Set<KeychainQueryItem>
    ) async throws {
        let status = SecItemDelete(
            query.toCFDictionary()
        )

        guard status == errSecSuccess else {
            throw KeychainError.errorStatus(status)
        }
    }

}

private extension Set<KeychainQueryItem> {

    func toCFDictionary() -> CFDictionary {
        var dictionary = [CFString: Any]()

        for item in self {
            let entry = item.toCFDictionaryEntry()
            dictionary[entry.0] = entry.1
        }

        return dictionary as CFDictionary
    }

}
