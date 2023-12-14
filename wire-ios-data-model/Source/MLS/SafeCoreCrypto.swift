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
import WireCoreCrypto

// MARK: - Protocols

public protocol SafeCoreCryptoProtocol {
    func perform<T>(_ block: (CoreCryptoProtocol) async throws -> T) async rethrows -> T
    func perform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T
    func unsafePerform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T
    func mlsInit(clientID: String) throws
    func tearDown() throws
}

let defaultCipherSuite = CiphersuiteName.mls128Dhkemx25519Aes128gcmSha256Ed25519

public class SafeCoreCrypto: SafeCoreCryptoProtocol {
    
    public enum CoreCryptoSetupFailure: Error, Equatable {
        case failedToGetClientIDBytes
    }

    private let coreCrypto: CoreCryptoProtocol
    private let safeContext: SafeFileContext
    private var didInitializeMLS = false
    private let databasePath: String

    public convenience init(coreCryptoConfiguration config: CoreCryptoConfiguration) throws {
        guard let clientID = config.clientIDBytes else {
            throw CoreCryptoSetupFailure.failedToGetClientIDBytes
        }

        let coreCrypto = try CoreCrypto(
            path: config.path,
            key: config.key,
            clientId: clientID,
            ciphersuites: [defaultCipherSuite.rawValue]
        )

        self.init(coreCrypto: coreCrypto, databasePath: config.path)
        didInitializeMLS = true
    }

    public convenience init(path: String, key: String) throws {
        let coreCrypto = try CoreCrypto.deferredInit(
            path: path,
            key: key,
            ciphersuites: [defaultCipherSuite.rawValue]
        )

        try coreCrypto.setCallbacks(callbacks: CoreCryptoCallbacksImpl())

        self.init(coreCrypto: coreCrypto, databasePath: path)
    }

    public func mlsInit(clientID: String) throws {
        guard !didInitializeMLS else { return }

        guard let clientIdBytes = ClientId(from: clientID) else {
            throw CoreCryptoSetupFailure.failedToGetClientIDBytes
        }

        try coreCrypto.mlsInit(clientId: clientIdBytes,
                               ciphersuites: [defaultCipherSuite.rawValue])
        didInitializeMLS = true
    }

    init(coreCrypto: CoreCryptoProtocol, databasePath: String) {
        self.coreCrypto = coreCrypto
        self.databasePath = databasePath
        let directoryPathUrl = URL(fileURLWithPath: databasePath).deletingLastPathComponent()
        self.safeContext = SafeFileContext(fileURL: directoryPathUrl)
    }

    public func tearDown() throws {
        _ = try FileManager.default.removeItem(atPath: databasePath)
    }

    public func perform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T {
        var result: T
        WireLogger.coreCrypto.info("acquiring directory lock")
        safeContext.acquireDirectoryLock()
        WireLogger.coreCrypto.info("acquired lock. performing restoreFromDisk()")
        restoreFromDisk()

        defer {
            WireLogger.coreCrypto.info("releasing directory lock")
            safeContext.releaseDirectoryLock()
            WireLogger.coreCrypto.info("released lock")
        }

        do {
            result = try block(coreCrypto)
        } catch {
            WireLogger.coreCrypto.error("failed to perform block on core crypto")
            throw error
        }

        return result
    }

    // TODO: Remove when async core crypto is supported
    public func perform<T>(_ block: (WireCoreCrypto.CoreCryptoProtocol) async throws -> T) async rethrows -> T {
        try await block(coreCrypto)
    }

    public func unsafePerform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T {
        return try block(coreCrypto)
    }

    private func restoreFromDisk() {
        do {
            try coreCrypto.restoreFromDisk()
        } catch {
            WireLogger.coreCrypto.error(error.localizedDescription)
        }
    }
}
