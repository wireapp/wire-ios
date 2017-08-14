//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


private let log = ZMSLog(tag: "Accounts")


fileprivate extension UserDefaults {

    static let selectedAccountKey = "AccountManagerSelectedAccountKey"

    /// The identifier of the currently selected `Account` or `nil` if there is none.
    var selectedAccountIdentifier: UUID? {
        get { return string(forKey: UserDefaults.selectedAccountKey).flatMap(UUID.init) }
        set { set(newValue?.uuidString, forKey: UserDefaults.selectedAccountKey) }
    }

}


/// Class used to safely access and change stored accounts and the current selected account.
public final class AccountManager: NSObject {

    private let defaults = UserDefaults.shared()
    private(set) public var accounts = [Account]()
    private(set) public var selectedAccount: Account? // The currently selected account or `nil` in case there is none

    private var store: AccountStore

    /// Creates a new `AccountManager`.
    /// - parameter sharedDirectory: The directory of the shared container.
    @objc(initWithSharedDirectory:) public init(sharedDirectory: URL) {
        store = AccountStore(root: sharedDirectory)
        super.init()
        updateAccounts()
    }

    /// Deletes all content stored by an `AccountManager` on disk at the given URL, including the selected account.
    @objc (deleteAtRoot:) static public func delete(at root: URL) {
        AccountStore.delete(at: root)
        UserDefaults.shared().selectedAccountIdentifier = nil
    }

    /// Adds an account to the manager and persists it.
    /// - parameter account: The account to add.
    @objc(addAccount:) public func add(_ account: Account) {
        store.add(account)
        updateAccounts()
    }

    /// Adds an account to the mananger and immediately and selects it.
    /// - parameter account: The account to add and select.
    @objc(addAndSelectAccount:) public func addAndSelect(_ account: Account) {
        add(account)
        select(account)
    }

    /// Removes an account from the manager and the persistence layer.
    /// - parameter account: The account to remove.
    @objc(removeAccount:) public func remove(_ account: Account) {
        store.remove(account)
        if selectedAccount == account {
            defaults?.selectedAccountIdentifier = nil
        }
        updateAccounts()
    }

    /// Selects a new account.
    /// - parameter account: The account to select.
    @objc(selectAccount:) public func select(_ account: Account) {
        precondition(accounts.contains(account), "Selecting an account without first adding it is not allowed")
        guard account != selectedAccount else { return }
        defaults?.selectedAccountIdentifier = account.userIdentifier
        updateAccounts()
    }

    // MARK: - Private Helper

    /// Updates the local accounts array and the selected account.
    /// This method should be called each time accounts are added or
    /// removed, or when the selectedAccountIdentifier has been changed.
    private func updateAccounts() {
        accounts = computeSortedAccounts()
        selectedAccount = computeSelectedAccount()
    }

    /// Loads and computes the locally selected account if any
    /// - returns: The currently selected account or `nil` if there is none.
    private func computeSelectedAccount() -> Account? {
        return defaults?.selectedAccountIdentifier.flatMap(store.load)
    }

    /// Loads and sorts the stored accounts.
    /// - returns: An Array consisting of the sorted accounts. Accounts without team will
    /// be first, sorted by their user name. Accounts with team will be last,
    /// sorted by their team name.
    private func computeSortedAccounts() -> [Account] {
        return store.load().sorted { lhs, rhs in
            switch (lhs.teamName, rhs.teamName) {
            case (.some, .none): return false
            case (.none, .some): return true
            case (.some(let leftName), .some(let rightName)):
                guard leftName != rightName else { fallthrough }
                return leftName < rightName
            default: return lhs.userName < rhs.userName
            }
        }
    }
    
}
