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
import WireCommonComponents
import WireFoundation
import WireSyncEngine

struct DebugCoreCryptoAccount: Hashable {
    let userID: UUID
    let username: String
    let keys: [KeychainItem]
    let uniqueKeyID: UUID?
    let isSelected: Bool
}

// MARK: - ViewModel

class DeveloperCoreCryptoKeysViewModel: ObservableObject {
    @Published var accounts: [DebugCoreCryptoAccount] = []

    private let userDefaults = UserDefaults.applicationGroup
    private let keychainHelper = DeveloperKeychainHelper()
    private let accountManager = SessionManager.shared?.accountManager

    init() {
        loadAccounts()
    }

    func loadAccounts() {
        guard let accountManager else { return }

        accounts = accountManager.accounts.compactMap { account in
            DebugCoreCryptoAccount(
                userID: account.userIdentifier,
                username: account.userName,
                keys: fetchKechainItems(for: account.userIdentifier),
                uniqueKeyID: fetchUniqueIdentifier(for: account.userIdentifier),
                isSelected: accountManager.selectedAccount == account
            )
        }
    }

    func nameText(for account: DebugCoreCryptoAccount) -> String {
        var text = account.username

        if account.isSelected {
            text += " - current account"
        }

        return text
    }

    func deleteKeychainItem(_ item: KeychainItem) {
        keychainHelper.delete(item)
        loadAccounts()
    }

    private func fetchKechainItems(for userID: UUID) -> [KeychainItem] {
        keychainHelper.fetchAll(matchingSecClass: kSecClassKey).filter {
            $0.applicationTag?.contains(userID.uuidString) ?? false
        }
    }

    private func fetchUniqueIdentifier(for userID: UUID) -> UUID? {
        let userDefaults = PrivateUserDefaults<CoreCryptoKeyProviderDefaults>(
            userID: userID,
            storage: userDefaults
        )
        return userDefaults.getUUID(forKey: CoreCryptoKeyProviderDefaults.uniqueKeyIdentifier)
    }

}
