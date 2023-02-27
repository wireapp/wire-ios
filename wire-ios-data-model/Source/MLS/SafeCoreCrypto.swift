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
import CoreCryptoSwift

// MARK: - Protocols

public protocol SafeCoreCryptoProtocol {
    func perform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T
    func unsafePerform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T
}

public struct SafeCoreCrypto: SafeCoreCryptoProtocol {
    public enum CoreCryptoSetupFailure: Error, Equatable {
        case failedToGetClientIDBytes
    }

    private let coreCrypto: CoreCryptoProtocol
    private let safeContext: SafeFileContext

    public init(coreCryptoConfiguration config: CoreCryptoConfiguration) throws {
        guard let clientID = config.clientIDBytes() else {
            throw CoreCryptoSetupFailure.failedToGetClientIDBytes
        }
        let coreCrypto = try CoreCrypto(
            path: config.path,
            key: config.key,
            clientId: clientID,
            entropySeed: nil
        )

        self.init(coreCrypto: coreCrypto, coreCryptoConfiguration: config)
    }

    init(coreCrypto: CoreCryptoProtocol, coreCryptoConfiguration: CoreCryptoConfiguration) {
        self.coreCrypto = coreCrypto
        let directoryPathUrl = URL(fileURLWithPath: coreCryptoConfiguration.path).deletingLastPathComponent()
        self.safeContext = SafeFileContext(fileURL: directoryPathUrl)
    }

    public func perform<T>(_ block: (CoreCryptoProtocol) throws -> T) rethrows -> T {
        var result: T
        safeContext.acquireDirectoryLock()
        restoreFromDisk()
        result = try block(coreCrypto)
        safeContext.releaseDirectoryLock()
        return result
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
