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
    ///
    /// - Parameters:
    ///   - context: a user authenticated context.

    func unlockDatabase(context: LAContext) throws

    /// Fetch all public keys.
    ///
    /// Public keys are used to encrypt content.

    func fetchPublicKeys() throws -> EARPublicKeys

    /// Fetch all private keys.
    ///
    /// Private keys are used to decrypt context.

    func fetchPrivateKeys() throws -> EARPrivateKeys

}

public protocol EARServiceDelegate: AnyObject {

    /// Prepare for the migration of existing database content.
    ///
    /// When the migration can be started, invoke the `onReady` closure.

    func prepareForMigration(onReady: @escaping (NSManagedObjectContext) throws -> Void) rethrows

}

public enum EARServiceFailure: Error {

    case cannotPerformMigration
    case databaseKeyMissing

}

public class EARService: EARServiceInterface {

    // MARK: - Properties

    public weak var delegate: EARServiceDelegate?

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

    // MARK: - Life cycle

    public convenience init(
        accountID: UUID,
        databaseContexts: [NSManagedObjectContext] = []
    ) {
        self.init(
            accountID: accountID,
            keyRepository: EARKeyRepository(),
            keyEncryptor: EARKeyEncryptor(),
            databaseContexts: databaseContexts
        )
    }

    init(
        accountID: UUID,
        keyRepository: EARKeyRepositoryInterface = EARKeyRepository(),
        keyEncryptor: EARKeyEncryptorInterface = EARKeyEncryptor(),
        databaseContexts: [NSManagedObjectContext]
    ) {
        self.accountID = accountID
        self.keyRepository = keyRepository
        self.keyEncryptor = keyEncryptor
        self.databaseContexts = databaseContexts
        primaryPublicKeyDescription = .primaryKeyDescription(accountID: accountID)
        primaryPrivateKeyDescription = .primaryKeyDescription(accountID: accountID)
        secondaryPublicKeyDescription = .secondaryKeyDescription(accountID: accountID)
        secondaryPrivateKeyDescription = .secondaryKeyDescription(accountID: accountID)
        databaseKeyDescription = .keyDescription(accountID: accountID)
    }

    // MARK: - Enable / disable

    public func enableEncryptionAtRest(
        context: NSManagedObjectContext,
        skipMigration: Bool = false
    ) throws {
        guard !context.encryptMessagesAtRest else {
            return
        }

        WireLogger.ear.info("turning on EAR")

        let enableEAR: (NSManagedObjectContext) throws -> Void = { [weak self] context in
            guard let `self` = self else { return }

            do {
                try self.deleteExistingKeys()
                let databaseKey = try self.generateKeys()

                if !skipMigration {
                    try context.migrateTowardEncryptionAtRest(databaseKey: databaseKey)
                }

                self.setDatabaseKeyInAllContexts(databaseKey)
                context.encryptMessagesAtRest = true
            } catch {
                WireLogger.ear.error("failed to turn on EAR: \(error)")
                context.databaseKey = nil
                context.encryptMessagesAtRest = false
                try? self.deleteExistingKeys()
                throw error
            }
        }

        if skipMigration {
            WireLogger.ear.info("skipping migration")
            try enableEAR(context)
        } else if let delegate = delegate {
            WireLogger.ear.info("preparing for migration")
            try delegate.prepareForMigration { context in
                try enableEAR(context)
            }
        } else {
            throw EARServiceFailure.cannotPerformMigration
        }
    }

    public func disableEncryptionAtRest(
        context: NSManagedObjectContext,
        skipMigration: Bool = false
    ) throws {
        guard context.encryptMessagesAtRest else {
            return
        }

        WireLogger.ear.info("turning off EAR")

        guard let databaseKey = context.databaseKey else {
            throw EARServiceFailure.databaseKeyMissing
        }

        let disableEAR: (NSManagedObjectContext) throws -> Void = { [weak self] context in
            guard let `self` = self else { return }

            context.encryptMessagesAtRest = false
            self.setDatabaseKeyInAllContexts(nil)

            do {
                if !skipMigration {
                    try context.migrateAwayFromEncryptionAtRest(databaseKey: databaseKey)
                }
            } catch {
                WireLogger.ear.error("failed to turn off EAR: \(error)")
                self.setDatabaseKeyInAllContexts(databaseKey)
                context.encryptMessagesAtRest = true
                throw error
            }

            try? self.deleteExistingKeys()
        }

        if skipMigration {
            WireLogger.ear.info("skipping migration")
            try disableEAR(context)
        } else if let delegate = delegate {
            WireLogger.ear.info("preparing for migration")
            try delegate.prepareForMigration { context in
                try disableEAR(context)
            }
        }  else {
            throw EARServiceFailure.cannotPerformMigration
        }
    }

    // MARK: - Keys

    private func deleteExistingKeys() throws {
        WireLogger.ear.info("deleting existing keys")
        try keyRepository.deletePublicKey(description: primaryPublicKeyDescription)
        try keyRepository.deletePrivateKey(description: primaryPrivateKeyDescription)
        try keyRepository.deletePublicKey(description: secondaryPublicKeyDescription)
        try keyRepository.deletePrivateKey(description: secondaryPrivateKeyDescription)
        try keyRepository.deleteDatabaseKey(description: databaseKeyDescription)
    }

    private func generateKeys() throws -> VolatileData {
        WireLogger.ear.info("generating new keys")
        let primaryPublicKey: SecKey
        let secondaryPublicKey: SecKey
        let databaseKey: Data
        let encryptedDatabaseKey: Data

        do {
            let id = primaryPrivateKeyDescription.id
            let keyPair = try keyGenerator.generatePrimaryPublicPrivateKeyPair(id: id)
            primaryPublicKey = keyPair.publicKey
        } catch {
            WireLogger.ear.error("failed to generate primary public private keypair: \(String(describing: error))")
            throw error
        }

        do {
            let id = secondaryPrivateKeyDescription.id
            let keyPair = try keyGenerator.generateSecondaryPublicPrivateKeyPair(id: id)
            secondaryPublicKey = keyPair.publicKey
        } catch {
            WireLogger.ear.error("failed to generate secondary public private keypair: \(String(describing: error))")
            throw error
        }

        do {
            databaseKey = try keyGenerator.generateKey(numberOfBytes: 32)
            encryptedDatabaseKey = try keyEncryptor.encryptDatabaseKey(
                databaseKey,
                publicKey: primaryPublicKey
            )
        } catch {
            WireLogger.ear.error("failed to generate database key: \(String(describing: error))")
            throw error
        }

        do {
            try keyRepository.storePublicKey(
                description: primaryPublicKeyDescription,
                key: primaryPublicKey
            )

            try keyRepository.storePublicKey(
                description: secondaryPublicKeyDescription,
                key: secondaryPublicKey
            )

            try keyRepository.storeDatabaseKey(
                description: databaseKeyDescription,
                key: encryptedDatabaseKey
            )
        } catch {
            WireLogger.ear.error("failed to store keys: \(String(describing: error))")
            throw error
        }

        return VolatileData(from: databaseKey)
    }

    // MARK: - Public keys

    public func fetchPublicKeys() throws -> EARPublicKeys {
        do {
            return EARPublicKeys(
                primary: try fetchPrimaryPublicKey(),
                secondary: try fetchSecondaryPublicKey()
            )
        } catch {
            WireLogger.ear.error("unable to fetch public keys: \(String(describing: error))")
            throw error
        }
    }

    private func fetchPrimaryPublicKey() throws -> SecKey {
        return try keyRepository.fetchPublicKey(description: primaryPublicKeyDescription)
    }

    private func fetchSecondaryPublicKey() throws -> SecKey {
        return try keyRepository.fetchPublicKey(description: secondaryPublicKeyDescription)
    }

    // MARK: - Private keys

    public func fetchPrivateKeys() throws -> EARPrivateKeys {
        do {
            return EARPrivateKeys(
                primary: try? fetchPrimaryPrivateKey(),
                secondary: try fetchSecondaryPrivateKey()
            )
        } catch {
            WireLogger.ear.error("unable to fetch private keys: \(String(describing: error))")
            throw error
        }
    }

    private func fetchPrimaryPrivateKey(context: LAContext? = nil) throws -> SecKey {
        if let context = context {
            let authenticatedKeyDescription = PrivateEARKeyDescription.primaryKeyDescription(
                accountID: accountID,
                context: context
            )

            return try keyRepository.fetchPrivateKey(description: authenticatedKeyDescription)
        } else {
            return try keyRepository.fetchPrivateKey(description: primaryPrivateKeyDescription)
        }
    }

    private func fetchSecondaryPrivateKey() throws -> SecKey {
        return try keyRepository.fetchPrivateKey(description: secondaryPrivateKeyDescription)
    }

    // MARK: - Database key

    private func fetchDecyptedDatabaseKey(context: LAContext) throws -> VolatileData {
        let privateKey = try fetchPrimaryPrivateKey(context: context)
        let encryptedDatabaseKeyData = try fetchEncryptedDatabaseKey()
        let databaseKeyData = try keyEncryptor.decryptDatabaseKey(
            encryptedDatabaseKeyData,
            privateKey: privateKey
        )
        return VolatileData(from: databaseKeyData)
    }

    private func fetchEncryptedDatabaseKey() throws -> Data {
        return try keyRepository.fetchDatabaseKey(description: databaseKeyDescription)

    }

    // MARK: - Lock / unlock database

    public func lockDatabase() {
        WireLogger.ear.info("locking database")
        setDatabaseKeyInAllContexts(nil)
        keyRepository.clearCache()
    }

    public func unlockDatabase(context: LAContext) throws {
        do {
            WireLogger.ear.info("unlocking database")
            let databaseKey = try fetchDecyptedDatabaseKey(context: context)
            setDatabaseKeyInAllContexts(databaseKey)
        } catch {
            WireLogger.ear.error("failed to unlock database: \(String(describing: error))")
            throw error
        }
    }

    private func setDatabaseKeyInAllContexts(_ key: VolatileData?) {
        performInAllContexts {
            $0.databaseKey = key
        }
    }

    private func performInAllContexts(_ block: (NSManagedObjectContext) -> Void) {
        for context in databaseContexts {
            context.performAndWait {
                block(context)
            }
        }
    }

}

public struct EARPublicKeys {

    public let primary: SecKey
    public let secondary: SecKey

    public init(
        primary: SecKey,
        secondary: SecKey
    ) {
        self.primary = primary
        self.secondary = secondary
    }

}

public struct EARPrivateKeys {

    public let primary: SecKey?
    public let secondary: SecKey

    public init(
        primary: SecKey?,
        secondary: SecKey
    ) {
        self.primary = primary
        self.secondary = secondary
    }

}
