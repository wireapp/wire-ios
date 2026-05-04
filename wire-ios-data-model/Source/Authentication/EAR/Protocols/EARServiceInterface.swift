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

/// Protocol for managing Encryption at Rest (EAR) functionality.
///
/// This service is the main entry point for all EAR operations, including:
/// - Enabling/disabling encryption
/// - Locking/unlocking the database
/// - Managing encryption keys
///
/// sourcery: AutoMockable
public protocol EARServiceInterface: AnyObject {

    /// Delegate that assists with database migrations during EAR state changes.
    var delegate: EARServiceDelegate? { get set }

    /// Enables encryption at rest.
    ///
    /// This operation:
    /// 1. Generates new encryption keys (primary, secondary, and database keys)
    /// 2. Prompts user for biometric authentication
    /// 3. Encrypts existing sensitive data in the database (unless `skipMigration` is true)
    /// 4. Marks the database as encrypted
    ///
    /// If any error occurs, all changes are rolled back and keys are destroyed.
    ///
    /// - Parameters:
    ///   - context: The database context in which to perform the migration
    ///   - skipMigration: Whether to skip migrating existing data (useful for testing)
    /// - Throws: `EARServiceFailure` if the operation fails
    func enableEncryptionAtRest(
        context: NSManagedObjectContext,
        skipMigration: Bool
    ) throws

    /// Disables encryption at rest.
    ///
    /// This operation:
    /// 1. Decrypts all encrypted data in the database (unless `skipMigration` is true)
    /// 2. Destroys all encryption keys
    /// 3. Marks the database as unencrypted
    ///
    /// If any error occurs during migration, changes are rolled back and keys are preserved.
    ///
    /// - Parameters:
    ///   - context: The database context in which to perform the migration
    ///   - skipMigration: Whether to skip migrating existing data (useful for testing)
    /// - Throws: `EARServiceFailure` if the operation fails
    func disableEncryptionAtRest(
        context: NSManagedObjectContext,
        skipMigration: Bool
    ) throws

    /// Locks the database, preventing access to encrypted content.
    ///
    /// This operation:
    /// - Clears the database key from memory
    /// - Clears the keychain cache
    /// - Makes all encrypted data inaccessible until the database is unlocked
    ///
    /// Typically called when the app enters the background.
    func lockDatabase()

    /// Unlocks the database, allowing access to encrypted content.
    ///
    /// This operation:
    /// - Prompts the user for biometric authentication
    /// - Retrieves the primary private key from the keychain
    /// - Decrypts the database key
    /// - Makes encrypted data accessible again
    ///
    /// Typically called when the app returns to the foreground or when user authentication succeeds.
    ///
    /// - Throws: Error if authentication fails or keys cannot be accessed
    func unlockDatabase() throws

    /// Fetches both primary and secondary public keys.
    ///
    /// Public keys are used to encrypt content. The keys are stored in the keychain with
    /// accessibility level `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
    ///
    /// - Returns: The public keys if EAR is enabled, or `nil` if EAR is disabled
    /// - Throws: Error if EAR is enabled but keys cannot be fetched
    func fetchPublicKeys() throws -> EARPublicKeys?

    /// Fetches private keys for decryption.
    ///
    /// Private keys are used to decrypt content. Access is restricted by iOS:
    /// - **Secondary key**: Available after first device unlock (even in background)
    /// - **Primary key**: Requires biometric authentication (only available in foreground)
    ///
    /// - Parameter includingPrimary: Whether to also fetch the primary private key (requires authentication)
    /// - Returns: The private keys if EAR is enabled, or `nil` if EAR is disabled
    /// - Throws: Error if EAR is enabled but keys cannot be accessed
    func fetchPrivateKeys(includingPrimary: Bool) throws -> EARPrivateKeys?

    /// Whether the database is currently locked.
    var isLocked: Bool { get }

    /// Whether encryption at rest is currently enabled for this account.
    var isEAREnabled: Bool { get }

    /// Stores the initial EAR flag value.
    ///
    /// This method exists for migration purposes. The EAR flag was previously stored in
    /// Core Data store metadata but is now stored in shared user defaults. This method
    /// allows copying the flag from the old location to the new location during app updates.
    ///
    /// - Parameter enabled: Whether EAR is enabled
    func setInitialEARFlagValue(_ enabled: Bool)
}
