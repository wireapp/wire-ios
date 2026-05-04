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
import os
import WireDataModel
import WireLogging

public let AccountManagerDidUpdateAccountsNotificationName = Notification
    .Name("AccountManagerDidUpdateAccountsNotification")

/// Manages the known and selected accounts.

public final class AccountManager: NSObject, Sendable {

    // MARK: - Properties

    /// The currently selected account.

    public var selectedAccount: Account? {
        guard let id = defaults.selectedAccountIdentifier else { return nil }
        return cache.withLock { $0[id] }
    }

    /// All known accounts.

    public var accounts: Set<Account> {
        cache.withLock { Set($0.values) }
    }

    /// All accounts excluding the selected account.

    public var inactiveAccounts: Set<Account> {
        if let selectedAccount {
            accounts.subtracting([selectedAccount])
        } else {
            accounts
        }
    }

    /// The sum of unread conversations in all accounts.

    public var totalUnreadCount: Int {
        cache.withLock { dict in
            dict.values.reduce(0) {
                $0 + $1.unreadConversationCount
            }
        }
    }

    /// The number of known accounts.

    public var numberOfAccounts: Int {
        cache.withLock { $0.count }
    }

    /// Whether there are any known accounts.

    public var hasAccounts: Bool {
        cache.withLock { !$0.isEmpty }
    }

    private let currentAppVersion: String
    private let cache = OSAllocatedUnfairLock<[UUID: Account]>(initialState: [:])
    private let store: AccountStore
    private nonisolated(unsafe) let defaults: UserDefaults // UserDefaults is thread safe but not marked as `Sendable`.

    // MARK: - Init

    /// Create a new `AccountManager`.
    ///
    /// - parameter currentAppVersion: The current semantic version of the app.
    /// - parameter directory: The directory to store account data.
    /// - parameter defaults: User defaults for storage.

    public init(
        currentAppVersion: String,
        directory: URL,
        defaults: UserDefaults = .shared()!
    ) throws {
        self.currentAppVersion = currentAppVersion
        self.store = try AccountStore(directory: directory)
        self.defaults = defaults
        super.init()
        refreshCache()

        for account in accounts {
            var journal = Journal(
                userID: account.userIdentifier,
                storage: defaults
            )

            journal.markInitialAppVersionForExistingAccount()
        }
    }

    // MARK: - Add / update

    /// Add an account to the manager and persist it.
    ///
    /// - parameter account: The account to add.

    public func addOrUpdate(_ account: Account) {
        if store.storeAccount(account) {
            var journal = Journal(
                userID: account.userIdentifier,
                storage: defaults
            )
            journal.markInitialAppVersionForNewAccount(currentVersion: currentAppVersion)
        }
        refreshCache()
    }

    /// Add an account to the mananger and immediately and select it.
    ///
    /// - parameter account: The account to add and select.

    public func addAndSelect(_ account: Account) {
        addOrUpdate(account)
        select(account)
    }

    /// Select a new account.
    ///
    /// - parameter account: The account to select.

    public func select(_ account: Account) {
        let id = account.userIdentifier

        precondition(
            cache.withLock { $0[id] != nil },
            "Selecting an account without first adding it is not allowed"
        )

        guard id != defaults.selectedAccountIdentifier else {
            return
        }

        defaults.selectedAccountIdentifier = id
        refreshCache()

        WireLogger.system.setActiveAccount(
            accoundID: id.safeForLoggingDescription
        )
    }

    // MARK: - Remove

    /// Remove an account from the manager and the persistence layer.
    ///
    /// - parameter account: The account to remove.

    public func remove(_ account: Account) {
        store.deleteAccount(account)
        if selectedAccount == account {
            defaults.selectedAccountIdentifier = nil
            WireLogger.system.clearActiveAccount()
        }
        refreshCache()
    }

    /// Delete all content stored by an `AccountManager` on disk at the
    /// given URL, including the selected account.

    public static func delete(at root: URL) {
        AccountStore.delete(directory: AccountURLs(root: root).accounts)
        UserDefaults.shared().selectedAccountIdentifier = nil
    }

    // MARK: - Retrieve

    /// Fetch an account.
    ///
    /// - Parameter id: The user id of the account to fetch.
    /// - Returns: The account, if it exists.

    public func account(with id: UUID) -> Account? {
        cache.withLock { $0[id] }
    }

    /// Load and sort the stored accounts.
    ///
    /// - returns: An Array consisting of the sorted accounts. Accounts without team will
    /// be first, sorted by their user name. Accounts with team will be last,
    /// sorted by their team name.

    public func sortedAccounts() -> [Account] {
        cache.withLock { dict in
            dict.values.sorted { lhs, rhs in
                switch (lhs.teamName, rhs.teamName) {
                case (.some, .none):
                    return false
                case (.none, .some):
                    return true
                case let (.some(leftName), .some(rightName)):
                    guard leftName != rightName else { fallthrough }
                    return leftName < rightName
                default:
                    return lhs.userName < rhs.userName
                }
            }
        }
    }

    // MARK: - Private Helper

    private func refreshCache() {
        let accounts = store.fetchAllAccounts()

        cache.withLock { dict in
            // Add or update values in cache.
            for account in accounts {
                // Since some objects (eg. AccountView) observe changes in the account, we must
                // make sure their object addresses are maintained after updating, i.e if
                // exisiting objects need to be updated from the account store, we just update
                // their properties and not replace the whole object.
                if let existingAccount = dict[account.userIdentifier] {
                    existingAccount.updateWith(account)
                    dict[account.userIdentifier] = existingAccount
                } else {
                    dict[account.userIdentifier] = account
                }
            }

            // Remove deleted accounts.
            for key in Set(dict.keys).subtracting(accounts.map(\.userIdentifier)) {
                dict[key] = nil
            }
        }

        NotificationCenter.default.post(
            name: AccountManagerDidUpdateAccountsNotificationName,
            object: self
        )
    }

}

private extension UserDefaults {

    private static let key = "AccountManagerSelectedAccountKey"

    /// The id of the currently selected `Account`.

    var selectedAccountIdentifier: UUID? {
        get {
            string(forKey: Self.key).flatMap(UUID.init(transportString:))
        }
        set {
            set(newValue?.uuidString, forKey: Self.key)
        }
    }

}
