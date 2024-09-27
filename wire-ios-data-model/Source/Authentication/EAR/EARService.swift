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

import CoreData
import Foundation
import LocalAuthentication

// MARK: - EARServiceInterface

/// An object that provides encryption at rest.
///
/// sourcery: AutoMockable
public protocol EARServiceInterface: AnyObject {
    var delegate: EARServiceDelegate? { get set }

    /// Enable encryption at rest.
    ///
    /// - Parameters:
    ///   - context: a database context in which to perform migrations.
    ///   - skipMigration: whether migration of existing database should be performed.

    func enableEncryptionAtRest(
        context: NSManagedObjectContext,
        skipMigration: Bool
    ) throws

    /// Disable encryption at rest.
    ///
    /// - Parameters:
    ///   - context: a database context in which to perform migrations.
    ///   - skipMigration: whether migration of existing database should be performed.

    func disableEncryptionAtRest(
        context: NSManagedObjectContext,
        skipMigration: Bool
    ) throws

    /// Lock the database.
    ///
    /// Database content can not be decrypted until the database is unlocked.

    func lockDatabase()

    /// Unlock the database.

    func unlockDatabase() throws

    /// Fetch all public keys.
    ///
    /// Public keys are used to encrypt content. If EAR is disabled,
    /// `nil` is returned.

    func fetchPublicKeys() throws -> EARPublicKeys?

    /// Fetch all private keys.
    ///
    /// Private keys are used to decrypt context. If EAR is disabled,
    /// `nil` is returned.

    func fetchPrivateKeys(includingPrimary: Bool) throws -> EARPrivateKeys?

    func setInitialEARFlagValue(_ enabled: Bool)
}

// MARK: - EARService

/// The EARService is responsible for managing encryption at rest functionality. See <doc:encryption-at-rest> for more
/// information about how encryption at rest works.

public class EARService: EARServiceInterface {
    // MARK: Lifecycle

    /// Create a new `EARService`.
    ///
    /// - Parameters:
    ///   - accountID: The id of the self user.
    ///   - databaseContexts: A list of database contexts that require access to the database key.
    ///   - canPerformKeyMigration: Whether key migration can be performed. Key migration should not be performed when
    /// the service is running in app extensions.
    ///   - sharedUserDefaults: The shared user defaults in which to keep track of whether EAR is enabled.
    ///   - authenticationContext: The authentication context used to access encryption keys.

    public convenience init(
        accountID: UUID,
        databaseContexts: [NSManagedObjectContext] = [],
        canPerformKeyMigration: Bool = false,
        sharedUserDefaults: UserDefaults,
        authenticationContext: any AuthenticationContextProtocol
    ) {
        let earStorage = EARStorage(userID: accountID, sharedUserDefaults: sharedUserDefaults)

        self.init(
            accountID: accountID,
            keyRepository: EARKeyRepository(),
            keyEncryptor: EARKeyEncryptor(),
            databaseContexts: databaseContexts,
            canPerformKeyMigration: canPerformKeyMigration,
            earStorage: earStorage,
            authenticationContext: authenticationContext
        )
    }

    init(
        accountID: UUID,
        keyRepository: EARKeyRepositoryInterface = EARKeyRepository(),
        keyEncryptor: EARKeyEncryptorInterface = EARKeyEncryptor(),
        databaseContexts: [NSManagedObjectContext],
        canPerformKeyMigration: Bool,
        earStorage: EARStorage,
        authenticationContext: AuthenticationContextProtocol
    ) {
        self.accountID = accountID
        self.keyRepository = keyRepository
        self.keyEncryptor = keyEncryptor
        self.earStorage = earStorage
        self.databaseContexts = databaseContexts
        self.authenticationContext = authenticationContext

        self.primaryPublicKeyDescription = .primaryKeyDescription(accountID: accountID)
        self.primaryPrivateKeyDescription = .primaryKeyDescription(accountID: accountID, context: nil)
        self.secondaryPublicKeyDescription = .secondaryKeyDescription(accountID: accountID)
        self.secondaryPrivateKeyDescription = .secondaryKeyDescription(accountID: accountID)
        self.databaseKeyDescription = .keyDescription(accountID: accountID)

        if canPerformKeyMigration {
            migrateKeysIfNeeded()
        }
    }

    // MARK: Public

    // MARK: - Properties

    /// An object to assist in migrations.

    public weak var delegate: EARServiceDelegate?

    // MARK: - Feature Flag

    /// Whether encryption at rest is enabled.

    public var isEAREnabled: Bool {
        earStorage.earEnabled()
    }

    /// Store the encryption a rest flag value.
    ///
    /// This flag used to be stored in the database store metadata but was moved to
    /// the shared user defaults. This method was introduced to copy the value from
    /// old location to the new location.

    public func setInitialEARFlagValue(_ enabled: Bool) {
        earStorage.enableEAR(enabled)
    }

    // MARK: - Enable / disable

    /// Enable encryption at rest.
    ///
    /// Invoking this method will generate new encryption keys and prompt the user for
    /// biometric authentication. Sensitive data in the database will be encrypted with
    /// the newly generated database key (unless `skipMigration` is `true`). If an error
    /// occurs during this process, the keys will be destroyed, the migration is rolled
    /// back and encryption at rest will remain disabled.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the migration.
    ///   - skipMigration: Whether the migration should be skipped. This is helpful for testing.

    public func enableEncryptionAtRest(
        context: NSManagedObjectContext,
        skipMigration: Bool = false
    ) throws {
        guard !context.encryptMessagesAtRest else {
            WireLogger.ear.warn("skip enableEncryptionAtRest because EAR already enabled")
            return
        }

        WireLogger.ear.info("turning on EAR")

        let enableEAR: (NSManagedObjectContext) throws -> Void = { [weak self] context in
            guard let self else {
                return
            }

            do {
                try deleteExistingKeys()
                try generateKeys()
                let databaseKey = try fetchDecryptedDatabaseKey()

                if !skipMigration {
                    try context.migrateTowardEncryptionAtRest(databaseKey: databaseKey)
                }

                setDatabaseKeyInAllContexts(databaseKey)
                earStorage.enableEAR(true)
                context.encryptMessagesAtRest = true
            } catch {
                WireLogger.ear.error("failed to turn on EAR: \(error)")
                context.databaseKey = nil
                context.encryptMessagesAtRest = false
                earStorage.enableEAR(false)
                try? deleteExistingKeys()
                throw error
            }
        }

        if skipMigration {
            WireLogger.ear.info("skipping migration")
            try enableEAR(context)
        } else if let delegate {
            WireLogger.ear.info("preparing for migration")
            try delegate.prepareForMigration { context in
                try enableEAR(context)
            }
        } else {
            throw EARServiceFailure.cannotPerformMigration
        }
    }

    /// Disable encryption at rest.
    ///
    /// Invoking this method will decrypt data in the database (unless `skipMigration` is `true`)
    /// and destroy the encryption keys. If an error occurs during this process, the migration
    /// will be rolled back, the keys will not be destroyed, and encryption at rest will remain
    /// enabled.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the migration.
    ///   - skipMigration: Whether the migration should be skipped. This is helpful for testing.

    public func disableEncryptionAtRest(
        context: NSManagedObjectContext,
        skipMigration: Bool = false
    ) throws {
        guard context.encryptMessagesAtRest else {
            WireLogger.ear.warn("skip disableEncryptionAtRest because EAR already disabled ")
            return
        }

        WireLogger.ear.info("turning off EAR")

        guard let databaseKey = context.databaseKey else {
            throw EARServiceFailure.databaseKeyMissing
        }

        let disableEAR: (NSManagedObjectContext) throws -> Void = { [weak self] context in
            guard let self else {
                return
            }

            earStorage.enableEAR(false)
            context.encryptMessagesAtRest = false
            setDatabaseKeyInAllContexts(nil)

            do {
                if !skipMigration {
                    try context.migrateAwayFromEncryptionAtRest(databaseKey: databaseKey)
                }
            } catch {
                WireLogger.ear.error("failed to turn off EAR: \(error)")
                setDatabaseKeyInAllContexts(databaseKey)
                context.encryptMessagesAtRest = true
                earStorage.enableEAR(true)
                throw error
            }

            try? deleteExistingKeys()
        }

        if skipMigration {
            WireLogger.ear.info("skipping migration")
            try disableEAR(context)
        } else if let delegate {
            WireLogger.ear.info("preparing for migration")
            try delegate.prepareForMigration { context in
                try disableEAR(context)
            }
        } else {
            throw EARServiceFailure.cannotPerformMigration
        }
    }

    // MARK: - Public keys

    /// Fetch both the primary and secondary public keys.

    public func fetchPublicKeys() throws -> EARPublicKeys? {
        guard isEAREnabled else {
            return nil
        }

        do {
            WireLogger.ear.debug("fetch public keys")
            return try EARPublicKeys(
                primary: fetchPrimaryPublicKey(),
                secondary: fetchSecondaryPublicKey()
            )
        } catch {
            WireLogger.ear.error("unable to fetch public keys: \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Private keys

    /// Fetch the private keys.
    ///
    /// Access to the private keys is restricted. The secondary key is available in the
    /// background if the device has been unlocked once. The primary key is only available
    /// when the app is active in the foreground.
    ///
    /// - Parameter includingPrimary: Set to `true` to request also the primary private key.
    /// - Returns: The private key(s) if encryption at rest is enabled and the keys are accessible.

    public func fetchPrivateKeys(includingPrimary: Bool) throws -> EARPrivateKeys? {
        guard isEAREnabled else {
            return nil
        }

        do {
            return try EARPrivateKeys(
                primary: includingPrimary ? try? fetchPrimaryPrivateKey() : nil,
                secondary: fetchSecondaryPrivateKey()
            )
        } catch {
            WireLogger.ear.error("unable to fetch private keys: \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Lock / unlock database

    /// Lock the database.
    ///
    /// After invoking this method, the contents of the database are not accessible
    /// until the database is unlocked again.

    public func lockDatabase() {
        WireLogger.ear.info("locking database", attributes: .safePublic)
        setDatabaseKeyInAllContexts(nil)
        keyRepository.clearCache()
    }

    /// Unlock the database.
    ///
    /// Invoking this method will allow access to the database. This will only succeed
    /// the user has authenticated via biometrics.

    public func unlockDatabase() throws {
        do {
            WireLogger.ear.info("unlocking database", attributes: .safePublic)
            let databaseKey = try fetchDecryptedDatabaseKey()
            setDatabaseKeyInAllContexts(databaseKey)
        } catch {
            WireLogger.ear.error("failed to unlock database: \(String(describing: error))")
            throw error
        }
    }

    // MARK: Internal

    func deleteExistingKeys() throws {
        WireLogger.ear.debug("deleting existing keys")
        try deletePrimaryKeys()
        try deleteSecondaryKeys()
        try deleteDatabaseKey()
    }

    @discardableResult
    func generateKeys() throws -> VolatileData {
        WireLogger.ear.debug("generating new keys")

        let primaryPublicKey = try generatePrimaryKeys().publicKey
        let secondaryPublicKey = try generateSecondaryKeys().publicKey
        let databaseKey = try generateDatabaseKey()
        let encryptedDatabaseKey: Data

        do {
            encryptedDatabaseKey = try keyEncryptor.encryptDatabaseKey(
                databaseKey,
                publicKey: primaryPublicKey
            )
        } catch {
            WireLogger.ear.error("failed to generate database key: \(String(describing: error))")
            throw error
        }

        do {
            try storePrimaryPublicKey(primaryPublicKey)
            try storeSecondaryPublicKey(secondaryPublicKey)
            try storeDatabaseKey(encryptedDatabaseKey)
        } catch {
            WireLogger.ear.error("failed to store keys: \(String(describing: error))")
            throw error
        }

        return VolatileData(from: databaseKey)
    }

    func setDatabaseKeyInAllContexts(_ key: VolatileData?) {
        performInAllContexts {
            $0.databaseKey = key
        }
    }

    // MARK: Private

    private let accountID: UUID
    private let keyGenerator = EARKeyGenerator()
    private let keyEncryptor: EARKeyEncryptorInterface
    private let keyRepository: EARKeyRepositoryInterface
    private let databaseContexts: [NSManagedObjectContext]

    private let primaryPublicKeyDescription: PublicEARKeyDescription
    private let primaryPrivateKeyDescription: PrivateEARKeyDescription
    private let secondaryPublicKeyDescription: PublicEARKeyDescription
    private let secondaryPrivateKeyDescription: PrivateEARKeyDescription
    private let databaseKeyDescription: DatabaseEARKeyDescription
    private let earStorage: EARStorage

    private let authenticationContext: any AuthenticationContextProtocol

    // MARK: - Keys

    private var existSecondaryKeys: Bool {
        (try? fetchSecondaryPublicKey()) != nil
    }

    // MARK: - Migrate keys

    private func migrateKeysIfNeeded() {
        WireLogger.ear.info("migrating ear keys if needed...", attributes: .safePublic)

        guard
            isEAREnabled,
            !existSecondaryKeys
        else {
            return
        }

        do {
            let secondaryKeys = try generateSecondaryKeys()
            try storeSecondaryPublicKey(secondaryKeys.publicKey)
        } catch {
            WireLogger.ear.error("failed to migrate keys: \(error)")
        }
    }

    private func deletePrimaryKeys() throws {
        try keyRepository.deletePublicKey(description: primaryPublicKeyDescription)
        try keyRepository.deletePrivateKey(description: primaryPrivateKeyDescription)
    }

    private func deleteSecondaryKeys() throws {
        try keyRepository.deletePublicKey(description: secondaryPublicKeyDescription)
        try keyRepository.deletePrivateKey(description: secondaryPrivateKeyDescription)
    }

    private func deleteDatabaseKey() throws {
        try keyRepository.deleteDatabaseKey(description: databaseKeyDescription)
    }

    private func generatePrimaryKeys() throws -> (publicKey: SecKey, privateKey: SecKey) {
        do {
            let id = primaryPrivateKeyDescription.id
            return try keyGenerator.generatePrimaryPublicPrivateKeyPair(id: id)
        } catch {
            WireLogger.ear.error("failed to generate primary public private keypair: \(String(describing: error))")
            throw error
        }
    }

    private func generateSecondaryKeys() throws -> (publicKey: SecKey, privateKey: SecKey) {
        WireLogger.ear.debug("generating secondary keys")

        do {
            let id = secondaryPrivateKeyDescription.id
            return try keyGenerator.generateSecondaryPublicPrivateKeyPair(id: id)
        } catch {
            WireLogger.ear.error("failed to generate secondary public private keypair: \(String(describing: error))")
            throw error
        }
    }

    private func generateDatabaseKey() throws -> Data {
        try keyGenerator.generateKey(numberOfBytes: 32)
    }

    private func storePrimaryPublicKey(_ key: SecKey) throws {
        WireLogger.ear.debug("storing primary public key")
        try keyRepository.storePublicKey(
            description: primaryPublicKeyDescription,
            key: key
        )
    }

    private func storeSecondaryPublicKey(_ key: SecKey) throws {
        WireLogger.ear.debug("storing secondary public key")
        try keyRepository.storePublicKey(
            description: secondaryPublicKeyDescription,
            key: key
        )
    }

    private func storeDatabaseKey(_ key: Data) throws {
        WireLogger.ear.debug("storing database key")
        try keyRepository.storeDatabaseKey(
            description: databaseKeyDescription,
            key: key
        )
    }

    private func fetchPrimaryPublicKey() throws -> SecKey {
        try keyRepository.fetchPublicKey(description: primaryPublicKeyDescription)
    }

    private func fetchSecondaryPublicKey() throws -> SecKey {
        try keyRepository.fetchPublicKey(description: secondaryPublicKeyDescription)
    }

    private func fetchPrimaryPrivateKey() throws -> SecKey {
        WireLogger.ear.debug("fetching private primary key")

        // create a new description instead of the stored `primaryPrivateKeyDescription`,
        // because it doesn't not use the `authenticationContext`.

        let authenticatedKeyDescription: PrivateEARKeyDescription = .primaryKeyDescription(
            accountID: accountID,
            context: authenticationContext
        )

        return try keyRepository.fetchPrivateKey(description: authenticatedKeyDescription)
    }

    private func fetchSecondaryPrivateKey() throws -> SecKey {
        try keyRepository.fetchPrivateKey(description: secondaryPrivateKeyDescription)
    }

    // MARK: - Database key

    private func fetchDecryptedDatabaseKey() throws -> VolatileData {
        let privateKey = try fetchPrimaryPrivateKey()
        let encryptedDatabaseKeyData = try fetchEncryptedDatabaseKey()
        let databaseKeyData = try keyEncryptor.decryptDatabaseKey(
            encryptedDatabaseKeyData,
            privateKey: privateKey
        )
        return VolatileData(from: databaseKeyData)
    }

    private func fetchEncryptedDatabaseKey() throws -> Data {
        try keyRepository.fetchDatabaseKey(description: databaseKeyDescription)
    }

    private func performInAllContexts(_ block: (NSManagedObjectContext) -> Void) {
        for context in databaseContexts {
            context.performAndWait {
                block(context)
            }
        }
    }
}
