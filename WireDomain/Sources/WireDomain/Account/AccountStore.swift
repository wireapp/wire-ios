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
import WireAPI
import WireDataModel
import WireLogging
import WireSystem

private let log = WireLogger(tag: "Accounts")

/// Persistence layer for `Account` objects.
/// Objects are stored in files named after their identifier like this:
///
/// ```
/// - Root url passed to init
///     - Accounts
///         - 47B3C313-E3FA-4DE4-8DBE-5BBDB6A0A14B
///         - 0F5771BB-2103-4E45-9ED2-E7E6B9D46C0F
/// ```

struct AccountStore {

    private let directory: URL
    private static let directoryName = "Accounts"
    private let fileManager = FileManager.default

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Create a new `AccountStore`.
    ///
    /// `Account` objects will be stored in a subdirectory of the passed in url.
    /// - parameter root: The root url in which the storage will use to store its data

    init(root: URL) throws {
        self.directory = root.appendingPathComponent(AccountStore.directoryName)
        try fileManager.createAndProtectDirectory(at: directory)
    }

    // MARK: - Fetch

    /// Fetch all stored accounts.
    ///
    /// - returns: All accounts stored in this `AccountStore`.

    func fetchAllAccounts() -> Set<Account> {
        Set(listAccountIDs().compactMap(fetchAccount))
    }

    /// Fetch a single account.
    ///
    /// - parameter id: The `UUID` of the user the account belongs to.
    /// - returns: The `Account` if it exists.

    func fetchAccount(with id: UUID) -> Account? {
        let url = url(for: id)

        guard
            let data = try? Data(contentsOf: url),
            let storedAccount = try? decoder.decode(
                StoredAccount.self,
                from: data
            )
        else {
            return nil
        }

        return Account(storedAccount)
    }

    // MARK: - Store

    /// Store an `Account`.
    ///
    /// If the account already exists, it will be overwritten.
    ///
    /// - parameter account: The account to store.
    /// - returns: Whether the operation was successful.

    @discardableResult
    func storeAccount(_ account: Account) -> Bool {
        do {
            let storedAccount = StoredAccount(account)
            let url = url(for: account.userIdentifier)
            let data = try encoder.encode(storedAccount)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            let accountDescription = account.safeForLoggingDescription
            let errorDescription = error.safeForLoggingDescription
            log.error("Unable to store account \(accountDescription), error: \(errorDescription)")
            return false
        }
    }

    // MARK: Backend Environment

    @discardableResult
    func storeBackendEnvironment(_ backendEnvironment: BackendEnvironment2, for accountId: UUID) -> Bool {
        do {
            let storedBackendEnvironment = backendEnvironment.toStored()
            let url = backendEnvironmentUrl(for: accountId)
            let data = try encoder.encode(storedBackendEnvironment)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            let errorDescription = error.safeForLoggingDescription
            log.error("Unable to store account \(backendEnvironment), error: \(errorDescription)")
            return false
        }
    }

    func fetchBackendEnvironment(accountId: UUID) throws -> BackendEnvironment2? {
        let url = backendEnvironmentUrl(for: accountId)

        do {
            let data = try Data(contentsOf: url)
            let stored = try decoder.decode(
                StoredBackendEnvironment.self,
                from: data
            )
            return try stored.toDomain()
        } catch {
            let errorDescription = error.safeForLoggingDescription
            log.error("Unable to fetch backend environment for account \(accountId), error: \(errorDescription)")
            return nil
        }
    }

    // MARK: - Delete

    /// Delete an `Account`.
    ///
    /// - parameter account: The account which should be deleted.
    /// - returns: `false` if the account cannot be found or cannot be deleted otherwise `true`.

    @discardableResult
    func deleteAccount(_ account: Account) -> Bool {
        do {
            try fileManager.removeItem(at: url(for: account.userIdentifier))
            deleteBackgroundEnvironment(account: account)
            return true
        } catch {
            let accountDescription = account.safeForLoggingDescription
            let errorDescription = error.safeForLoggingDescription
            log.error("Unable to delete account \(accountDescription), error: \(errorDescription)")
            return false
        }
    }

    @discardableResult
    func deleteBackgroundEnvironment(account: Account) -> Bool {
        do {
            try fileManager.removeItem(at: backendEnvironmentUrl(for: account.userIdentifier))
            return true
        } catch {
            let accountDescription = account.safeForLoggingDescription
            let errorDescription = error.safeForLoggingDescription
            log.error("Unable to delete account \(accountDescription), error: \(errorDescription)")
            return false
        }
    }

    /// Delete the persistence layer of an `AccountStore` from the file system.
    ///
    /// Mostly useful for cleaning up after tests or for complete account resets.
    ///
    /// - parameter root: The root url of the store that should be deleted.

    @discardableResult
    static func delete(at root: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: root.appendingPathComponent(directoryName))
            return true
        } catch {
            log.error("Unable to remove all accounts, error: \(error.safeForLoggingDescription)")
            return false
        }
    }

    // MARK: - Private Helper

    private func listAccountIDs() -> Set<UUID> {
        do {
            let paths = try fileManager.contentsOfDirectory(atPath: directory.path)
            let ids = paths.compactMap(UUID.init(uuidString:))
            return Set(ids)
        } catch {
            log.error("failed to list account ids, error: \(error.safeForLoggingDescription)")
            return []
        }
    }

    private func url(for id: UUID) -> URL {
        directory.appendingPathComponent(id.uuidString)
    }

    private func backendEnvironmentUrl(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString)-backend-environment.json")
    }
}

private extension Error {

    var safeForLoggingDescription: String {
        (self as NSError).safeForLoggingDescription
    }

}
