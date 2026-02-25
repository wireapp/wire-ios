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

import WireCrypto
import WireLogging

/// Protocol for encrypting and decrypting sensitive data when Encryption at Rest (EAR) is enabled.
///
/// This service provides authenticated encryption using ChaCha20-Poly1305 AEAD (Authenticated Encryption with
/// Associated Data).
/// All encryption operations require a database key and context data for additional authentication.
///
/// ## Thread Safety
///
/// All methods are thread-safe and can be called from any queue.
///
/// ## Key Management
///
/// The database key is volatile and stored only in memory. When the database is locked:
/// - The database key is cleared from memory
/// - All encryption/decryption operations fail with `EncryptionError.missingDatabaseKey`
/// - The cached context data is also cleared
///
/// sourcery: AutoMockable
public protocol EARMessageEncryptionServiceProtocol {

    /// Whether the database is currently locked.
    ///
    /// Returns `true` if EAR is enabled and the database key is not available (database is locked).
    /// Returns `false` if EAR is disabled or the database is unlocked.
    var isLocked: Bool { get }

    /// Sets or clears the database encryption key.
    ///
    /// - Parameter key: The database key to use for encryption/decryption, or `nil` to lock the database.
    ///
    /// When `key` is `nil`:
    /// - The database becomes locked
    /// - Cached context data is cleared
    /// - All subsequent encryption/decryption operations will fail
    func setDatabaseKey(_ key: VolatileData?)

    /// Retrieves the current database key.
    ///
    /// - Returns: The database key if set, or `nil` if the database is locked.
    func getDatabaseKey() -> VolatileData?

    /// Retrieves and caches the context data for authenticated encryption.
    ///
    /// Context data (also known as Associated Authenticated Data or AAD) provides additional
    /// authentication without being encrypted. It typically includes the self-client identifier
    /// to bind encrypted data to a specific device.
    ///
    /// The context data is cached after first retrieval to avoid repeated lookups on every
    /// encryption/decryption operation.
    ///
    /// - Parameter context: The managed object context to fetch the self-client from
    /// - Returns: The context data for use in encryption/decryption
    /// - Throws: `EncryptionError.missingContextData` if the self-client is not available
    func getContextData(
        from context: NSManagedObjectContext
    ) throws -> Data

    /// Encrypts data using ChaCha20-Poly1305 AEAD.
    ///
    /// - Parameters:
    ///   - data: The plaintext data to encrypt
    ///   - contextData: Additional authenticated data (typically self-client ID)
    /// - Returns: A tuple containing the encrypted ciphertext and the nonce
    /// - Throws:
    ///   - `EncryptionError.missingDatabaseKey` if the database is locked
    ///   - `EncryptionError.crypto` if the cryptographic operation fails
    func encrypt(
        data: Data,
        contextData: Data
    ) throws -> (data: Data, nonce: Data)

    /// Decrypts data using ChaCha20-Poly1305 AEAD.
    ///
    /// - Parameters:
    ///   - data: The encrypted ciphertext to decrypt
    ///   - nonce: The nonce that was used during encryption
    ///   - contextData: Additional authenticated data (must match encryption context)
    /// - Returns: The decrypted plaintext data
    /// - Throws:
    ///   - `EncryptionError.missingDatabaseKey` if the database is locked
    ///   - `EncryptionError.crypto` if decryption or authentication fails
    func decrypt(
        data: Data,
        nonce: Data,
        contextData: Data
    ) throws -> Data

}

public final class EARMessageEncryptionService: EARMessageEncryptionServiceProtocol {

    // MARK: - Properties

    private let lock = NSLock()
    private var databaseKey: VolatileData?
    private let earStorage: EARStorage
    private var cachedContextData: Data?

    // MARK: - Types

    enum EncryptionError: LocalizedError, Equatable {

        case missingDatabaseKey
        case missingContextData
        case crypto(error: ChaCha20Poly1305.AEADEncryption.EncryptionError)

        var errorDescription: String? {
            switch self {
            case .missingDatabaseKey:
                "Database key not found. Perhaps the database is locked."

            case .missingContextData:
                "Couldn't obtain context data."

            case let .crypto(error):
                error.errorDescription
            }
        }

    }

    // MARK: - Init

    init(earStorage: EARStorage) {
        self.earStorage = earStorage
    }

    // MARK: - Public Interface

    public var isLocked: Bool {
        guard earStorage.earEnabled() else { return false }
        lock.lock()
        defer { lock.unlock() }
        return databaseKey == nil
    }

    // This is to make sure the context data gets cached lazily in order to improve the performance,
    // otherwise we would fetch it for every encryption / decryption.
    // It would be cleaner to inject it at the beginning of the life cycle but we're not guaranteed to
    // have the self client at that time.
    public func getContextData(from context: NSManagedObjectContext) throws -> Data {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cachedContextData {
            return cached
        }

        let contextData = try context.earContextData()
        cachedContextData = contextData
        return contextData
    }

    public func setDatabaseKey(_ key: VolatileData?) {
        lock.lock()
        defer { lock.unlock() }
        databaseKey = key
        if key == nil {
            cachedContextData = nil
        }
        WireLogger.ear.debug("Database key \(key == nil ? "cleared" : "set")")
    }

    public func getDatabaseKey() -> VolatileData? {
        lock.lock()
        defer { lock.unlock() }
        return databaseKey
    }

    public func encrypt(
        data: Data,
        contextData: Data
    ) throws -> (data: Data, nonce: Data) {
        lock.lock()
        defer { lock.unlock() }

        guard let key = databaseKey else {
            WireLogger.ear.error("failed to encrypt data for EAR: missing database key", attributes: .safePublic)
            throw EncryptionError.missingDatabaseKey
        }

        WireLogger.ear.debug("encrypting data for EAR")

        do {
            let (ciphertext, nonce) = try ChaCha20Poly1305.AEADEncryption.encrypt(
                message: data,
                context: contextData,
                key: key._storage
            )
            return (ciphertext, nonce)
        } catch let error as ChaCha20Poly1305.AEADEncryption.EncryptionError {
            WireLogger.ear.error(
                "failed to encrypt data for EAR with error: \(error.errorDescription ?? "unknown")",
                attributes: .safePublic
            )
            throw EncryptionError.crypto(error: error)
        }
    }

    public func decrypt(
        data: Data,
        nonce: Data,
        contextData: Data
    ) throws -> Data {
        lock.lock()
        defer { lock.unlock() }

        guard let key = databaseKey else {
            WireLogger.ear.error("failed to decrypt data for EAR: missing database key", attributes: .safePublic)
            throw EncryptionError.missingDatabaseKey
        }

        WireLogger.ear.debug("decrypting data for EAR")

        do {
            return try ChaCha20Poly1305.AEADEncryption.decrypt(
                ciphertext: data,
                nonce: nonce,
                context: contextData,
                key: key._storage
            )
        } catch let error as ChaCha20Poly1305.AEADEncryption.EncryptionError {
            WireLogger.ear.error(
                "failed to decrypt data for EAR with error: \(error.errorDescription ?? "unknown")",
                attributes: .safePublic
            )
            throw EncryptionError.crypto(error: error)
        }
    }

}
