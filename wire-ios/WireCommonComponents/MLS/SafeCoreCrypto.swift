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
    func perform<T>(_ block: (CoreCryptoInterface) throws -> T) rethrows -> T
}


public struct SafeCoreCrypto: SafeCoreCryptoProtocol {

    private let coreCrypto: CoreCryptoInterface
    private let safeContext: SafeFileContext

    init(coreCrypto: CoreCryptoInterface, coreCryptoConfiguration: CoreCryptoConfiguration) {
        self.coreCrypto = coreCrypto
        let pathUrl = URL(fileURLWithPath: coreCryptoConfiguration.path)
        self.safeContext = SafeFileContext(fileURL: pathUrl)
    }

    public func perform<T>(_ block: (CoreCryptoInterface) throws -> T) rethrows -> T {
        var result: T
        safeContext.acquireDirectoryLock()
        //TODO: call `restoreFromDisk`
        result = try block(coreCrypto)
        safeContext.releaseDirectoryLock()
        return result
    }
}
