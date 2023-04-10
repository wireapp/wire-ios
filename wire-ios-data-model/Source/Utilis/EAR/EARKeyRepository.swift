//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public protocol EARKeyRepositoryInterface {

    func fetchPrimaryPublicKey() throws -> SecKey

    func fetchPrimaryPrivateKey(
        context: LAContext?,
        authenticationPrompt: String?
    ) throws -> SecKey

    func fetchSecondaryPublicKey() throws -> SecKey

    func fetchSecondaryPrivateKey() throws -> SecKey

    func fetchDatabaseKey() throws -> Data

}

public extension EARKeyRepositoryInterface {

    func fetchPublicKeys() -> (primary: SecKey, secondary: SecKey)? {
        do {
            return try (fetchPrimaryPublicKey(), fetchSecondaryPublicKey())
        } catch {
            return nil
        }
    }

    func fetchPrivateKeys(
        context: LAContext? = nil,
        authenticationPrompt: String? = nil
    ) -> (primary: SecKey?, secondary: SecKey?) {
        let primary = try? fetchPrimaryPrivateKey(
            context: context,
            authenticationPrompt: authenticationPrompt
        )

        let secondary = try? fetchSecondaryPrivateKey()
        return (primary, secondary)
    }

}

public class EARKeyRepository: EARKeyRepositoryInterface {

    // MARK: - Properties

    let accountID: UUID

    // MARK: - Life cycle

    public convenience init(account: Account) {
        self.init(accountID: account.userIdentifier)
    }

    public init(accountID: UUID) {
        self.accountID = accountID
    }

    // MARK: - Primary

    /// Attempt to fetch the primary public key.
    ///
    /// This key should be used to encrypt the databse key as well
    /// as stored update events (excepting call events).
    ///
    /// Returns: The key.

    public func fetchPrimaryPublicKey() throws -> SecKey {
        let description = PublicEARKeyDescription.primaryKeyDescription(accountID: accountID)
        return try KeychainManager.fetchItem(description)
    }

    /// Attempt to fetch the primary private key.
    ///
    /// This key should be used to decrypt the databse key as well
    /// as stored update events (excepting call events).
    ///
    /// - Parameters:
    ///   - context: A valid authentication context.
    ///   - authenticationPrompt: A message to show when authentication is requested.
    ///
    /// Returns: The key.

    public func fetchPrimaryPrivateKey(
        context: LAContext? = nil,
        authenticationPrompt: String? = nil
    ) throws -> SecKey {
        let description = PrivateEARKeyDescription.primaryKeyDescription(
            accountID: accountID,
            context: context,
            authenticationPrompt: authenticationPrompt
        )

        return try KeychainManager.fetchItem(description)
    }

    // MARK: - Secondary

    /// Attempt to fetch the secondary public key.
    ///
    /// This key should be used to encrypt stored call events.
    ///
    /// Returns: The key.

    public func fetchSecondaryPublicKey() throws -> SecKey {
        let description = PublicEARKeyDescription.secondaryKeyDescription(accountID: accountID)
        return try KeychainManager.fetchItem(description)
    }

    /// Attempt to fetch the secondary private key.
    ///
    /// This key should be used to decrypt stored call events.
    ///
    /// Returns: The key.

    public func fetchSecondaryPrivateKey() throws -> SecKey {
        let description = PrivateEARKeyDescription.secondaryKeyDescription(accountID: accountID)
        return try KeychainManager.fetchItem(description)
    }

    // MARK: - Database

    /// Attempt to fetch the databse key.
    ///
    /// This key should be used to encrypt and decrypt content in the database.
    ///
    /// Returns: The key.

    public func fetchDatabaseKey() throws -> Data {
        // TODO: decrypt
        let description = DatabaseEARKeyDescription.keyDescription(accountID: accountID)
        return try KeychainManager.fetchItem(description)
    }

}
