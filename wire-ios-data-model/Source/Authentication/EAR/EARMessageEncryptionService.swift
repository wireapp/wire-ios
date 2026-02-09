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

// TODO: Add doc comments
public protocol EARMessageEncryptionServiceProtocol {

    var isLocked: Bool { get }

    func setDatabaseKey(_ key: VolatileData?)

    func getDatabaseKey() -> VolatileData?

    func getContextData(
        from context: NSManagedObjectContext
    ) throws -> Data

    func encrypt(
        data: Data,
        contextData: Data
    ) throws -> (data: Data, nonce: Data)

    func encrypt(
        data: Data,
        contextData: Data,
        databaseKey: VolatileData
    ) throws -> (data: Data, nonce: Data)

    func decrypt(
        data: Data,
        nonce: Data,
        contextData: Data
    ) throws -> Data

    func decrypt(
        data: Data,
        nonce: Data,
        contextData: Data,
        databaseKey: VolatileData
    ) throws -> Data
}

public final class EARMessageEncryptionService: EARMessageEncryptionServiceProtocol {

    // MARK: - Properties

    private let lock = NSLock()
    private var databaseKey: VolatileData?
    private let earStorage: EARStorage
    private var cachedContextData: Data?

    // MARK: - Types

    enum EncryptionError: LocalizedError {

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
        if let cached = cachedContextData {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let contextData = try context.earContextData()

        lock.lock()
        cachedContextData = contextData
        lock.unlock()

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
        guard let key = databaseKey else {
            lock.unlock()
            throw EncryptionError.missingDatabaseKey
        }
        lock.unlock()

        return try encrypt(data: data, contextData: contextData, databaseKey: key)
    }

    public func encrypt(
        data: Data,
        contextData: Data,
        databaseKey: VolatileData
    ) throws -> (data: Data, nonce: Data) {

        WireLogger.ear.debug("encrypting data for EAR")

        do {
            let (ciphertext, nonce) = try ChaCha20Poly1305.AEADEncryption.encrypt(
                message: data,
                context: contextData,
                key: databaseKey._storage
            )
            return (ciphertext, nonce)
        } catch let error as ChaCha20Poly1305.AEADEncryption.EncryptionError {
            WireLogger.ear.debug("failed to encrypt data for EAR with error: \(error.errorDescription ?? "unknown")")
            throw EncryptionError.crypto(error: error)
        }
    }

    public func decrypt(
        data: Data,
        nonce: Data,
        contextData: Data
    ) throws -> Data {
        lock.lock()
        guard let key = databaseKey else {
            lock.unlock()
            throw EncryptionError.missingDatabaseKey
        }
        lock.unlock()

        return try decrypt(
            data: data,
            nonce: nonce,
            contextData: contextData,
            databaseKey: key
        )
    }

    public func decrypt(
        data: Data,
        nonce: Data,
        contextData: Data,
        databaseKey: VolatileData
    ) throws -> Data {

        WireLogger.ear.debug("decrypting data for EAR")

        do {
            return try ChaCha20Poly1305.AEADEncryption.decrypt(
                ciphertext: data,
                nonce: nonce,
                context: contextData,
                key: databaseKey._storage
            )
        } catch let error as ChaCha20Poly1305.AEADEncryption.EncryptionError {
            WireLogger.ear.debug("failed to decrypt data for EAR with error: \(error.errorDescription ?? "unknown")")
            throw EncryptionError.crypto(error: error)
        }
    }

}
