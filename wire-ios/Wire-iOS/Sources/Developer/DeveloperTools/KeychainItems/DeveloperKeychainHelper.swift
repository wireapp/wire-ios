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
import Security

class DeveloperKeychainHelper {

    func fetchAll(matchingSecClass secClass: CFString) -> [KeychainItem] {
        let query: [CFString: Any] = [
            kSecClass: secClass,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecReturnAttributes: true,
            kSecReturnData: true
        ]

        let items = fetchItems(query: query)

        return items.map { item in
            KeychainItem(
                account: item[kSecAttrAccount as String] as? String,
                applicationTag: string(from: item[kSecAttrApplicationTag as String]),
                label: string(from: item[kSecAttrLabel as String]),
                value: string(from: item[kSecValueData as String]),
                accessGroup: item[kSecAttrAccessGroup as String] as? String,
                secClass: secClass
            )
        }
    }

    func delete(_ item: KeychainItem) {
        switch item.secClass {
        case kSecClassGenericPassword:
            if let account = item.account {
                deleteItem(
                    secClass: kSecClassGenericPassword,
                    attributes: [kSecAttrAccount: account]
                )
            }
        case kSecClassKey:
            var attributes = [CFString: Data]()

            if let tag = data(from: item.applicationTag) {
                attributes[kSecAttrApplicationTag] = tag
            } else if let label = data(from: item.label) {
                attributes[kSecAttrLabel] = label
            } else {
                break
            }

            deleteItem(
                secClass: kSecClassKey,
                attributes: attributes
            )
        default:
            break
        }
    }

    func deleteAll() {
        SecItemDelete([kSecClass: kSecClassGenericPassword] as CFDictionary)
        SecItemDelete([kSecClass: kSecClassKey] as CFDictionary)
    }

    // MARK: Helpers

    private func fetchItems(query: [CFString: Any]) -> [[String: Any]] {
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            return []
        }
        return items
    }

    private func deleteItem(secClass: CFString, attributes: [CFString: Any]) {
        var query: [CFString: Any] = [kSecClass: secClass]
        attributes.forEach { query[$0.key] = $0.value }
        SecItemDelete(query as CFDictionary)
    }

    private func string(from data: Any?) -> String? {
        guard let data = data as? Data else { return nil }
        return String(data: data, encoding: .utf8) ?? "<binary data>"
    }

    private func data(from string: String?) -> Data? {
        guard let string else { return nil }
        return string.data(using: .utf8)
    }
}
