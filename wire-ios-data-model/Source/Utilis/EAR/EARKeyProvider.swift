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

/// An object that provides access to encryption at rest
/// keys.

public struct EncryptionAtRestKeyProvider {

    // MARK: - Properties

    let accountID: UUID

    // MARK: - Primary

    /// Attempt to fetch the primary public key.
    ///
    /// This key should be used to encrypt the databse key as well
    /// as stored update events (excepting call events).
    ///
    /// Returns: The key.

    public func fetchPrimaryPublicKey() throws -> SecKey {
        return try KeychainManager.fetchItem(PublicEARKeyDescription(
            accountID: accountID,
            label: "primary-public"
        ))
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
        return try KeychainManager.fetchItem(PrivateEARKeyDescription(
            accountID: accountID,
            label: "primary-private",
            context: context,
            prompt: authenticationPrompt
        ))
    }

    // MARK: - Secondary

    /// Attempt to fetch the secondary public key.
    ///
    /// This key should be used to encrypt stored call events.
    ///
    /// Returns: The key.

    public func fetchSecondaryPublicKey() throws -> SecKey {
        return try KeychainManager.fetchItem(PublicEARKeyDescription(
            accountID: accountID,
            label: "secondary-public"
        ))
    }

    /// Attempt to fetch the secondary private key.
    ///
    /// This key should be used to decrypt stored call events.
    ///
    /// Returns: The key.

    public func fetchSecondaryPrivateKey() throws -> SecKey {
        return try KeychainManager.fetchItem(PrivateEARKeyDescription(
            accountID: accountID,
            label: "secondary-private"
        ))
    }

    // MARK: - Database

    /// Attempt to fetch the databse key.
    ///
    /// This key should be used to encrypt and decrypt content in the database.
    ///
    /// Returns: The key.

    public func fetchDatabaseKey() throws -> Data {
        return try KeychainManager.fetchItem(DatabaseEARKeyDescription(
            accountID: accountID,
            label: "database"
        ))
    }

}
