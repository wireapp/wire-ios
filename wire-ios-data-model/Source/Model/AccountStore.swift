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

private let log = WireLogger(tag: "Accounts")

// MARK: - AccountStore

/// Persistence layer for `Account` objects.
/// Objects are stored in files named after their identifier like this:
///
/// ```
/// - Root url passed to init
///     - Accounts
///         - 47B3C313-E3FA-4DE4-8DBE-5BBDB6A0A14B
///         - 0F5771BB-2103-4E45-9ED2-E7E6B9D46C0F
/// ```
public final class AccountStore: NSObject {
    private static let directoryName = "Accounts"
    private let fileManager = FileManager.default
    private let directory: URL // The url to the directory in which accounts are stored in

    /// Creates a new `AccountStore`.
    /// `Account` objects will be stored in a subdirectory of the passed in url.
    /// - parameter root: The root url in which the storage will use to store its data
    public required init(root: URL) {
        self.directory = root.appendingPathComponent(AccountStore.directoryName)
        super.init()
        try! fileManager.createAndProtectDirectory(at: directory)
    }

    // MARK: - Storing and Retrieving

    /// Loads all stored accounts.
    /// - returns: All accounts stored in this `AccountStore`.
    func load() -> Set<Account> {
        Set<Account>(loadURLs().compactMap(Account.load))
    }

    /// Tries to load a stored account with the given `UUID`.
    /// - parameter uuid: The `UUID` of the user the account belongs to.
    /// - returns: The `Account` stored for the passed in `UUID`, or `nil` otherwise.
    func load(_ uuid: UUID) -> Account? {
        Account.load(from: url(for: uuid))
    }

    /// Stores an `Account` in the account store.
    /// - parameter account: The account which should be saved (or updated).
    /// - returns: Whether or not the operation was successful.
    @discardableResult
    func add(_ account: Account) -> Bool {
        do {
            try account.write(to: url(for: account))
            return true
        } catch {
            let accountDescription = account.safeForLoggingDescription
            let errorDescription = error.safeForLoggingDescription
            log.error("Unable to store account \(accountDescription), error: \(errorDescription)")
            return false
        }
    }

    /// Deletes an `Account` from the account store.
    /// - parameter account: The account which should be deleted.
    /// - returns: `false` if the account cannot be found or cannot be deleted otherwise `true`.
    @discardableResult
    func remove(_ account: Account) -> Bool {
        do {
            try fileManager.removeItem(at: url(for: account))
            return true
        } catch {
            let accountDescription = account.safeForLoggingDescription
            let errorDescription = error.safeForLoggingDescription
            log.error("Unable to delete account \(accountDescription), error: \(errorDescription)")
            return false
        }
    }

    /// Deletes the persistence layer of an `AccountStore` from the file system.
    /// Mostly useful for cleaning up after tests or for complete account resets.
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

    /// Loads the urls to all stored accounts.
    /// - returns: The urls to all accounts stored in this `AccountStore`.
    private func loadURLs() -> Set<URL> {
        do {
            let uuidName: (String) -> Bool = { UUID(uuidString: $0) != nil }
            let paths = try fileManager.contentsOfDirectory(atPath: directory.path)
            return Set<URL>(paths.filter(uuidName).map(directory.appendingPathComponent))
        } catch {
            log.error("Unable to load accounts, error: \(error.safeForLoggingDescription)")
            return []
        }
    }

    /// Create a local url for an `Account` inside this `AccountStore`.
    /// - parameter account: The account for which the url should be generated.
    /// - returns: The `URL` for the given account.
    private func url(for account: Account) -> URL {
        url(for: account.userIdentifier)
    }

    /// Create a local url for an `Account` with the given `UUID` inside this `AccountStore`.
    /// - parameter uuid: The uuid of the user for which the url should be generated.
    /// - returns: The `URL` for the given uuid.
    private func url(for uuid: UUID) -> URL {
        directory.appendingPathComponent(uuid.uuidString)
    }
}

extension Error {
    fileprivate var safeForLoggingDescription: String {
        (self as NSError).safeForLoggingDescription
    }
}
