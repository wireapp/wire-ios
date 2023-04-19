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

/// An object that provides encryption at rest services.

public protocol EARServiceInterface: AnyObject {

    var delegate: EARServiceDelegate? { get set }

    /// Enable encryption at rest.
    ///
    /// - Parameters:
    ///   - context: a database context in which to perform migrations.
    ///   - skipMigration: whethr migration of existing database should be performed.

    func enableEncryptionAtRest(
        context: NSManagedObjectContext,
        skipMigration: Bool
    ) throws

    /// Disable encryption at rest.
    ///
    /// - Parameters:
    ///   - context: a database context in which to perform migrations.
    ///   - skipMigration: whethr migration of existing database should be performed.

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

    func prepareForMigration(onReady: @escaping (NSManagedObjectContext) throws -> Void)

}

public enum EARServiceFailure: Error {

    case cannotPerformMigration

}

public class EARService: EARServiceInterface {

    // MARK: - Properties

    public weak var delegate: EARServiceDelegate?

    private let accountID: UUID
    private let keyRepository: EARKeyRepositoryInterface
    private let databaseContexts: [NSManagedObjectContext]

    private let primaryPublicKeyDescription: PublicEARKeyDescription
    private let primaryPrivateKeyDescription: PrivateEARKeyDescription
    private let secondaryPublicKeyDescription: PublicEARKeyDescription
    private let secondaryPrivateKeyDescription: PrivateEARKeyDescription
    private let databaseKeyDescription: DatabaseEARKeyDescription

    // MARK: - Life cycle

    public init(
        accountID: UUID,
        keyRepository: EARKeyRepositoryInterface = EARKeyRepository(),
        databaseContexts: NSManagedObjectContext...
    ) {
        self.accountID = accountID
        self.keyRepository = keyRepository
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

        try deleteExistingKeys()
        let databaseKey = try generateKeys()
        storeDatabaseKeyInAllContexts(databaseKey)

        let enableEAR = { (context: NSManagedObjectContext) in
            try context.enableEncryptionAtRest(
                databaseKey: databaseKey,
                skipMigration: skipMigration
            )
        }

        if skipMigration {
            WireLogger.ear.info("skipping migration")
            try enableEAR(context)
        } else if let delegate = delegate {
            WireLogger.ear.info("preparing for migration")
            delegate.prepareForMigration { context in
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

        let databaseKey = context.databaseKey!
        clearDatabaseKeyInAllContexts()

        let disableEAR = { [weak self] (context: NSManagedObjectContext) in
            guard let `self` = self else { return }
            try context.disableEncryptionAtRest(
                databaseKey: databaseKey,
                skipMigration: skipMigration
            )
            try self.deleteExistingKeys()
        }

        if skipMigration {
            try disableEAR(context)
        } else {
            delegate?.prepareForMigration { context in
                try disableEAR(context)
            }
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

        do {
            let identifier = primaryPrivateKeyDescription.id
            let keyPair = try KeychainManager.generatePublicPrivateKeyPair(identifier: identifier)
            primaryPublicKey = keyPair.publicKey
        } catch {
            WireLogger.ear.error("failed to generate primary public private keypair: \(String(describing: error))")
            throw error
        }

        do {
            let identifier = secondaryPrivateKeyDescription.id
            let keyPair = try KeychainManager.generatePublicPrivateKeyPair(identifier: identifier)
            secondaryPublicKey = keyPair.publicKey
        } catch {
            WireLogger.ear.error("failed to generate secondary public private keypair: \(String(describing: error))")
            throw error
        }

        do {
            let databaseKeyData = try KeychainManager.generateKey(numberOfBytes: 32)
            databaseKey = try encryptDatabaseKey(databaseKeyData, publicKey: primaryPublicKey)
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
                key: databaseKey
            )
        } catch {
            WireLogger.ear.error("failed to store keys: \(String(describing: error))")
            try? deleteExistingKeys()
            throw error
        }

        return VolatileData(from: databaseKey)
    }

    public func fetchPublicKeys() throws -> EARPublicKeys {
        do {
            let primary = try keyRepository.fetchPublicKey(description: primaryPublicKeyDescription)
            let secondary = try keyRepository.fetchPublicKey(description: secondaryPublicKeyDescription)

            return EARPublicKeys(
                primary: primary,
                secondary: secondary
            )
        } catch {
            WireLogger.ear.error("unable to fetch public keys: \(String(describing: error))")
            throw error
        }
    }

    public func fetchPrivateKeys() throws -> EARPrivateKeys {
        do {
            let primary = try? keyRepository.fetchPrivateKey(description: primaryPrivateKeyDescription)
            let secondary = try keyRepository.fetchPrivateKey(description: secondaryPrivateKeyDescription)

            return EARPrivateKeys(
                primary: primary,
                secondary: secondary
            )
        } catch {
            WireLogger.ear.error("unable to fetch private keys: \(String(describing: error))")
            throw error
        }
    }

    private func fetchDecyptedDatabaseKey(context: LAContext) throws -> VolatileData {
        let privateKey = try fetchPrimaryPrivateKey()
        let encryptedDatabaseKeyData = try fetchEncryptedDatabaseKey()
        let databaseKeyData = try decryptDatabaseKey(encryptedDatabaseKeyData, privateKey: privateKey)
        return VolatileData(from: databaseKeyData)
    }

    private func fetchPrimaryPrivateKey() throws -> SecKey {
        return try keyRepository.fetchPrivateKey(description: primaryPrivateKeyDescription)
    }

    private func fetchEncryptedDatabaseKey() throws -> Data {
        return try keyRepository.fetchDatabaseKey(description: databaseKeyDescription)

    }

    private func encryptDatabaseKey(
        _ databaseKey: Data,
        publicKey: SecKey
    ) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let encryptedDatabaseKey = SecKeyCreateEncryptedData(
            publicKey,
            databaseKeyAlgorithm,
            databaseKey as CFData, &error
        ) else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }

        return encryptedDatabaseKey as Data
    }

    private func decryptDatabaseKey(
        _ encryptedDatabaseKey: Data,
        privateKey: SecKey
    ) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let databaseKey = SecKeyCreateDecryptedData(
            privateKey,
            databaseKeyAlgorithm,
            encryptedDatabaseKey as CFData,
            &error
        ) else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }

        return databaseKey as Data
    }

    private var databaseKeyAlgorithm: SecKeyAlgorithm {
        return .eciesEncryptionCofactorX963SHA256AESGCM
    }

    // MARK: - Lock / unlock database

    public func lockDatabase() {
        WireLogger.ear.info("locking database")
        clearDatabaseKeyInAllContexts()
    }

    public func unlockDatabase(context: LAContext) throws {
        do {
            WireLogger.ear.info("unlocking database")
            let databaseKey = try fetchDecyptedDatabaseKey(context: context)
            storeDatabaseKeyInAllContexts(databaseKey)
        } catch {
            WireLogger.ear.error("failed to unlock database: \(String(describing: error))")
            throw error
        }
    }

    private func storeDatabaseKeyInAllContexts(_ key: VolatileData) {
        performInAllContexts {
            $0.databaseKey = key
        }
    }

    private func clearDatabaseKeyInAllContexts() {
        performInAllContexts {
            $0.databaseKey = nil
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

}

public struct EARPrivateKeys {

    public let primary: SecKey?
    public let secondary: SecKey

}
