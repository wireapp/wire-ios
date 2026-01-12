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

import SwiftUI

// MARK: - Model

struct KeychainItem: Identifiable, Hashable {
    let id = UUID()

    // Password fields
    let account: String?

    // Key fields
    let applicationTag: String?
    let label: String?

    // Common
    let value: String?
    let accessGroup: String?
    let secClass: CFString
}

// MARK: - ViewModel

class DeveloperKeychainItemsViewModel: ObservableObject {
    @Published var passwordItems: [KeychainItem] = []
    @Published var keyItems: [KeychainItem] = []

    private let keychainHelper = DeveloperKeychainHelper()

    init() {
        fetchItems()
    }

    func nameFor(_ item: KeychainItem) -> String? {
        switch item.secClass {
        case kSecClassGenericPassword:
            item.account
        case kSecClassKey:
            item.applicationTag ?? item.label
        default: nil
        }
    }

    func fetchItems() {
        passwordItems = keychainHelper.fetchAll(matchingSecClass: kSecClassGenericPassword)
        keyItems = keychainHelper.fetchAll(matchingSecClass: kSecClassKey)
    }

    func delete(_ item: KeychainItem) {
        keychainHelper.delete(item)
        fetchItems()
    }

    func deleteAll() {
        keychainHelper.deleteAll()
        fetchItems()
    }
}
