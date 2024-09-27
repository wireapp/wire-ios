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

import Foundation
import WireCoreCrypto

// MARK: - SafeCoreCryptoProtocol

public protocol SafeCoreCryptoProtocol {
    func perform<T>(_ block: (CoreCryptoProtocol) async throws -> T) async rethrows -> T
    func unsafePerform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T
    func tearDown() throws
}

// MARK: - SafeCoreCrypto

public class SafeCoreCrypto: SafeCoreCryptoProtocol {
    public enum CoreCryptoSetupFailure: Error, Equatable {
        case failedToGetClientIDBytes
    }

    private let coreCrypto: CoreCryptoProtocol
    private let safeContext: SafeFileContext
    private let databasePath: String

    public convenience init(path: String, key: String) async throws {
        let coreCrypto = try await coreCryptoDeferredInit(
            path: path,
            key: key
        )

        try await coreCrypto.setCallbacks(callbacks: CoreCryptoCallbacksImpl())

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

    public func perform<T>(_ block: (CoreCryptoProtocol) async throws -> T) async rethrows -> T {
        safeContext.acquireDirectoryLock()
        await restoreFromDisk()

        defer {
            safeContext.releaseDirectoryLock()
        }

        return try await block(coreCrypto)
    }

    public func unsafePerform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T {
        try block(coreCrypto)
    }

    private func restoreFromDisk() async {
        do {
            try await coreCrypto.restoreFromDisk()
        } catch {
            WireLogger.coreCrypto.error("coreCrypto.restoreFromDisk() failed: \(error)", attributes: .safePublic)
        }
    }
}
