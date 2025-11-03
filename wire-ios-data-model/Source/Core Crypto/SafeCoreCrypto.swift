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

import Foundation
import WireCoreCrypto
import WireLegacyLogging

// MARK: - Protocols

public protocol SafeCoreCryptoProtocol {
    func perform<T>(_ block: @escaping (CoreCryptoContextProtocol) async throws -> T) async throws -> T
    func unsafePerform<T>(_ block: @escaping (CoreCryptoContextProtocol) async throws -> T) async throws -> T
    func configure(block: (CoreCryptoProtocol) async throws -> Void) async throws
    func tearDown() throws
}

public class SafeCoreCrypto: SafeCoreCryptoProtocol {

    public enum CoreCryptoSetupFailure: Error, Equatable {
        case failedToGetClientIDBytes
    }

    private let coreCrypto: CoreCryptoProtocol
    private let safeContext: SafeFileContext
    private let databasePath: String

    public convenience init(path: String, key: Data) async throws {

        let coreCrypto = try await CoreCrypto(
            keystorePath: path,
            key: key
        )

        setLogger(logger: CoreCryptoLoggerProxy(), level: .info)
        self.init(coreCrypto: coreCrypto, databasePath: path)
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

    public func perform<T>(_ block: @escaping (CoreCryptoContextProtocol) async throws -> T) async throws -> T {
        safeContext.acquireDirectoryLock()
        await restoreFromDisk()

        defer {
            safeContext.releaseDirectoryLock()
        }

        return try await coreCrypto.transaction(block)
    }

    public func unsafePerform<T>(_ block: @escaping (CoreCryptoContextProtocol) async throws -> T) async throws -> T {
        try await coreCrypto.transaction(block)
    }

    public func configure(block: (any CoreCryptoProtocol) async throws -> Void) async throws {
        try await block(coreCrypto)
    }

    private func restoreFromDisk() async {
        do {

            try await coreCrypto.transaction { context in
                try await context.proteusReloadSessions()
            }
        } catch {
            WireLogger.coreCrypto.error("coreCrypto.restoreFromDisk() failed: \(error)", attributes: .safePublic)
        }
    }
}
