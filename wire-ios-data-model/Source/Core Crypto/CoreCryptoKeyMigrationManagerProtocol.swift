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

// sourcery: AutoMockable
public protocol CoreCryptoKeyMigrationManagerProtocol {

    /// Wether there's any migration that is required

    var isAnyMigrationRequired: Bool { get }

    /// Wether we need to update the database key from String to Data (bytes) format

    var isMigrationToBytesNeeded: Bool { get }

    /// Wether we need to migrate the stored database key from an unscoped keychain item to a keychain item
    /// scoped by user

    var isMigrationToScopedKeyNeeded: Bool { get }

    /// Wether we need to re-encrypt the database with a new key and update it in keychain storage

    var isKeyRotationNeeded: Bool { get }

    /// Updates the database key from String to Data (bytes) format

    func migrateDatabaseKeyToBytes(path: String, oldKey: String, newKey: Data) async throws

    /// Marks the migration of the database key to bytes as skipped (done)

    func markMigrationToBytesAsSkipped()

    /// Marks the migration of the database key to a scoped keychain item storage as done

    func markMigrationToScopedKeyDone()

    /// Marks the re-encryption of the database with a new key as done

    func markKeyRotationAsDone()

    /// Re-encrypts the core crypto database with a new key

    func updateKey(path: String, oldKey: Data, newKey: Data) async throws

}

public enum CoreCryptoKeyMigrationManagerError: Swift.Error {
    case failedToUpdateKey(underlyingError: Swift.Error)
}
